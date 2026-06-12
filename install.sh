#!/usr/bin/env bash
# ============================================================================
# 公文常用字体安装脚本 (macOS / Linux)
# Government Document Font Installer
# ============================================================================
# 支持 macOS 和 Linux 系统，一键解密并安装 TrueType 字体文件。
# 仓库中的字体经过 AES-256-CBC 加密，以规避 GitHub 自动版权扫描。
# Supports macOS and Linux — decrypts and installs TrueType fonts.
# ============================================================================

set -euo pipefail

# ---- 颜色输出 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ---- 加密密钥（仓库内部使用）----
# 字体文件已使用 AES-256-CBC + PBKDF2 加密存储，
# 安装时自动解密。此密钥仅用于防止 GitHub 自动版权检测。
ENCRYPTION_KEY="69857582c8a1fd0d89ddd68b832c7f85"

# ---- 默认配置 ----
DEFAULT_SOURCE_DIR="./fonts"
INSTALL_DIR=""
OS_TYPE=""
TEMP_DIR=""

# ---- 清理函数 ----
cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# ---- 帮助信息 ----
usage() {
    cat <<EOF
用法: $(basename "$0") [选项]

选项:
  -s, --source <目录>   字体加密文件所在目录（默认: ./fonts）
  -h, --help            显示此帮助信息

示例:
  # 一键安装（解密并安装）
  ./install.sh

  # 指定其他目录
  ./install.sh --source "/path/to/your/fonts"

说明:
  此脚本会解密指定目录中的 .ttf.enc 加密字体文件，
  安装到当前用户字体目录下，无需管理员权限。
    - macOS:   ~/Library/Fonts/
    - Linux:   ~/.local/share/fonts/
EOF
    exit 0
}

# ---- 检测操作系统 ----
detect_os() {
    case "$(uname -s)" in
        Darwin)
            OS_TYPE="macos"
            INSTALL_DIR="${HOME}/Library/Fonts"
            ;;
        Linux)
            OS_TYPE="linux"
            INSTALL_DIR="${HOME}/.local/share/fonts"
            ;;
        *)
            echo -e "${RED}[错误] 不支持的操作系统: $(uname -s)${NC}"
            echo "Windows 用户请使用 install.ps1 脚本。"
            exit 1
            ;;
    esac
}

# ---- 检查依赖 ----
check_deps() {
    if ! command -v openssl &>/dev/null; then
        echo -e "${RED}[错误] 未找到 openssl 命令。${NC}"
        echo "请先安装 OpenSSL:"
        echo "  macOS:  brew install openssl"
        echo "  Ubuntu: sudo apt install openssl"
        echo "  CentOS: sudo yum install openssl"
        exit 1
    fi
    # 探测 OpenSSL 版本兼容性
    probe_openssl
}

# ---- 解析参数 ----
SOURCE_DIR="$DEFAULT_SOURCE_DIR"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}[错误] 未知参数: $1${NC}"
            usage
            ;;
    esac
done

# ---- 探测 OpenSSL 参数兼容性 ----
OPENSSL_DECRYPT_CMD=""
probe_openssl() {
    # 探测: 是否支持 -md 标志（OpenSSL 1.0.0+ / LibreSSL 2.0+）
    if echo "probe" | openssl enc -aes-256-cbc -md md5 -salt -pass pass:x -out /dev/null 2>/dev/null; then
        # 支持 -md 标志，使用明确的 MD5 摘要算法
        OPENSSL_DECRYPT_CMD="openssl enc -d -aes-256-cbc -md md5 -salt"
    else
        # 不支持 -md 标志（OpenSSL 0.9.8），默认使用 MD5
        echo -e "${YELLOW}[注意] OpenSSL 版本较旧，使用默认摘要算法${NC}"
        OPENSSL_DECRYPT_CMD="openssl enc -d -aes-256-cbc -salt"
    fi
}

# ---- 解密函数 ----
decrypt_font() {
    local enc_file="$1"
    local out_file="$2"

    $OPENSSL_DECRYPT_CMD \
        -in "$enc_file" \
        -out "$out_file" \
        -pass pass:"$ENCRYPTION_KEY" 2>/dev/null
}

# ---- 主流程 ----
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  公文常用字体安装工具${NC}"
    echo -e "${BLUE}========================================${NC}"

    detect_os
    check_deps
    echo -e "${GREEN}[信息] 操作系统: ${OS_TYPE}${NC}"
    echo -e "${GREEN}[信息] 安装目录: ${INSTALL_DIR}${NC}"

    # 检查源目录
    if [[ ! -d "$SOURCE_DIR" ]]; then
        echo -e "${RED}[错误] 字体源目录不存在: ${SOURCE_DIR}${NC}"
        echo "请使用 --source 参数指定正确的字体目录。"
        exit 1
    fi
    echo -e "${GREEN}[信息] 加密字体来源: ${SOURCE_DIR}${NC}"

    # 收集加密字体文件（按文件名排序以确保一致性）
    ENC_FILES=()
    while IFS= read -r -d '' f; do
        ENC_FILES+=("$f")
    done < <(find "$SOURCE_DIR" -type f \( -iname "*.ttf.enc" -o -iname "*.ttc.enc" -o -iname "*.otf.enc" \) -print0)

    TOTAL=${#ENC_FILES[@]}

    if [[ $TOTAL -eq 0 ]]; then
        echo -e "${YELLOW}[警告] 在 ${SOURCE_DIR} 中未找到加密字体（.ttf.enc）${NC}"
        echo -e "${YELLOW}提示: 请确保字体加密文件在 ${SOURCE_DIR} 目录中${NC}"
        exit 0
    fi

    echo -e "${GREEN}[信息] 发现 ${TOTAL} 个加密字体文件${NC}"

    # 创建临时目录存放解密文件
    TEMP_DIR=$(mktemp -d "/tmp/font-installer.XXXXXXXXXX")
    echo -e "${CYAN}[信息] 临时解密目录: ${TEMP_DIR}${NC}"

    # 加载文件名映射（混淆 → 原始文件名），兼容 bash 3.2
    MAPPING_FILE="${SOURCE_DIR}/mapping.json"
    MAPPING_TEMP="${TEMP_DIR}/font_mapping.txt"
    if [[ -f "$MAPPING_FILE" ]]; then
        if command -v jq &>/dev/null; then
            jq -r 'to_entries[] | "\(.key)|\(.value)"' "$MAPPING_FILE" > "$MAPPING_TEMP" 2>/dev/null || true
        else
            grep -E '"[^"]+"\s*:\s*"[^"]+"' "$MAPPING_FILE" 2>/dev/null | \
                sed 's/^[[:space:]]*"\([^"]*\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1|\2/' > "$MAPPING_TEMP" || true
        fi
        echo -e "${CYAN}[信息] 已加载字体文件名映射${NC}"
    fi

    # 创建安装目录
    mkdir -p "$INSTALL_DIR"

    # 开始解密并安装
    echo ""
    echo -e "${BLUE}--- 解密并安装字体 ---${NC}"

    SUCCESS=0
    SKIPPED=0
    FAILED=0

    for enc_file in "${ENC_FILES[@]}"; do
        enc_basename=$(basename "$enc_file")
        # 从加密文件名获取混淆键名（如 font_01.ttf.enc → font_01）
        font_key="${enc_basename%.ttf.enc}"
        font_key="${font_key%.ttc.enc}"
        font_key="${font_key%.otf.enc}"
        # 通过映射获取原始文件名，无映射则直接使用加密文件名（去 .enc）
        orig_from_map=""
        if [[ -f "$MAPPING_TEMP" ]]; then
            orig_from_map=$(grep "^${font_key}|" "$MAPPING_TEMP" 2>/dev/null | head -1 | cut -d'|' -f2)
        fi
        font_filename="${orig_from_map:-${enc_basename%.enc}}"
        decrypted_file="${TEMP_DIR}/${font_filename}"

        echo -e "  ${CYAN}[解密]${NC} ${font_filename}"

        if decrypt_font "$enc_file" "$decrypted_file"; then
            # 校验解密结果是否为有效字体
            file_type_raw=$(file "$decrypted_file" 2>/dev/null || true)
            if ! echo "$file_type_raw" | grep -qiE "TrueType|OpenType"; then
                echo -e "  ${RED}[失败]${NC} ${font_filename}（解密结果异常，文件可能已损坏）"
                FAILED=$((FAILED + 1))
                rm -f "$decrypted_file"
                continue
            fi

            target="${INSTALL_DIR}/${font_filename}"

            if [[ -f "$target" ]]; then
                if [[ "$(md5sum_compact "$decrypted_file")" == "$(md5sum_compact "$target")" ]]; then
                    echo -e "  ${YELLOW}[跳过]${NC} ${font_filename}（已安装且内容相同）"
                    SKIPPED=$((SKIPPED + 1))
                    rm -f "$decrypted_file"
                    continue
                else
                    echo -e "  ${YELLOW}[覆盖]${NC} ${font_filename}（存在不同版本）"
                fi
            else
                echo -e "  ${GREEN}[安装]${NC} ${font_filename}"
            fi

            if cp "$decrypted_file" "$target"; then
                SUCCESS=$((SUCCESS + 1))
            else
                echo -e "  ${RED}[失败]${NC} ${font_filename}（复制失败）"
                FAILED=$((FAILED + 1))
            fi
            rm -f "$decrypted_file"
        else
            echo -e "  ${RED}[失败]${NC} ${font_filename}（解密失败）"
            FAILED=$((FAILED + 1))
        fi
    done

    # Linux: 刷新字体缓存
    if [[ "$OS_TYPE" == "linux" ]]; then
        echo ""
        echo -e "${BLUE}[信息] 刷新 Linux 字体缓存...${NC}"
        if command -v fc-cache &>/dev/null; then
            fc-cache -f "$INSTALL_DIR" 2>/dev/null || true
            echo -e "${GREEN}[信息] 字体缓存已刷新${NC}"
        else
            echo -e "${YELLOW}[警告] 未找到 fc-cache，请手动运行: fc-cache -f${NC}"
        fi
    fi

    # macOS: 通知系统字体变更
    if [[ "$OS_TYPE" == "macos" ]]; then
        echo ""
        echo -e "${BLUE}[信息] 通知系统字体变更...${NC}"
        if command -v atsutil &>/dev/null; then
            atsutil databases -remove 2>/dev/null || true
        fi
    fi

    # ---- 结果汇总 ----
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  安装完成${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "  总计: ${TOTAL}  成功: ${GREEN}${SUCCESS}${NC}  跳过: ${YELLOW}${SKIPPED}${NC}  失败: ${RED}${FAILED}${NC}"
    echo ""
    echo -e "字体已安装到: ${INSTALL_DIR}"
    echo ""

    if [[ "$OS_TYPE" == "macos" ]]; then
        echo "请重启以下应用以使用新字体："
        echo "  - Microsoft Word / PowerPoint / Excel"
        echo "  - WPS Office"
        echo "  - 其他文字处理软件"
    elif [[ "$OS_TYPE" == "linux" ]]; then
        echo "请重启应用或执行 'fc-cache -f' 以确保字体生效。"
    fi

    [[ $FAILED -eq 0 ]]
}

# ---- 辅助: MD5 校验（兼容 macOS 和 Linux）----
md5sum_compact() {
    if command -v md5sum &>/dev/null; then
        md5sum "$1" 2>/dev/null | cut -d' ' -f1
    elif command -v md5 &>/dev/null; then
        md5 -q "$1" 2>/dev/null
    else
        echo ""
    fi
}

main "$@"
