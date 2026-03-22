# OpenFarm Agent API Spec (v1)

本文档描述当前项目中 Agent 相关协议的**实际实现**（以代码为准），用于对接外部 Agent/SDK。

## 1. 入口与职责

- `AgentAdapter`：对外 API 入口，提供 `get_observation` / `submit_action` / capability 控制。 
- `ActionSchema`：动作参数校验。 
- `ActionDispatcher`：动作执行与统一返回结构。 
- `ObservationBuilder`：观测快照构建。 
- `ReplayLogger`：事件回放日志（JSONL）。

## 2. Capability 协议

`AgentAdapter.get_capabilities()` 返回：

```json
{
  "move_to": true,
  "interact": true,
  "plant": true,
  "water": true,
  "harvest": true,
  "sell": true,
  "talk_to": true,
  "rest": true
}
```

`AgentAdapter.set_capabilities(next)` 只会覆盖已有 key。

## 3. Action 调用协议

### 3.1 调用

- 方法：`submit_action(action_name: String, params: Dictionary = {})`
- 调度：内部调用 `ActionDispatcher.execute_for_actor(_player, action_name, params)`

### 3.2 统一返回结构（ActionResult）

```json
{
  "success": true,
  "error_code": "",
  "time_cost": 1.0,
  "energy_cost": 2.0,
  "emitted_events": []
}
```

字段说明：

- `success: bool`：动作是否成功。
- `error_code: string`：失败原因（成功通常为空字符串）。
- `time_cost: float`：该动作推进的游戏时间成本（抽象单位）。
- `energy_cost: float`：该动作消耗的体力。
- `emitted_events: Array<Dictionary>`：动作内生成的业务事件。

### 3.3 动作与参数（v1）

| action_name | 必填参数 | 可选参数 | 说明 |
| --- | --- | --- | --- |
| `move_to` | 无（但 `target` / `direction` 至少一个） | `target`, `direction`, `delta`, `speed` | 移动 |
| `interact` | `target_id` | - | 与目标交互 |
| `plant` | `seed_id`, `tile` | - | 播种 |
| `water` | `tile` | - | 浇水 |
| `harvest` | `tile` | - | 收获 |
| `sell` | `item_id`, `qty` | - | 售卖 |
| `talk_to` | `npc_id` | - | 对话 |
| `rest` | 无 | - | 休息到次日 |

### 3.4 常见错误码

- 通用：`unknown_action`、`dispatcher_missing`、`capability_blocked`
- 参数：`missing_param_*`、`move_requires_target_or_direction`
- 动作执行：`actor_missing`、`invalid_target`、`unknown_target`、`farm_system_missing`、`insufficient_energy`、`invalid_seed`、`missing_seed`、`invalid_qty`、`missing_item`、`item_not_sellable`、`invalid_npc`、`map_change_failed`

## 4. Observation 协议

`AgentAdapter.get_observation()` 返回结构：

```json
{
  "time": {"day": 1, "period": "Morning"},
  "player": {
    "position": {"x": 0.0, "y": 0.0},
    "energy": 100,
    "gold": 0
  },
  "inventory": {},
  "nearby_objects": [],
  "farm_plots": [],
  "current_quest": {}
}
```

字段说明：

- `time`：来自 `GameState.get_time_data()`。
- `player.position`：`{x, y}` 字典形式。
- `inventory`：物品 -> 数量。
- `nearby_objects`：基于世界节点扫描与距离过滤（默认 120）。
- `farm_plots`：来自 `FarmSystem.get_all_plots()`。
- `current_quest`：来自 `GameState.get_quest_data()`。

## 5. 事件桥接协议

`AgentAdapter` 会转发 dispatcher 信号为统一 `event_emitted(event_name, payload)`：

- `action_started`：`{"action": string, "payload": {...}}`
- `action_finished`：`{"action": string, "result": ActionResult}`
- `time_advanced`：时间数据
- `inventory_changed`：`{"inventory": {...}}`
- `quest_updated`：`{"quest": {...}}`

## 6. Replay JSONL 协议

`ReplayLogger` 每条日志结构：

```json
{
  "schema_version": 1,
  "session_id": "<string>",
  "seq": 1,
  "event_name": "action_started",
  "payload": {},
  "meta": {
    "scene_path": "res://scenes/Main.tscn",
    "day": 1,
    "period": "Morning",
    "unix_time": 1700000000
  }
}
```

默认输出路径：`user://openfarm_replay.jsonl`。

## 7. 兼容性说明

- 当前协议版本建议标记为 **v1**。
- 新增 action 或 observation 字段时，优先保持向后兼容（新增可选字段，不删除已有字段）。
