extends CanvasLayer

@export var Player: CharacterBody3D
@export var EnemyTracker: Marker3D

# Player Resources
@onready var healthBar: TextureProgressBar = $PlayerBars/Health
@onready var jumpBar: TextureProgressBar = $PlayerBars/Jump
@onready var specialBar: TextureProgressBar = $PlayerBars/Special

# Weapon
@onready var reloadBar: TextureProgressBar = $Reload
@onready var weaponLabel: Label = $WeaponData/WeaponName
@onready var weaponAmmoCount: Label = $WeaponData/WeaponAmmo/WeaponAmmoCount


# Game progress
@onready var moneyLabel: Label = $ProgressData/Money
@onready var enemyCount: Label = $ProgressData/EnemyProgress/EnemyCount


func _ready() -> void:
	healthBar.max_value = Player.Resources.max_health
	healthBar.value = Player.Resources.health
	moneyLabel.text = "$ 0"
	enemyCount.text = "0"
	
	jumpBar.max_value = Player.Resources.max_jump
	jumpBar.value = Player.Resources.jump

	specialBar.max_value = Player.Resources.max_special
	specialBar.value = Player.Resources.special

	Player.update_player_reload.connect(on_update_player_reload)
	Player.update_equipped_weapon.connect(on_update_equipped_weapon)
	Player.update_ammo.connect(on_update_ammo)
	Player.Resources.update_player_health.connect(on_update_player_health)
	Player.Resources.update_player_money.connect(on_update_player_money)
	
	EnemyTracker.update_heli_count.connect(on_update_heli_count)

func on_update_player_health(health) -> void:
	healthBar.value = health

func on_update_player_reload(value) -> void:
	reloadBar.value = value
	
func on_update_equipped_weapon(_name, count) -> void:
	weaponLabel.text = _name
	weaponAmmoCount.text = "∞" if count == -1 else (str(count) + "x")

func on_update_ammo(count) -> void:
	weaponAmmoCount.text = str(count) + "x"
	
func on_update_player_money(value) -> void:
	moneyLabel.text = "$ " + str(value)
	
func on_update_heli_count(value) -> void:
	enemyCount.text = str(value)
