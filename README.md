# 相清夫 · iPhone / iPad 安装包

在本机浏览、分类、搜索和整理照片。此仓库提供 SideStore 安装包与配置说明。

**[打开最新版本下载页](https://github.com/Bronsontt/xiangqingfu-releases/releases/latest)**

| 文件 | 用途 |
| --- | --- |
| `XiangQingFu-SideStore-Family-1.0-1.zip` | 首次安装推荐：IPA、官方 iloader Windows x64 安装器、中文说明、Windows agent 提示词和校验清单 |
| `XiangQingFu-1.0-1-SideStore.ipa` | 已装好 SideStore 时，直接在 iPhone 上下载并导入 |
| `01-WINDOWS-AGENT-PROMPT.txt` | 交给能够操作家人 Windows 电脑的 agent 的完整配置提示词 |

GitHub 自动提供的 `Source code` 压缩包只包含本仓库说明，**不包含 App 安装包**。

## 开始安装

1. 在 Windows 下载完整家庭安装 ZIP 并解压。
2. 把 [Windows agent 提示词](01-WINDOWS-AGENT-PROMPT.txt) 全文交给能操作这台 Windows 的 agent，并让它访问解压目录。也可以按 [中文安装说明](00-START-HERE.txt) 手动操作。
3. 用数据线连接 iPhone，配合完成 Apple 账号登录、信任开发者、开发者模式和 SideStore 首次刷新。
4. 在 iPhone 的“文件”App 保存 IPA，再由 SideStore 导入。

## 使用要求

- 相清夫要求 **iOS / iPadOS 17.0 或更新**，支持 iPhone 和 iPad。
- 使用本人免费的 Apple 账号，无需购买开发者会员。首次安装需要电脑；正常情况下，后续可在手机上通过 **Wi-Fi + LocalDevVPN** 刷新。
- 免费签名只有 **7 天**。建议每 2～3 天刷新 SideStore 和相清夫，不要只依赖后台自动刷新。
- 系统升级、配对失效或 SideStore 过期时，可能需要重新借助电脑处理。
- 配置时由本人直接输入密码、验证码和手机锁屏密码，不要发到 agent 聊天中。
- 首次验收只需浏览照片。实际删除系统照片时，开启 iCloud 照片的设备会同步删除。

## 当前版本验证

1.0（构建 1）已完成 Release 真机构建和安装包结构/哈希检查。IPA 由收件人的 SideStore 重新签名；最终安装和首次续签需在收件人的设备上验证。

## 官方工具

[SideStore 安装准备](https://docs.sidestore.io/docs/installation/prerequisites) · [SideStore 安装流程](https://docs.sidestore.io/docs/installation/install) · [iloader 官方项目](https://iloader.app)

随包附带的是未修改的官方 iloader v2.4.1 x64 安装器，来源、哈希和 MIT 许可在 `tools/` 目录。本项目与 SideStore、iloader 或 Apple 无隶属关系。
