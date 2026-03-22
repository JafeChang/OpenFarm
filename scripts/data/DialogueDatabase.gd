extends Node
class_name DialogueDatabase

const DIALOGUES := {
	"NPC_Alice": {
		"active": {
			"line_id": "alice_active_001",
			"text": "Keep going! Finish your current quest and come back to me."
		},
		"completed": {
			"line_id": "alice_completed_001",
			"text": "Nice work! I can give you the reward now."
		},
		"rewarded": {
			"line_id": "alice_rewarded_001",
			"text": "Great pace today. Check the next objective!"
		},
		"done": {
			"line_id": "alice_done_001",
			"text": "You cleared all current quests. More soon!"
		}
	}
}

func get_dialogue(npc_id: String, quest: Dictionary) -> Dictionary:
	if not DIALOGUES.has(npc_id):
		return {"line_id": "generic_001", "text": "Hello."}

	var npc_table: Dictionary = DIALOGUES[npc_id]
	var status := str(quest.get("status", "active"))
	if npc_table.has(status):
		return (npc_table[status] as Dictionary).duplicate(true)
	return {"line_id": "generic_001", "text": "Hello."}
