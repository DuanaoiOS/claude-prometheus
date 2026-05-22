<#
.SYNOPSIS
    Prometheus — Bringing the fire of AI to your terminal.
.DESCRIPTION
    将 AI 之火带到你的终端。一键安装 Claude Code，
    检测系统环境，安装 Node.js (如需要)，
    支持配置第三方大模型 (DeepSeek, OpenRouter 等)。
.PARAMETER ApiKey
    第三方 API Key
.PARAMETER BaseUrl
    API Base URL
.PARAMETER Model
    模型名称
.PARAMETER ConfigOnly
    仅配置模型，不安装 Claude Code
.EXAMPLE
    .\install-claude-code.ps1
.EXAMPLE
    .\install-claude-code.ps1 -ApiKey "sk-xxx" -BaseUrl "https://api.deepseek.com/anthropic" -Model "deepseek-v4-pro"
#>

param(
    [string]$ApiKey = "",
    [string]$BaseUrl = "",
    [string]$Model = "",
    [switch]$ConfigOnly = $false
)

# 设置错误处理
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

"@ -ForegroundColor Cyan
}

# -------------------- 管理员权限检查 --------------------
function Test-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Warn "建议以管理员身份运行此脚本 (Run as Administrator)"
        Write-Warn "npm 全局安装可能需要管理员权限"
        Write-Host ""
    }
}

# -------------------- Windows 依赖全面检测 --------------------
function Test-WindowsDependencies {
    Write-Host ""
    Write-Info "全面检测 Windows 开发环境依赖..."

    $missingDeps = @()

    # 1. Git (Claude Code 需要 git 管理代码仓库上下文)
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitVer = (git --version 2>$null) -replace 'git version ', ''
        Write-Ok "git: $gitVer"
    } else {
        Write-Warn "git: 未安装 (Claude Code 需要 git 管理代码上下文)"
        $missingDeps += "git"
    }

    # 2. 检查是否有 C++ 编译工具 (windows-build-tools 或 VS Build Tools)
    $hasBuildTools = $false
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $globalModules = npm ls -g --depth=0 2>$null
        if ($globalModules -match "windows-build-tools") {
            $hasBuildTools = $true
            Write-Ok "windows-build-tools: 已安装"
        }
    }
    # 检查 Visual Studio Build Tools
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vsWhere) {
        $vsInfo = & $vsWhere -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -format json 2>$null | ConvertFrom-Json
        if ($vsInfo) {
            $hasBuildTools = $true
            Write-Ok "Visual Studio Build Tools: 已安装"
        }
    }
    if (-not $hasBuildTools) {
        Write-Warn "C++ 编译工具: 未检测到 (编译原生 npm 模块可能需要)"
        $missingDeps += "build-tools"
    }

    # 3. 检查磁盘空间 (至少 2GB)
    $drive = (Get-Location).Drive.Name
    $disk = Get-PSDrive -Name $drive
    $freeGB = [math]::Round($disk.Free / 1GB, 1)
    if ($freeGB -ge 2) {
        Write-Ok "磁盘剩余空间: ${freeGB}GB"
    } else {
        Write-Warn "磁盘剩余空间: ${freeGB}GB (建议至少 2GB)"
    }

    # 4. 检查 Windows 版本
    $osInfo = Get-CimInstance Win32_OperatingSystem
    Write-Ok "Windows: $($osInfo.Caption) (版本 $($osInfo.Version))"

    # 处理缺失依赖
    if ($missingDeps.Count -gt 0) {
        Write-Host ""
        Write-Warn "发现 $($missingDeps.Count) 个缺失/建议安装的组件:"
        foreach ($dep in $missingDeps) {
            switch ($dep) {
                "git" {
                    Write-Host "   - git: 从 https://git-scm.com/download/win 下载安装"
                }
                "build-tools" {
                    Write-Host "   - C++ 编译工具: 以管理员身份运行: npm install -g windows-build-tools"
                    Write-Host "     或安装 Visual Studio Build Tools: https://visualstudio.microsoft.com/downloads/"
                }
            }
        }

        # 自动尝试安装 windows-build-tools
        if ($missingDeps -contains "build-tools") {
            Write-Host ""
            $installBT = Read-Host "是否自动安装 windows-build-tools? (需要较长时间) [y/N]"
            if ($installBT -eq "y" -or $installBT -eq "Y") {
                Write-Info "安装 windows-build-tools (这个过程可能需要 10-20 分钟)..."
                npm install -g windows-build-tools
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
        Write-Warn "无法访问 npm registry，请检查网络或代理设置"
        if ($env:HTTP_PROXY -or $env:HTTPS_PROXY) {
            Write-Info "检测到代理设置: $($env:HTTP_PROXY ?? $env:HTTPS_PROXY)"
        }
    }
}

# -------------------- Node.js 检测与安装 --------------------
function Test-NodeJS {
    Write-Info "检查 Node.js..."
    try {
        $nodeVersion = (node -v) -replace 'v', ''
        $majorVersion = [int]($nodeVersion -split '\.')[0]
        if ($majorVersion -ge 18) {
            Write-Ok "Node.js v$nodeVersion 已满足要求 (>= v18)"
            return $true
        } else {
            Write-Warn "Node.js v$nodeVersion 版本过低，需要 >= v18"
            return $false
        }
    } catch {
        Write-Warn "未检测到 Node.js"
        return $false
    }
}

function Install-NodeJS {
    Write-Info "安装 Node.js (LTS)..."

    # 尝试使用 winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Info "通过 winget 安装 Node.js LTS..."
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements

        Write-Warn "Node.js 安装完成后，请重新打开 PowerShell 并重新运行本脚本"
        Write-Warn "或者手动刷新 PATH 后继续..."
    }
    # 尝试使用 Chocolatey
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Info "通过 Chocolatey 安装 Node.js LTS..."
        choco install nodejs-lts -y
    }
    # 直接下载安装
    else {
        Write-Info "下载 Node.js 安装程序..."
        $nodeUrl = "https://nodejs.org/dist/v20.18.0/node-v20.18.0-x64.msi"
        $installer = "$env:TEMP\nodejs-installer.msi"

        try {
            Invoke-WebRequest -Uri $nodeUrl -OutFile $installer -UseBasicParsing
            Write-Info "运行安装程序..."
            Start-Process msiexec.exe -Wait -ArgumentList "/i `"$installer`" /quiet /norestart"
            Remove-Item $installer -Force

            # 刷新 PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            Write-Ok "Node.js 安装完成"
        } catch {
            Write-Error2 "自动安装失败，请手动安装 Node.js:"
            Write-Host "  下载链接: https://nodejs.org/ (选择 LTS 版本)"
            Write-Host "  安装完成后重新运行本脚本"
            exit 1
        }
    }
}

# -------------------- Claude Code 安装 --------------------
function Install-ClaudeCode {
    Write-Info "安装 Claude Code..."
    npm install -g @anthropic-ai/claude-code

    try {
        $version = claude --version 2>$null
        Write-Ok "Claude Code 安装成功 ($version)"
    } catch {
        Write-Error2 "Claude Code 安装失败，请检查 npm 全局路径是否在 PATH 中"
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

    # 配置方式
    Write-Host "请选择配置方式:"
    Write-Host "  1) 使用环境变量 (推荐)"
    Write-Host "  2) 使用 Claude Code 配置文件"
    Write-Host ""
    $configMethod = Read-Host "请输入选项 [1/2] (默认 1)"
    if ([string]::IsNullOrWhiteSpace($configMethod)) { $configMethod = "1" }

    # API Key
    Write-Host ""
    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        $ApiKey = Read-Host "请输入第三方 API Key"
        if ([string]::IsNullOrWhiteSpace($ApiKey)) {
            Write-Error2 "API Key 不能为空，跳过模型配置"
            return
        }
    }

    # 提供商选择
    Write-Host ""
    Write-Host "支持以下第三方模型提供商:"
    Write-Host "  1) DeepSeek (deepseek-v4-pro / deepseek-v4-flash，百万上下文)"
    Write-Host "  2) OpenRouter (支持多种模型)"
    Write-Host "  3) 自定义 Anthropic 兼容 API"
    Write-Host "  4) 阿里百炼 (通义千问)"
    Write-Host "  5) 智谱 AI (GLM)"
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($BaseUrl) -or [string]::IsNullOrWhiteSpace($Model)) {
        $providerChoice = Read-Host "请选择提供商 [1-5] (默认 1)"
        if ([string]::IsNullOrWhiteSpace($providerChoice)) { $providerChoice = "1" }

        switch ($providerChoice) {
            "1" {
                $BaseUrl = "https://api.deepseek.com/anthropic"
                Write-Host ""
                Write-Host "DeepSeek 可用模型 (支持 1M token 上下文):"
                Write-Host "  a) deepseek-v4-pro   (旗舰版，擅长复杂推理与代码生成)"
                Write-Host "  b) deepseek-v4-flash (轻量快速版，性价比高)"
                Write-Host "  c) 自定义模型名称"
                $modelChoice = Read-Host "请选择 [a/b/c] (默认 a)"
                if ([string]::IsNullOrWhiteSpace($modelChoice)) { $modelChoice = "a" }
                switch ($modelChoice) {
                    "a" { $Model = "deepseek-v4-pro" }
                    "b" { $Model = "deepseek-v4-flash" }
                    "c" { $Model = Read-Host "请输入模型名称" }
                }
            }
            "2" {
                $BaseUrl = "https://openrouter.ai/api/v1"
                Write-Host ""
                Write-Host "OpenRouter 常用模型:"
                Write-Host "  a) anthropic/claude-sonnet-4"
                Write-Host "  b) anthropic/claude-opus-4"
                Write-Host "  c) deepseek/deepseek-v4-pro"
                Write-Host "  d) 自定义模型名称"
                $modelChoice = Read-Host "请选择 [a/b/c/d] (默认 a)"
                if ([string]::IsNullOrWhiteSpace($modelChoice)) { $modelChoice = "a" }
                switch ($modelChoice) {
                    "a" { $Model = "anthropic/claude-sonnet-4" }
                    "b" { $Model = "anthropic/claude-opus-4" }
                    "c" { $Model = "deepseek/deepseek-v4-pro" }
                    "d" { $Model = Read-Host "请输入模型名称" }
                }
            }
            "3" {
                $BaseUrl = Read-Host "请输入 API Base URL"
                $Model = Read-Host "请输入模型名称"
            }
            "4" {
                $BaseUrl = "https://dashscope.aliyuncs.com/apps/anthropic"
                Write-Host ""
                Write-Host "百炼可用模型:"
                Write-Host "  a) qwen-plus"
                Write-Host "  b) qwen-max"
                Write-Host "  c) 自定义模型名称"
                $modelChoice = Read-Host "请选择 [a/b/c] (默认 a)"
                if ([string]::IsNullOrWhiteSpace($modelChoice)) { $modelChoice = "a" }
                switch ($modelChoice) {
                    "a" { $Model = "qwen-plus" }
                    "b" { $Model = "qwen-max" }
                    "c" { $Model = Read-Host "请输入模型名称" }
                }
            }
            "5" {
                $BaseUrl = "https://open.bigmodel.cn/api/anthropic"
                Write-Host ""
                Write-Host "智谱可用模型:"
                Write-Host "  a) glm-4.5"
                Write-Host "  b) glm-4.6"
                Write-Host "  c) 自定义模型名称"
                $modelChoice = Read-Host "请选择 [a/b/c] (默认 a)"
                if ([string]::IsNullOrWhiteSpace($modelChoice)) { $modelChoice = "a" }
                switch ($modelChoice) {
                    "a" { $Model = "glm-4.5" }
                    "b" { $Model = "glm-4.6" }
                    "c" { $Model = Read-Host "请输入模型名称" }
                }
            }
            default {
                Write-Warn "无效选择，使用 DeepSeek 默认配置"
                $BaseUrl = "https://api.deepseek.com/anthropic"
                $Model = "deepseek-v4-pro"
            }
        }
    }

    # 应用配置
    if ($configMethod -eq "1") {
        Set-EnvConfig
    } else {
        Set-FileConfig
    }
}

function Set-EnvConfig {
    Write-Info "配置环境变量..."

    # 设置用户级环境变量 (永久)
    [Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $ApiKey, "User")
    [Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $BaseUrl, "User")
    [Environment]::SetEnvironmentVariable("ANTHROPIC_MODEL", $Model, "User")

    # 设置当前会话
    $env:ANTHROPIC_API_KEY = $ApiKey
    $env:ANTHROPIC_BASE_URL = $BaseUrl
    $env:ANTHROPIC_MODEL = $Model

    Write-Ok "环境变量配置完成 (用户级别，新 PowerShell 窗口生效)"
}

function Set-FileConfig {
    $configFile = "$env:USERPROFILE\.claude.json"

    Write-Info "配置 Claude Code 配置文件..."

    $config = @{}
    if (Test-Path $configFile) {
        try {
            $config = Get-Content $configFile -Raw | ConvertFrom-Json | Out-Hashtable
        } catch {
            Write-Warn "无法读取现有配置文件，将创建新文件"
        }
    }

    $config["ANTHROPIC_API_KEY"] = $ApiKey
    $config["ANTHROPIC_BASE_URL"] = $BaseUrl
    $config["ANTHROPIC_MODEL"] = $Model

    $config | ConvertTo-Json -Depth 10 | Set-Content $configFile -Encoding UTF8
    Write-Ok "配置文件已写入: $configFile"
}

# -------------------- 安装后验证 --------------------
function Test-Installation {
    Write-Host ""
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  安装验证" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    # Node.js
    try { Write-Ok "Node.js: $(node -v)" } catch { Write-Error2 "Node.js: 未安装" }

    # npm
    try { Write-Ok "npm: $(npm -v)" } catch { Write-Error2 "npm: 未安装" }

    # Claude Code
    try {
        Write-Ok "Claude Code: $(claude --version 2>$null)"
    } catch {
        Write-Warn "Claude Code: 未找到命令"
        $npmBin = "$(npm config get prefix)\bin"
        Write-Info "请将以下路径添加到 PATH: $npmBin"
    }

    # 模型配置
    Write-Host ""
    if ($env:ANTHROPIC_API_KEY) {
        Write-Ok "API Key: 已配置 ($($env:ANTHROPIC_API_KEY.Substring(0, [Math]::Min(8, $env:ANTHROPIC_API_KEY.Length)))...)"
    } elseif ([Environment]::GetEnvironmentVariable("ANTHROPIC_API_KEY", "User")) {
        Write-Ok "API Key: 已配置 (需新窗口生效)"
    } else {
        Write-Warn "API Key: 未配置"
    }

    if ($env:ANTHROPIC_BASE_URL) {
        Write-Ok "Base URL: $env:ANTHROPIC_BASE_URL"
    }
    if ($env:ANTHROPIC_MODEL) {
        Write-Ok "默认模型: $env:ANTHROPIC_MODEL"
    }
}

# -------------------- 使用说明 --------------------
function Show-Usage {
    Write-Host ""
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  快速开始" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  启动 Claude Code:" -ForegroundColor White
    Write-Host "    claude"
    Write-Host ""
    Write-Host "  启动交互式对话:"
    Write-Host "    claude chat"
    Write-Host ""
    Write-Host "  查看帮助:"
    Write-Host "    claude --help"
    Write-Host ""
    Write-Host "  切换模型 (Claude Code 内):"
    Write-Host "    /model"
    Write-Host ""
    Write-Host "  修改配置:"
    Write-Host "    重新运行: .\install-claude-code.ps1"
    Write-Host "    或直接编辑: `$env:USERPROFILE\.claude.json"
    Write-Host ""
    Write-Host "  ⚠ 如果使用第三方模型，首次启动可能需要" -ForegroundColor Yellow
    Write-Host "    手动在 Claude Code 中使用 /model 选择模型" -ForegroundColor Yellow
    Write-Host ""
}

# -------------------- 主流程 --------------------
function Main {
    Show-Banner

    Test-Admin

    # Windows 依赖全面检测
    Test-WindowsDependencies

    if ($ConfigOnly) {
        Set-ModelConfig
        Test-Installation
        return
    }

    # 网络检查
    Test-Network

    # 检查并安装 Node.js
    $nodeOk = Test-NodeJS
    if (-not $nodeOk) {
        Install-NodeJS

        # 刷新 PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        # 再次检查
        try {
            $null = node -v
        } catch {
            Write-Error2 "Node.js 安装后仍不可用，请重新打开 PowerShell 后运行:"
            Write-Host "  .\install-claude-code.ps1"
            Write-Host ""
            Write-Host "或者手动安装 Node.js: https://nodejs.org/"
            return
        }
    }

    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Error2 "npm 未找到，请检查 Node.js 安装"
        return
    }

    # 检查是否已安装 Claude Code
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Write-Info "Claude Code 已安装"
        $reinstall = Read-Host "是否重新安装? [y/N]"
        if ($reinstall -eq "y" -or $reinstall -eq "Y") {
            Write-Info "更新 Claude Code..."
            npm install -g @anthropic-ai/claude-code
        }
    } else {
        Install-ClaudeCode
    }

    # 配置第三方模型
    if ($ApiKey -and $BaseUrl -and $Model) {
        Write-Info "使用命令行参数配置模型..."
        Set-EnvConfig
    } else {
        Write-Host ""
        $doConfig = Read-Host "是否配置第三方大模型? [Y/n]"
        if ($doConfig -ne "n" -and $doConfig -ne "N") {
            Set-ModelConfig
        }
    }

    # 验证
    Test-Installation

    # 使用说明
    Show-Usage

    Write-Host "✅ 安装完成!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  启动 Claude Code:" -ForegroundColor White
    Write-Host "    claude"
    Write-Host ""
}

# 运行主流程
Main
