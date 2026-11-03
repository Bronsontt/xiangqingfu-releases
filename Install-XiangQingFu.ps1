# Compatible with Windows PowerShell 5.1. Dot-source to test without running setup.
param([string]$PackageRoot = '', [switch]$ValidateOnly)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Get-XqfHash([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Resolve-XqfFile([string]$Root, [string]$Relative) {
    if ([string]::IsNullOrWhiteSpace($Relative) -or $Relative.Contains(':') -or
        [IO.Path]::IsPathRooted($Relative) -or $Relative -match '(^|[\\/])\.\.([\\/]|$)') {
        throw "Unsafe package path: $Relative"
    }
    $base = [IO.Path]::GetFullPath($Root).TrimEnd([char[]]@('/', '\')) + [IO.Path]::DirectorySeparatorChar
    $path = [IO.Path]::GetFullPath((Join-Path $base $Relative))
    if (-not $path.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) { throw 'Path escapes package.' }
    return $path
}

function Invoke-XqfRequest([string]$Url, [string]$OutFile = '') {
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            $parameters = @{ Uri = $Url; UseBasicParsing = $true; TimeoutSec = 45;
                Headers = @{ 'User-Agent' = 'XiangQingFu-Windows-Setup/2' }; ErrorAction = 'Stop' }
            if ($OutFile) {
                Invoke-WebRequest @parameters -OutFile ($OutFile + '.part') | Out-Null
                Move-Item -LiteralPath ($OutFile + '.part') -Destination $OutFile -Force
                return
            }
            return (Invoke-WebRequest @parameters).Content
        } catch {
            if ($OutFile) { Remove-Item -LiteralPath ($OutFile + '.part') -Force -ErrorAction SilentlyContinue }
            if ($attempt -eq 3) { throw }
            Start-Sleep -Seconds $attempt
        }
    }
}

function Test-XqfAssetUrl($Asset, [string]$Tag) {
    $expected = 'https://github.com/Bronsontt/xiangqingfu-releases/releases/download/' +
        [Uri]::EscapeDataString($Tag) + '/' + [Uri]::EscapeDataString([string]$Asset.name)
    if ($Asset.state -ne 'uploaded' -or $Asset.browser_download_url -cne $expected) {
        throw 'Unexpected release asset source.'
    }
}

function Expand-XqfArchive([string]$Zip, [string]$Destination) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($Zip)
    try {
        $seen = @{}
        $total = [long]0
        foreach ($entry in $archive.Entries) {
            $path = Resolve-XqfFile $Destination $entry.FullName
            if ($seen.ContainsKey($path)) { throw 'Duplicate ZIP path.' }
            $seen[$path] = $true
            $total += $entry.Length
            if ($total -gt 536870912 -or $archive.Entries.Count -gt 2000) { throw 'Unexpected package size.' }
            if ((($entry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000) { throw 'ZIP symlink rejected.' }
        }
    } finally { $archive.Dispose() }
    Expand-Archive -LiteralPath $Zip -DestinationPath $Destination -Force
}

function Get-XqfPackage([string]$CacheRoot) {
    Write-Host '正在获取相清夫安装包（失败后可再次双击重试）…'
    $release = Invoke-XqfRequest 'https://api.github.com/repos/Bronsontt/xiangqingfu-releases/releases/latest' | ConvertFrom-Json
    if ($release.draft -ne $false -or $release.prerelease -ne $false -or
        [string]$release.tag_name -notmatch '^[A-Za-z0-9._-]+$' -or [string]$release.id -notmatch '^\d+$') {
        throw 'Invalid stable release metadata.'
    }
    $assets = @($release.assets | Where-Object { $_.name -match '^XiangQingFu-SideStore-Family-[A-Za-z0-9._-]+\.zip$' })
    if ($assets.Count -ne 1) { throw 'Expected exactly one family ZIP in this release.' }
    $asset = $assets[0]
    Test-XqfAssetUrl $asset $release.tag_name
    $folder = Join-Path $CacheRoot ([string]$release.id)
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $release | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $folder 'release.json') -Encoding UTF8
    $expected = ''
    if ([string]$asset.digest -match '^sha256:([a-fA-F0-9]{64})$') { $expected = $Matches[1] }
    else {
        $sums = @($release.assets | Where-Object { $_.name -eq 'BUNDLE-SHA256.txt' })
        if ($sums.Count -ne 1) { throw 'No release SHA-256 available.' }
        Test-XqfAssetUrl $sums[0] $release.tag_name
        $lines = (Invoke-XqfRequest $sums[0].browser_download_url) -split '\r?\n'
        $matching = @($lines | Where-Object { $_ -match ('^[a-fA-F0-9]{64}  ' + [regex]::Escape($asset.name) + '$') })
        if ($matching.Count -ne 1) { throw 'Missing or ambiguous ZIP checksum.' }
        $expected = $matching[0].Substring(0, 64)
    }
    $zip = Join-Path $folder $asset.name
    if (-not (Test-Path -LiteralPath $zip) -or (Get-XqfHash $zip) -ne $expected) {
        Invoke-XqfRequest $asset.browser_download_url $zip
    }
    if ((Get-Item -LiteralPath $zip).Length -ne [long]$asset.size -or (Get-XqfHash $zip) -ne $expected) {
        throw '安装包大小或 SHA-256 不匹配。已停止，不运行包内程序。'
    }
    # Always unpack the verified ZIP into a new directory; do not reuse partially extracted scripts.
    $expanded = Join-Path $folder ('unpacked-' + [Guid]::NewGuid().ToString('N'))
    Expand-XqfArchive $zip $expanded
    $roots = @(Get-ChildItem -LiteralPath $expanded -Filter manifest.json -Recurse -File)
    if ($roots.Count -ne 1) { throw 'Expected exactly one manifest.' }
    return $roots[0].DirectoryName
}

function Test-XqfPackage([string]$Root) {
    $sumsFile = Join-Path $Root 'SHA256SUMS.txt'
    $seen = @{}
    foreach ($line in (Get-Content -LiteralPath $sumsFile -Encoding UTF8)) {
        if (-not $line.Trim()) { continue }
        if ($line -notmatch '^([a-fA-F0-9]{64})  (.+)$') { throw 'Invalid SHA256SUMS line.' }
        $hash = $Matches[1]; $relative = $Matches[2]
        $path = Resolve-XqfFile $Root $relative
        if ($seen.ContainsKey($relative)) { throw 'Duplicate checksum entry.' }
        $seen[$relative] = $true
        if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-XqfHash $path) -ne $hash) {
            throw "文件校验失败：$relative"
        }
    }
    foreach ($required in @('manifest.json', 'tools/iloader-release.json')) {
        if (-not $seen.ContainsKey($required)) { throw "Missing checksum: $required" }
    }
    $manifest = Get-Content -LiteralPath (Join-Path $Root 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$manifest.ipa -notmatch '^XiangQingFu-[A-Za-z0-9._-]+\.ipa$' -or
        -not $seen.ContainsKey([string]$manifest.ipa)) { throw 'Invalid IPA filename.' }
    $ipa = Resolve-XqfFile $Root $manifest.ipa
    if ((Get-XqfHash $ipa) -ne $manifest.ipaSHA256 -or (Get-Item -LiteralPath $ipa).Length -ne $manifest.ipaBytes) {
        throw 'IPA does not match manifest.'
    }
    $release = Get-Content -LiteralPath (Join-Path $Root 'tools/iloader-release.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $installer = $release.installer
    $installerPath = Resolve-XqfFile $Root ('tools/' + $installer.filename)
    if (-not $seen.ContainsKey('tools/' + $installer.filename) -or
        [string]$installer.url -notmatch '^https://github\.com/nab138/iloader/releases/download/v[0-9.]+/iloader-windows-x64\.msi$' -or
        (Get-XqfHash $installerPath) -ne $installer.sha256 -or
        (Get-Item -LiteralPath $installerPath).Length -ne $installer.size) { throw 'iloader verification failed.' }
    return @{ Manifest = $manifest; Ipa = $ipa; Installer = $installerPath; IloaderVersion = $release.version }
}

function Find-XqfIloader {
    $candidates = @()
    foreach ($base in @($env:LOCALAPPDATA, $env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if ($base) { $candidates += (Join-Path $base 'iloader\iloader.exe') }
    }
    $command = Get-Command iloader.exe -ErrorAction SilentlyContinue
    if ($command) { $candidates += $command.Source }
    foreach ($key in @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
        $entries = @(Get-ItemProperty -Path $key -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq 'iloader' })
        foreach ($entry in $entries) {
            if ($entry.InstallLocation) { $candidates += (Join-Path $entry.InstallLocation 'iloader.exe') }
        }
    }
    foreach ($path in $candidates) {
        if (Test-Path -LiteralPath $path -PathType Leaf) { return $path }
    }
    return $null
}

function Get-XqfAppleService {
    return Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*Apple*Mobile*Device*' } | Select-Object -First 1
}

function Start-XqfSetup([string]$LocalPackage = '') {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw '请在家人的 Windows 电脑上运行。' }
    if ($PSVersionTable.PSVersion.Major -lt 5) { throw '需要 Windows PowerShell 5.1 或更新版本。' }
    $architecture = $env:PROCESSOR_ARCHITECTURE
    if ($env:PROCESSOR_ARCHITEW6432) { $architecture = $env:PROCESSOR_ARCHITEW6432 }
    if ($architecture -ne 'AMD64') { throw '此入口适用于 Intel/AMD 64 位 Windows。其他架构请交给 agent 核对官方安装器。' }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    [Console]::OutputEncoding = New-Object Text.UTF8Encoding
    $cache = Join-Path $env:LOCALAPPDATA 'XiangQingFu-Setup'
    New-Item -ItemType Directory -Path $cache -Force | Out-Null
    $statusPath = Join-Path $cache 'setup-status.json'
    $status = [ordered]@{ setupRevision = 2; startedAt = [DateTimeOffset]::Now.ToString('o');
        stage = 'preparing'; phoneInstallation = 'not_verified'; renewal = 'not_verified' }
    $status | ConvertTo-Json | Set-Content -LiteralPath $statusPath -Encoding UTF8
    try {
        if (-not $LocalPackage) {
            $base = if ($env:XQF_LAUNCHER) { Split-Path -Parent $env:XQF_LAUNCHER } else { $PSScriptRoot }
            if ($base -and (Test-Path -LiteralPath (Join-Path $base 'manifest.json'))) { $LocalPackage = $base }
            else { $LocalPackage = Get-XqfPackage $cache }
        }
        $kit = Test-XqfPackage $LocalPackage
        $status.stage = 'package_verified'
        $status['packageRoot'] = $LocalPackage
        $status['ipaSHA256'] = Get-XqfHash $kit.Ipa
        $status['appVersion'] = [string]$kit.Manifest.version
        $status['appBuild'] = [string]$kit.Manifest.build
        $status | ConvertTo-Json | Set-Content -LiteralPath $statusPath -Encoding UTF8
        $appleService = Get-XqfAppleService
        if (-not $appleService) {
            Write-Host '未检测到 Apple 手机驱动服务。正在准备官方 iTunes；已有 Apple Devices 的电脑可先在其中确认手机连接。'
            $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
            if ($winget) {
                & $winget.Source install --id Apple.iTunes --exact --source winget --accept-source-agreements --accept-package-agreements
                $appleService = Get-XqfAppleService
            }
            if (-not $appleService) {
                Start-Process 'https://www.apple.com/itunes/download/win64'
                throw '请完成已打开的 Apple 官方 iTunes 安装（或让 agent 检查现有 Apple Devices 驱动），然后再次双击此入口继续。'
            }
        }
        $status['appleDriverService'] = [string]$appleService.Status
        $iloader = Find-XqfIloader
        if (-not $iloader) {
            Write-Host '正在安装已校验的官方 iloader；如出现 Windows 权限提示，请本人确认。'
            $process = Start-Process msiexec.exe -ArgumentList ('/i "' + $kit.Installer + '" /passive /norestart') -Wait -PassThru
            if ($process.ExitCode -eq 3010 -or $process.ExitCode -eq 1641) {
                throw 'iloader 安装要求重启 Windows。重启后再次双击入口即可继续。'
            }
            if ($process.ExitCode -ne 0) { throw "iloader 安装未完成，Windows Installer 返回 $($process.ExitCode)。请保留此错误交给 agent。" }
            $iloader = Find-XqfIloader
            if (-not $iloader) { throw 'iloader 已运行安装器，但尚未找到程序。请让 agent 定位，不重复卸载安装。' }
        }
        $status['iloaderPath'] = $iloader
        # iloader 2.4.1 has no public CLI for importing an IPA. Do not invent one or automate credentials.
        $clipboardReady = $false
        try { Set-Clipboard -Value $kit.Ipa; $clipboardReady = $true } catch { }
        $instructions = @"
相清夫安装助手 · 已准备好安装文件

1. 用数据线连接 iPhone，解锁并点“信任此电脑”。
2. 在已打开的 iloader 中选择手机；若未登录，请本人登录 Apple 账号。
3. 点击 Import IPA（导入 IPA），在文件名输入框粘贴下面的完整路径，再点打开：

$($kit.Ipa)

随后等待 iloader 的签名和安装完成。
手机提示未信任开发者时：设置 → 通用 → VPN 与设备管理 → 信任对应开发者。
手机要求开发者模式时：设置 → 隐私与安全性 → 开发者模式 → 开启并重启确认。
系统最低要求：iOS / iPadOS $($kit.Manifest.minimumOSVersion)。

这一步不需要 SideStore 登录或 LocalDevVPN。已有 SideStore 和相清夫请保留。
免费签名有效期为 7 天：建议每 5 天接回电脑，以同一账号、同一安装标识再次 Import IPA 覆盖续签。
请勿卸载相清夫，否则本地整理进度会丢失。切换签名工具时先核对安装标识。
本助手只完成电脑准备；请实际打开手机上的相清夫确认成功。
密码、验证码只在 iloader/手机界面输入，不交给 agent。

SideStore 的手机独立续签可以稍后排查，见安装包中的 REPAIR-SIDESTORE.md。
准备状态：$statusPath
"@
        $next = Join-Path $cache 'NEXT-STEPS.txt'
        $instructions | Set-Content -LiteralPath $next -Encoding UTF8
        Start-Process -FilePath $iloader
        Start-Process notepad.exe -ArgumentList ('"' + $next + '"')
        $status.stage = 'ready_for_import_ipa'
        $status['clipboardContainsIpaPath'] = $clipboardReady
        $status | ConvertTo-Json | Set-Content -LiteralPath $statusPath -Encoding UTF8
        Write-Host '电脑准备完成。请按打开的说明在 iloader 点击 Import IPA。手机安装结果尚未验证。' -ForegroundColor Green
        Write-Host "再次双击可恢复准备；状态文件：$statusPath"
    } catch {
        $status.stage = 'needs_attention'
        $status['error'] = $_.Exception.Message
        $status | ConvertTo-Json | Set-Content -LiteralPath $statusPath -Encoding UTF8
        throw
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        # This read-only mode also allows exercising the .cmd entry in Windows CI.
        if ($env:XQF_VERIFY_PACKAGE) { $PackageRoot = $env:XQF_VERIFY_PACKAGE; $ValidateOnly = $true }
        if ($ValidateOnly) {
            if (-not $PackageRoot) { throw 'ValidateOnly requires PackageRoot.' }
            $verified = Test-XqfPackage $PackageRoot
            Write-Host ('PACKAGE_VERIFIED ' + $verified.Manifest.version)
        } else { Start-XqfSetup $PackageRoot }
    }
    catch { Write-Host ("准备未完成：" + $_.Exception.Message) -ForegroundColor Red; exit 1 }
}
