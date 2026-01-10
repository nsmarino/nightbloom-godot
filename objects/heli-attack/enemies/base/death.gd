extends AIMove


@export var death_timer : float = 3


func on_enter():
	Events.helicopter_destroyed.emit(character.global_position)
	character.player.Resources.gain_money(200)
	character.Sprite.visible = false
	character.HUD.visible = false
	character.ParticlesDeath.emitting = true	
	character.Collider.queue_free()
	character.WeaponSocket.queue_free()
	

func check_transition(delta) -> Array:
	if duration_longer_than(death_timer):
		character.queue_free()
	return [false, ""]
