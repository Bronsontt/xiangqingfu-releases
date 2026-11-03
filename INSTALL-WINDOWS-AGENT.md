# Windows agent 安装任务：先通过 USB 安装相清夫

安装流程修订 2 · 2026-11-03。供能够操作家人实际 Windows 电脑的 agent 执行。用户要求安装时执行；仅要求阅读时不执行。

## 本次修复与完成目标

默认流程改为 **Windows iloader → Import IPA → 直接安装相清夫**。SideStore 和 LocalDevVPN 均不再是安装前置条件。安装成功后，可再配置手机独立续签。

截图中 `Welcome to SideStore / Failed to Sign In / kCFErrorDomainCFNetwork error -1005` 是 **SideStore 的登录连接中断**，不是 LocalDevVPN 的登录失败，也不是 SideStore 的正数 `1005` 文件不存在错误。不要因此反复卸载 VPN、重装 SideStore 或反复提交密码。

家人若已在 iloader 登录、已连接手机，优先复用，直接到第 3 节。无需企业证书、越狱、LiveContainer、JIT 或付费会员。

## 操作分工：尽量只让家人批准

- 下载、解压、校验、定位文件、复制/填写路径、运行命令和点击电脑按钮均由 agent 完成；不要把这些步骤逐项交给家人执行。优先使用已有本机命令行、桌面控制或 UI 自动化能力。
- 用户已授权本任务范围内必要的下载、校验、常规软件安装与相清夫安装时，直接推进；仅在系统或工具明确要求审批、需要判断影响其他 App 的操作，或本人不可替代的手机确认/验证时停下。
- 优先复用 iloader 已有登录和配对，不主动退出账号或反复索要凭据。Apple 若要求重新登录、验证码或手机锁屏密码，由本人在对应界面输入；不能承诺这些操作只点批准即可完成，也不读取或导出保存的密码。
- 安装助手显示“准备完成”后必须继续操作 iloader 的 Import IPA，等待实际签名安装结果；不能停在打开软件、复制路径或显示说明这一步。
- 遇错先检查实际状态、读取错误并执行适用修复。缺少桌面控制能力时明确说明限制，先完成其他可执行步骤，不假装已经完成界面操作。
- 保留已完成进度；接线、手机解锁、信任和开发者模式等必须本人操作的环节，每次只说明当前必要的一步。最终以 iloader 安装结果和家人实际打开 App 的反馈验收。

## 1. 下载与自动准备

优先下载本仓库的 [Install-XiangQingFu.cmd](https://github.com/Bronsontt/xiangqingfu-releases/blob/main/Install-XiangQingFu.cmd)，保存为同名 `.cmd` 后运行。这是可检查的本项目启动脚本，不是 iloader 官方程序。

- 自动查询本仓库最新稳定 Release，下载唯一家庭 ZIP；先核对 Release 的 SHA-256 和大小，再解压并校验 IPA 与官方 iloader 安装器。
- 缓存位于 `%LOCALAPPDATA%\XiangQingFu-Setup`。下载中断后重新运行会复用校验通过的 ZIP。也可在完整安装包内直接双击入口。
- 已有 iloader 优先复用。缺少 Apple 手机驱动时尝试通过 winget 的 `Apple.iTunes` 准备官方组件；无 winget 或仍缺驱动时打开 Apple 官方入口并提示下一步。
- 启动器打开 iloader 和当前操作说明，并尝试复制准确 IPA 路径。**它不会自动登录、点击 Import IPA、确认手机权限，也不会将“电脑准备好”写成“手机安装成功”。** agent 应继续完成能操作的界面步骤。
- 不以管理员身份运行整个 agent；UAC 由本人确认。密码、验证码、锁屏密码只在官方来源的 iloader 或手机界面输入，不进入聊天、脚本、日志。
- 只有云端容器、未连接用户 Windows 时，说明无法操控本机；继续提供启动器和必要步骤，不假装已操作电脑或手机。

入口支持 Intel/AMD x64 Windows、Windows PowerShell 5.1+。其他架构核对 [iloader 官方发布](https://github.com/nab138/iloader/releases)，不强装 x64 包，不关闭防火墙、杀毒软件或组织策略。

### 自动入口不可用时

1. 读取 `https://api.github.com/repos/Bronsontt/xiangqingfu-releases/releases/latest`，确认非 draft、非 prerelease，固定这一次 `tag_name`。
2. 下载唯一匹配 `^XiangQingFu-SideStore-Family-.+\.zip$` 的 uploaded 附件。API 不通时从同一个官方 Release 页面取附件，不使用未知镜像。
3. 比较 asset 的 `digest`（`sha256:`）及 `size`；没有 digest 时用同一 Release 的 `BUNDLE-SHA256.txt`，精确匹配文件名。校验失败不解压或运行。
4. 解压到本次新建目录，读取唯一 `manifest.json`。核对 IPA 的 SHA-256、大小、最低系统版本和包内 `tools/iloader-release.json`。清单路径不得逃出解压目录。
5. 最新 Release 若仍包含修订 1 的说明，以**本文件的 USB 直接安装流程**为准；旧包内的“先刷新 SideStore”不再是前置要求。IPA 本身无需更改。
6. 已有可运行 iloader 和可识别手机的驱动直接复用，否则安装已校验的官方 iloader，按 [官方准备页](https://docs.sidestore.io/docs/installation/prerequisites) 补充 Apple 驱动。

## 2. 复用当前进度

- 读取 `%LOCALAPPDATA%\XiangQingFu-Setup\setup-status.json` 和 `NEXT-STEPS.txt`（若存在）。状态只表示电脑准备进度，不证明手机已安装。
- iloader 已显示 `Sign Out` / 已登录时，不让家人再次输入密码。手机上的 SideStore 登录可以暂时关闭。
- 已安装的 SideStore、LocalDevVPN、相清夫均保留；不要用卸载、删除配对、撤销全部证书来“重来一次”。
- 核对目标手机、iOS 版本（相清夫最低 iOS 17.0，以 manifest 为准）和空闲开发签名 App 名额。连接多台设备时确认目标。
- 若旧版相清夫由其他工具签名，先核对实际 Bundle ID、原 Apple 账号及工具的标识修改设置；无法保证同一标识时暂停覆盖步骤，不删除旧 App 或承诺迁移保留数据。

## 3. 直接安装相清夫（默认路径）

1. 请家人用 USB 数据线连接 iPhone，解锁并在手机上点“信任此电脑”。确认 iloader 已识别目标设备。
2. 若未登录，让本人在 iloader 界面登录自己的 Apple 账号并完成验证；不退出手机现有 iCloud 账号。
3. **点击 `Import IPA`（导入 IPA），选择已经校验的相清夫 `.ipa`。不要点击 `Install SideStore`，不要导入外层 ZIP。** 文件名和绝对路径来自 manifest / NEXT-STEPS.txt。
4. 等待 iloader 签名和安装完成。iloader 2.4.1 官方界面支持 Import IPA；没有已核实的无交互命令行导入参数，不凭空编造 `--install` 命令。
5. 手机要求信任开发者时：设置 → 通用 → VPN 与设备管理 → 对应开发者 → 信任（部分系统为允许并重启）。
6. 手机要求开发者模式时：设置 → 隐私与安全性 → 开发者模式 → 开启，重启后再次确认。已开启则跳过。
7. 打开手机上的相清夫，让家人自己选择照片权限；只浏览授权照片验收，不删除或修改真实照片。

每次只给家人当前需要完成的 1～3 步。电脑 GUI 能操作的按钮由 agent 操作，手机和账号安全确认由本人完成。

### iloader 也失败时

- `Download SideStore` 一直转圈：这是 SideStore 下载阶段。在确认没有正在写入设备后结束该任务，回到 **Import IPA** 导入本地相清夫文件。
- iloader 本身登录失败：记录完整错误类型及脱敏错误码，不循环提交密码。检查电脑时间、官方登录服务及当前网络；电脑测试通过不代表手机通过。
- 找不到手机：确认线材、解锁、信任和 Apple Mobile Device 服务；先复用已有 iTunes/Apple Devices，不盲目卸载。
- 超过免费 App 名额、App ID 限额、证书冲突：读取具体错误并说明影响，不自动删除其他 App 或撤销证书。
- 相清夫代码没有参与 SideStore 登录请求，不把该登录问题归因到相清夫 IPA。

## 4. 免费续签（必须交代）

USB 路线没有取消免费签名 **7 天**有效期。建议每 **5 天**接回 Windows，用**同一个 Apple 账号、同一个实际安装标识**在 iloader 再次 `Import IPA` 覆盖安装。不要卸载相清夫。若版本提供可用刷新入口，以实际界面为准，不假定存在未核实的按钮。

这条路线需要电脑续签；只有完成下一节验收后，才能告知家人可以脱离电脑续签。不要承诺后台必定刷新或永久免电脑。

## 5. 可选：修复 SideStore 手机独立续签

相清夫已经能用后，若家人需要手机续签，再按 [REPAIR-SIDESTORE.md](https://github.com/Bronsontt/xiangqingfu-releases/blob/main/REPAIR-SIDESTORE.md) 分别检查网络、LocalDevVPN 本地隧道、Anisette 和配对。

修复后先刷新 SideStore 自己，再用同一账号且核对实际标识后将相清夫导入 SideStore 管理。**不要假定 iloader 装好的相清夫会自动出现在 SideStore 的可续签列表中。** 拔掉 USB，确认 SideStore 和相清夫都在 Wi-Fi + LocalDevVPN 下刷新成功，才记为“手机独立续签已验证”。

## 6. 验收与交接

分别记录，不把准备或替代方案写成原故障已修好：

| 项目 | 通过标准 |
| --- | --- |
| 文件准备 | ZIP、IPA、安装器校验通过 |
| USB 安装 | iloader 安装成功；家人实际打开相清夫并浏览授权照片 |
| 电脑续签 | 已说明每 5 天接回电脑、同账号同标识覆盖；执行过才能称已验证 |
| SideStore 登录 | 明确记录成功 / 仍失败 / 未测试 |
| 手机独立续签 | 拔线后两款 App 刷新成功才算通过，否则写未验证 |

最后给出已完成、待本人操作和续签方式。无法看到手机时，依据家人明确反馈记录；不索取密码或公开设备配对文件。

官方依据：[iloader](https://iloader.app/)、[Apple 对 -1005 的解释](https://developer.apple.com/library/archive/qa/qa1941/_index.html)、[SideStore 安装](https://docs.sidestore.io/docs/installation/install)、[故障排查](https://docs.sidestore.io/docs/troubleshooting/common-issues)。
