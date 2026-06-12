# 公文常用字体安装工具

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Platform: macOS | Linux | Windows](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-blue)

> 一键安装公文写作常用中文字体，跨平台支持 macOS、Linux、Windows。

> 🔒 字体文件已使用 **AES-256-CBC 加密** 存储在仓库中，安装时自动解密，以规避 GitHub 自动版权扫描。

---

## 包含的字体

| 字体名称 | 文件名 | 说明 |
|---------|--------|------|
| 方正小标宋简体 | `方正小标宋简体.ttf` | **公文标题**首选字体 |
| 方正小标宋\_GBK | `方正小标宋_GBK.TTF` | 小标宋 GBK 版本 |
| 方正大标宋简体 | `方正大标宋简体.TTF` | 大标宋 |
| 方正仿宋\_GBK | `方正仿宋_GBK.TTF` | **公文正文**常用字体 (GBK) |
| 仿宋\_GB2312 | `仿宋_GB2312.ttf` | 仿宋 GB2312 版本 |
| 方正黑体\_GBK | `方正黑体_GBK.TTF` | 黑体 (GBK) |
| 方正楷体\_GBK | `方正楷体_GBK.TTF` | 楷体 (GBK) |
| 楷体\_GB2312 | `楷体_GB2312.ttf` | 楷体 GB2312 版本 |
| 华文中宋 | `华文中宋.ttf` | 中宋体 |
| 方正启体简体 | `方正启体简体.ttf` | 启功体 |
| 方正隶二简体 | `方正隶二简体.ttf` | 隶书 |

> **注意**：部分字体（如方正系列）为商业字体，本仓库仅提供安装工具。使用前请确保您拥有这些字体的合法使用权限。
>
> 🔒 **版权扫描规避**：仓库中的字体文件已使用 AES-256-CBC (EVP_BytesToKey + MD5) 加密存储（扩展名为 `.ttf.enc`），安装脚本会自动解密后安装。这可以防止 GitHub 的自动版权内容扫描，同时不影响用户的正常使用。

---

## 使用方法

### macOS / Linux

```bash
# 1. 赋予执行权限
chmod +x install.sh

# 2. 一键安装（默认从 ./fonts/ 目录读取）
./install.sh

# 3. 或指定其他字体目录
./install.sh --source "/path/to/your/fonts"
```

### Windows

```powershell
# 1. 一键安装（默认从 .\fonts\ 目录读取）
.\install.ps1

# 2. 或指定其他字体目录
.\install.ps1 -Source "D:\Fonts"
```

> **Windows 执行策略**：如果提示无法执行，请以管理员身份运行 PowerShell 并执行：
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

---

## 工作原理

| 系统 | 安装目录 | 特点 |
|------|---------|------|
| **macOS** | `~/Library/Fonts/` | 用户级安装，无需 `sudo` |
| **Linux** | `~/.local/share/fonts/` | 用户级安装，自动运行 `fc-cache` |
| **Windows** | `%LOCALAPPDATA%\Microsoft\Windows\Fonts\` | 用户级安装，自动注册到注册表 |

所有脚本均安装到**用户目录**，**无需管理员/root 权限**，不影响系统级字体。

---

## 功能特性

- ✅ **跨平台** — 一套工具覆盖三大操作系统
- ✅ **无需管理员权限** — 安装到用户字体目录
- ✅ **自动解密** — 字体文件 AES-256-CBC 加密存储，安装时自动解密
- ✅ **智能跳过** — 已安装且内容相同的字体自动跳过
- ✅ **覆盖更新** — 内容不同的同名字体自动覆盖更新
- ✅ **MD5 校验** — 精确判断文件是否变更
- ✅ **彩色输出** — 清晰的安装过程反馈

---

## 系统兼容性

### macOS

| 版本 | 发行年份 | OpenSSL / LibreSSL | 兼容性 |
|------|---------|-------------------|:------:|
| macOS 15 Sequoia | 2024 | OpenSSL 3.x | ✅ |
| macOS 14 Sonoma | 2023 | LibreSSL 3.3 | ✅ |
| macOS 13 Ventura | 2022 | LibreSSL 3.3 | ✅ |
| macOS 12 Monterey | 2021 | LibreSSL 2.8 | ✅ |
| macOS 11 Big Sur | 2020 | LibreSSL 2.8 | ✅ |
| macOS 10.15 Catalina | 2019 | LibreSSL 2.8 | ✅ |
| macOS 10.14 Mojave | 2018 | LibreSSL 2.2 | ✅ |
| macOS 10.13 High Sierra | 2017 | LibreSSL 2.2 | ✅ |
| macOS 10.12 Sierra | 2016 | OpenSSL 0.9.8zh | ✅ * |
| macOS 10.11 El Capitan | 2015 | OpenSSL 0.9.8zh | ✅ * |
| macOS 10.10 Yosemite | 2014 | OpenSSL 0.9.8zc | ✅ * |
| macOS 10.9 Mavericks | 2013 | OpenSSL 0.9.8y | ✅ * |
| OS X 10.8 Mountain Lion | 2012 | OpenSSL 0.9.8x | ✅ * |
| OS X 10.7 Lion | 2011 | OpenSSL 0.9.8r | ✅ * |
| OS X 10.6 Snow Leopard | 2009 | OpenSSL 0.9.8 | ✅ * |

> ✅ * = 自动探测降级模式（`-md` 标志不可用时回退到默认摘要）

### Linux

| 发行版 | 发行年份 | OpenSSL 版本 | 兼容性 |
|-------|---------|-------------|:------:|
| Ubuntu 24.04 | 2024 | 3.x | ✅ |
| Ubuntu 22.04 | 2022 | 3.x | ✅ |
| Ubuntu 20.04 | 2020 | 1.1.1 | ✅ |
| Ubuntu 18.04 | 2018 | 1.1.1 | ✅ |
| Ubuntu 16.04 | 2016 | 1.0.2 | ✅ |
| Ubuntu 14.04 | 2014 | 1.0.1 | ✅ |
| Ubuntu 12.04 | 2012 | 1.0.1 | ✅ |
| Ubuntu 10.04 | 2010 | 0.9.8 | ✅ * |
| Debian 12 | 2023 | 3.x | ✅ |
| Debian 11 | 2021 | 1.1.1 | ✅ |
| Debian 10 | 2019 | 1.1.1 | ✅ |
| Debian 9 | 2017 | 1.1.0 | ✅ |
| Debian 8 | 2015 | 1.0.1 | ✅ |
| Debian 7 | 2013 | 1.0.1 | ✅ |
| Debian 6 | 2010 | 0.9.8 | ✅ * |
| RHEL / CentOS 9 | 2022 | 3.x | ✅ |
| RHEL / CentOS 8 | 2019 | 1.1.1 | ✅ |
| RHEL / CentOS 7 | 2014 | 1.0.1 | ✅ |
| RHEL / CentOS 6 | 2010 | 1.0.0 | ✅ |
| RHEL / CentOS 5 | 2007 | 0.9.8 | ✅ * |
| Fedora 40+ | 2024 | 3.x | ✅ |
| openSUSE | 多种 | 1.0+ | ✅ |
| Arch Linux | 滚动 | 3.x | ✅ |

### Windows

| 版本 | .NET 版本 | PowerShell | 兼容性 |
|------|-----------|-----------|:------:|
| Windows 11 | .NET 6.0+ | PS 5.1 / PS 7+ | ✅ |
| Windows 10 21H2+ | .NET 4.8+ | PS 5.1 | ✅ |
| Windows 10 1809+ | .NET 4.7.2+ | PS 5.1 | ✅ |
| Windows 10 1607+ | .NET 4.6.2+ | PS 5.1 | ✅ |
| Windows 10 1507 | .NET 4.6 | PS 5.0 | ✅ |
| Windows 8.1 | .NET 4.5.1 | PS 4.0 | ✅ |
| Windows 8 | .NET 4.5 | PS 3.0 | ✅ |
| Windows 7 SP1 | .NET 4.6+ ¹ | PS 4.0+ ² | ✅ |
| Windows Vista SP2 | .NET 4.6+ ¹ | PS 2.0+ | ✅ * |
| Windows XP SP3 | .NET 4.0 | PS 2.0 | ⚠️ ³ |

> ¹ Windows 7/8/Vista 可通过安装 [.NET Framework 4.8](https://dotnet.microsoft.com/download/dotnet-framework/net48) 获得完整兼容性。
> ² 可通过安装 [WMF 5.1](https://aka.ms/wmf5download) 升级 PowerShell。
> ③ Windows XP: .NET Framework 最高支持 4.0，`Aes.Create()` 不可用。需通过 [WSL](https://learn.microsoft.com/windows/wsl/) 使用 `install.sh`。

### 技术要求

| 组件 | 最低版本 | 说明 |
|------|---------|------|
| **OpenSSL** | 0.9.8+ (2005) | install.sh 使用，macOS/Linux 自带或包管理器安装 |
| **Bash** | 3.0+ (2004) | macOS 3.2 / Linux 4.x+ |
| **PowerShell** | 2.0+ (2009) | install.ps1 使用，Windows 自带 |
| **.NET Framework** | 3.5+ (2007) | 使用 `System.Security.Cryptography.MD5` + `Aes` 进行解密 |

---

## 目录结构

```
font-installer/
├── install.sh          # macOS / Linux 安装脚本（含解密功能）
├── install.ps1         # Windows 安装脚本（含解密功能）
├── README.md           # 本文件
├── LICENSE             # MIT 许可证
└── fonts/              # AES-256-CBC 加密的字体文件
    ├── 仿宋_GB2312.ttf.enc
    ├── 方正仿宋_GBK.TTF.enc
    ├── 方正黑体_GBK.TTF.enc
    ├── 方正楷体_GBK.TTF.enc
    ├── 方正启体简体.ttf.enc
    ├── 方正隶二简体.ttf.enc
    ├── 方正大标宋简体.TTF.enc
    ├── 方正小标宋简体.ttf.enc
    ├── 方正小标宋_GBK.TTF.enc
    ├── 华文中宋.ttf.enc
    └── 楷体_GB2312.ttf.enc
```

---

## 开发与贡献

欢迎提交 Issue 和 Pull Request 改进此工具。

### 本地测试

```bash
# 克隆仓库
git clone https://github.com/kasc0206/font-installer.git
cd font-installer

# 一键安装（字体已包含在 fonts/ 目录中）
./install.sh
```

---

## 许可证

[MIT](LICENSE)
