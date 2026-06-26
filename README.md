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

## 远程服务器模式

当 Claude Code 运行在远程 Linux 服务器上（通过 SSH 连接）时，本地桌面默认无法收到弹窗。支持两种远程通知方案：

| | 方案一：SSH 反向隧道 | 方案二：ntfy.sh 云端推送 |
|---|---|---|
| 原理 | TCP 消息经 SSH 隧道转发到本地 | HTTP POST 到 ntfy 服务器，推送到订阅设备 |
| 前置要求 | 本地运行 listener + SSH 加 `-R` 参数 | 手机/桌面安装 ntfy app |
| 网络要求 | SSH 连接保持 | 服务器能访问 ntfy.sh（或自建服务） |
| 适用场景 | 同一内网、低延迟要求 | 无固定本地机器、手机通知、多设备 |

通过 `config.json` 中的 `remote.mode` 字段切换（默认 `"tunnel"`）。

---

### 方案一：SSH 反向隧道（mode: tunnel）

#### 原理

```
1. 本地机器运行 TCP 监听进程（listener），监听端口 9876
2. SSH 连接时加 -R 参数建立反向隧道
3. 服务器上 Claude Code 触发 hook → popup.sh 发送 TCP 消息到 localhost:9876
4. SSH 隧道将消息转发到本地机器
5. listener 收到消息，弹出本地桌面通知
```

#### 安装步骤

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
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper/remote/listener.ps1" -OutFile "$env:USERPROFILE\.claude\claudecode-popper\listener.ps1" -UseBasicParsing
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

---

### 方案二：ntfy.sh 云端推送（mode: ntfy）

[ntfy.sh](https://ntfy.sh) 是免费的开源推送服务。服务器发 HTTP POST，手机/桌面即时收到通知。**无需 listener 进程，无需 SSH 隧道。**

#### 安装步骤

**第一步：安装 ntfy app**

在手机或本地桌面安装 ntfy 客户端：https://ntfy.sh/#app

- Android: Google Play / F-Droid
- iOS: App Store
- 桌面: Web app 或各平台客户端

**第二步：订阅 topic**

在 ntfy app 中订阅一个自定义 topic 名称（如 `claude-code-mydevice`）。名称要足够独特，避免被他人订阅。

**第三步：配置服务器上的 config.json**

编辑 `~/.claude/claudecode-popper/config.json`：

```json
{
  "remote": {
    "mode": "ntfy"
  },
  "ntfy": {
    "server": "https://ntfy.sh",
    "topic": "claude-code-mydevice"
  }
}
```

**第四步：重启 Claude Code**

#### ntfy 配置参考

```json
{
  "ntfy": {
    "server": "https://ntfy.sh",
    "topic": "claude-code-mydevice",
    "token": "",
    "priority": "high",
    "tags": ["robot_face"],
    "click": ""
  }
}
```

- `server` — ntfy 服务器地址。默认 `https://ntfy.sh`，也支持自建
- `topic` — 订阅 topic 名称（必填，需与 app 订阅一致）
- `token` — 认证 token（可选，自建服务或付费 plan 使用）
- `priority` — 通知优先级：`min` / `low` / `default` / `high` / `urgent`
- `tags` — 通知标签（emoji 或文字）
- `click` — 点击通知后打开的 URL（可选）

#### 环境变量

| 变量 | 说明 |
|------|------|
| `CLAUDE_REMOTE_MODE` | 覆盖 `remote.mode`（`tunnel` / `ntfy`） |
| `CLAUDE_NTFY_TOPIC` | 覆盖 `ntfy.topic` |
| `CLAUDE_NTFY_SERVER` | 覆盖 `ntfy.server` |

#### 安全建议

- topic 名称应足够随机/独特，避免被他人猜到并订阅
- 自建 ntfy 服务时可通过 `token` 做认证
- ntfy.sh 公共服务上 topic 是公开的，任何知道名称的人都能订阅

---

### 通用配置

`~/.claude/claudecode-popper/config.json` 中的 `remote` 字段：

```json
{
  "remote": {
    "mode": "tunnel",
    "port": 9876,
    "fallback_to_local": true
  }
}
```

- `mode` — 远程通知模式：`"tunnel"`（SSH 反向隧道）或 `"ntfy"`（云端推送）
- `port` — tunnel 模式下监听端口，需与 SSH `-R` 参数一致（默认 9876）
- `fallback_to_local` — 远程发送失败时是否回退到服务器本地通知（默认 `true`）

环境变量：

| 变量 | 说明 |
|------|------|
| `CLAUDE_REMOTE_MODE` | 覆盖 `remote.mode` |
| `CLAUDE_REMOTE_PORT` | 覆盖 `remote.port` |

### 两种使用方式

**方式一：使用 remote/ 目录的专用脚本（推荐）**

服务器上只安装 `remote/popup.sh`，专门用于远程发送。不依赖服务器桌面环境。

**方式二：使用原平台脚本 + 环境变量**

服务器上安装 `linux/popup.sh`，设置 `CLAUDE_REMOTE_MODE=ntfy` 或 `CLAUDE_REMOTE_PORT=9876` 环境变量。脚本会先尝试远程发送，失败后回退到本地 `notify-send`。适合偶尔需要本地弹窗的场景。
