# 🔥 Prometheus

> *Bringing the fire of AI to your terminal.*

[中文](README.md) | English

A cross-platform toolkit for installing AI agent CLIs — Claude Code and OpenClaw — with automatic environment detection and third-party LLM configuration (DeepSeek-v4, OpenAI, Anthropic, OpenRouter, Qwen, GLM, and more).

## Tools

| Tool | Directory | Description |
|------|-----------|-------------|
| **Claude Code** | [`claude-code-installer/`](claude-code-installer/) | Anthropic's official AI coding assistant CLI |
| **OpenClaw** 🦞 | [`openclaw-installer/`](openclaw-installer/) | Personal AI agent with multi-channel messaging support |


## Quick Start

### macOS / Linux

```bash
# Claude Code
curl -fsSL https://raw.githubusercontent.com/DuanaoiOS/claude-prometheus/main/claude-code-installer/install-claude-code.sh | bash

# OpenClaw 🦞
curl -fsSL https://raw.githubusercontent.com/DuanaoiOS/claude-prometheus/main/openclaw-installer/install-openclaw.sh | bash
```

### Windows

**PowerShell (recommended):**

```powershell
# Claude Code
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DuanaoiOS/claude-prometheus/main/claude-code-installer/install-claude-code.ps1" -OutFile "install-claude-code.ps1"; .\install-claude-code.ps1

# OpenClaw 🦞
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DuanaoiOS/claude-prometheus/main/openclaw-installer/install-openclaw.ps1" -OutFile "install-openclaw.ps1"; .\install-openclaw.ps1
```

## CLI Arguments

### Claude Code

Supports non-interactive installation for CI/CD or automation:

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

| Argument | Description |
|----------|-------------|
| `--api-key` / `-ApiKey` | Third-party API key |
| `--base-url` / `-BaseUrl` | API Base URL |
| `--model` / `-Model` | Model name |
| `--config-only` / `-ConfigOnly` | Configure model only, skip installation |

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

| Argument | Description |
|----------|-------------|
| `--deepseek-key` / `-DeepSeekKey` | DeepSeek API key |
| `--openai-key` / `-OpenAIKey` | OpenAI API key |
| `--anthropic-key` / `-AnthropicKey` | Anthropic API key |
| `--openrouter-key` / `-OpenRouterKey` | OpenRouter API key |
| `--gemini-key` / `-GeminiKey` | Google Gemini API key |
| `--qwen-key` / `-QwenKey` | Alibaba Qwen / DashScope API key |
| `--glm-key` / `-GlmKey` | Zhipu GLM API key |
| `--config-only` / `-ConfigOnly` | Configure model only, skip installation |
| `--skip-onboarding` / `-SkipOnboarding` | Skip interactive onboarding |

## Supported Third-Party Models

### Claude Code

| Provider | Base URL | Models |
|----------|----------|--------|
| **DeepSeek** | `https://api.deepseek.com/anthropic` | `deepseek-v4-pro`, `deepseek-v4-flash` (1M context) |
| **OpenRouter** | `https://openrouter.ai/api/v1` | `anthropic/claude-sonnet-4`, `anthropic/claude-opus-4`, `deepseek/deepseek-v4-pro` |
| **Alibaba Bailian** | `https://dashscope.aliyuncs.com/apps/anthropic` | `qwen-plus`, `qwen-max` |
| **Zhipu AI** | `https://open.bigmodel.cn/api/anthropic` | `glm-4.5`, `glm-4.6` |
| **Custom** | Any Anthropic-compatible API | Custom |

### OpenClaw

OpenClaw natively supports multiple providers via provider-specific environment variables — no Base URL needed:

| Provider | Environment Variable | Example Models |
|----------|---------------------|----------------|
| **DeepSeek** | `DEEPSEEK_API_KEY` | `deepseek-v4-pro`, `deepseek-v4-flash` |
| **OpenAI** | `OPENAI_API_KEY` | `gpt-5`, `gpt-4o` |
| **Anthropic** | `ANTHROPIC_API_KEY` | `claude-sonnet-4-6`, `claude-opus-4-7` |
| **OpenRouter** | `OPENROUTER_API_KEY` | `deepseek/deepseek-v4-pro` |
| **Gemini** | `GEMINI_API_KEY` | `gemini-2.5-pro` |
| **Qwen** | `DASHSCOPE_API_KEY` | `qwen-max`, `qwen-plus` |
| **GLM** | `ZAI_API_KEY` | `glm-4-plus` |

## OpenClaw Quick Reference

```bash
# Start the gateway
openclaw gateway --port 18789 --verbose

# Chat with the AI
openclaw agent --message "Hello" --thinking high

# Send a message to a channel
openclaw message send --to +1234567890 --message "Hello"

# Interactive setup
openclaw onboard

# Reconfigure a specific provider
openclaw onboard --auth-choice deepseek-api-key
```

## Environment Requirements

| Dependency | Claude Code | OpenClaw | Auto-Installed |
|------------|-------------|----------|----------------|
| **Node.js** | >= 18 | >= 22 (24 recommended) | ✅ Script auto-installs |
| **npm / pnpm / bun** | ✅ | ✅ | ✅ |
| **git** | Required | Optional | ⚠️ Manual install |
| **Xcode CLT** (macOS) | Native modules | Native modules | ⚠️ Script-guided |
| **C++ build tools** (Windows) | Native modules | Native modules | ⚠️ Optional |
| Network | Downloads | Downloads | - |

### macOS Dependencies

The script checks and provides guidance for:
- **git**: Claude Code uses git for repository context and diffs. Install via `xcode-select --install` on macOS
- **Xcode Command Line Tools**: Provides `make`/`gcc`/`clang` for compiling native npm modules. The script auto-triggers the install dialog
- **Homebrew**: Recommended but optional — the script can also install Node.js via nvm
- **Disk space**: At least 2GB free recommended

### Windows Dependencies

The script checks and provides guidance for:
- **git**: Download from https://git-scm.com/download/win
- **C++ build tools**: Optionally install `windows-build-tools` or Visual Studio Build Tools

## Workflow

1. Detect operating system (macOS / Linux / Windows)
2. Check development environment (git, build tools, disk space, etc.)
3. Test network connectivity
4. Check Node.js version, auto-install if needed
5. Install the AI agent CLI via npm
6. Configure third-party LLM providers (interactive or via CLI arguments)
7. Verify installation

## Config File Locations

| System | Shell Config | Claude Code Config | OpenClaw Config |
|--------|-------------|-------------------|-----------------|
| macOS / Linux | `~/.zshrc` or `~/.bashrc` | `~/.claude.json` | `~/.openclaw/openclaw.json` |
| Windows | User environment variables | `%USERPROFILE%\.claude.json` | `%USERPROFILE%\.openclaw\openclaw.json` |

## Verifying Installation

```bash
# Check version
claude --version

# Launch
claude

# Switch models (inside Claude Code)
/model
```

```bash
# OpenClaw
openclaw gateway --port 18789 --verbose
```

## Manual Environment Variable Setup

If the script's configuration doesn't take effect, add manually:

**macOS / Linux** (`~/.zshrc` or `~/.bashrc`):

```bash
# Claude Code
export ANTHROPIC_API_KEY="your-api-key"
export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
export ANTHROPIC_MODEL="deepseek-v4-pro"

# OpenClaw
export DEEPSEEK_API_KEY="your-api-key"
```

**Windows** (System Properties → Environment Variables):

```
ANTHROPIC_API_KEY = your-api-key
ANTHROPIC_BASE_URL = https://api.deepseek.com/anthropic
ANTHROPIC_MODEL = deepseek-v4-pro
```

## FAQ

**Q: `claude` command not found after installation?**

A: The npm global bin directory is not in your PATH. Add it:

```bash
# macOS / Linux
export PATH="$(npm config get prefix)/bin:$PATH"

# Or add permanently
echo 'export PATH="$(npm config get prefix)/bin:$PATH"' >> ~/.zshrc
```

**Q: Third-party models don't work?**

A: Ensure the API endpoint is compatible with the Anthropic Messages API format. For native APIs that aren't compatible (e.g., original DeepSeek API), use a proxy service like LiteLLM, or use an Anthropic-compatible endpoint like `https://api.deepseek.com/anthropic`.

**Q: PowerShell script blocked on Windows?**

A: Set the execution policy:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Q: `openclaw` command not found after installation?**

A: Same as above — add the npm global bin directory to your PATH. Alternatively, reinstall using pnpm (`pnpm add -g openclaw@latest`) which handles PATH more reliably on some systems.

**Q: `sharp` errors during OpenClaw installation?**

A: The installer automatically sets `SHARP_IGNORE_GLOBAL_LIBVIPS=1` to work around globally-installed libvips conflicts. If you still see errors, try installing with bun or pnpm instead.

## License

MIT
