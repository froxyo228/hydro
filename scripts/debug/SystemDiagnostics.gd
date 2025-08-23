# ========== SystemDiagnostics.gd ==========
# [Cursor] Диагностика систем для тестирования
extends Node

func _ready():
	print("=== ДИАГНОСТИКА СИСТЕМ HYDROSIM 2.0 ===")
	
	# Проверяем автолоады
	check_autoloads()
	
	# Проверяем системы в группах
	await get_tree().process_frame
	check_systems()
	
	print("=== ДИАГНОСТИКА ЗАВЕРШЕНА ===")

func check_autoloads():
	print("\n🔧 Проверка автолоадов:")
	
	var autoloads = [
		"GameManager",
		"ConfigManager", 
		"BuildController",
		"MaterialSystem",
		"GeoData"
	]
	
	for autoload_name in autoloads:
		var node = get_node_or_null("/root/" + autoload_name)
		if node:
			print("  ✅ %s: OK" % autoload_name)
		else:
			print("  ❌ %s: НЕ НАЙДЕН" % autoload_name)

func check_systems():
	print("\n🏗️ Проверка систем в группах:")
	
	var systems = {
		"material_system": "MaterialSystem",
		"build_controller": "BuildController", 
		"geo_data": "GeoData",
		"river_system": "RiverSystem",
		"weather_system": "WeatherSystem",
		"economic_system": "EconomicSystem",
		"save_system": "SaveSystem",
		"hud": "AdvancedHUD",
		"dam_preview": "DamPreview"
	}
	
	for group_name in systems:
		var nodes = get_tree().get_nodes_in_group(group_name)
		if nodes.size() > 0:
			print("  ✅ %s: %d узел(ов)" % [systems[group_name], nodes.size()])
		else:
			print("  ❌ %s: НЕ НАЙДЕН в группе '%s'" % [systems[group_name], group_name])
	
	# Проверяем материалы
	check_materials()
	
	# Проверяем зоны строительства
	check_build_zones()

func check_materials():
	print("\n🧱 Проверка материалов:")
	
	var material_system = get_tree().get_first_node_in_group("material_system")
	if material_system:
		var materials = material_system.get_all_materials()
		print("  📦 Найдено материалов: %d" % materials.size())
		
		for material in materials:
			var base_strength = material_system.get_base_strength(material.type)
			print("    - %s: прочность %d" % [material.name, base_strength])
	else:
		print("  ❌ MaterialSystem не найден")

func check_build_zones():
	print("\n🏗️ Проверка зон строительства:")
	
	var zones = get_tree().get_nodes_in_group("build_zones")
	print("  🎯 Найдено зон: %d" % zones.size())
	
	var surveyed = 0
	var occupied = 0
	
	for zone in zones:
		if zone.is_surveyed:
			surveyed += 1
		if zone.is_occupied:
			occupied += 1
	
	print("    - Разведанных: %d" % surveyed)
	print("    - Занятых: %d" % occupied)
