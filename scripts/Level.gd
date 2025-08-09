# ========== Level.gd ==========
# Основная сцена уровня
extends Node2D

signal survey_completed

@export var river_width: float = 200.0
@export var num_build_zones: int = 5

func _ready():
	add_to_group("level")
	generate_build_zones()

func generate_build_zones():
	# Создаем зоны строительства вдоль реки
	var river = $River
	var river_length = 800  # Длина реки
	var spacing = river_length / num_build_zones
	
	for i in range(num_build_zones):
		var zone = preload("res://scenes/build_zone.tscn").instantiate()  # Или создавай через код
		zone.zone_id = "zone_" + str(i)
		zone.position = Vector2(i * spacing - river_length/2, randf_range(-50, 50))
		
		# Случайные характеристики
		zone.difficulty_modifier = randi() % 6
		zone.power_potential = randf_range(50, 150)
		zone.geological_stability = randf_range(0.3, 1.0)
		
		zone.add_to_group("build_zones")
		river.add_child(zone)
