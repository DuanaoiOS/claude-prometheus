#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Prometheus — Bringing the fire of AI to your terminal.
# 一键安装 Claude Code + 配置第三方大模型
# 支持: macOS / Linux / Windows (Git Bash / WSL)
# ============================================================

# -------------------- 颜色定义 --------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# -------------------- 全局变量 --------------------
OS=""
NODE_VERSION_REQUIRED=18
INSTALL_NODE=false
API_KEY=""
BASE_URL=""
MODEL_NAME=""
CONFIG_ONLY=false

# -------------------- 工具函数 --------------------
print_banner() {
  echo -e "${CYAN}${BOLD}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║                                          ║"
  echo "  ║       🔥  Prometheus 普罗米修斯          ║"
  echo "  ║                                          ║"
  echo "  ║       将 AI 之火带到你的终端              ║"
  echo "  ║       环境检测 · 一键安装 · 模型配置       ║"
  echo "  ║                                          ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "${NC}"
}

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# -------------------- 系统检测 --------------------
detect_os() {
  local uname_out
  uname_out="$(uname -s 2>/dev/null || echo "unknown")"

  case "$uname_out" in
    Darwin)  OS="macos" ;;
    Linux)   OS="linux" ;;
    MINGW*|MSYS*|CYGWIN*) OS="windows-gitbash" ;;
    *)
      # 兼容 Windows 上的 MSYS2 / Git Bash 不标准的情况
      if [[ -n "${WINDIR:-}" ]] || [[ -n "${SystemRoot:-}" ]] || [[ -d "/mnt/c/Windows" ]]; then
        OS="windows-gitbash"
      else
        OS="linux"
      fi
      ;;
  esac

  info "检测到操作系统: ${BOLD}${OS}${NC}"
}

# -------------------- 权限检查 --------------------
check_permissions() {
  if [[ "$OS" == "macos" || "$OS" == "linux" ]]; then
    if [[ "$(id -u)" -eq 0 ]]; then
      warn "检测到 root 用户，npm 全局安装无需 sudo"
    fi
  fi
}

# -------------------- macOS 依赖全面检测 --------------------
check_macos_dependencies() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi

  echo ""
  info "全面检测 macOS 开发环境依赖..."

  local missing_deps=()

  # 1. Git (Claude Code 需要 git 进行代码仓库上下文分析)
  if check_command git; then
    ok "git: $(git --version 2>/dev/null | head -1)"
  else
    warn "git: 未安装（Claude Code 需要 git 管理代码上下文）"
    missing_deps+=("git")
  fi

  # 2. Xcode Command Line Tools (提供 make/gcc/clang，编译原生 npm 模块)
  if xcode-select -p &>/dev/null; then
    local xcode_path
    xcode_path=$(xcode-select -p 2>/dev/null)
    ok "Xcode CLT: 已安装 (${xcode_path})"
  else
    warn "Xcode Command Line Tools: 未安装（编译原生模块需要）"
    missing_deps+=("xcode-clt")
  fi

  # 3. Homebrew (macOS 包管理器，便于安装 Node.js)
  if check_command brew; then
    ok "Homebrew: $(brew --version 2>/dev/null | head -1)"
  else
    warn "Homebrew: 未安装（推荐安装，便于管理 Node.js 等依赖）"
    missing_deps+=("homebrew")
  fi

  # 4. curl (下载依赖时使用)
  if check_command curl; then
    ok "curl: 已安装"
  else
    warn "curl: 未安装"
    missing_deps+=("curl")
  fi

  # 5. 检查 macOS 版本兼容性
  local macos_version
  macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
  local macos_major
  macos_major=$(echo "$macos_version" | cut -d. -f1)
  if [[ "$macos_major" -ge 13 ]]; then
    ok "macOS: ${macos_version} (兼容)"
  else
    warn "macOS: ${macos_version} (建议 macOS 13+ 以获得最佳兼容性)"
  fi

  # 6. 检查磁盘空间 (至少 2GB 剩余)
  local free_space
  free_space=$(df -g . | tail -1 | awk '{print $4}' 2>/dev/null || echo "0")
  if [[ "$free_space" -ge 2 ]]; then
    ok "磁盘剩余空间: ${free_space}GB"
  else
    warn "磁盘剩余空间: ${free_space}GB (建议至少 2GB 剩余空间)"
  fi

  # 处理缺失依赖
  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo ""
    warn "发现 ${#missing_deps[@]} 个缺失/建议安装的组件:"
    for dep in "${missing_deps[@]}"; do
      case "$dep" in
        git)
          echo "   - git: 执行 'xcode-select --install' 或从 https://git-scm.com 下载"
          ;;
        xcode-clt)
          echo "   - Xcode Command Line Tools: 执行 'xcode-select --install' 安装"
          ;;
        homebrew)
          echo "   - Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
          ;;
        curl)
          echo "   - curl: 系统应自带，请检查 PATH 配置"
          ;;
      esac
    done

    # 自动尝试安装 Xcode CLT
    if [[ " ${missing_deps[*]} " =~ "xcode-clt" ]]; then
      echo ""
      info "正在尝试自动安装 Xcode Command Line Tools..."
      if xcode-select --install 2>/dev/null; then
        warn "已触发安装弹窗，请完成安装后按回车继续..."
        read -r
      else
        warn "无法自动触发安装，请手动执行: xcode-select --install"
      fi
    fi
    echo ""
  else
    ok "macOS 环境依赖检查全部通过"
  fi
}

# -------------------- 命令检测 --------------------
check_command() {
  command -v "$1" &>/dev/null
}

# -------------------- 网络检测 --------------------
check_network() {
  info "检查网络连接..."
  if curl -s --connect-timeout 5 https://registry.npmjs.org/ &>/dev/null; then
    ok "网络连接正常"
  else
    warn "无法访问 npm registry，请检查网络或代理设置"
    if [[ -n "${HTTP_PROXY:-}" ]] || [[ -n "${http_proxy:-}" ]]; then
      info "检测到 HTTP 代理: ${HTTP_PROXY:-${http_proxy:-}}"
    fi
  fi
}

# -------------------- Node.js 检测与安装 --------------------
check_nodejs() {
  info "检查 Node.js..."

  if check_command node; then
    local node_version
    node_version=$(node -v | sed 's/v//' | cut -d. -f1)
    if [[ "$node_version" -ge "$NODE_VERSION_REQUIRED" ]]; then
      ok "Node.js $(node -v) 已满足要求 (>= v${NODE_VERSION_REQUIRED})"
      return 0
    else
      warn "Node.js $(node -v) 版本过低，需要 >= v${NODE_VERSION_REQUIRED}"
    fi
  else
    warn "未检测到 Node.js"
  fi

  INSTALL_NODE=true
}

install_nodejs() {
  if [[ "$INSTALL_NODE" != "true" ]]; then
    return
  fi

  info "安装 Node.js (LTS)..."

  case "$OS" in
    macos)
      if check_command brew; then
        info "通过 Homebrew 安装 Node.js..."
        brew install node
      else
        warn "未安装 Homebrew，使用 nvm 安装 Node.js..."
        install_nodejs_via_nvm
      fi
      ;;
    linux)
      install_nodejs_via_nvm
      ;;
    windows-gitbash)
      warn "Windows Git Bash 环境，请手动安装 Node.js:"
      echo "  1. 下载 Node.js: https://nodejs.org/ (选择 LTS 版本)"
      echo "  2. 安装后重新运行本脚本"
      echo ""
      # 尝试使用 winget 或 choco
      if check_command winget; then
        info "检测到 winget，尝试自动安装..."
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
      elif check_command choco; then
        info "检测到 Chocolatey，尝试自动安装..."
        choco install nodejs-lts -y
      else
        error "请安装 Node.js >= v${NODE_VERSION_REQUIRED} 后重新运行本脚本"
        exit 1
      fi
      ;;
  esac

  # 重新加载 shell 环境
  export PATH="$HOME/.nvm/versions/node/$(ls "$HOME/.nvm/versions/node/" 2>/dev/null | sort -V | tail -1)/bin:$PATH" 2>/dev/null || true

  if check_command node; then
    ok "Node.js $(node -v) 安装成功"
  fi
}

install_nodejs_via_nvm() {
  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"

  if [[ -s "$nvm_dir/nvm.sh" ]]; then
    info "nvm 已安装，直接安装 Node.js LTS..."
    # shellcheck source=/dev/null
    source "$nvm_dir/nvm.sh"
    nvm install --lts
    nvm use --lts
  else
    info "安装 nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash

    # shellcheck source=/dev/null
    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

    nvm install --lts
    nvm use --lts
    ok "nvm + Node.js LTS 安装完成"
  fi
}

# -------------------- Claude Code 安装 --------------------
install_claude_code() {
  info "安装 Claude Code..."
  npm install -g @anthropic-ai/claude-code

  if check_command claude; then
    ok "Claude Code 安装成功 ($(claude --version 2>/dev/null || echo 'installed'))"
  else
    error "Claude Code 安装失败，请检查 npm 全局路径是否在 PATH 中"
    info "npm 全局 bin 路径: $(npm config get prefix)/bin"
    exit 1
  fi
}

# -------------------- 第三方模型配置 --------------------
configure_third_party_model() {
  local config_file="${CLAUDE_CONFIG_PATH:-$HOME/.claude.json}"

  echo ""
  echo -e "${CYAN}${BOLD}════════════════════════════════════════════${NC}"
  echo -e "${CYAN}${BOLD}  第三方大模型配置${NC}"
  echo -e "${CYAN}${BOLD}════════════════════════════════════════════${NC}"
  echo ""

  # 选择配置方式
  echo "请选择配置方式:"
  echo "  1) 使用环境变量 (推荐，所有终端生效)"
  echo "  2) 使用 Claude Code 配置文件"
  echo ""
  read -rp "请输入选项 [1/2] (默认 1): " config_method
  config_method=${config_method:-1}

  # API Key
  echo ""
  echo -e "${YELLOW}请输入第三方 API Key (输入后回车确认):${NC}"
  read -rp "API Key: " API_KEY

  if [[ -z "$API_KEY" ]]; then
    error "API Key 不能为空，跳过模型配置"
    return 1
  fi

  # 提供商选择
  echo ""
  echo "支持以下第三方模型提供商:"
  echo "  1) DeepSeek (deepseek-v4-pro / deepseek-v4-flash，百万上下文)"
  echo "  2) OpenRouter (支持多种模型)"
  echo "  3) 自定义 Anthropic 兼容 API"
  echo "  4) 阿里百炼 (通义千问)"
  echo "  5) 智谱 AI (GLM)"
  echo ""
  read -rp "请选择提供商 [1-5] (默认 1): " provider_choice
  provider_choice=${provider_choice:-1}

  case "$provider_choice" in
    1)
      BASE_URL="https://api.deepseek.com/anthropic"
      echo ""
      echo "DeepSeek 可用模型 (支持 1M token 上下文):"
      echo "  a) deepseek-v4-pro   (旗舰版，擅长复杂推理与代码生成)"
      echo "  b) deepseek-v4-flash (轻量快速版，性价比高)"
      echo "  c) 自定义模型名称"
      read -rp "请选择 [a/b/c] (默认 a): " model_choice
      case "${model_choice:-a}" in
        a) MODEL_NAME="deepseek-v4-pro" ;;
        b) MODEL_NAME="deepseek-v4-flash" ;;
        c) read -rp "请输入模型名称: " MODEL_NAME ;;
      esac
      ;;
    2)
      BASE_URL="https://openrouter.ai/api/v1"
      echo ""
      echo "OpenRouter 常用模型:"
      echo "  a) anthropic/claude-sonnet-4"
      echo "  b) anthropic/claude-opus-4"
      echo "  c) deepseek/deepseek-v4-pro"
      echo "  d) 自定义模型名称"
      read -rp "请选择 [a/b/c/d] (默认 a): " model_choice
      case "${model_choice:-a}" in
        a) MODEL_NAME="anthropic/claude-sonnet-4" ;;
        b) MODEL_NAME="anthropic/claude-opus-4" ;;
        c) MODEL_NAME="deepseek/deepseek-v4-pro" ;;
        d) read -rp "请输入模型名称: " MODEL_NAME ;;
      esac
      ;;
    3)
      read -rp "请输入 API Base URL: " BASE_URL
      read -rp "请输入模型名称: " MODEL_NAME
      ;;
    4)
      BASE_URL="https://dashscope.aliyuncs.com/compatible-mode/v1"
      echo ""
      echo "百炼可用模型:"
      echo "  a) qwen-plus"
      echo "  b) qwen-max"
      echo "  c) 自定义模型名称"
      read -rp "请选择 [a/b/c] (默认 a): " model_choice
      case "${model_choice:-a}" in
        a) MODEL_NAME="qwen-plus" ;;
        b) MODEL_NAME="qwen-max" ;;
        c) read -rp "请输入模型名称: " MODEL_NAME ;;
      esac
      ;;
    5)
      BASE_URL="https://open.bigmodel.cn/api/paas/v4"
      echo ""
      echo "智谱可用模型:"
      echo "  a) glm-4-plus"
      echo "  b) glm-4-flash"
      echo "  c) 自定义模型名称"
      read -rp "请选择 [a/b/c] (默认 a): " model_choice
      case "${model_choice:-a}" in
        a) MODEL_NAME="glm-4-plus" ;;
        b) MODEL_NAME="glm-4-flash" ;;
        c) read -rp "请输入模型名称: " MODEL_NAME ;;
      esac
      ;;
    *)
      warn "无效选择，使用 DeepSeek 默认配置"
      BASE_URL="https://api.deepseek.com/anthropic"
      MODEL_NAME="deepseek-v4-pro"
      ;;
  esac

  # 应用配置
  if [[ "$config_method" == "1" ]]; then
    apply_env_config
  else
    apply_file_config "$config_file"
  fi
}

apply_env_config() {
  local shell_rc=""
  case "${SHELL:-}" in
    */zsh) shell_rc="$HOME/.zshrc" ;;
    */bash) shell_rc="$HOME/.bashrc" ;;
    *) shell_rc="$HOME/.profile" ;;
  esac

  # macOS 默认 shell 为 zsh
  if [[ "$OS" == "macos" ]] && [[ ! -f "$shell_rc" ]]; then
    shell_rc="$HOME/.zshrc"
  fi

  info "写入环境变量到 ${shell_rc}..."

  # 备份注释头
  local marker="# >>> Claude Code Third-Party Model Config >>>"

  # 删除旧配置
  if [[ -f "$shell_rc" ]]; then
    sed -i.bak '/^# >>> Claude Code/,/^# <<< Claude Code/d' "$shell_rc"
    rm -f "${shell_rc}.bak"
  fi

  cat <<EOF >> "$shell_rc"

${marker}
export ANTHROPIC_API_KEY="${API_KEY}"
export ANTHROPIC_BASE_URL="${BASE_URL}"
export ANTHROPIC_MODEL="${MODEL_NAME}"
# 可选: 设置超长思考模式 (deepseek-v4-pro 等推理模型)
# export ANTHROPIC_THINKING_TYPE="enabled"
# <<< Claude Code Third-Party Model Config <<<
EOF

  # Windows Git Bash 也写入 .bash_profile
  if [[ "$OS" == "windows-gitbash" ]]; then
    cat <<EOF >> "$HOME/.bash_profile"

${marker}
export ANTHROPIC_API_KEY="${API_KEY}"
export ANTHROPIC_BASE_URL="${BASE_URL}"
export ANTHROPIC_MODEL="${MODEL_NAME}"
# <<< Claude Code Third-Party Model Config <<<
EOF
  fi

  # 同时应用到当前会话
  export ANTHROPIC_API_KEY="${API_KEY}"
  export ANTHROPIC_BASE_URL="${BASE_URL}"
  export ANTHROPIC_MODEL="${MODEL_NAME}"

  ok "环境变量配置完成"
  info "新终端窗口将自动加载配置，或执行: source ${shell_rc}"
}

apply_file_config() {
  local config_file="$1"
  local tmp_file
  local config_json

  # 如果已有配置文件，合并
  if [[ -f "$config_file" ]]; then
    info "检测到已有配置文件，合并更新..."
    # 使用 node 合并 JSON（不再依赖 jq）
    config_json=$(node -e "
      const fs = require('fs');
      let config = {};
      try { config = JSON.parse(fs.readFileSync('$config_file', 'utf8')); } catch(e) {}
      config.ANTHROPIC_API_KEY = '$API_KEY';
      config.ANTHROPIC_BASE_URL = '$BASE_URL';
      config.ANTHROPIC_MODEL = '$MODEL_NAME';
      console.log(JSON.stringify(config, null, 2));
    " 2>/dev/null || echo '{}')
  else
    config_json=$(node -e "
      console.log(JSON.stringify({
        ANTHROPIC_API_KEY: '$API_KEY',
        ANTHROPIC_BASE_URL: '$BASE_URL',
        ANTHROPIC_MODEL: '$MODEL_NAME'
      }, null, 2));
    ")
  fi

  echo "$config_json" > "$config_file"
  ok "配置文件已写入: ${config_file}"
}

# -------------------- 安装后验证 --------------------
verify_installation() {
  echo ""
  echo -e "${CYAN}${BOLD}════════════════════════════════════════════${NC}"
  echo -e "${CYAN}${BOLD}  安装验证${NC}"
  echo -e "${CYAN}${BOLD}════════════════════════════════════════════${NC}"
  echo ""

  # Node.js
  if check_command node; then
    ok "Node.js: $(node -v)"
  else
    error "Node.js: 未安装"
  fi

  # npm
  if check_command npm; then
    ok "npm: $(npm -v)"
  else
    error "npm: 未安装"
  fi

  # Claude Code
  if check_command claude; then
    ok "Claude Code: $(claude --version 2>/dev/null || echo '已安装')"
  else
    warn "Claude Code: 未找到命令，全局 npm bin 路径可能不在 PATH 中"
    local npm_bin
    npm_bin="$(npm config get prefix 2>/dev/null || echo "$HOME/.npm-global")/bin"
    info "请将以下路径添加到 PATH: ${npm_bin}"
    # 尝试直接执行
    if [[ -x "${npm_bin}/claude" ]]; then
      ok "找到 Claude 可执行文件: ${npm_bin}/claude"
    fi
  fi

  # 模型配置
  echo ""
  if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    ok "API Key: 已配置 (${ANTHROPIC_API_KEY:0:8}...)"
  else
    warn "API Key: 未配置"
  fi

  if [[ -n "${ANTHROPIC_BASE_URL:-}" ]]; then
    ok "Base URL: ${ANTHROPIC_BASE_URL}"
  fi

  if [[ -n "${ANTHROPIC_MODEL:-}" ]]; then
    ok "默认模型: ${ANTHROPIC_MODEL}"
  fi
}

# -------------------- 使用说明 --------------------
print_usage() {
  echo ""
  echo -e "${CYAN}${BOLD}════════════════════════════════════════════${NC}"
  echo -e "${CYAN}${BOLD}  快速开始${NC}"
  echo -e "${CYAN}${BOLD}════════════════════════════════════════════${NC}"
  echo ""
  echo -e "  ${BOLD}启动 Claude Code:${NC}"
  echo "    claude"
  echo ""
  echo -e "  ${BOLD}启动交互式对话:${NC}"
  echo "    claude chat"
  echo ""
  echo -e "  ${BOLD}查看帮助:${NC}"
  echo "    claude --help"
  echo ""
  echo -e "  ${BOLD}切换模型 (Claude Code 内):${NC}"
  echo "    /model"
  echo ""
  echo -e "  ${BOLD}修改配置:${NC}"
  echo "    重新运行本脚本: ./install-claude-code.sh"
  echo "    或直接编辑: ~/.claude.json"
  echo ""
  echo -e "${YELLOW}  ⚠ 注意: 如果使用第三方模型，首次启动可能需要"
  echo "    手动在 Claude Code 中使用 /model 选择模型${NC}"
  echo ""
}

# -------------------- 命令行参数 --------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --api-key)
        API_KEY="$2"
        shift 2
        ;;
      --base-url)
        BASE_URL="$2"
        shift 2
        ;;
      --model)
        MODEL_NAME="$2"
        shift 2
        ;;
      --config-only)
        CONFIG_ONLY=true
        shift
        ;;
      --help|-h)
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  --api-key KEY     第三方 API Key（跳过交互输入）"
        echo "  --base-url URL    API Base URL"
        echo "  --model NAME      模型名称"
        echo "  --config-only     仅配置模型，不安装 Claude Code"
        echo "  -h, --help        显示帮助"
        echo ""
        echo "示例:"
        echo "  # 交互式安装"
        echo "  ./install-claude-code.sh"
        echo ""
        echo "  # 命令行参数安装 DeepSeek v4"
        echo "  ./install-claude-code.sh --api-key sk-xxx \\"
        echo "      --base-url https://api.deepseek.com/anthropic \\"
        echo "      --model deepseek-v4-pro"
        exit 0
        ;;
      *)
        error "未知选项: $1"
        echo "使用 --help 查看帮助"
        exit 1
        ;;
    esac
  done
}

# -------------------- 主流程 --------------------
main() {
  print_banner

  # 解析命令行参数
  parse_args "$@"

  # 检测系统
  detect_os

  # 权限检查
  check_permissions

  # macOS 依赖全面检测
  check_macos_dependencies

  if [[ "$CONFIG_ONLY" == "true" ]]; then
    configure_third_party_model
    verify_installation
    exit 0
  fi

  # 网络检查
  check_network

  # 检查并安装 Node.js
  check_nodejs
  install_nodejs

  # 验证 Node.js 可用
  if ! check_command node; then
    error "Node.js 未安装成功，请手动安装后重试"
    exit 1
  fi

  if ! check_command npm; then
    error "npm 未找到，请检查 Node.js 安装"
    exit 1
  fi

  # 检查是否已安装 Claude Code
  if check_command claude; then
    info "Claude Code 已安装 ($(claude --version 2>/dev/null || echo 'installed'))"
    read -rp "是否重新安装? [y/N]: " reinstall
    if [[ "${reinstall,,}" == "y" ]]; then
      info "更新 Claude Code..."
      npm install -g @anthropic-ai/claude-code
    fi
  else
    install_claude_code
  fi

  # 配置第三方模型
  if [[ -n "$API_KEY" ]] && [[ -n "$BASE_URL" ]] && [[ -n "$MODEL_NAME" ]]; then
    # 命令行已提供全部参数，直接配置
    info "使用命令行参数配置模型..."
    apply_env_config
  else
    # 交互式配置
    echo ""
    read -rp "是否配置第三方大模型? [Y/n]: " do_config
    if [[ "${do_config,,}" != "n" ]]; then
      configure_third_party_model
    fi
  fi

  # 验证
  verify_installation

  # 使用说明
  print_usage

  echo -e "${GREEN}${BOLD}✅ 安装完成!${NC}"
  echo ""
  echo -e "  ${BOLD}重新加载 shell 环境:${NC}"
  if [[ "$OS" == "windows-gitbash" ]]; then
    echo "    source ~/.bashrc  # 或重新打开终端"
  else
    echo "    source ~/.zshrc   # zsh 用户"
    echo "    source ~/.bashrc  # bash 用户"
  fi
  echo ""
  echo -e "  ${BOLD}启动 Claude Code:${NC}"
  echo "    claude"
  echo ""
}

main "$@"
