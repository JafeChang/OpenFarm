# OpenFarm Task List

状态标记说明：
- [x] 已完成
- [...] 进行中
- [] 未开始

## 1) 本地可玩核心（Godot 本体）
- [x] 主场景与项目配置（`Main` 入口、基础输入映射）
- [x] Player 移动与基础交互
- [x] 农地地块循环：播种 -> 浇水 -> 成长 -> 收获
- [x] 金币与售卖（含出货箱交互）
- [x] 睡觉/休息推进到次日并恢复体力
- [x] Farm / Town 双场景地图切换
- [x] NPC 对话内容与交互体验（对话库与任务状态文案已接入）
- [] TileMap 级地图与碰撞细化

## 2) 任务与目标系统
- [x] 任务进度与奖励领取闭环
- [x] 线性任务链框架（收获任务 -> 售卖任务）
- [x] 任务可视化反馈（DebugHUD 已展示任务状态/奖励/消息）
- [] 并行任务 / 前置条件 / 任务分支

## 3) Agent API（外部控制层）
- [x] Observation 快照（时间、玩家、背包、附近对象、农地、任务）
- [x] 统一 Action schema 与 dispatcher 执行入口
- [x] 动作结果统一结构（success/error_code/time_cost/energy_cost/events）
- [x] 事件桥接（action/time/inventory/quest）
- [x] DemoAgent（确定性策略）
- [x] Agent 能力权限细化（Adapter 能力白名单与拦截已接入）
- [] 独立 Python/TypeScript SDK

## 4) 可调试 / 可回放 / 可持久化
- [x] DebugHUD（状态、任务、最近动作、最近消息）
- [x] 本地 Save/Load（`user://openfarm_save.json`）
- [x] ReplayLogger（`user://openfarm_replay.jsonl`）
- [x] 回放数据结构标准化（schema_version/meta/seq 已接入）
- [] 回放可视化回放器（UI）

## 5) 工程化与质量
- [x] 关键规则去硬编码（`ItemDatabase`）
- [x] 基础 smoke 用例脚本（协议形状校验脚本已添加）
- [...] 自动化测试（CI/headless，已提供 headless smoke 脚本）
- [x] 文档化 API 规范（Action/Observation/Event，见 `docs/API_SPEC.md`）

## C) 建议的“下一步 task list”（按优先级）
- [x] 正式 UI 化（背包/任务/时间，已落地 GameHUD 第一版）
- [...] 农地可视化升级（TileMap + 地块状态渲染；已接入 `FarmPlotRenderer` 地块状态色块）
- [] 任务系统 V2（并行 + 条件 + 奖励池）
- [x] 自动化 smoke 测试脚本（至少 action/observation 协议回归，见 `scripts/tests/RunSmokeChecks.gd`）
