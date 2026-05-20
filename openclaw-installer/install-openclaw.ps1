<#
.SYNOPSIS
    Prometheus — Bringing the fire of AI to your terminal.
    OpenClaw 一键安装脚本 (Windows PowerShell)
.DESCRIPTION
    将 AI 之火带到你的终端。一键安装 OpenClaw，
    检测系统环境，安装 Node.js 24 (如需要)，
    支持配置第三方大模型 (DeepSeek-v4, OpenAI, Anthropic, OpenRouter 等)。
.PARAMETER DeepSeekKey
    DeepSeek API Key
.PARAMETER OpenAIKey
    OpenAI API Key
.PARAMETER AnthropicKey
    Anthropic API Key
.PARAMETER OpenRouterKey
    OpenRouter API Key
.PARAMETER GeminiKey
    Google Gemini API Key
.PARAMETER QwenKey
    阿里百炼 / Qwen API Key
.PARAMETER GlmKey
    智谱 GLM API Key
.PARAMETER ConfigOnly
    仅配置模型，不安装 OpenClaw
.PARAMETER SkipOnboarding
    跳过交互式 onboarding
.EXAMPLE
    .\install-openclaw.ps1
.EXAMPLE
    .\install-openclaw.ps1 -DeepSeekKey "sk-xxx" -SkipOnboarding
#>

param(
    [string]$DeepSeekKey = "",
    [string]$OpenAIKey = "",
    [string]$AnthropicKey = "",
    [string]$OpenRouterKey = "",
    [string]$GeminiKey = "",
    [string]$QwenKey = "",
    [string]$GlmKey = "",
    [switch]$ConfigOnly = $false,
    [switch]$SkipOnboarding = $false
)

$ErrorActionPreference = "Stop"

# -------------------- 颜色函数 --------------------
function Write-Info  { Write-Host "[INFO]  $args" -ForegroundColor Blue }
function Write-Ok    { Write-Host "[OK]    $args" -ForegroundColor Green }
function Write-Warn  { Write-Host "[WARN]  $args" -ForegroundColor Yellow }
function Write-Error2 { Write-Host "[ERROR] $args" -ForegroundColor Red }

# -------------------- Banner --------------------
function Show-Banner {
    Write-Host @"

    🔥  Prometheus 普罗米修斯
    将 AI 之火带到你的终端
    环境检测 · 一键安装 · 模型配置

    🦞  OpenClaw 安装器

"@ -ForegroundColor Cyan
}

# -------------------- 管理员权限检查 --------------------
function Test-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Warn "建议以管理员身份运行此脚本"
        Write-Host ""
    }
}

# -------------------- Windows 依赖全面检测 --------------------
function Test-WindowsDependencies {
    Write-Host ""
    Write-Info "全面检测 Windows 开发环境依赖..."

    $missingDeps = @()

    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitVer = (git --version 2>$null) -replace 'git version ', ''
        Write-Ok "git: $gitVer"
    } else {
        Write-Warn "git: 未安装"
        $missingDeps += "git"
    }

    $hasBuildTools = $false
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $globalModules = npm ls -g --depth=0 2>$null
        if ($globalModules -match "windows-build-tools") {
            $hasBuildTools = $true
            Write-Ok "windows-build-tools: 已安装"
        }
    }
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vsWhere) {
        $vsInfo = & $vsWhere -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -format json 2>$null | ConvertFrom-Json
        if ($vsInfo) {
            $hasBuildTools = $true
            Write-Ok "Visual Studio Build Tools: 已安装"
        }
    }
    if (-not $hasBuildTools) {
        Write-Warn "C++ 编译工具: 未检测到"
        $missingDeps += "build-tools"
    }

    $drive = (Get-Location).Drive.Name
    $disk = Get-PSDrive -Name $drive
    $freeGB = [math]::Round($disk.Free / 1GB, 1)
    if ($freeGB -ge 2) {
        Write-Ok "磁盘剩余空间: ${freeGB}GB"
    } else {
        Write-Warn "磁盘剩余空间: ${freeGB}GB (建议至少 2GB)"
    }

    $osInfo = Get-CimInstance Win32_OperatingSystem
    Write-Ok "Windows: $($osInfo.Caption)"

    if ($missingDeps.Count -gt 0) {
        Write-Host ""
        Write-Warn "发现 $($missingDeps.Count) 个缺失组件:"
        foreach ($dep in $missingDeps) {
            switch ($dep) {
                "git" { Write-Host "   - git: https://git-scm.com/download/win" }
                "build-tools" {
                    Write-Host "   - C++ 编译工具: npm install -g windows-build-tools"
                    Write-Host "     或: https://visualstudio.microsoft.com/downloads/"
                }
            }
        }
        Write-Host ""
    } else {
        Write-Ok "Windows 环境依赖检查全部通过"
    }
}

# -------------------- 网络检查 --------------------
function Test-Network {
    Write-Info "检查网络连接..."
    try {
        $null = Invoke-WebRequest -Uri "https://registry.npmjs.org/" -TimeoutSec 5 -UseBasicParsing
        Write-Ok "网络连接正常"
    } catch {
        Write-Warn "无法访问 npm registry，请检查网络或代理"
    }
}

# -------------------- Node.js 检测与安装 --------------------
function Test-NodeJS {
    Write-Info "检查 Node.js..."
    try {
        $nodeVersion = (node -v) -replace 'v', ''
        $majorVersion = [int]($nodeVersion -split '\.')[0]
        if ($majorVersion -ge 22) {
            Write-Ok "Node.js v$nodeVersion 已满足要求 (>= v22)"
            return $true
        } else {
            Write-Warn "Node.js v$nodeVersion 版本过低，需要 >= v22"
            return $false
        }
    } catch {
        Write-Warn "未检测到 Node.js"
        return $false
    }
}

function Install-NodeJS {
    Write-Info "安装 Node.js 24 (LTS)..."

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Info "通过 winget 安装 Node.js 24 LTS..."
        winget install OpenJS.NodeJS.24 --accept-package-agreements --accept-source-agreements
        Write-Warn "安装完成后，请重新打开 PowerShell 并重新运行本脚本"
    }
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Info "通过 Chocolatey 安装 Node.js 24 LTS..."
        choco install nodejs-lts -y
    }
    else {
        $nodeUrl = "https://nodejs.org/dist/v24.0.0/node-v24.0.0-x64.msi"
        $installer = "$env:TEMP\nodejs-installer.msi"
        try {
            Invoke-WebRequest -Uri $nodeUrl -OutFile $installer -UseBasicParsing
            Start-Process msiexec.exe -Wait -ArgumentList "/i `"$installer`" /quiet /norestart"
            Remove-Item $installer -Force
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            Write-Ok "Node.js 安装完成"
        } catch {
            Write-Error2 "自动安装失败，请手动安装: https://nodejs.org/ (选择 LTS 版本)"
            exit 1
        }
    }
}

# -------------------- OpenClaw 安装 --------------------
function Install-OpenClaw {
    Write-Info "安装 OpenClaw..."

    $env:SHARP_IGNORE_GLOBAL_LIBVIPS = "1"

    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        Write-Info "使用 pnpm 安装..."
        pnpm add -g openclaw@latest
        pnpm approve-builds -g
    }
    elseif (Get-Command bun -ErrorAction SilentlyContinue) {
        Write-Info "使用 bun 安装..."
        bun add -g openclaw@latest
    }
    else {
        Write-Info "使用 npm 安装..."
        npm install -g openclaw@latest
    }

    try {
        $null = openclaw --version 2>$null
        Write-Ok "OpenClaw 安装成功"
    } catch {
        Write-Error2 "OpenClaw 安装失败，请检查 npm 全局路径是否在 PATH 中"
        $npmBin = "$(npm config get prefix)\bin"
        Write-Info "npm 全局 bin 路径: $npmBin"
    }
}

# -------------------- 第三方模型配置 --------------------
function Set-ModelConfig {
    Write-Host ""
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  第三方大模型配置" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "OpenClaw 原生支持多种模型提供商，通过环境变量配置。"
    Write-Host ""

    Write-Host "请选择配置方式:"
    Write-Host "  1) 使用环境变量 (推荐)"
    Write-Host "  2) 使用 OpenClaw 配置文件"
    Write-Host ""
    $configMethod = Read-Host "请输入选项 [1/2] (默认 1)"
    if ([string]::IsNullOrWhiteSpace($configMethod)) { $configMethod = "1" }

    Write-Host ""
    Write-Host "支持以下模型提供商 (可多选，用逗号分隔，如: 1,3,4):"
    Write-Host "  1) DeepSeek (deepseek-v4-pro / deepseek-v4-flash，1M 上下文)"
    Write-Host "  2) OpenAI (GPT-4o / GPT-5 等)"
    Write-Host "  3) Anthropic (Claude Sonnet 4 / Opus 4)"
    Write-Host "  4) OpenRouter (聚合多家模型)"
    Write-Host "  5) Google Gemini"
    Write-Host "  6) 阿里百炼 / Qwen"
    Write-Host "  7) 智谱 GLM"
    Write-Host "  8) 全部配置"
    Write-Host ""

    $providerInput = Read-Host "请输入选项 (默认 1)"
    if ([string]::IsNullOrWhiteSpace($providerInput)) { $providerInput = "1" }
    $providerChoices = $providerInput -split ',' | ForEach-Object { $_.Trim() }

    foreach ($choice in $providerChoices) {
        switch ($choice) {
            "1" {
                Write-Host ""
                Write-Host "--- DeepSeek 配置 ---" -ForegroundColor Yellow
                Write-Host "可用模型: deepseek-v4-pro (旗舰), deepseek-v4-flash (轻量)，1M 上下文"
                $global:DeepSeekKey = Read-Host "DeepSeek API Key"
            }
            "2" {
                Write-Host ""
                Write-Host "--- OpenAI 配置 ---" -ForegroundColor Yellow
                $global:OpenAIKey = Read-Host "OpenAI API Key"
            }
            "3" {
                Write-Host ""
                Write-Host "--- Anthropic 配置 ---" -ForegroundColor Yellow
                $global:AnthropicKey = Read-Host "Anthropic API Key"
            }
            "4" {
                Write-Host ""
                Write-Host "--- OpenRouter 配置 ---" -ForegroundColor Yellow
                $global:OpenRouterKey = Read-Host "OpenRouter API Key"
            }
            "5" {
                Write-Host ""
                Write-Host "--- Google Gemini 配置 ---" -ForegroundColor Yellow
                $global:GeminiKey = Read-Host "Gemini API Key"
            }
            "6" {
                Write-Host ""
                Write-Host "--- 阿里百炼 / Qwen 配置 ---" -ForegroundColor Yellow
                $global:QwenKey = Read-Host "Qwen / DashScope API Key"
            }
            "7" {
                Write-Host ""
                Write-Host "--- 智谱 GLM 配置 ---" -ForegroundColor Yellow
                $global:GlmKey = Read-Host "智谱 Z.AI API Key"
            }
            "8" {
                $global:DeepSeekKey = Read-Host "DeepSeek API Key"
                $global:OpenAIKey = Read-Host "OpenAI API Key"
                $global:AnthropicKey = Read-Host "Anthropic API Key"
                $global:OpenRouterKey = Read-Host "OpenRouter API Key"
                $global:GeminiKey = Read-Host "Gemini API Key"
                $global:QwenKey = Read-Host "Qwen API Key"
                $global:GlmKey = Read-Host "GLM API Key"
            }
            default { Write-Warn "无效选项: $choice，跳过" }
        }
    }

    if ($configMethod -eq "1") {
        Set-EnvConfig
    } else {
        Set-FileConfig
    }
}

function Set-EnvConfig {
    Write-Info "配置环境变量..."

    if ($DeepSeekKey) {
        [Environment]::SetEnvironmentVariable("DEEPSEEK_API_KEY", $DeepSeekKey, "User")
        $env:DEEPSEEK_API_KEY = $DeepSeekKey
    }
    if ($OpenAIKey) {
        [Environment]::SetEnvironmentVariable("OPENAI_API_KEY", $OpenAIKey, "User")
        $env:OPENAI_API_KEY = $OpenAIKey
    }
    if ($AnthropicKey) {
        [Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $AnthropicKey, "User")
        $env:ANTHROPIC_API_KEY = $AnthropicKey
    }
    if ($OpenRouterKey) {
        [Environment]::SetEnvironmentVariable("OPENROUTER_API_KEY", $OpenRouterKey, "User")
        $env:OPENROUTER_API_KEY = $OpenRouterKey
    }
    if ($GeminiKey) {
        [Environment]::SetEnvironmentVariable("GEMINI_API_KEY", $GeminiKey, "User")
        $env:GEMINI_API_KEY = $GeminiKey
    }
    if ($QwenKey) {
        [Environment]::SetEnvironmentVariable("DASHSCOPE_API_KEY", $QwenKey, "User")
        $env:DASHSCOPE_API_KEY = $QwenKey
    }
    if ($GlmKey) {
        [Environment]::SetEnvironmentVariable("ZAI_API_KEY", $GlmKey, "User")
        $env:ZAI_API_KEY = $GlmKey
    }

    Write-Ok "环境变量配置完成 (用户级别，新 PowerShell 窗口生效)"
}

function Set-FileConfig {
    $configDir = "$env:USERPROFILE\.openclaw"
    $configFile = "$configDir\openclaw.json"

    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    Write-Info "配置 OpenClaw 配置文件..."

    $config = @{}
    if (Test-Path $configFile) {
        try {
            $config = Get-Content $configFile -Raw | ConvertFrom-Json
        } catch {
            Write-Warn "无法读取现有配置文件，将创建新文件"
        }
    }

    if (-not $config.models) { $config | Add-Member -MemberType NoteProperty -Name "models" -Value @{} -Force }
    if (-not $config.models.providers) { $config.models | Add-Member -MemberType NoteProperty -Name "providers" -Value @{} -Force }

    if ($DeepSeekKey) { $config.models.providers | Add-Member -MemberType NoteProperty -Name "deepseek" -Value @{ apiKey = $DeepSeekKey } -Force }
    if ($OpenAIKey) { $config.models.providers | Add-Member -MemberType NoteProperty -Name "openai" -Value @{ apiKey = $OpenAIKey } -Force }
    if ($AnthropicKey) { $config.models.providers | Add-Member -MemberType NoteProperty -Name "anthropic" -Value @{ apiKey = $AnthropicKey } -Force }
    if ($OpenRouterKey) { $config.models.providers | Add-Member -MemberType NoteProperty -Name "openrouter" -Value @{ apiKey = $OpenRouterKey } -Force }
    if ($GeminiKey) { $config.models.providers | Add-Member -MemberType NoteProperty -Name "gemini" -Value @{ apiKey = $GeminiKey } -Force }
    if ($QwenKey) { $config.models.providers | Add-Member -MemberType NoteProperty -Name "qwen" -Value @{ apiKey = $QwenKey } -Force }
    if ($GlmKey) { $config.models.providers | Add-Member -MemberType NoteProperty -Name "zai" -Value @{ apiKey = $GlmKey } -Force }

    $config | ConvertTo-Json -Depth 10 | Set-Content $configFile -Encoding UTF8
    Write-Ok "配置文件已写入: $configFile"
}

# -------------------- 运行 Onboarding --------------------
function Start-Onboarding {
    Write-Host ""
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  初始化配置" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    if ($SkipOnboarding) {
        Write-Info "跳过 onboarding (--skip-onboarding)"
        return
    }

    Write-Info "运行 OpenClaw onboarding (安装守护进程 + 交互式配置)..."
    Write-Host ""
    Write-Warn "  接下来将进入 OpenClaw 交互式配置向导"
    Write-Host "  你可以选择:"
    Write-Host "    - 安装守护进程 (daemon)"
    Write-Host "    - 配置消息渠道 (WhatsApp/Telegram/Slack 等)"
    Write-Host "    - 选择默认模型"
    Write-Host ""

    $runOb = Read-Host "是否现在运行? [Y/n]"
    if ($runOb -ne "n" -and $runOb -ne "N") {
        openclaw onboard --install-daemon
    } else {
        Write-Info "跳过 onboarding，之后可手动执行: openclaw onboard --install-daemon"
    }
}

# -------------------- 安装后验证 --------------------
function Test-Installation {
    Write-Host ""
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  安装验证" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    try { Write-Ok "Node.js: $(node -v)" } catch { Write-Error2 "Node.js: 未安装" }
    try { Write-Ok "npm: $(npm -v)" } catch { Write-Error2 "npm: 未安装" }
    try { Write-Ok "OpenClaw: 已安装" } catch { Write-Warn "OpenClaw: 未找到命令" }

    Write-Host ""
    Write-Host "已配置的模型提供商:"
    if ($env:DEEPSEEK_API_KEY) { Write-Ok "DeepSeek: 已配置" }
    if ($env:OPENAI_API_KEY) { Write-Ok "OpenAI: 已配置" }
    if ($env:ANTHROPIC_API_KEY) { Write-Ok "Anthropic: 已配置" }
    if ($env:OPENROUTER_API_KEY) { Write-Ok "OpenRouter: 已配置" }
    if ($env:GEMINI_API_KEY) { Write-Ok "Gemini: 已配置" }
    if ($env:DASHSCOPE_API_KEY) { Write-Ok "Qwen: 已配置" }
    if ($env:ZAI_API_KEY) { Write-Ok "GLM: 已配置" }
}

# -------------------- 使用说明 --------------------
function Show-Usage {
    Write-Host ""
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  快速开始" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  启动网关:"
    Write-Host "    openclaw gateway --port 18789 --verbose"
    Write-Host ""
    Write-Host "  与 AI 对话:"
    Write-Host "    openclaw agent --message '你好' --thinking high"
    Write-Host ""
    Write-Host "  发送消息:"
    Write-Host "    openclaw message send --to +1234567890 --message 'Hello'"
    Write-Host ""
    Write-Host "  重新配置:"
    Write-Host "    openclaw onboard"
    Write-Host ""
    Write-Host "  修改模型配置:"
    Write-Host "    编辑 `$env:USERPROFILE\.openclaw\openclaw.json"
    Write-Host ""
}

# -------------------- 主流程 --------------------
function Main {
    Show-Banner
    Test-Admin
    Test-WindowsDependencies

    if ($ConfigOnly) {
        Set-ModelConfig
        Test-Installation
        return
    }

    Test-Network

    $nodeOk = Test-NodeJS
    if (-not $nodeOk) {
        Install-NodeJS
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        try {
            $null = node -v
        } catch {
            Write-Error2 "Node.js 安装后仍不可用，请重新打开 PowerShell 后运行: .\install-openclaw.ps1"
            return
        }
    }

    if (-not (Get-Command npm -ErrorAction SilentlyContinue) -and
        -not (Get-Command pnpm -ErrorAction SilentlyContinue) -and
        -not (Get-Command bun -ErrorAction SilentlyContinue)) {
        Write-Error2 "未找到 JavaScript 包管理器"
        return
    }

    if (Get-Command openclaw -ErrorAction SilentlyContinue) {
        Write-Info "OpenClaw 已安装"
        $reinstall = Read-Host "是否重新安装/更新? [y/N]"
        if ($reinstall -eq "y" -or $reinstall -eq "Y") {
            Install-OpenClaw
        }
    } else {
        Install-OpenClaw
    }

    if ($DeepSeekKey -or $OpenAIKey -or $AnthropicKey) {
        Write-Info "使用命令行参数配置模型..."
        Set-EnvConfig
    } else {
        Write-Host ""
        $doConfig = Read-Host "是否配置第三方大模型? [Y/n]"
        if ($doConfig -ne "n" -and $doConfig -ne "N") {
            Set-ModelConfig
        }
    }

    Start-Onboarding
    Test-Installation
    Show-Usage

    Write-Host "✅ OpenClaw 安装完成!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  启动 OpenClaw 网关:" -ForegroundColor White
    Write-Host "    openclaw gateway --port 18789 --verbose"
    Write-Host ""
}

Main
