# CLI Status 菜单栏应用 - 需求提案

## 背景与目标

开发一个 macOS 原生菜单栏应用，用于监控和管理本地安装的 AI CLI 工具版本。用户可以在状态栏快速查看各工具的当前版本、最新版本，并一键执行更新或安装操作。

## 约束集合

### 硬约束 (Hard Constraints)

| ID | 约束描述 | 来源 |
|----|---------|------|
| HC-01 | 必须使用 Swift + SwiftUI 开发 | 用户选择 |
| HC-02 | 必须作为 macOS 菜单栏应用运行 | 需求定义 |
| HC-03 | 必须支持 macOS 13+ (Ventura 或更高) | SwiftUI 特性依赖 |
| HC-04 | 必须支持 Apple Silicon (arm64) 架构 | 目标设备 |

### 工具检测约束

| 工具名称 | 检测命令 | 版本解析 | 最新版本源 | 更新命令 | 安装命令 |
|---------|---------|---------|-----------|---------|---------|
| Claude Code | `claude --version` | 解析 "X.Y.Z (Claude Code)" | npm: @anthropic-ai/claude-code | `npm update -g @anthropic-ai/claude-code` | `npm install -g @anthropic-ai/claude-code` |
| Codex | `codex --version` | 解析 "codex-cli X.Y.Z" | npm: @openai/codex | `npm update -g @openai/codex` | `npm install -g @openai/codex` |
| Gemini CLI | `gemini --version` | 直接版本号 | npm: @google/gemini-cli | `npm update -g @google/gemini-cli` | `npm install -g @google/gemini-cli` |
| Amp Code | `amp --version` | 解析 "X.Y.Z (...)" | npm: @sourcegraph/amp | `amp update` | `curl -fsSL https://ampcode.com/install.sh \| sh` |
| Droid | `droid --version` | 直接版本号 | 无公开 API，使用安装脚本检查 | `curl -fsSL https://app.factory.ai/cli \| sh` | `curl -fsSL https://app.factory.ai/cli \| sh` |
| OpenCode | `opencode --version` | 直接版本号 | npm: opencode-ai | `npm update -g opencode-ai` | `npm install -g opencode-ai` |

### 软约束 (Soft Constraints)

| ID | 约束描述 | 优先级 |
|----|---------|-------|
| SC-01 | 定时自动检查更新（建议间隔 1 小时） | 高 |
| SC-02 | 未安装工具显示安装按钮 | 高 |
| SC-03 | 更新/安装操作显示进度指示 | 中 |
| SC-04 | 支持深色/浅色模式自适应 | 中 |
| SC-05 | 内存占用应小于 50MB | 低 |

### 依赖关系

| ID | 依赖描述 |
|----|---------|
| DEP-01 | npm 全局安装命令需要 Node.js 环境 |
| DEP-02 | curl 安装脚本需要网络访问 |
| DEP-03 | 版本比较需要网络连接到 npm registry |

### 风险项

| ID | 风险描述 | 缓解策略 |
|----|---------|---------|
| RISK-01 | Droid 无公开版本 API | 使用安装脚本输出或跳过最新版本检查 |
| RISK-02 | Amp 版本号格式特殊（带 git hash） | 特殊解析逻辑 |
| RISK-03 | 更新命令可能需要管理员权限 | 提示用户或使用 osascript 提权 |
| RISK-04 | npm registry 可能访问缓慢 | 添加超时和重试机制 |

## 功能需求

### REQ-01: 菜单栏图标与状态显示

**场景**: 用户启动应用后
**期望**:
- 状态栏显示应用图标
- 图标可显示整体状态（全部最新/有更新可用/检查中）

### REQ-02: 工具列表展示

**场景**: 用户点击状态栏图标
**期望**:
- 下拉菜单显示所有监控的 CLI 工具
- 每个工具显示：名称、当前版本、最新版本
- 有更新可用时视觉高亮显示

### REQ-03: 版本检查功能

**场景**: 定时触发或用户手动触发
**期望**:
- 检测本地安装版本
- 查询远程最新版本
- 比较并标记需要更新的工具

### REQ-04: 更新功能

**场景**: 用户点击某工具的更新按钮
**期望**:
- 执行对应的更新命令
- 显示更新进度/状态
- 更新完成后刷新版本显示

### REQ-05: 安装功能

**场景**: 用户点击未安装工具的安装按钮
**期望**:
- 执行对应的安装命令
- 显示安装进度/状态
- 安装完成后显示已安装版本

### REQ-06: 设置与配置

**场景**: 用户希望自定义应用行为
**期望**:
- 可配置检查间隔
- 可配置开机自启动
- 可启用/禁用特定工具的监控

## 成功判据

| ID | 判据描述 | 验证方法 |
|----|---------|---------|
| SUCC-01 | 应用能在 macOS 菜单栏正常显示 | 手动验证 |
| SUCC-02 | 能正确检测已安装工具的版本 | 与命令行输出对比 |
| SUCC-03 | 能正确获取各工具的最新版本 | 与 npm view 输出对比 |
| SUCC-04 | 能正确执行更新操作 | 更新后版本号变化 |
| SUCC-05 | 能正确执行安装操作 | 安装后工具可用 |
| SUCC-06 | 定时检查功能正常工作 | 观察自动刷新行为 |

## 技术架构建议

```
CLIStatusApp/
├── CLIStatusApp.swift          # @main 入口
├── Models/
│   ├── CLITool.swift          # CLI 工具模型
│   └── VersionInfo.swift      # 版本信息模型
├── Views/
│   ├── MenuBarView.swift      # 菜单栏视图
│   ├── ToolRowView.swift      # 工具行视图
│   └── SettingsView.swift     # 设置视图
├── Services/
│   ├── VersionChecker.swift   # 版本检查服务
│   ├── UpdateService.swift    # 更新执行服务
│   └── ShellExecutor.swift    # Shell 命令执行器
└── Utilities/
    └── VersionParser.swift    # 版本解析工具
```

## 最终技术决策

| 决策点 | 选择 | 理由 |
|-------|------|------|
| 技术栈 | Swift + SwiftUI | 用户选择，原生性能最佳 |
| 最低版本 | macOS 14 (Sonoma) | 可使用 @Observable 宏 |
| App Sandbox | 禁用 | 需要执行外部 CLI 工具 |
| 菜单样式 | `.menuBarExtraStyle(.window)` | 支持富交互 UI |
| 状态管理 | @Observable (Observation framework) | macOS 14+ 最佳实践 |
| 版本检查 | 启动时 + 每小时定时 + 手动刷新 | 用户选择 |
| 系统通知 | 启用 (UNUserNotificationCenter) | 用户选择 |

## 下一步行动

详见 `implementation-plan.md` 中的零决策实施计划。

**实施阶段：**
1. Phase 1: 项目基础设施 (P1)
2. Phase 2: 数据模型层 (P2)
3. Phase 3: 服务层 (P3)
4. Phase 4: 视图模型层 (P4)
5. Phase 5: UI 层 (P5)
6. Phase 6: 完善与测试 (P6)

执行命令：`/ccg:spec-impl` 开始实施
