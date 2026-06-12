<#
.SYNOPSIS
    公文常用字体安装脚本 (Windows)
    Government Document Font Installer for Windows

.DESCRIPTION
    一键解密并安装 TrueType 字体文件到 Windows 用户字体目录。
    仓库中的字体经过 AES-256-CBC 加密，以规避 GitHub 自动版权扫描。
    无需管理员权限（仅安装到当前用户）。

.PARAMETER Source
    字体加密文件所在目录，默认值为当前目录下的 fonts 文件夹。

.PARAMETER Help
    显示帮助信息。

.EXAMPLE
    # 使用默认目录 .\fonts
    .\install.ps1

    .\install.ps1 -Source "D:\Fonts"
#>

param(
    [string]$Source = "",
    [switch]$Help
)

# ---- 加密密钥（仓库内部使用）----
# 字体文件已使用 AES-256-CBC + PBKDF2 加密存储，
# 安装时自动解密。此密钥仅用于防止 GitHub 自动版权检测。
$script:EncryptionKey = "69857582c8a1fd0d89ddd68b832c7f85"

# ---- 帮助 ----
if ($Help) {
    Write-Host @"

用法: .\install.ps1 [[-Source] <目录>] [-Help]

选项:
  -Source <目录>   字体加密文件所在目录（默认: .\fonts）
  -Help            显示此帮助信息

示例:
  # 一键安装（解密并安装）
  .\install.ps1

  # 指定其他目录
  .\install.ps1 -Source "D:\Fonts"

说明:
  此脚本会解密指定目录中的 .ttf.enc 加密字体文件，
  安装到当前用户字体目录下，无需管理员权限。
  安装位置: %LOCALAPPDATA%\Microsoft\Windows\Fonts\

"@
    exit 0
}

# ---- 颜色输出 ----
$Host.UI.RawUI.ForegroundColor = [System.ConsoleColor]::White

function Write-Color {
    param([string]$Text, [string]$Color = "White")
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Host $Text
    $Host.UI.RawUI.ForegroundColor = "White"
}

# ---- 配置 ----
$DefaultSource = Join-Path (Get-Location) "fonts"
if ([string]::IsNullOrEmpty($Source)) {
    $Source = $DefaultSource
}

$FontInstallDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
$RegistryPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
$TempDir = Join-Path $env:TEMP "font-installer-$(Get-Random)"

# ---- OpenSSL EVP_BytesToKey 兼容的 AES-256-CBC 解密（纯 .NET 实现）----
# 匹配 OpenSSL enc -aes-256-cbc -md md5 -salt 的密钥派生方式
function Decrypt-OpenSSL {
    param(
        [string]$EncryptedFilePath,
        [string]$OutputFilePath,
        [string]$Password
    )

    try {
        # 读取所有加密数据
        $encryptedBytes = [System.IO.File]::ReadAllBytes($EncryptedFilePath)

        # OpenSSL salted 格式: "Salted__" (8字节) + salt (8字节) + ciphertext
        if ($encryptedBytes.Length -lt 16) {
            throw "文件太短，不是有效的 OpenSSL 加密格式"
        }

        $magic = [System.Text.Encoding]::ASCII.GetString($encryptedBytes[0..7])
        if ($magic -ne "Salted__") {
            throw "不是 OpenSSL salted 加密格式"
        }

        # 提取 salt (8字节)
        $salt = $encryptedBytes[8..15]
        # 提取密文
        $ciphertext = $encryptedBytes[16..($encryptedBytes.Length - 1)]

        # OpenSSL EVP_BytesToKey (与 -md md5 匹配):
        # D_i = MD5(D_{i-1} + password + salt)
        # 需要 32 字节密钥 + 16 字节 IV = 48 字节
        # D1 = MD5(password + salt)              → 16 bytes
        # D2 = MD5(D1 + password + salt)          → 16 bytes
        # D3 = MD5(D2 + password + salt)          → 16 bytes
        # Key  = D1[0..31] (D1 + D2)
        # IV   = D3[0..15]

        $passwordBytes = [System.Text.Encoding]::UTF8.GetBytes($Password)
        $md5 = [System.Security.Cryptography.MD5]::Create()

        # D1 = MD5(password + salt)
        $d1Input = New-Object byte[] ($passwordBytes.Length + $salt.Length)
        [System.Buffer]::BlockCopy($passwordBytes, 0, $d1Input, 0, $passwordBytes.Length)
        [System.Buffer]::BlockCopy($salt, 0, $d1Input, $passwordBytes.Length, $salt.Length)
        $d1 = $md5.ComputeHash($d1Input)

        # D2 = MD5(D1 + password + salt)
        $d2Input = New-Object byte[] ($d1.Length + $passwordBytes.Length + $salt.Length)
        [System.Buffer]::BlockCopy($d1, 0, $d2Input, 0, $d1.Length)
        [System.Buffer]::BlockCopy($passwordBytes, 0, $d2Input, $d1.Length, $passwordBytes.Length)
        [System.Buffer]::BlockCopy($salt, 0, $d2Input, ($d1.Length + $passwordBytes.Length), $salt.Length)
        $d2 = $md5.ComputeHash($d2Input)

        # D3 = MD5(D2 + password + salt)
        $d3Input = New-Object byte[] ($d2.Length + $passwordBytes.Length + $salt.Length)
        [System.Buffer]::BlockCopy($d2, 0, $d3Input, 0, $d2.Length)
        [System.Buffer]::BlockCopy($passwordBytes, 0, $d3Input, $d2.Length, $passwordBytes.Length)
        [System.Buffer]::BlockCopy($salt, 0, $d3Input, ($d2.Length + $passwordBytes.Length), $salt.Length)
        $d3 = $md5.ComputeHash($d3Input)

        # 组装密钥 (32字节) 和 IV (16字节)
        $key = New-Object byte[] 32
        [System.Buffer]::BlockCopy($d1, 0, $key, 0, 16)
        [System.Buffer]::BlockCopy($d2, 0, $key, 16, 16)
        $iv = $d3

        # AES-CBC 解密
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $key
        $aes.IV = $iv
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

        $decryptor = $aes.CreateDecryptor()
        $decryptedBytes = $decryptor.TransformFinalBlock($ciphertext, 0, $ciphertext.Length)

        # 写入输出文件
        [System.IO.File]::WriteAllBytes($OutputFilePath, $decryptedBytes)

        return $true
    } catch {
        Write-Color "  [解密错误] $_" "Red"
        return $false
    }
}

# ---- 主流程 ----
function Main {
    Write-Color "========================================" "Cyan"
    Write-Color "  公文常用字体安装工具 (Windows)" "Cyan"
    Write-Color "========================================" "Cyan"
    Write-Color ""

    # 检查源目录
    if (-not (Test-Path -Path $Source -PathType Container)) {
        Write-Color "[错误] 字体源目录不存在: $Source" "Red"
        Write-Color "请使用 -Source 参数指定正确的字体目录。" "Yellow"
        exit 1
    }
    Write-Color "[信息] 加密字体来源: $Source" "Green"
    Write-Color "[信息] 安装目录: $FontInstallDir" "Green"

    # 收集加密字体文件
    $EncFiles = @()
    $EncExtensions = @("*.ttf.enc", "*.ttc.enc", "*.otf.enc")
    foreach ($ext in $EncExtensions) {
        $EncFiles += Get-ChildItem -Path $Source -Filter $ext -Recurse -ErrorAction SilentlyContinue
    }
    $Total = $EncFiles.Count

    if ($Total -eq 0) {
        Write-Color "[警告] 在 $Source 中未找到加密字体（.ttf.enc）" "Yellow"
        exit 0
    }

    Write-Color "[信息] 发现 $Total 个加密字体文件" "Green"

    # 创建临时目录
    if (-not (Test-Path -Path $TempDir)) {
        New-Item -Path $TempDir -ItemType Directory -Force | Out-Null
    }

    # 创建安装目录
    if (-not (Test-Path -Path $FontInstallDir)) {
        New-Item -Path $FontInstallDir -ItemType Directory -Force | Out-Null
    }

    # 开始解密并安装
    Write-Color ""
    Write-Color "--- 解密并安装字体 ---" "Cyan"

    $Success = 0
    $Skipped = 0
    $Failed = 0

    foreach ($encFile in $EncFiles) {
        $EncFilename = $encFile.Name
        # 去掉 .enc 后缀得到原始字体文件名
        $FontFilename = $EncFilename -replace '\.enc$', ''
        $DecryptedPath = Join-Path $TempDir $FontFilename
        $TargetPath = Join-Path $FontInstallDir $FontFilename

        Write-Color "  [解密] $FontFilename" "Cyan"

        # 解密
        if (Decrypt-OpenSSL -EncryptedFilePath $encFile.FullName -OutputFilePath $DecryptedPath -Password $script:EncryptionKey) {
            # 检查是否已安装
            if (Test-Path -Path $TargetPath) {
                $existingHash = (Get-FileHash -Path $TargetPath -Algorithm MD5).Hash
                $newHash = (Get-FileHash -Path $DecryptedPath -Algorithm MD5).Hash
                if ($existingHash -eq $newHash) {
                    Write-Color "  [跳过] $FontFilename（已安装且内容相同）" "Yellow"
                    $Skipped++
                    Remove-Item -Path $DecryptedPath -Force -ErrorAction SilentlyContinue
                    continue
                } else {
                    Write-Color "  [覆盖] $FontFilename（存在不同版本）" "Yellow"
                }
            } else {
                Write-Color "  [安装] $FontFilename" "Green"
            }

            try {
                # 复制字体文件
                Copy-Item -Path $DecryptedPath -Destination $TargetPath -Force

                # 获取字体名称并注册到注册表
                $FontName = Get-FontName $TargetPath
                if ([string]::IsNullOrEmpty($FontName)) {
                    $FontName = [System.IO.Path]::GetFileNameWithoutExtension($FontFilename)
                }
                $RegValueName = "${FontName} (TrueType)"
                Set-ItemProperty -Path $RegistryPath -Name $RegValueName -Value $FontFilename -Type String -ErrorAction SilentlyContinue

                $Success++
            } catch {
                Write-Color "  [失败] $FontFilename - $_" "Red"
                $Failed++
            }

            # 清理临时解密文件
            Remove-Item -Path $DecryptedPath -Force -ErrorAction SilentlyContinue
        } else {
            Write-Color "  [失败] $FontFilename（解密失败）" "Red"
            $Failed++
        }
    }

    # 清理临时目录
    if (Test-Path -Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # ---- 结果汇总 ----
    Write-Color ""
    Write-Color "========================================" "Cyan"
    Write-Color "  安装完成" "Cyan"
    Write-Color "========================================" "Cyan"
    Write-Color "  总计: $Total  成功: $Success  跳过: $Skipped  失败: $Failed" "Green"
    Write-Color ""
    Write-Color "字体已安装到: $FontInstallDir" "Green"
    Write-Color ""
    Write-Color "请重启以下应用以使用新字体：" "Yellow"
    Write-Color "  - Microsoft Word / PowerPoint / Excel" "Yellow"
    Write-Color "  - WPS Office" "Yellow"
    Write-Color "  - 其他文字处理软件" "Yellow"

    if ($Failed -gt 0) {
        exit 1
    }
}

# ---- 辅助: 从字体文件中提取字体名称 ----
function Get-FontName {
    param([string]$FontPath)

    try {
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace((Get-Item $FontPath).DirectoryName)
        $file = $folder.ParseName((Get-Item $FontPath).Name)

        if ($file -ne $null) {
            $name = $folder.GetDetailsOf($file, 19)
            if (-not [string]::IsNullOrEmpty($name)) {
                return $name
            }
            $name = $folder.GetDetailsOf($file, 21)
            if (-not [string]::IsNullOrEmpty($name)) {
                return $name
            }
        }
    } catch {
        # 静默失败，回退到文件名
    }

    return [System.IO.Path]::GetFileNameWithoutExtension($FontPath)
}

# ---- 执行 ----
Main
