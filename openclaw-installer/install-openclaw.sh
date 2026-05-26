#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Prometheus — Bringing the fire of AI to your terminal.
# OpenClaw 一键安装脚本
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
NODE_VERSION_REQUIRED=22
INSTALL_NODE=false
CONFIG_ONLY=false

# 模型配置
DEEPSEEK_KEY=""
OPENAI_KEY=""
ANTHROPIC_KEY=""
OPENROUTER_KEY=""
GEMINI_KEY=""
QWEN_KEY=""
GLM_KEY=""

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
  echo "  ║          🦞  OpenClaw 安装器             ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "${NC}"
}

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

check_command() {
  command -v "$1" &>/dev/null
}

# -------------------- 系统检测 --------------------
detect_os() {
  local uname_out
  uname_out="$(uname -s 2>/dev/null || echo "unknown")"

  case "$uname_out" in
    Darwin)  OS="macos" ;;
    Linux)   OS="linux" ;;
    MINGW*|MSYS*|CYGWIN*) OS="windows-gitbash" ;;
    *)
      if [[ -n "${WINDIR:-}" ]] || [[ -n "${SystemRoot:-}" ]] || [[ -d "/mnt/c/Windows" ]]; then
        OS="windows-gitbash"
      else
        OS="linux"
      fi
      ;;
  esac

  info "检测到操作系统: ${BOLD}${OS}${NC}"
}

# -------------------- macOS 环境依赖检测 --------------------
check_macos_dependencies() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi

  echo ""
  info "全面检测 macOS 开发环境依赖..."

  local missing_deps=()

  if check_command git; then
    ok "git: $(git --version 2>/dev/null | head -1)"
  else
    warn "git: 未安装（OpenClaw 可通过 git 感知代码上下文）"
    missing_deps+=("git")
  fi

  if xcode-select -p &>/dev/null; then
    ok "Xcode CLT: 已安装"
  else
    warn "Xcode Command Line Tools: 未安装（编译原生模块需要）"
    missing_deps+=("xcode-clt")
  fi

  if check_command brew; then
    ok "Homebrew: $(brew --version 2>/dev/null | head -1)"
  else
    warn "Homebrew: 未安装（推荐）"
    missing_deps+=("homebrew")
  fi

  if check_command curl; then
    ok "curl: 已安装"
  else
    warn "curl: 未安装"
    missing_deps+=("curl")
  fi

  local macos_version
  macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
  local macos_major
  macos_major=$(echo "$macos_version" | cut -d. -f1)
  if [[ "$macos_major" -ge 13 ]]; then
    ok "macOS: ${macos_version} (兼容)"
  else
    warn "macOS: ${macos_version} (建议 macOS 13+)"
  fi

  local free_space
  free_space=$(df -g . | tail -1 | awk '{print $4}' 2>/dev/null || echo "0")
  if [[ "$free_space" -ge 2 ]]; then
    ok "磁盘剩余空间: ${free_space}GB"
  else
    warn "磁盘剩余空间: ${free_space}GB (建议至少 2GB)"
  fi

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo ""
    warn "发现 ${#missing_deps[@]} 个缺失/建议安装的组件:"
    for dep in "${missing_deps[@]}"; do
      case "$dep" in
        git)
          echo "   - git: 执行 'xcode-select --install' 或从 https://git-scm.com 下载"
          ;;
        xcode-clt)
          echo "   - Xcode Command Line Tools: 执行 'xcode-select --install'"
          ;;
        homebrew)
          echo "   - Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
          ;;
        curl)
          echo "   - curl: 系统应自带，请检查 PATH 配置"
          ;;
      esac
    done

    if [[ " ${missing_deps[*]} " =~ "xcode-clt" ]]; then
      echo ""
      info "正在尝试自动安装 Xcode Command Line Tools..."
      if xcode-select --install 2>/dev/null; then
        warn "已触发安装弹窗，请完成安装后按回车继续..."
        read -r
      fi
    fi
    echo ""
  else
    ok "macOS 环境依赖检查全部通过"
  fi
}

# -------------------- 网络检测 --------------------
check_network() {
  info "检查网络连接..."
  if curl -s --connect-timeout 5 https://registry.npmjs.org/ &>/dev/null; then
    ok "网络连接正常"
  else
    warn "无法访问 npm registry，请检查网络或代理设置"
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

  info "安装 Node.js 24 (LTS)..."

  case "$OS" in
    macos)
      if check_command brew; then
        info "通过 Homebrew 安装 Node.js..."
        brew install node@24
        brew link --force --overwrite node@24
      else
        install_nodejs_via_nvm
      fi
      ;;
    linux|windows-gitbash)
      install_nodejs_via_nvm
      ;;
  esac

  if check_command node; then
    ok "Node.js $(node -v) 安装成功"
  fi
}

install_nodejs_via_nvm() {
  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"

  if [[ -s "$nvm_dir/nvm.sh" ]]; then
    info "nvm 已安装，直接安装 Node.js 24 LTS..."
    source "$nvm_dir/nvm.sh"
    nvm install 24
    nvm use 24
  else
    info "安装 nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash

    export NVM_DIR="$HOME/.nvm"

    # 重试 source nvm.sh（curl pipe 后文件可能未就绪）
    local retry=0
    while [[ $retry -lt 5 ]]; do
      if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        source "$NVM_DIR/nvm.sh"
        break
      fi
      sleep 1
      ((retry++))
    done

    if ! type -t nvm &>/dev/null && ! command -v node &>/dev/null; then
      error "nvm 安装后无法加载，请手动安装 Node.js >= v${NODE_VERSION_REQUIRED}"
      exit 1
    fi

    nvm install 24
    nvm use 24
    ok "nvm + Node.js 24 安装完成"
  fi

  # 仅在 nvm 路径下更新 PATH
  local nvm_node_bin
  nvm_node_bin=$(dirname "$(command -v node)" 2>/dev/null || echo "")
  if [[ -n "$nvm_node_bin" ]] && [[ "$nvm_node_bin" == "$NVM_DIR"* ]]; then
    export PATH="$nvm_node_bin:$PATH"
  fi
}

# -------------------- OpenClaw 安装 --------------------
install_openclaw() {
  info "安装 OpenClaw..."

  # sharp 兼容性处理
  if ! check_command pnpm && ! check_command bun; then
    info "使用 npm 安装..."
    SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install -g openclaw@latest
  elif check_command pnpm; then
    info "检测到 pnpm，使用 pnpm 安装..."
    pnpm add -g openclaw@latest
    pnpm approve-builds -g
  elif check_command bun; then
    info "检测到 bun，使用 bun 安装..."
    bun add -g openclaw@latest
  fi

  if check_command openclaw; then
    ok "OpenClaw 安装成功"
  else
    error "OpenClaw 安装失败，请检查 npm 全局路径是否在 PATH 中"
    info "npm 全局 bin 路径: $(npm config get prefix)/bin"
    exit 1
  fi
}

# -------------------- 第三方模型配置 --------------------
configure_models() {
  echo ""
  echo -e "${CYAN}${BOLD}════════════════════════════════════════════${NC}"
  echo -e "${CYAN}${BOLD}  第三方大模型配置${NC}"
  echo -e "${CYAN}${BOLD}════════════════════════════════════════════${NC}"
  echo ""
  echo "OpenClaw 原生支持多种模型提供商，通过环境变量配置 API Key。"
  echo ""

  # 配置方式选择
  echo "请选择配置方式:"
  echo "  1) 使用环境变量 (推荐，所有终端生效)"
  echo "  2) 使用 OpenClaw 配置文件 (~/.openclaw/openclaw.json)"
  echo ""
  read -rp "请输入选项 [1/2] (默认 1): " config_method
  config_method=${config_method:-1}

  # 提供商选择（支持多选）
  echo ""
  echo "请选择要配置的模型提供商 (可多选，用空格分隔):"
  echo "  1) DeepSeek (deepseek-v4-pro / deepseek-v4-flash，1M 上下文)"
  echo "  2) OpenAI (GPT-4o / GPT-5 等)"
  echo "  3) Anthropic (Claude Sonnet 4 / Opus 4)"
  echo "  4) OpenRouter (聚合多家模型)"
  echo "  5) Google Gemini"
  echo "  6) 阿里百炼 / Qwen"
  echo "  7) 智谱 GLM"
  echo "  8) 全部配置"
  echo ""
  read -rp "请输入选项 (如: 1 3 4，默认 1): " -a provider_choices
  if [[ ${#provider_choices[@]} -eq 0 ]]; then
    provider_choices=(1)
  fi

  for choice in "${provider_choices[@]}"; do
    case "$choice" in
      1) configure_deepseek ;;
      2) configure_openai ;;
      3) configure_anthropic ;;
      4) configure_openrouter ;;
      5) configure_gemini ;;
      6) configure_qwen ;;
      7) configure_glm ;;
      8)
        configure_deepseek
        configure_openai
        configure_anthropic
        configure_openrouter
        configure_gemini
        configure_qwen
        configure_glm
        ;;
      *) warn "无效选项: $choice，跳过" ;;
    esac
  done

  # 应用配置
  if [[ "$config_method" == "1" ]]; then
    write_env_config
  else
    write_file_config
  fi
}

configure_deepseek() {
  echo ""
  echo -e "${YELLOW}--- DeepSeek 配置 ---${NC}"
  echo "可用模型: deepseek-v4-pro (旗舰), deepseek-v4-flash (轻量)，支持 1M 上下文"
  read -rp "DeepSeek API Key: " DEEPSEEK_KEY
}

configure_openai() {
  echo ""
  echo -e "${YELLOW}--- OpenAI 配置 ---${NC}"
  echo "可用模型: gpt-5, gpt-4o 等"
  read -rp "OpenAI API Key: " OPENAI_KEY
}

configure_anthropic() {
  echo ""
  echo -e "${YELLOW}--- Anthropic 配置 ---${NC}"
  echo "可用模型: claude-sonnet-4-6, claude-opus-4-7 等"
  read -rp "Anthropic API Key: " ANTHROPIC_KEY
}

configure_openrouter() {
  echo ""
  echo -e "${YELLOW}--- OpenRouter 配置 ---${NC}"
  echo "聚合平台，支持 deepseek-v4-pro, claude, gpt 等多种模型"
  read -rp "OpenRouter API Key: " OPENROUTER_KEY
}

configure_gemini() {
  echo ""
  echo -e "${YELLOW}--- Google Gemini 配置 ---${NC}"
  echo "可用模型: gemini-2.5-pro, gemini-2.5-flash 等"
  read -rp "Gemini API Key: " GEMINI_KEY
}

configure_qwen() {
  echo ""
  echo -e "${YELLOW}--- 阿里百炼 / Qwen 配置 ---${NC}"
  echo "可用模型: qwen-max, qwen-plus 等"
  read -rp "Qwen / DashScope API Key: " QWEN_KEY
}

configure_glm() {
  echo ""
  echo -e "${YELLOW}--- 智谱 GLM 配置 ---${NC}"
  echo "可用模型: glm-4.5, glm-4.6, glm-4.7 等"
  read -rp "智谱 Z.AI API Key: " GLM_KEY
}

write_env_config() {
  local shell_rc=""
  # macOS 自 Catalina 起默认 shell 为 zsh
  if [[ "$OS" == "macos" ]]; then
    shell_rc="$HOME/.zshrc"
  else
    case "${SHELL:-}" in
      */zsh)   shell_rc="$HOME/.zshrc" ;;
      */bash)  shell_rc="$HOME/.bashrc" ;;
      *)       shell_rc="$HOME/.profile" ;;
    esac
  fi

  info "写入环境变量到 ${shell_rc}..."

  # 删除旧配置
  local marker="# >>> Prometheus OpenClaw Config >>>"
  if [[ -f "$shell_rc" ]]; then
    sed -i.bak '/^# >>> Prometheus OpenClaw/,/^# <<< Prometheus OpenClaw/d' "$shell_rc"
    rm -f "${shell_rc}.bak"
  fi

  {
    echo ""
    echo "${marker}"
    [[ -n "$DEEPSEEK_KEY" ]]   && echo "export DEEPSEEK_API_KEY=\"${DEEPSEEK_KEY}\""
    [[ -n "$OPENAI_KEY" ]]     && echo "export OPENAI_API_KEY=\"${OPENAI_KEY}\""
    [[ -n "$ANTHROPIC_KEY" ]]  && echo "export ANTHROPIC_API_KEY=\"${ANTHROPIC_KEY}\""
    [[ -n "$OPENROUTER_KEY" ]] && echo "export OPENROUTER_API_KEY=\"${OPENROUTER_KEY}\""
    [[ -n "$GEMINI_KEY" ]]     && echo "export GEMINI_API_KEY=\"${GEMINI_KEY}\""
    [[ -n "$QWEN_KEY" ]]       && echo "export DASHSCOPE_API_KEY=\"${QWEN_KEY}\""
    [[ -n "$GLM_KEY" ]]        && echo "export ZAI_API_KEY=\"${GLM_KEY}\""

    # 默认模型设置 (优先 DeepSeek)
    if [[ -n "$DEEPSEEK_KEY" ]]; then
      echo "# 默认使用 DeepSeek V4 Pro"
    fi

    echo "# <<< Prometheus OpenClaw Config <<<"
  } >> "$shell_rc"

  # Windows Git Bash
  if [[ "$OS" == "windows-gitbash" ]]; then
    {
      echo ""
      echo "${marker}"
      [[ -n "$DEEPSEEK_KEY" ]]   && echo "export DEEPSEEK_API_KEY=\"${DEEPSEEK_KEY}\""
      [[ -n "$OPENAI_KEY" ]]     && echo "export OPENAI_API_KEY=\"${OPENAI_KEY}\""
      [[ -n "$ANTHROPIC_KEY" ]]  && echo "export ANTHROPIC_API_KEY=\"${ANTHROPIC_KEY}\""
      [[ -n "$OPENROUTER_KEY" ]] && echo "export OPENROUTER_API_KEY=\"${OPENROUTER_KEY}\""
      [[ -n "$GEMINI_KEY" ]]     && echo "export GEMINI_API_KEY=\"${GEMINI_KEY}\""
      [[ -n "$QWEN_KEY" ]]       && echo "export DASHSCOPE_API_KEY=\"${QWEN_KEY}\""
      [[ -n "$GLM_KEY" ]]        && echo "export ZAI_API_KEY=\"${GLM_KEY}\""
      echo "# <<< Prometheus OpenClaw Config <<<"
    } >> "$HOME/.bash_profile"
  fi

  # 应用到当前会话
  [[ -n "$DEEPSEEK_KEY" ]]   && export DEEPSEEK_API_KEY="${DEEPSEEK_KEY}"
  [[ -n "$OPENAI_KEY" ]]     && export OPENAI_API_KEY="${OPENAI_KEY}"
  [[ -n "$ANTHROPIC_KEY" ]]  && export ANTHROPIC_API_KEY="${ANTHROPIC_KEY}"
  [[ -n "$OPENROUTER_KEY" ]] && export OPENROUTER_API_KEY="${OPENROUTER_KEY}"
  [[ -n "$GEMINI_KEY" ]]     && export GEMINI_API_KEY="${GEMINI_KEY}"
  [[ -n "$QWEN_KEY" ]]       && export DASHSCOPE_API_KEY="${QWEN_KEY}"
  [[ -n "$GLM_KEY" ]]        && export ZAI_API_KEY="${GLM_KEY}"

  ok "环境变量配置完成"
  info "新终端窗口将自动加载，或执行: source ${shell_rc}"
}

write_file_config() {
  local config_dir="$HOME/.openclaw"
  local config_file="${config_dir}/openclaw.json"

  mkdir -p "$config_dir"

  export _PROMETHEUS_CONFIG_FILE="$config_file"
  export _PROMETHEUS_DEEPSEEK_KEY="$DEEPSEEK_KEY"
  export _PROMETHEUS_OPENAI_KEY="$OPENAI_KEY"
  export _PROMETHEUS_ANTHROPIC_KEY="$ANTHROPIC_KEY"
  export _PROMETHEUS_OPENROUTER_KEY="$OPENROUTER_KEY"
  export _PROMETHEUS_GEMINI_KEY="$GEMINI_KEY"
  export _PROMETHEUS_QWEN_KEY="$QWEN_KEY"
  export _PROMETHEUS_GLM_KEY="$GLM_KEY"

  if node <<'NODESCRIPT'; then
    const fs = require('fs');
    const configFile = process.env._PROMETHEUS_CONFIG_FILE;
    let config = {};
    if (fs.existsSync(configFile)) {
      try { config = JSON.parse(fs.readFileSync(configFile, 'utf8')); } catch(e) {}
    }

    config.models = config.models || {};
    config.models.providers = config.models.providers || {};
    config.agents = config.agents || {};
    config.agents.defaults = config.agents.defaults || {};
    config.agents.defaults.model = config.agents.defaults.model || {};

    const keys = {
      deepseek:   process.env._PROMETHEUS_DEEPSEEK_KEY,
      openai:     process.env._PROMETHEUS_OPENAI_KEY,
      anthropic:  process.env._PROMETHEUS_ANTHROPIC_KEY,
      openrouter: process.env._PROMETHEUS_OPENROUTER_KEY,
      gemini:     process.env._PROMETHEUS_GEMINI_KEY,
      qwen:       process.env._PROMETHEUS_QWEN_KEY,
      zai:        process.env._PROMETHEUS_GLM_KEY,
    };

    for (const [provider, key] of Object.entries(keys)) {
      if (key) {
        config.models.providers[provider] = { apiKey: key };
      }
    }

    if (keys.deepseek) {
      config.agents.defaults.model.primary = config.agents.defaults.model.primary || 'deepseek/deepseek-v4-pro';
    }

    fs.writeFileSync(configFile, JSON.stringify(config, null, 2));
NODESCRIPT
    ok "配置文件已写入: ${config_file}"
  else
    warn "配置文件生成失败，请使用环境变量方式配置"
  fi
}

# -------------------- 运行 Onboarding --------------------
run_onboarding() {
  echo ""
  echo -e "${CYAN}${BOLD}════════════════════════════════════════════${NC}"
  echo -e "${CYAN}${BOLD}  初始化配置${NC}"
  echo -e "${CYAN}${BOLD}════════════════════════════════════════════${NC}"
  echo ""
  info "运行 OpenClaw onboarding (安装守护进程 + 交互式配置)..."
  echo ""
  echo -e "${YELLOW}  ⚠ 接下来将进入 OpenClaw 交互式配置向导${NC}"
  echo "  你可以选择:"
  echo "    - 安装守护进程 (daemon)"
  echo "    - 配置消息渠道 (WhatsApp/Telegram/Slack 等)"
  echo "    - 选择默认模型"
  echo ""
  read -rp "是否现在运行? [Y/n]: " run_ob
  if [[ "${run_ob,,}" != "n" ]]; then
    openclaw onboard --install-daemon
  else
    info "跳过 onboarding，之后可手动执行: openclaw onboard --install-daemon"
  fi
}

# -------------------- 安装后验证 --------------------
verify_installation() {
  echo ""
  echo -e "${CYAN}${BOLD}════════════════════════════════════════════${NC}"
  echo -e "${CYAN}${BOLD}  安装验证${NC}"
  echo -e "${CYAN}${BOLD}════════════════════════════════════════════${NC}"
  echo ""

  if check_command node; then
    ok "Node.js: $(node -v)"
  else
    error "Node.js: 未安装"
  fi

  if check_command npm; then
    ok "npm: $(npm -v)"
  else
    error "npm: 未安装"
  fi

  if check_command openclaw; then
    ok "OpenClaw: 已安装"
  else
    warn "OpenClaw: 未找到命令"
    local npm_bin
    npm_bin="$(npm config get prefix 2>/dev/null || echo "$HOME/.npm-global")/bin"
    info "请将以下路径添加到 PATH: ${npm_bin}"
  fi

  echo ""
  echo "已配置的模型提供商:"
  [[ -n "${DEEPSEEK_KEY:-}" ]]   && ok "DeepSeek: 已配置"
  [[ -n "${OPENAI_KEY:-}" ]]     && ok "OpenAI: 已配置"
  [[ -n "${ANTHROPIC_KEY:-}" ]]  && ok "Anthropic: 已配置"
  [[ -n "${OPENROUTER_KEY:-}" ]] && ok "OpenRouter: 已配置"
  [[ -n "${GEMINI_KEY:-}" ]]     && ok "Gemini: 已配置"
  [[ -n "${QWEN_KEY:-}" ]]       && ok "Qwen: 已配置"
  [[ -n "${GLM_KEY:-}" ]]        && ok "GLM: 已配置"
}

# -------------------- 使用说明 --------------------
print_usage() {
  echo ""
  echo -e "${CYAN}${BOLD}════════════════════════════════════════════${NC}"
  echo -e "${CYAN}${BOLD}  快速开始${NC}"
  echo -e "${CYAN}${BOLD}════════════════════════════════════════════${NC}"
  echo ""
  echo -e "  ${BOLD}启动网关:${NC}"
  echo "    openclaw gateway --port 18789 --verbose"
  echo ""
  echo -e "  ${BOLD}与 AI 对话:${NC}"
  echo "    openclaw agent --message \"你好\" --thinking high"
  echo ""
  echo -e "  ${BOLD}发送消息到渠道:${NC}"
  echo "    openclaw message send --to +1234567890 --message \"Hello\""
  echo ""
  echo -e "  ${BOLD}重新配置:${NC}"
  echo "    openclaw onboard"
  echo ""
  echo -e "  ${BOLD}查看帮助:${NC}"
  echo "    openclaw --help"
  echo ""
  echo -e "  ${BOLD}修改模型配置:${NC}"
  echo "    编辑 ~/.openclaw/openclaw.json"
  echo "    或重新运行本脚本: ./install-openclaw.sh"
  echo ""
}

# -------------------- 命令行参数 --------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --deepseek-key)
        DEEPSEEK_KEY="$2"; shift 2 ;;
      --openai-key)
        OPENAI_KEY="$2"; shift 2 ;;
      --anthropic-key)
        ANTHROPIC_KEY="$2"; shift 2 ;;
      --openrouter-key)
        OPENROUTER_KEY="$2"; shift 2 ;;
      --gemini-key)
        GEMINI_KEY="$2"; shift 2 ;;
      --qwen-key)
        QWEN_KEY="$2"; shift 2 ;;
      --glm-key)
        GLM_KEY="$2"; shift 2 ;;
      --config-only)
        CONFIG_ONLY=true; shift ;;
      --skip-onboarding)
        SKIP_ONBOARDING=true; shift ;;
      --help|-h)
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  --deepseek-key KEY     DeepSeek API Key"
        echo "  --openai-key KEY       OpenAI API Key"
        echo "  --anthropic-key KEY    Anthropic API Key"
        echo "  --openrouter-key KEY   OpenRouter API Key"
        echo "  --gemini-key KEY       Google Gemini API Key"
        echo "  --qwen-key KEY         阿里百炼 / Qwen API Key"
        echo "  --glm-key KEY          智谱 GLM API Key"
        echo "  --config-only          仅配置模型，跳过安装"
        echo "  --skip-onboarding      跳过交互式 onboarding"
        echo "  -h, --help             显示帮助"
        echo ""
        echo "示例:"
        echo "  # 交互式安装"
        echo "  ./install-openclaw.sh"
        echo ""
        echo "  # 命令行参数安装 DeepSeek"
        echo "  ./install-openclaw.sh --deepseek-key sk-xxx --skip-onboarding"
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
  parse_args "$@"
  detect_os
  check_macos_dependencies

  if [[ "$CONFIG_ONLY" == "true" ]]; then
    configure_models
    verify_installation
    exit 0
  fi

  check_network
  check_nodejs
  install_nodejs

  if ! check_command node; then
    error "Node.js 未安装成功，请手动安装后重试"
    exit 1
  fi

  if ! check_command npm && ! check_command pnpm && ! check_command bun; then
    error "未找到任何 JavaScript 包管理器 (npm/pnpm/bun)"
    exit 1
  fi

  # 检查是否已安装 OpenClaw
  if check_command openclaw; then
    info "OpenClaw 已安装"
    read -rp "是否重新安装/更新? [y/N]: " reinstall
    if [[ "${reinstall,,}" == "y" ]]; then
      info "更新 OpenClaw..."
      install_openclaw
    fi
  else
    install_openclaw
  fi

  # 配置第三方模型
  if [[ -n "$DEEPSEEK_KEY" ]] || [[ -n "$OPENAI_KEY" ]] || [[ -n "$ANTHROPIC_KEY" ]]; then
    info "使用命令行参数配置模型..."
    write_env_config
  else
    echo ""
    read -rp "是否配置第三方大模型? [Y/n]: " do_config
    if [[ "${do_config,,}" != "n" ]]; then
      configure_models
    fi
  fi

  # 运行 onboarding
  if [[ "${SKIP_ONBOARDING:-false}" != "true" ]]; then
    run_onboarding
  fi

  verify_installation
  print_usage

  echo -e "${GREEN}${BOLD}✅ OpenClaw 安装完成!${NC}"
  echo ""
  echo -e "  ${BOLD}重新加载 shell 环境:${NC}"
  echo "    source ~/.zshrc   # zsh 用户"
  echo "    source ~/.bashrc  # bash 用户"
  echo ""
  echo -e "  ${BOLD}启动 OpenClaw 网关:${NC}"
  echo "    openclaw gateway --port 18789 --verbose"
  echo ""
}

main "$@"
