# WunjoAgentTools

---

Several practical Skills/Tools for coding agents.

---

# 1. Cexp(change explainer)(Skill)

格式化地讲解Agent对代码的修改和设计思想，帮助用户无需自行阅读代码，就可以掌握Agent的改动

# 2. Claude Code Popper(Hook)

Claude Code 完成任务/执行过程中发生请求时弹出桌面通知。支持 Windows / Linux / macOS。

## 一键安装

**Windows** (PowerShell):
```powershell
irm https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper/windows/install.ps1 | iex
```

**Linux** (Bash):
```bash
curl -fsSL https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper/linux/install.sh | bash
```

**macOS** (Bash):
```bash
curl -fsSL https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper/macos/install.sh | bash
```

安装后重启 Claude Code 生效。

## 一键卸载

**Windows**:
```powershell
irm https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper/windows/uninstall.ps1 | iex
```

**Linux**:
```bash
curl -fsSL https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper/linux/uninstall.sh | bash
```

**macOS**:
```bash
curl -fsSL https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper/macos/uninstall.sh | bash
```

## 安装后文件位置

```
~/.claude/claudecode-popper/
├── popup.ps1 (Windows) / popup.sh (Linux/macOS)
├── config.json
└── uninstall.ps1 (Windows) / uninstall.sh (Linux/macOS)
```

## 自定义配置

编辑 `~/.claude/claudecode-popper/config.json`：

```json
{
  "notification": {
    "title": "Claude Code",
    "message": "请求已处理",
    "sound": true
  },
  "stop": {
    "title": "Claude Code",
    "message": "任务完成",
    "sound": true
  }
}
```

- `notification` — Claude 发送通知时触发（如等待输入）
- `stop` — Claude 完成任务时触发
- `sound` — 是否播放提示音（`true` / `false`）

## 工作原理

通过 Claude Code 的 [hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) 机制，在 `Notification` 和 `Stop` 事件时调用系统原生弹窗：

| 系统   | 弹窗方式                          |
| ------ | --------------------------------- |
| Windows | WPF Window（PowerShell）         |
| Linux   | `notify-send`（libnotify）       |
| macOS   | `osascript`（系统原生通知）       |

## 远程服务器模式（SSH）

当 Claude Code 运行在远程 Linux 服务器上（通过 SSH 连接）时，本地桌面默认无法收到弹窗。远程模式通过 **SSH 反向隧道 + TCP 监听** 解决此问题。

### 原理

```
1. 本地机器运行 TCP 监听进程（listener），监听端口 9876
2. SSH 连接时加 -R 参数建立反向隧道
3. 服务器上 Claude Code 触发 hook → popup.sh 发送 TCP 消息到 localhost:9876
4. SSH 隧道将消息转发到本地机器
5. listener 收到消息，弹出本地桌面通知
```

### 安装步骤

**第一步：在服务器上安装远程 popup**

```bash
curl -fsSL https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper/remote/install.sh | bash
```

**第二步：在本地机器上下载 listener**

Linux / macOS：
```bash
mkdir -p ~/.claude/claudecode-popper
curl -fsSL https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper/remote/listener.sh -o ~/.claude/claudecode-popper/listener.sh
chmod +x ~/.claude/claudecode-popper/listener.sh
```

Windows (PowerShell)：
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\claudecode-popper" | Out-Null
irm https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper/remote/listener.ps1 -OutFile "$env:USERPROFILE\.claude\claudecode-popper\listener.ps1"
```

**第三步：启动 listener**

在本地机器的一个终端窗口中运行：

```bash
# Linux / macOS
bash ~/.claude/claudecode-popper/listener.sh

# Windows PowerShell
powershell -File "$env:USERPROFILE\.claude\claudecode-popper\listener.ps1"
```

**第四步：SSH 连接时加反向隧道**

```bash
ssh -R 9876:localhost:9876 user@your-server
```

保持 listener 运行和 SSH 连接，正常使用 Claude Code 即可收到本地弹窗。

### 配置

`~/.claude/claudecode-popper/config.json` 中的 `remote` 字段：

```json
{
  "remote": {
    "port": 9876,
    "fallback_to_local": true
  }
}
```

- `port` — 监听端口，需与 SSH `-R` 参数一致（默认 9876）
- `fallback_to_local` — TCP 发送失败时是否回退到服务器本地通知（默认 `true`）

也可通过环境变量 `CLAUDE_REMOTE_PORT` 覆盖端口配置。

### 两种使用方式

**方式一：使用 remote/ 目录的专用脚本（推荐）**

服务器上只安装 `remote/popup.sh`，专门用于远程发送。不依赖服务器桌面环境。

**方式二：使用原平台脚本 + 环境变量**

服务器上安装 `linux/popup.sh`，设置 `CLAUDE_REMOTE_PORT=9876` 环境变量。脚本会先尝试 TCP 发送，失败后回退到本地 `notify-send`。适合偶尔需要本地弹窗的场景。
