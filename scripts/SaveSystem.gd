# ========== SaveSystem.gd ==========
# [Cursor] Система сохранения/загрузки
extends Node

const SAVE_FILE = "user://hydrosim_save.dat"

func _ready():
	add_to_group("save_system")

func save_game() -> bool:
	var save_file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if save_file == null:
		print("Ошибка создания файла сохранения")
		return false
	var save_data = {}
	if GameManager:
		save_data["game_manager"] = {
			"money": GameManager.money,
			"reputation": GameManager.reputation,
			"current_state": GameManager.current_state
		}
	save_data["dams"] = []
	if GameManager and GameManager.built_dams:
		for dam in GameManager.built_dams:
			save_data["dams"].append({
				"position": var_to_str(dam.global_position),
				"structural_integrity": dam.structural_integrity,
				"was_surveyed": dam.was_surveyed,
				"operational_time": dam.operational_time,
				# [Cursor] Сохраняем новые поля
				"material_type": dam.material_type,
				"current_strength": dam.current_strength,
				"max_strength": dam.max_strength
			})
	save_data["build_zones"] = []
	for zone in get_tree().get_nodes_in_group("build_zones"):
		save_data["build_zones"].append({
			"zone_id": zone.zone_id,
			"is_surveyed": zone.is_surveyed,
			"is_occupied": zone.is_occupied,
			"is_safe": zone.is_safe
		})
	# [Cursor] Сохраняем состояние RiverSystem
	save_data["river_system"] = {}
	var river_system = get_tree().get_first_node_in_group("river_system")
	if river_system:
		save_data["river_system"]["current_flow"] = river_system.current_flow
		save_data["river_system"]["weather_factor"] = river_system.weather_factor
		save_data["river_system"]["time_elapsed"] = river_system.time_elapsed
	
	save_data["timestamp"] = Time.get_unix_time_from_system()
	save_file.store_string(JSON.stringify(save_data))
	save_file.close()
	print("Игра сохранена")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE):
		print("Файл сохранения не найден")
		return false
	var save_file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if save_file == null:
		print("Ошибка чтения файла сохранения")
		return false
	var save_data_text = save_file.get_as_text()
	save_file.close()
	var json = JSON.new()
	var parse_result = json.parse(save_data_text)
	if parse_result != OK:
		print("Ошибка парсинга файла сохранения")
		return false
	var save_data = json.data
	if save_data.has("game_manager") and GameManager:
		var gm_data = save_data["game_manager"]
		GameManager.money = gm_data.get("money", 100000)
		GameManager.reputation = gm_data.get("reputation", 50)
		GameManager.current_state = gm_data.get("current_state", GameManager.GameState.PLANNING)
	if save_data.has("build_zones"):
		var zones_data = save_data["build_zones"]
		var zones = get_tree().get_nodes_in_group("build_zones")
		for i in range(min(zones_data.size(), zones.size())):
			var zone_data = zones_data[i]
			var zone = zones[i]
			zone.is_surveyed = zone_data.get("is_surveyed", false)
			zone.is_occupied = zone_data.get("is_occupied", false)
			zone.is_safe = zone_data.get("is_safe", false)
			zone.update_visual()
	
	# [Cursor] Загружаем состояние RiverSystem
	if save_data.has("river_system"):
		var river_system = get_tree().get_first_node_in_group("river_system")
		if river_system:
			var rs_data = save_data["river_system"]
			river_system.current_flow = rs_data.get("current_flow", 100.0)
			river_system.weather_factor = rs_data.get("weather_factor", 1.0)
			river_system.time_elapsed = rs_data.get("time_elapsed", 0.0)
	
	print("Игра загружена")
	return true

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

