# ========== Level.gd ==========
# Основная сцена уровня
extends Node2D

signal survey_completed

@export var river_width: float = 200.0
@export var num_build_zones: int = 5

func _ready():
	add_to_group("level")
	generate_build_zones()
	setup_systems()

func generate_build_zones():
	# [Cursor] Создаем зоны строительства в удобных местах вокруг реки (которая теперь в центре)
	var river = $River
	var river_pos = river.position  # (576, 324)
	
	# [Cursor] Предустановленные позиции зон для удобного тестирования
	var zone_configs = [
		{"id": "zone_1", "pos": Vector2(-200, 0), "power": 120.0, "stability": 0.8, "surveyed": false, "safe": false},
		{"id": "zone_2", "pos": Vector2(0, -100), "power": 100.0, "stability": 0.9, "surveyed": false, "safe": false},
		{"id": "zone_3", "pos": Vector2(200, 0), "power": 80.0, "stability": 0.6, "surveyed": false, "safe": false},
		{"id": "zone_4", "pos": Vector2(0, 100), "power": 150.0, "stability": 0.4, "surveyed": false, "safe": false}
	]
	
	for i in range(min(zone_configs.size(), num_build_zones)):
		var config = zone_configs[i]
		var zone = preload("res://scenes/build/build_zone.tscn").instantiate()
		zone.zone_id = config.id
		zone.position = river_pos + config.pos  # Относительно реки
		
		# Настраиваем характеристики
		zone.power_potential = config.power
		zone.geological_stability = config.stability
		zone.is_surveyed = config.get("surveyed", false)
		zone.is_safe = config.get("safe", false)
		zone.difficulty_modifier = int((1.0 - config.stability) * 5)
		
		zone.add_to_group("build_zones")
		river.add_child(zone)

func setup_systems():
	# [Cursor] Создаем и добавляем новые системы
	var river_system = preload("res://scripts/systems/RiverSystem.gd").new()
	river_system.add_to_group("river_system")
	add_child(river_system)
	
	var weather_system = preload("res://scripts/systems/WeatherSystem.gd").new()
	weather_system.add_to_group("weather_system")
	add_child(weather_system)
	
	# [Cursor] EventSystem отключен - не создаем
	# var event_system = preload("res://scripts/EventSystem.gd").new()
	# add_child(event_system)
	
	var economic_system = preload("res://scripts/systems/EconomicSystem.gd").new()
	economic_system.add_to_group("economic_system")
	add_child(economic_system)
	
	var save_system = preload("res://scripts/systems/SaveSystem.gd").new()
	save_system.add_to_group("save_system")
	add_child(save_system)
