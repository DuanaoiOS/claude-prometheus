# 🔥 Prometheus 

> 将 AI 之火带到你的终端。
> *Bringing the fire of AI to your terminal.*

[English](README_EN.md) | 中文

A cross-platform toolkit for installing AI agent CLIs — Claude Code and OpenClaw — with automatic environment detection and third-party LLM configuration (DeepSeek-v4, OpenAI, Anthropic, OpenRouter, Qwen, GLM, and more).

## 工具列表

| 工具 | 目录 | 说明 |
|------|------|------|
| **Claude Code** | [`claude-code-installer/`](claude-code-installer/) | Anthropic 官方 AI 编程助手 CLI |
| **OpenClaw** 🦞 | [`openclaw-installer/`](openclaw-installer/) | 个人 AI 助手，支持多渠道消息 |


## 快速开始

### macOS / Linux

```bash
# Claude Code
curl -fsSL https://raw.githubusercontent.com/DuanaoiOS/claude-prometheus/main/claude-code-installer/install-claude-code.sh | bash

# OpenClaw 🦞
curl -fsSL https://raw.githubusercontent.com/DuanaoiOS/claude-prometheus/main/openclaw-installer/install-openclaw.sh | bash
```

### Windows

**PowerShell（推荐）:**

```powershell
# Claude Code
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DuanaoiOS/claude-prometheus/main/claude-code-installer/install-claude-code.ps1" -OutFile "install-claude-code.ps1"; .\install-claude-code.ps1

# OpenClaw 🦞
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DuanaoiOS/claude-prometheus/main/openclaw-installer/install-openclaw.ps1" -OutFile "install-openclaw.ps1"; .\install-openclaw.ps1
```

## 命令行参数

### Claude Code

支持非交互式安装，适合 CI/CD 或自动化场景:

```bash
# Bash
./install-claude-code.sh \
  --api-key "sk-your-api-key" \
  --base-url "https://api.deepseek.com/anthropic" \
  --model "deepseek-v4-pro"

# PowerShell
.\install-claude-code.ps1 `
  -ApiKey "sk-your-api-key" `
  -BaseUrl "https://api.deepseek.com/anthropic" `
  -Model "deepseek-v4-pro"
```

| 参数 | 说明 |
|------|------|
| `--api-key` / `-ApiKey` | 第三方 API Key |
| `--base-url` / `-BaseUrl` | API Base URL |
| `--model` / `-Model` | 模型名称 |
| `--config-only` / `-ConfigOnly` | 仅配置模型，跳过安装 |

### OpenClaw 🦞

```bash
# Bash
./install-openclaw.sh \
  --deepseek-key "sk-xxx" \
  --openai-key "sk-xxx" \
  --skip-onboarding

# PowerShell
.\install-openclaw.ps1 `
  -DeepSeekKey "sk-xxx" `
  -OpenAIKey "sk-xxx" `
  -SkipOnboarding
```

| 参数 | 说明 |
|------|------|
| `--deepseek-key` / `-DeepSeekKey` | DeepSeek API Key |
| `--openai-key` / `-OpenAIKey` | OpenAI API Key |
| `--anthropic-key` / `-AnthropicKey` | Anthropic API Key |
| `--openrouter-key` / `-OpenRouterKey` | OpenRouter API Key |
| `--gemini-key` / `-GeminiKey` | Google Gemini API Key |
| `--qwen-key` / `-QwenKey` | 阿里百炼 / Qwen API Key |
| `--glm-key` / `-GlmKey` | 智谱 GLM API Key |
| `--config-only` / `-ConfigOnly` | 仅配置模型，跳过安装 |
| `--skip-onboarding` / `-SkipOnboarding` | 跳过交互式 onboarding |

## 支持的第三方模型

| 提供商 | Base URL | 可用模型 |
|--------|----------|----------|
| **DeepSeek** | `https://api.deepseek.com/anthropic` | `deepseek-v4-pro`, `deepseek-v4-flash`（1M 上下文） |
| **OpenRouter** | `https://openrouter.ai/api/v1` | `anthropic/claude-sonnet-4`, `anthropic/claude-opus-4`, `deepseek/deepseek-v4-pro` |
| **阿里百炼** | `https://dashscope.aliyuncs.com/apps/anthropic` | `qwen-plus`, `qwen-max` |
| **智谱 AI** | `https://open.bigmodel.cn/api/anthropic` | `glm-4.5`, `glm-4.6` |
| **自定义** | 任意 Anthropic 兼容 API | 自定义 |

### OpenClaw 模型配置

OpenClaw 原生支持多家模型提供商，各使用独立的环境变量，无需配置 Base URL：

| 提供商 | 环境变量 | 模型示例 |
|--------|---------|----------|
| **DeepSeek** | `DEEPSEEK_API_KEY` | `deepseek-v4-pro`, `deepseek-v4-flash` |
| **OpenAI** | `OPENAI_API_KEY` | `gpt-5`, `gpt-4o` |
| **Anthropic** | `ANTHROPIC_API_KEY` | `claude-sonnet-4-6`, `claude-opus-4-7` |
| **OpenRouter** | `OPENROUTER_API_KEY` | `deepseek/deepseek-v4-pro` |
| **Gemini** | `GEMINI_API_KEY` | `gemini-2.5-pro` |
| **Qwen** | `DASHSCOPE_API_KEY` | `qwen-max`, `qwen-plus` |
| **GLM** | `ZAI_API_KEY` | `glm-4-plus` |

## OpenClaw 常用命令

```bash
# 启动网关
openclaw gateway --port 18789 --verbose

# 与 AI 对话
openclaw agent --message "你好" --thinking high

# 发送消息到渠道
openclaw message send --to +1234567890 --message "Hello"

# 交互式配置
openclaw onboard

# 重新配置模型
openclaw onboard --auth-choice deepseek-api-key
```

## 环境要求

| 依赖 | Claude Code | OpenClaw | 自动安装 |
|------|-------------|----------|----------|
| **Node.js** | >= 18 | >= 22 (推荐 24) | ✅ 脚本自动安装 |
| **npm / pnpm / bun** | ✅ | ✅ | ✅ |
| **git** | ✅ | 可选 | ⚠️ 需手动安装 |
| **Xcode CLT** (macOS) | 编译模块 | 编译模块 | ⚠️ 脚本引导安装 |
| **C++ 编译工具** (Windows) | 编译模块 | 编译模块 | ⚠️ 可选安装 |
| 网络连接 | 下载依赖 | 下载依赖 | - |

### macOS 依赖说明

脚本会自动检测以下组件并提供安装指引：
- **git**: Claude Code 需要通过 git 理解代码仓库的变更、分支等信息。macOS 可通过 `xcode-select --install` 安装
- **Xcode Command Line Tools**: 提供 `make`/`gcc`/`clang` 等编译工具，某些 npm 包需要编译原生模块。脚本会自动触发安装弹窗
- **Homebrew**: 推荐但非必须，脚本也可通过 nvm 安装 Node.js
- **磁盘空间**: 至少 2GB 剩余空间

### Windows 依赖说明

脚本会自动检测以下组件并提供安装指引：
- **git**: 从 https://git-scm.com/download/win 下载安装
- **C++ 编译工具**: 可选安装 `windows-build-tools` 或 Visual Studio Build Tools

## 脚本工作流程

1. 检测操作系统（macOS / Linux / Windows）
2. 全面检测开发环境依赖（git、编译工具、磁盘空间等）
3. 检查网络连接
4. 检查 Node.js 版本，不满足则自动安装
5. 通过 npm 全局安装 AI agent CLI (Claude Code / OpenClaw)
6. 交互式配置第三方模型（或通过命令行参数）
7. (OpenClaw) 可选运行 onboarding 守护进程配置
8. 验证安装结果

## 配置文件位置

| 系统 | 环境变量文件 | Claude Code 配置 | OpenClaw 配置 |
|------|-------------|-----------------|---------------|
| macOS / Linux | `~/.zshrc` 或 `~/.bashrc` | `~/.claude.json` | `~/.openclaw/openclaw.json` |
| Windows | 用户环境变量 | `%USERPROFILE%\.claude.json` | `%USERPROFILE%\.openclaw\openclaw.json` |

## 验证安装

```bash
# Claude Code
claude --version
claude

# 在 Claude Code 内切换模型
/model
```

```bash
# OpenClaw
openclaw gateway --port 18789 --verbose
```

## 手动配置环境变量

如果脚本配置未生效，可手动添加:

**macOS / Linux** (`~/.zshrc` 或 `~/.bashrc`):

```bash
export ANTHROPIC_API_KEY="your-api-key"
export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
export ANTHROPIC_MODEL="deepseek-v4-pro"
```

**Windows** (系统属性 → 环境变量):

```
ANTHROPIC_API_KEY = your-api-key
ANTHROPIC_BASE_URL = https://api.deepseek.com/anthropic
ANTHROPIC_MODEL = deepseek-v4-pro
```

## 常见问题

**Q: 安装后 `claude` 命令找不到？**

A: npm 全局 bin 路径不在 PATH 中。添加到 PATH:

```bash
# macOS / Linux
export PATH="$(npm config get prefix)/bin:$PATH"

# 或添加到 ~/.zshrc / ~/.bashrc
echo 'export PATH="$(npm config get prefix)/bin:$PATH"' >> ~/.zshrc
```

**Q: 第三方模型不工作？**

A: 确保 API 端点兼容 Anthropic Messages API 格式。对于不兼容的 API（如原生 DeepSeek API），需要使用代理服务（如 LiteLLM）或选择支持 Anthropic 格式的端点。

**Q: Windows 上 PowerShell 脚本无法执行？**

A: 设置执行策略:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Q: `openclaw` 命令找不到？**

A: 同 Claude Code 问题，添加 npm 全局 bin 到 PATH。或者使用 pnpm / bun 安装，它们在部分系统上 PATH 处理更可靠。

**Q: OpenClaw 安装时 `sharp` 报错？**

A: 安装脚本已自动设置 `SHARP_IGNORE_GLOBAL_LIBVIPS=1` 来绕过全局 libvips 冲突。如果仍有问题，尝试用 bun 或 pnpm 安装。

## License

MIT
