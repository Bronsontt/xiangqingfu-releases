# SideStore 登录与 LocalDevVPN 排障

修订日期：2026-11-03。先通过 iloader 的 **Import IPA** 装好相清夫；下列排障只影响以后在手机上独立续签，不阻挡首次使用。

## 先认清报错来自哪里

| 界面 / 错误 | 可以确认什么 | 下一步 |
| --- | --- | --- |
| Welcome to SideStore、Apple ID、Failed to Sign In、CFNetwork -1005 | SideStore 登录连接中断；不能直接认定密码错或 VPN 损坏 | 检查手机网络和登录服务 |
| LocalDevVPN 一直连接中或 VPN 配置失败 | 本机 VPN 配置 / 隧道尚未工作 | 检查 VPN 授权和冲突 |
| SideStore 1414 / No Wi-Fi or VPN / AFC | SideStore 访问设备服务失败 | 检查 Wi-Fi、VPN 和配对 |
| iloader 的 Download SideStore 转圈 | 电脑正在下载 SideStore，尚未完成安装 | 回到本地相清夫 Import IPA 路线 |

LocalDevVPN 让 SideStore 访问 iPhone 自身的服务，不是提供外网线路的加速器，也不需要 Apple 账号登录。`-1005` 是 Apple 网络错误，与 SideStore 正数 `1005`（找不到 App 文件）不同。

## A. SideStore 登录 -1005

1. 不再反复点击 Sign in。记录当前 iOS、SideStore、LocalDevVPN 版本和完整错误类型；不要记录密码或验证码。
2. 在手机 Safari 检查 `https://developer.apple.com/` 是否能打开。这仅验证网页连接，不证明登录、签名接口正常。电脑网络测试也不能代替手机测试。
3. 手机连接可靠 Wi-Fi；必要时换另一条 Wi-Fi 或另一台手机提供的热点作对照。SideStore 安装/刷新仍按官方要求使用 Wi-Fi，不以本机蜂窝网络替代。
4. 如有其他 VPN、按需自动连接 VPN、DNS 拦截器，先记录原设置，临时停止冲突项，仅保留 LocalDevVPN 进行对照；结束后恢复需要的设置。不要关闭防火墙或重置全部网络。
5. 关闭再打开 SideStore；LocalDevVPN 连接稳定后重试一次。确认 iPhone 日期与时间正确。
6. 若电脑 iloader 已能登录而手机 SideStore 仍失败，说明至少电脑这条登录路径可用；不能断定手机账号或服务器一定正常。继续用 iloader 安装/续签相清夫。
7. 需要继续修 SideStore 时，在当前设置里的 Anisette Servers 选择**应用内置、官方维护的可用服务**；名称以实际界面为准，不硬编码旧服务器地址或填写陌生服务。每次只改一项再验证。重置 adi.pb、退出重登会重置认证状态，仅在普通网络检查无效且官方指引适用时执行，不循环重试。

没有实际看到登录成功前，保留“SideStore 登录仍失败/未验证”。截图不足以确定根因是网络切换、DNS、Anisette 还是 Apple 服务。

## B. LocalDevVPN 确实无法连接

1. 从 [SideStore 官方准备页](https://docs.sidestore.io/docs/installation/prerequisites) 指向的 [App Store](https://apps.apple.com/app/localdevvpn/id6755608044) 安装/更新 LocalDevVPN。
2. 打开 LocalDevVPN 点 Connect。首次添加 VPN 配置时由本人点允许并输入锁屏密码；在系统“VPN 与设备管理”确认选择的是 LocalDevVPN。
3. 检查其他 VPN 是否通过按需连接抢回连接，以及 DNS 拦截器是否干扰；只临时停用实际冲突项，不删除公司/学校管理配置。
4. 重新连接 LocalDevVPN，再重新打开 SideStore；必要时重启手机。连接成功仅证明隧道建立，仍要分别验证登录和刷新。
5. 只有官方指引和实际版本明确匹配时才调整 Device IP；SideStore 配置必须与 LocalDevVPN 实际 Device IP 一致。不要为了 -1005 套用网上旧的 Tunnel IP / 掩码。

## C. 已登录，但刷新报配对或设备连接错误

确认 Wi-Fi + LocalDevVPN 都已连接；按官方顺序重启 SideStore、LocalDevVPN。仍失败时连接 Windows，用 iloader 的 Manage Pairing File 按官方说明更新配对。系统升级后可能需要重新配对；配对资料只留在自己的设备上，不上传。

## 修复后的验收

1. SideStore 能登录；My Apps 中先刷新 SideStore 自己成功。
2. 相清夫若先由 iloader 安装，不会自动进入 SideStore 管理。核对同一 Apple 账号、相同实际安装标识后再导入，不能确定时先沿用电脑续签，勿卸载旧版。
3. 拔掉 USB，保持 Wi-Fi + LocalDevVPN，SideStore 与相清夫都刷新成功，有效期接近 7 天，才记为“手机独立续签成功”。

若仍失败，相清夫仍可通过电脑续签使用；免费签名不能承诺永久有效。建议每 5 天连接 Windows，以同一账号和标识覆盖续签。

依据：[Apple -1005](https://developer.apple.com/library/archive/qa/qa1941/_index.html)、[SideStore 准备](https://docs.sidestore.io/docs/installation/prerequisites)、[安装](https://docs.sidestore.io/docs/installation/install)、[常见问题](https://docs.sidestore.io/docs/troubleshooting/common-issues)、[错误码](https://docs.sidestore.io/docs/troubleshooting/error-codes)。
