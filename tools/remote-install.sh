#!/usr/bin/env bash
# ============================================================================
# 公文常用字体 - 远程一键安装脚本 (macOS / Linux)
#
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/kasc0206/font-installer/main/tools/remote-install.sh | bash
#
# 说明:
#   此脚本会自动从 GitHub 下载字体安装工具包，
#   解密并安装所有公文常用字体，完成后自动清理临时文件。
# ============================================================================

set -euo pipefail

REPO_OWNER="kasc0206"
REPO_NAME="font-installer"
REPO_BRANCH="main"
ARCHIVE_URL="file:///tmp/tmp.lCAlUfpkJo/repo.tar.gz"

# ---- 颜色输出 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ---- 清理 ----
TEMP_DIR=""
cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# ---- 主流程 ----
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  公文常用字体 - 远程一键安装${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # 检查依赖
    if ! command -v curl &>/dev/null; then
        echo -e "${RED}[错误] 未找到 curl 命令${NC}"
        echo "请先安装 curl:"
        echo "  macOS:  brew install curl"
        echo "  Ubuntu: sudo apt install curl"
        exit 1
    fi

    if ! command -v tar &>/dev/null; then
        echo -e "${RED}[错误] 未找到 tar 命令${NC}"
        exit 1
    fi

    # 创建临时目录
    TEMP_DIR=$(mktemp -d "/tmp/font-installer-remote.XXXXXXXXXX")
    echo -e "${CYAN}[下载]${NC} 正在下载字体安装工具包..."
    echo -e "        ${ARCHIVE_URL}"

    # 下载并解压
    curl -fsSL "$ARCHIVE_URL" -o "${TEMP_DIR}/repo.tar.gz" 2>/dev/null

    if [[ ! -f "${TEMP_DIR}/repo.tar.gz" || ! -s "${TEMP_DIR}/repo.tar.gz" ]]; then
        echo -e "${RED}[错误] 下载失败，请检查网络连接${NC}"
        exit 1
    fi

    tar xzf "${TEMP_DIR}/repo.tar.gz" -C "$TEMP_DIR" 2>/dev/null

    # 查找解压后的目录（排除临时目录自身）
    EXTRACTED_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "${REPO_NAME}-${REPO_BRANCH}" ! -path "$TEMP_DIR" | head -1)
    if [[ -z "$EXTRACTED_DIR" ]]; then
        echo -e "${RED}[错误] 解压失败${NC}"
        exit 1
    fi

    echo -e "${GREEN}[下载完成]${NC} 正在安装字体..."
    echo ""

    # 运行安装脚本
    bash "${EXTRACTED_DIR}/install.sh" --source "${EXTRACTED_DIR}/fonts"

    local exit_code=$?

    echo ""
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✓ 一键安装完成！${NC}"
    else
        echo -e "${RED}✗ 安装过程出现错误${NC}"
    fi

    return $exit_code
}

main "$@"
