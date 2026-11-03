# 相清夫 · iPhone / iPad 家庭安装

在本机浏览、分类、搜索和整理照片。安装流程已更新：**先用 Windows 的 iloader 直接安装相清夫，不再卡在 SideStore 登录或 LocalDevVPN。**

## Windows 双击入口

**[下载 Windows 启动包](https://github.com/Bronsontt/xiangqingfu-releases/raw/refs/heads/main/XiangQingFu-Windows-Start.zip)**，解压后双击 `Install-XiangQingFu.cmd`。启动包很小，运行时会自动下载完整安装文件。

[查看启动脚本](Install-XiangQingFu.cmd)（也可单独保存为同名 `.cmd`，不要保存成 `.txt`）。

1. 在 Windows 双击启动器。它会下载、校验安装包，复用或安装 iloader，并打开当前操作说明。
2. USB 连接 iPhone，在 iloader 选择手机；本人登录 Apple 账号后，点击 **Import IPA**，粘贴助手复制的文件路径。
3. 手机按提示确认信任和开发者模式，安装后打开相清夫。

Apple 登录、UAC 和手机确认需要本人配合；启动器不会绕过这些确认。支持 Intel/AMD x64 Windows 和 Windows PowerShell 5.1+，无管理员身份运行 agent 的要求。

## 让 Windows agent 继续代办

把下面内容交给能操作你电脑的 agent；如果之前已在 iloader 登录，请复用现状：

```text
请读取并执行以下任务，直接操作我的 Windows 完成相清夫安装：
https://raw.githubusercontent.com/Bronsontt/xiangqingfu-releases/main/INSTALL-WINDOWS-AGENT.md

已授权必要的下载、校验和安装；电脑操作由你完成，仅在系统审批或必须本人验证时让我配合。
```

[完整安装任务](INSTALL-WINDOWS-AGENT.md) · [复制启动提示词](01-WINDOWS-AGENT-PROMPT.txt) · [SideStore 登录排障](REPAIR-SIDESTORE.md)

## 续签与下载

- 免费 Apple 账号签名有效期 **7 天**。默认路线建议每 **5 天**接回 Windows，用同一 Apple 账号、同一实际安装标识再次 **Import IPA** 覆盖续签，不卸载相清夫。
- 希望在手机上独立续签，可稍后配置 SideStore + Wi-Fi + LocalDevVPN。只有拔掉 USB 后两款 App 都刷新成功，才算验证完成。
- [最新 IPA 和完整安装包](https://github.com/Bronsontt/xiangqingfu-releases/releases/latest)。旧 ZIP 若仍带有“先刷新 SideStore”的说明，请以本页和当前任务文档为准；新启动器兼容原有 IPA，无需重编译 App。
- GitHub 自动提供的 Source code 压缩包不包含 App 安装包。
- 相清夫最低要求 iOS / iPadOS 17.0。照片权限由本人选择；验收只浏览照片，无需删除真实照片。

## 本次修复的边界

`Welcome to SideStore / Failed to Sign In / -1005` 表示 SideStore 登录网络中断，不是 LocalDevVPN 需要登录 Apple 账号。新的 USB 路线移除了这一安装阻塞；不能据此声称原来的手机登录网络故障已经修好。

App 仍为 1.0（构建 1），安装流程修订为 2。App 已完成 Release 真机构建及 IPA 校验；最终手机安装、运行、续签需要在收件人设备上确认。

随包 iloader 是 [官方 v2.4.1](https://github.com/nab138/iloader/releases/tag/v2.4.1) 未修改的 x64 安装器；启动脚本由本项目维护。与 iloader、SideStore、Apple 无隶属关系。本仓库只分发安装包、安装脚本和说明，不提供账号、设备配对文件或签名私钥。
