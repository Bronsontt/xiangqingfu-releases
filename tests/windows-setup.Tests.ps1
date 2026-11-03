param([string]$SourceRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$templates = Join-Path $SourceRoot 'distribution/sidestore'
if (-not (Test-Path -LiteralPath $templates)) { $templates = $SourceRoot }
$source = Join-Path $templates 'Install-XiangQingFu.ps1'
$launcher = Join-Path $templates 'Install-XiangQingFu.cmd'
$errors = $null; $tokens = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($source, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
[void][System.Management.Automation.Language.Parser]::ParseFile($launcher, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
. $source
$script:count = 0
function Check([string]$Name, [scriptblock]$Body) {
    & $Body
    $script:count++
    Write-Host "PASS $Name"
}
function Reject([scriptblock]$Body) {
    $rejected = $false
    try { & $Body | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw 'Expected rejection.' }
}
$work = Join-Path ([IO.Path]::GetTempPath()) ('xqf-test-' + [Guid]::NewGuid().ToString('N'))
$kit = Join-Path $work "中文 family's kit & test (1)"
New-Item -ItemType Directory -Path (Join-Path $kit 'tools') -Force | Out-Null
function Write-Sums {
    $lines = @()
    foreach ($path in @('manifest.json', 'XiangQingFu-1.0-1-SideStore.ipa', 'tools/iloader-release.json', 'tools/iloader-test.msi')) {
        $lines += ((Get-XqfHash (Join-Path $kit $path)) + '  ' + $path)
    }
    $lines | Set-Content -LiteralPath (Join-Path $kit 'SHA256SUMS.txt') -Encoding UTF8
}
try {
    'test IPA bytes, not executable' | Set-Content -LiteralPath (Join-Path $kit 'XiangQingFu-1.0-1-SideStore.ipa') -Encoding UTF8
    'test installer bytes, never executed' | Set-Content -LiteralPath (Join-Path $kit 'tools/iloader-test.msi') -Encoding UTF8
    $ipa = Join-Path $kit 'XiangQingFu-1.0-1-SideStore.ipa'
    $msi = Join-Path $kit 'tools/iloader-test.msi'
    $manifest = @{ version = '1.0'; build = '1'; minimumOSVersion = '17.0'; ipa = 'XiangQingFu-1.0-1-SideStore.ipa'; ipaSHA256 = Get-XqfHash $ipa; ipaBytes = (Get-Item $ipa).Length }
    $manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $kit 'manifest.json') -Encoding UTF8
    @{version='v2.4.1'; installer=@{filename='iloader-test.msi'; url='https://github.com/nab138/iloader/releases/download/v2.4.1/iloader-windows-x64.msi'; sha256=Get-XqfHash $msi; size=(Get-Item $msi).Length}} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $kit 'tools/iloader-release.json') -Encoding UTF8
    Write-Sums
    Check 'valid local package, Unicode and shell characters in path' {
        $result = Test-XqfPackage $kit
        if ($result.Ipa -ne $ipa) { throw 'Wrong IPA path.' }
    }
    Check 'tampered IPA rejected' {
        $original = [IO.File]::ReadAllBytes($ipa)
        Add-Content -LiteralPath $ipa -Value 'tampered'
        Reject { Test-XqfPackage $kit }
        [IO.File]::WriteAllBytes($ipa, $original)
    }
    Check 'tampered installer rejected' {
        $original = [IO.File]::ReadAllBytes($msi)
        Add-Content -LiteralPath $msi -Value 'tampered'
        Reject { Test-XqfPackage $kit }
        [IO.File]::WriteAllBytes($msi, $original)
    }
    Check 'missing checksum entry rejected' {
        Get-Content -LiteralPath (Join-Path $kit 'SHA256SUMS.txt') | Where-Object { $_ -notmatch 'manifest.json$' } | Set-Content -LiteralPath (Join-Path $work 'short-sums.txt')
        Copy-Item -LiteralPath (Join-Path $work 'short-sums.txt') -Destination (Join-Path $kit 'SHA256SUMS.txt') -Force
        Reject { Test-XqfPackage $kit }
        Write-Sums
    }
    Check 'duplicate checksum rejected' {
        Add-Content -LiteralPath (Join-Path $kit 'SHA256SUMS.txt') -Value ((Get-XqfHash $ipa) + '  XiangQingFu-1.0-1-SideStore.ipa')
        Reject { Test-XqfPackage $kit }
        Write-Sums
    }
    Check 'manifest size mismatch rejected even with matching checksums' {
        $manifest.ipaBytes++
        $manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $kit 'manifest.json') -Encoding UTF8
        Write-Sums
        Reject { Test-XqfPackage $kit }
        $manifest.ipaBytes--
        $manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $kit 'manifest.json') -Encoding UTF8
        Write-Sums
    }
    Check 'path traversal, absolute path and ADS rejected' {
        foreach ($path in @('../escape', 'tools/../../escape', '..\escape', 'C:\escape', '/escape', 'file:stream')) {
            Reject { Resolve-XqfFile $kit $path }
        }
    }
    Check 'release asset host, state, and tag checked' {
        $asset = @{name='kit.zip'; state='uploaded'; browser_download_url='https://github.com/Bronsontt/xiangqingfu-releases/releases/download/v1/kit.zip'}
        Test-XqfAssetUrl $asset 'v1'
        Reject { Test-XqfAssetUrl $asset 'v2' }
        $asset.browser_download_url = 'https://example.com/kit.zip'
        Reject { Test-XqfAssetUrl $asset 'v1' }
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Check 'ZIP traversal blocked before extraction' {
        $zipPath = Join-Path $work 'malicious.zip'
        $archive = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
        [void]$archive.CreateEntry('../escaped.txt')
        $archive.Dispose()
        Reject { Expand-XqfArchive $zipPath (Join-Path $work 'bad-unpack') }
        if (Test-Path -LiteralPath (Join-Path $work 'escaped.txt')) { throw 'Escaped archive.' }
    }
    Check 'duplicate ZIP path blocked' {
        $zipPath = Join-Path $work 'duplicate.zip'
        $archive = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
        [void]$archive.CreateEntry('same.txt'); [void]$archive.CreateEntry('same.txt')
        $archive.Dispose()
        Reject { Expand-XqfArchive $zipPath (Join-Path $work 'duplicate-unpack') }
    }
    $fixtureZip = Join-Path $work 'fixture.zip'
    [IO.Compression.ZipFile]::CreateFromDirectory($kit, $fixtureZip)
    Check 'valid archive extracts and verifies' {
        $destination = Join-Path $work 'good-unpack'
        Expand-XqfArchive $fixtureZip $destination
        [void](Test-XqfPackage $destination)
    }
    # Exercise the real orchestration with network replaced by local bytes, including resume.
    $script:downloads = 0
    $script:fakeRelease = @{draft=$false; prerelease=$false; id=123; tag_name='v1'; assets=@(@{name='XiangQingFu-SideStore-Family-1-1.zip'; state='uploaded'; digest=('sha256:' + (Get-XqfHash $fixtureZip)); size=(Get-Item $fixtureZip).Length; browser_download_url='https://github.com/Bronsontt/xiangqingfu-releases/releases/download/v1/XiangQingFu-SideStore-Family-1-1.zip'})}
    function Invoke-XqfRequest([string]$Url, [string]$OutFile='') {
        if ($Url -eq 'https://api.github.com/repos/Bronsontt/xiangqingfu-releases/releases/latest') { return ($script:fakeRelease | ConvertTo-Json -Depth 10) }
        if ($OutFile) { Copy-Item -LiteralPath $fixtureZip -Destination $OutFile; $script:downloads++; return }
        return ((Get-XqfHash $fixtureZip) + '  XiangQingFu-SideStore-Family-1-1.zip')
    }
    Check 'release download and cache reuse are verified' {
        $cache = Join-Path $work 'cache'
        [void](Test-XqfPackage (Get-XqfPackage $cache))
        [void](Test-XqfPackage (Get-XqfPackage $cache))
        if ($script:downloads -ne 1) { throw 'Verified ZIP was downloaded again.' }
    }
    Check 'ambiguous release rejected' {
        $script:fakeRelease.assets += $script:fakeRelease.assets[0]
        Reject { Get-XqfPackage (Join-Path $work 'ambiguous-cache') }
        $script:fakeRelease.assets = @($script:fakeRelease.assets[0])
    }
    Check 'checksum-file fallback works' {
        $script:fakeRelease.assets[0].digest = $null
        $script:fakeRelease.assets += @{name='BUNDLE-SHA256.txt'; state='uploaded'; browser_download_url='https://github.com/Bronsontt/xiangqingfu-releases/releases/download/v1/BUNDLE-SHA256.txt'}
        [void](Test-XqfPackage (Get-XqfPackage (Join-Path $work 'fallback-cache')))
    }
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
        Check 'real CMD launcher under Windows PowerShell, no installs' {
            $cmdPath = Join-Path $kit 'Install-XiangQingFu.cmd'
            Copy-Item -LiteralPath $launcher -Destination $cmdPath
            $env:XQF_VERIFY_PACKAGE = $kit
            $output = & $cmdPath 2>&1
            if ($LASTEXITCODE -ne 0 -or ($output -join "`n") -notmatch 'PACKAGE_VERIFIED 1.0') { throw ($output | Out-String) }
            Remove-Item Env:XQF_VERIFY_PACKAGE
        }
    }
    Write-Host "ALL $script:count TESTS PASSED; no software installed and no phone actions performed."
} finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
