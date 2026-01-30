extends Node
class_name StaggerComponent

## Tracks individual stagger damage for a combat entity (enemy or party member)

signal stagger_changed(current: float, max_val: float)
signal staggered_state_changed(is_staggered: bool)
signal pressured_state_changed(is_pressured: bool)

# Core stagger properties
@export var max_stagger: float = 100.0
@export var stagger_drain_rate: float = 2.0  # per second when draining normally
@export var stagger_duration: float = 60.0  # how long STAGGERED state lasts

var stagger_damage: float = 0.0
var is_staggered: bool = false
var is_pressured: bool = false
var is_off_balance: bool = false

# Stagger timer for recovering from staggered state
var stagger_timer: float = 0.0

# Multipliers
var pressured_stagger_multiplier: float = 1.5  # extra stagger damage when pressured
var pressured_drain_multiplier: float = 0.25  # slower drain when pressured
var off_balance_stagger_multiplier: float = 1.25  # extra stagger damage when off balance


func _ready() -> void:
	# Connect to stagger drain signal
	Events.stagger_should_drain.connect(_on_stagger_should_drain)


func apply_stagger_damage(amount: float) -> void:
	if is_staggered:
		return  # Can't take more stagger damage while staggered
	
	var actual_amount: float = amount
	
	# Apply multipliers
	if is_pressured:
		actual_amount *= pressured_stagger_multiplier
	if is_off_balance:
		actual_amount *= off_balance_stagger_multiplier
	
	stagger_damage = min(max_stagger, stagger_damage + actual_amount)
	stagger_changed.emit(stagger_damage, max_stagger)
	
	# Check if we've become staggered
	if stagger_damage >= max_stagger:
		_enter_staggered_state()


func _enter_staggered_state() -> void:
	if is_staggered:
		return
	
	is_staggered = true
	stagger_timer = stagger_duration
	staggered_state_changed.emit(true)
	
	# Clear pressured when staggered
	if is_pressured:
		set_pressured(false)


func _exit_staggered_state() -> void:
	if not is_staggered:
		return
	
	is_staggered = false
	stagger_damage = 0.0
	stagger_changed.emit(stagger_damage, max_stagger)
	staggered_state_changed.emit(false)


func set_pressured(pressured: bool) -> void:
	if is_pressured == pressured:
		return
	
	is_pressured = pressured
	pressured_state_changed.emit(is_pressured)


func set_off_balance(off_balance: bool) -> void:
	is_off_balance = off_balance


func _on_stagger_should_drain(delta: float) -> void:
	if is_staggered:
		# Count down stagger timer
		stagger_timer -= delta
		if stagger_timer <= 0:
			_exit_staggered_state()
	else:
		# Drain stagger damage
		if stagger_damage > 0:
			var drain_rate: float = stagger_drain_rate
			if is_pressured:
				drain_rate *= pressured_drain_multiplier
			
			stagger_damage = max(0.0, stagger_damage - drain_rate * delta)
			stagger_changed.emit(stagger_damage, max_stagger)
			
			# Clear pressured state if stagger drains to 0
			if stagger_damage <= 0 and is_pressured:
				set_pressured(false)


func get_stagger_percentage() -> float:
	return stagger_damage / max_stagger


func reset() -> void:
	stagger_damage = 0.0
	is_staggered = false
	is_pressured = false
	is_off_balance = false
	stagger_timer = 0.0
	stagger_changed.emit(stagger_damage, max_stagger)
	staggered_state_changed.emit(false)
	pressured_state_changed.emit(false)
