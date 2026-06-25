# WunjoSkills
---
Several practical Skills for coding agents.
---

# cexp(change explainer)

格式化地讲解Agent对代码的修改和设计思想，帮助用户无需自行阅读代码，就可以掌握Agent的改动

# Claude Code Popper

Claude Code 完成任务/执行过程中发生请求时弹出桌面通知。支持 Windows / Linux / macOS。

## 一键安装

**Windows** (PowerShell):
```powershell
irm https://raw.githubusercontent.com/Wunjo777/claudecode-popper/main/windows/install.ps1 | iex
```

**Linux** (Bash):
```bash
curl -fsSL https://raw.githubusercontent.com/Wunjo777/claudecode-popper/main/linux/install.sh | bash
```

**macOS** (Bash):
```bash
curl -fsSL https://raw.githubusercontent.com/Wunjo777/claudecode-popper/main/macos/install.sh | bash
```

安装后重启 Claude Code 生效。

## 一键卸载

**Windows**:
```powershell
irm https://raw.githubusercontent.com/Wunjo777/claudecode-popper/main/windows/uninstall.ps1 | iex
```

**Linux**:
```bash
curl -fsSL https://raw.githubusercontent.com/Wunjo777/claudecode-popper/main/linux/uninstall.sh | bash
```

**macOS**:
```bash
curl -fsSL https://raw.githubusercontent.com/Wunjo777/claudecode-popper/main/macos/uninstall.sh | bash
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
