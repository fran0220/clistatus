# CLI Status App - 任务分解

## 阶段 1: 项目基础设施 ✅

### Task 1.1: 创建项目 ✅
- [x] 创建 Swift Package 项目
- [x] 配置为菜单栏应用（LSUIElement = YES）
- [x] 设置最低部署目标 macOS 14.0
- [x] 禁用 App Sandbox（需要执行外部命令）

### Task 1.2: 基础数据模型 ✅
- [x] 定义 CLITool 枚举（Models/CLITool.swift）
- [x] 定义 ToolStatus 模型（Models/ToolStatus.swift）
- [x] 定义 VersionInfo 模型（Models/VersionInfo.swift）

## 阶段 2: 核心服务层 ✅

### Task 2.1: Shell 命令执行器 ✅
- [x] 实现异步 Shell 命令执行（Services/ShellExecutor.swift）
- [x] 处理输出捕获和错误处理
- [x] 支持超时机制（withThrowingTaskGroup）

### Task 2.2: 版本检测服务 ✅
- [x] 实现本地版本检测（Services/VersionChecker.swift）
- [x] 实现远程最新版本查询（npm view）
- [x] 实现版本比较逻辑（VersionInfo.Comparable）

### Task 2.3: 更新/安装服务 ✅
- [x] 实现更新命令执行（Services/UpdateService.swift）
- [x] 实现安装命令执行
- [x] 系统通知服务（Services/NotificationService.swift）

## 阶段 3: UI 层 ✅

### Task 3.1: 菜单栏基础 ✅
- [x] 实现 MenuBarExtra（CLIStatusApp.swift）
- [x] 使用 SF Symbol terminal.fill
- [x] 实现 .window 样式弹窗

### Task 3.2: 工具列表视图 ✅
- [x] 实现工具行组件（Views/ToolRowView.swift）
- [x] 显示版本信息（当前 → 最新）
- [x] 更新/安装按钮

### Task 3.3: 设置视图 ✅
- [x] 检查间隔配置（Views/SettingsView.swift）
- [x] 开机自启动配置（SMAppService）
- [ ] 工具启用/禁用（未实现，低优先级）

## 阶段 4: 集成与优化 ✅

### Task 4.1: 定时检查 ✅
- [x] 实现后台定时器（AppState.checkTimer）
- [x] 定时器与设置同步（didSet + restartScheduledChecks）
- [ ] 网络状态监测（未实现，低优先级）

### Task 4.2: 持久化 ✅
- [x] UserDefaults 存储配置（@AppStorage）
- [ ] 缓存最后检查结果（未实现，低优先级）

### Task 4.3: 完善与测试 ⏳
- [x] 错误处理和用户提示
- [x] 深色/浅色模式适配（使用语义颜色）
- [ ] 性能优化（待测试）

## 工具配置详情

| 工具 | 包管理器 | 包名 | 特殊处理 |
|-----|---------|-----|---------|
| Claude Code | npm | @anthropic-ai/claude-code | 无 |
| Codex | npm | @openai/codex | 版本前缀 "codex-cli" |
| Gemini CLI | npm | @google/gemini-cli | 无 |
| Amp Code | 自有/npm | @sourcegraph/amp | 使用 amp update 命令 |
| Droid | curl 脚本 | N/A | 无远程版本 API |
| OpenCode | npm | opencode-ai | 无 |
