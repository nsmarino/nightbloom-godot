extends Node

enum Phase {
	START,
	PLAY,
	END,
}

# Game signals
signal helicopter_destroyed(loc: Vector3)
signal player_killed
signal phase_changed(phase: Phase)

# Combat phase signals
signal combat_started
signal turn_intro_started(is_player_turn: bool)  # Turn intro phase begins (everyone idles)
signal turn_intro_ended(is_player_turn: bool)    # Turn intro phase ends (turn begins)
signal turn_started(is_player_turn: bool)        # Actual turn gameplay begins
signal turn_ended(is_player_turn: bool)
signal combat_paused(paused: bool)
signal combat_ended(player_won: bool)

# Player resource signals
signal player_hp_changed(current: int, max_val: int)
signal player_mp_changed(current: int, max_val: int)
signal player_ap_changed(current: int, max_val: int)
signal player_damaged(amount: int)

# Enemy resource signals
signal enemy_hp_changed(current: int, max_val: int)
signal enemy_damaged(amount: int)

# Turn bar signal
signal turn_timer_updated(time_remaining: float, turn_duration: float)

# Combat action signals
signal attack_hit(attacker: Node, target: Node, damage: int)
signal player_state_changed(new_state: String)
signal enemy_state_changed(enemy: Node, new_state: String)

func _ready() -> void:
	print("Init autoload events")
