<#
.SYNOPSIS
    公文常用字体 - 远程一键安装脚本 (Windows)

.DESCRIPTION
    从 GitHub 自动下载字体安装工具包，解密并安装所有公文常用字体。
    完成后自动清理临时文件。

    用法:
        powershell -c "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/kasc0206/font-installer/main/tools/remote-install.ps1'))"
#>

$RepoOwner = "kasc0206"
$RepoName = "font-installer"
$RepoBranch = "main"
$ArchiveUrl = "https://github.com/${RepoOwner}/${RepoName}/archive/refs/heads/${RepoBranch}.tar.gz"

# ---- 颜色输出 ----
$Host.UI.RawUI.ForegroundColor = [System.ConsoleColor]::White

function Write-Color {
    param([string]$Text, [string]$Color = "White")
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Host $Text
    $Host.UI.RawUI.ForegroundColor = "White"
}

# ---- 主流程 ----
function Main {
    Write-Color "========================================" "Cyan"
    Write-Color "  公文常用字体 - 远程一键安装 (Windows)" "Cyan"
    Write-Color "========================================" "Cyan"
    Write-Color ""

    $TempDir = Join-Path $env:TEMP "font-installer-remote-$(Get-Random)"
    $ArchiveFile = Join-Path $TempDir "repo.tar.gz"

    try {
        # 创建临时目录
        New-Item -Path $TempDir -ItemType Directory -Force | Out-Null

        # 下载
        Write-Color "[下载] 正在下载字体安装工具包..." "Cyan"
        Write-Color "       $ArchiveUrl" "Gray"

        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($ArchiveUrl, $ArchiveFile)

        if (-not (Test-Path $ArchiveFile)) {
            throw "下载失败"
        }

        # 解压 (Windows 10+ 内置 tar 命令)
        $tarExists = Get-Command tar -ErrorAction SilentlyContinue
        if ($tarExists) {
            tar xzf $ArchiveFile -C $TempDir 2>$null
        } else {
            # 需要 7-Zip 或其他工具
            throw "未找到 tar 命令，请使用 Windows 10 1803+ 或安装 tar"
        }

        # 查找解压后的目录
        $ExtractedDir = Get-ChildItem -Path $TempDir -Directory | Where-Object { $_.Name -like "${RepoName}-*" } | Select-Object -First 1
        if (-not $ExtractedDir) {
            throw "解压失败"
        }

        Write-Color "[下载完成] 正在安装字体..." "Green"
        Write-Color ""

        # 运行安装脚本
        $InstallScript = Join-Path $ExtractedDir.FullName "install.ps1"
        & $InstallScript -Source (Join-Path $ExtractedDir.FullName "fonts")

        $exitCode = $LASTEXITCODE

        Write-Color ""
        if ($exitCode -eq 0) {
            Write-Color "✓ 一键安装完成！" "Green"
        } else {
            Write-Color "✗ 安装过程出现错误" "Red"
        }

    } catch {
        Write-Color "[错误] $_" "Red"
        $exitCode = 1
    } finally {
        # 清理临时文件
        if (Test-Path $TempDir) {
            Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    if ($exitCode -ne 0) {
        exit 1
    }
}

Main
