extends Node3D

#@onready var windmill: Node3D = $Level/Ground/Windmill

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.player_killed.connect(_on_player_killed)
	#_start_windmill_animation()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	pass
	
func _on_player_killed() -> void:
	get_tree().quit()


#func _start_windmill_animation() -> void:
	## Find AnimationPlayer in the windmill scene
	#var anim_player: AnimationPlayer = windmill.find_child("AnimationPlayer", true, false)
	#if anim_player:
		## Get the first animation and play it looped
		#var animations := anim_player.get_animation_list()
		#if animations.size() > 0:
			#var anim_name: String = animations[0]
			## Set the animation to loop
			#var animation := anim_player.get_animation(anim_name)
			#if animation:
				#animation.loop_mode = Animation.LOOP_LINEAR
			#anim_player.play(anim_name)
			#print("Playing windmill animation: ", anim_name)
		#else:
			#push_warning("Windmill has AnimationPlayer but no animations")
	#else:
		#push_warning("No AnimationPlayer found in Windmill")
