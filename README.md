# 🔥 Prometheus 普罗米修斯

> 将 AI 之火带到你的终端。
> *Bringing the fire of AI to your terminal.*

A cross-platform Claude Code installer that detects your environment, installs dependencies, and configures third-party LLMs (DeepSeek-v4, OpenRouter, Qwen, GLM, and more).

## 灵感

普罗米修斯（Prometheus）从奥林匹斯盗取火种赐予人类，开启了人类文明。这个工具如其名——将云端 AI 的强大能力带回本地，让每一个开发者都能自由使用 Claude Code，无论用的是哪家大模型。

## 快速开始

### macOS / Linux

```bash
# 1. 下载脚本
curl -O https://raw.githubusercontent.com/<your-repo>/main/install-claude-code.sh

# 2. 赋予执行权限
chmod +x install-claude-code.sh

# 3. 运行
./install-claude-code.sh
```

### Windows

**PowerShell（推荐）:**

```powershell
# 以管理员身份运行 PowerShell，执行:
.\install-claude-code.ps1
```

**Git Bash:**

```bash
chmod +x install-claude-code.sh
./install-claude-code.sh
```

## 命令行参数

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

## 支持的第三方模型

| 提供商 | Base URL | 可用模型 |
|--------|----------|----------|
| **DeepSeek** | `https://api.deepseek.com/anthropic` | `deepseek-v4-pro`, `deepseek-v4-flash`（1M 上下文） |
| **OpenRouter** | `https://openrouter.ai/api/v1` | `anthropic/claude-sonnet-4`, `anthropic/claude-opus-4`, `deepseek/deepseek-v4-pro` |
| **阿里百炼** | `https://dashscope.aliyuncs.com/compatible-mode/v1` | `qwen-plus`, `qwen-max` |
| **智谱 AI** | `https://open.bigmodel.cn/api/paas/v4` | `glm-4-plus`, `glm-4-flash` |
| **自定义** | 任意 Anthropic 兼容 API | 自定义 |

## 环境要求

| 依赖 | 用途 | 自动安装 |
|------|------|----------|
| **Node.js >= 18** | Claude Code 运行时 | ✅ 脚本自动安装 |
| **npm** | 包管理器（随 Node.js） | ✅ 随 Node.js 安装 |
| **git** | 代码仓库上下文分析 | ⚠️ 需手动安装 |
| **Xcode CLT** (macOS) | 编译原生 npm 模块 | ⚠️ 脚本引导安装 |
| **C++ 编译工具** (Windows) | 编译原生 npm 模块 | ⚠️ 可选安装 |
| 网络连接 | 下载依赖 | - |

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
5. 通过 npm 全局安装 Claude Code
6. 交互式配置第三方模型（或通过命令行参数）
7. 验证安装结果

## 配置文件位置

| 系统 | 环境变量文件 | Claude Code 配置 |
|------|-------------|-----------------|
| macOS / Linux | `~/.zshrc` 或 `~/.bashrc` | `~/.claude.json` |
| Windows | 用户环境变量 | `%USERPROFILE%\.claude.json` |

## 验证安装

```bash
# 检查版本
claude --version

# 启动
claude

# 在 Claude Code 内切换模型
/model
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

## License

MIT
