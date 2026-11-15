# 继承 StudyBrain 外置大脑项目 Spec

## Why

`D:\Fl.User\Documents\Trae-CN\temp_20261109_02` 是原 StudyBrain 项目的旧入口（与 `d:\StudyBrain` 为同一套内容）。需要完整继承原项目的风格、规则与工具链，确认我具备并可提供哪些能力，同时按用户指令把 2026-11-13 当天所有学习任务全部作废，等待稍后重新规划。

## What Changes

- 固化原项目的工作方式与硬性规则，作为后续所有 Agenda 的唯一依据（不另立风格）。
- 梳理并列出当前可执行 / 需要执行的完整能力清单。
- 将 2026-11-13（周五）当日全部任务标记为取消：不补、不内耗、不弹计时器。
- 保留既有工具与数据，不重写、不迁移、不删除。

## Impact

- Affected specs: `daily-study-agenda`（项目内 skills）、全局 `studyagenda` skill 的既有规则
- Affected code: `tools/study-timer.ps1`、`tools/agenda-stats.ps1`、`tools/report-html.ps1`、`data/sessions.csv`、`data/notes.csv`（均只读参考，不做修改）
- 新增数据：`data/cancelled.csv`（取消记录）

## 原项目既有事实（她做过的事）

1. 建起 StudyBrain 外置大脑目录：`tools/`、`data/`、`reports/`、`锐阅读八年级答案/`。
2. 写了两份 Agenda 规则：项目内 `.trae/skills/daily-study-agenda/SKILL.md` 与全局 `studyagenda` 技能（含假期 23:00 熔断线）。
3. 做桌面计时器：`tools/study-timer.ps1` + `tools/timer-hidden.vbs`，必须用 WMI 脱离进程树启动；毛玻璃小窗，支持拖动、双击暂停、右键菜单（暂停/重置/提前结束/关闭记中断）、到点弹「完成/延迟 5 分钟/延迟 10 分钟」。
4. 做历史时长统计：`tools/agenda-stats.ps1`，按科目取最近 5 次实际用时的均值，并限制在上下限内，输出 `SUGGEST|科目|分钟|样本数|平均`。
5. 做 HTML 报告：`tools/report-html.ps1`，支持周/月/季/年，正式版进 `reports\`、临时版进 `reports\temp\`，含学科小结卡片。
6. 注册计划任务 `StudyWeeklyReportFinal`：每周日 22:40 自动生成正式周报（当前状态 Ready）。
7. 建立数据闭环：`data/sessions.csv` 计时日志、`data/notes.csv` 一句话总结、`data/summary.md` 学科小结（尚未创建）。
8. 已生成并导出临时周报与 HTML 分享包（`reports/temp/`、`.trae-html-share-packages/`）。
9. 记录关键约束：11/13–11/16 假期熔断线 23:00、周三无作业且有 1 小时纯自由时间、历史每天必做、练字每天 10 分钟、数学永远最先。
10. 今天 20:05 与 20:06 两次启动数学计时器，均被用户关闭（日志记为「中断」，实际用时 0.2 / 0 分钟）。

## 能力清单（我可以且需要干什么）

**可以且默认要做的**
- 排 Agenda：自己取系统时间与星期，按星期、作业量、网课情况输出「现在做什么 + 剩余任务」，不输出整张时间表。
- 控时长：每次先查 `agenda-stats.ps1`，用历史均值，样本不足用默认值。
- 弹计时器：按科目英文 key 用 WMI 启动，到点提醒，记录 `sessions.csv`。
- 收总结：每完成任务问一句一句话总结，写入 `notes.csv`；不追问第二遍。
- 写报告：周日 22:30 后写 `summary.md` 并生成正式周报；月/季/年报按区间规则处理。
- 守红线：常规 22:30 / 假期 23:00 熔断；练字、历史不可砍；高压日减配；周三自由时间；网课切块 ≥1 小时。

**今天需要做的**
- 取消 2026-11-13 全部剩余任务（数学、错题复盘、背单词、语文阅读、历史、政治、练字）。
- 不再弹出任何计时器，不做补做提醒，不写负面记录。
- 等用户明确指令后再重新规划，不自作主张重排。

## ADDED Requirements

### Requirement: 今日任务全部取消

系统 SHALL 将 2026-11-13 当日所有未完成学习任务视为已取消，且不发生任何计时器弹窗。

#### Scenario: 用户要求取消今日任务
- **WHEN** 用户在 2026-11-13 明确表示今天任务全部取消、稍后重新规划
- **THEN** 系统记录该取消事实，并停止输出任何「现在做…」任务与计时器
- **AND** 不追问原因、不建议补做、不重排今日计划

#### Scenario: 稍后重新规划
- **WHEN** 用户之后给出重新规划指令（可能含新的作业量/网课信息）
- **THEN** 系统按原 StudyBrain 规则重新取时间并从数学开始排，不复用已作废的今日安排

### Requirement: 沿用原项目风格

系统 SHALL 保持原风格：干脆、只下指令、不写鼓励废话、只给当前任务与剩余任务清单。

#### Scenario: 日常询问要干啥
- **WHEN** 用户说「要干啥」或触发 studyagenda
- **THEN** 系统自行获取系统时间，输出当前任务（含分钟数）与剩余任务清单，并正常弹计时器（今日取消期间除外）

### Requirement: 不破坏既有资产

系统 SHALL 保留原项目全部脚本、数据与报告，不做重写或迁移。

#### Scenario: 继承旧项目
- **WHEN** 系统读取 `D:\Fl.User\Documents\Trae-CN\temp_20261109_02` 与 `d:\StudyBrain`
- **THEN** 确认两者为同一套内容，仅新增取消记录，不改动既有文件
