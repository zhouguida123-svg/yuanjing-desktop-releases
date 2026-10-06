# 源景工作台 · 桌面端发布仓

渠道：**GitHub Release 主链** + 百度/夸克备用；不接 COS。强制更新：关闭。

## 当前状态（2026-10-07）

| 项 | 状态 |
|---|---|
| 私有仓 | 已建 |
| r8 Setup（含去水印三档热补） | 已打，**未代码签名** |
| 公开 Release | **未发**（等 OV/EV 代码签名证书 `.pfx`） |
| 官网下载按钮 | 未开 |

## 签章阻断

本机构造机上无可用于 Authenticode 的代码签名证书（Adobe 内容证无关；无 `.pfx` / 无私钥 Code Signing EKU）。

提供证书后执行：

```text
signtool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /f <cert.pfx> /p <pass> Yuanjing-Setup-0.2.2.124-r8-candidate.exe
signtool verify /pa Yuanjing-Setup-0.2.2.124-r8-candidate.exe
```

再把草稿 Release 改为 published，并同步网盘。

## 候选包

见 Release **draft** `desktop-0.2.2.124-r8`（UNSIGNED）。
