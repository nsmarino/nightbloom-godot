extends BaseWeapon

var _autofire_enabled: bool = true
var _autofire_timer: float = 0.0
var _autofire_interval: float = 0.1  # time between autofire shots

func _physics_process(delta: float) -> void:
	
	if _autofire_enabled:
		_autofire_timer -= delta
		if _autofire_timer <= 0.0:
			_autofire()
			_autofire_timer = _autofire_interval

func _autofire() -> void:
	try_fire()

func set_autofire(enabled: bool) -> void:
	_autofire_enabled = enabled
	if enabled:
		_autofire_timer = 0.0  # fire immediately when enabled
