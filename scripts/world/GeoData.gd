# ========== GeoData.gd ==========
# [Cursor] Провайдер геоданных - читает существующие BuildZone
extends Node

func _ready():
	add_to_group("geo_data")

# [Cursor] Получить коэффициент почвы в позиции
# Сначала проверяем BuildZone, если нет - возвращаем 1.0
func get_soil_coefficient(position: Vector2) -> float:
	var build_zones = get_tree().get_nodes_in_group("build_zones")
	
	for zone in build_zones:
		if zone.has_method("get_rect") and zone.get_rect().has_point(position - zone.global_position):
			# [Cursor] Если зона разведана, возвращаем её коэффициент
			if zone.is_surveyed:
				return zone.geological_stability
			else:
				# [Cursor] Неразведанная зона - базовый коэффициент
				return 1.0
	
	# [Cursor] Если не попали ни в одну зону - возвращаем 1.0
	return 1.0

# [Cursor] Проверить, есть ли георазведка в позиции
func has_survey(position: Vector2) -> bool:
	var build_zones = get_tree().get_nodes_in_group("build_zones")
	
	for zone in build_zones:
		if zone.has_method("get_rect") and zone.get_rect().has_point(position - zone.global_position):
			return zone.is_surveyed
	
	return false

# [Cursor] Получить ближайшую безопасную позицию для строительства
func get_nearest_build_position(target_position: Vector2) -> Vector2:
	var build_zones = get_tree().get_nodes_in_group("build_zones")
	var nearest_position = target_position
	var min_distance = 1000.0
	
	for zone in build_zones:
		if not zone.is_occupied:
			var distance = target_position.distance_to(zone.global_position)
			if distance < min_distance:
				min_distance = distance
				nearest_position = zone.global_position
	
	return nearest_position
