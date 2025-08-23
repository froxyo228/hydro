# ========== GameManager.gd ==========
# Главный менеджер игры - управляет состоянием игры, ресурсами и прогрессом
extends Node

signal game_state_changed(new_state)
signal resources_changed(money, reputation)
signal dam_built(location)
signal dam_failed(location, reason)

enum GameState {
	PLANNING,    # Планирование - выбор места
	SURVEYING,   # Георазведка
	BUILDING,    # Строительство
	OPERATING,   # Эксплуатация
	FAILED       # Провал проекта
}

# Игровые ресурсы
@export var money: int = 100000
@export var reputation: int = 50  # От 0 до 100
@export var current_state: GameState = GameState.PLANNING

# Конфигурация игры
@export var survey_cost: int = 5000
@export var base_construction_cost: int = 50000

var current_level: Node = null
var built_dams: Array[Dam] = []
var economic_system = null
# [Cursor] Ссылки на новые системы
var river_system = null
var build_controller = null

func _ready():
	# Подключаемся к сигналам уровня
	if get_tree().get_first_node_in_group("level"):
		current_level = get_tree().get_first_node_in_group("level")
		current_level.connect("survey_completed", _on_survey_completed)
	
	# Подключаемся к системам
	await get_tree().process_frame
	economic_system = get_tree().get_first_node_in_group("economic_system")
	river_system = get_tree().get_first_node_in_group("river_system")
	build_controller = get_tree().get_first_node_in_group("build_controller")
	
	# [Cursor] Подключаемся к сигналам BuildController
	if build_controller:
		build_controller.build_confirmed.connect(_on_build_confirmed)

func change_state(new_state: GameState):
	current_state = new_state
	game_state_changed.emit(new_state)
	print("Состояние игры изменено на: ", GameState.keys()[new_state])

func can_afford(cost: int) -> bool:
	return money >= cost

func spend_money(amount: int) -> bool:
	if can_afford(amount):
		money -= amount
		resources_changed.emit(money, reputation)
		return true
	return false

func change_reputation(delta: int):
	reputation = clamp(reputation + delta, 0, 100)
	resources_changed.emit(money, reputation)

func start_survey() -> bool:
	if current_state != GameState.PLANNING:
		return false
	
	if spend_money(survey_cost):
		change_state(GameState.SURVEYING)
		return true
	return false

func _on_survey_completed():
	print("Георазведка завершена")
	change_state(GameState.PLANNING)

func build_dam(build_zone: BuildZone, skip_survey: bool = false) -> bool:
	if current_state != GameState.PLANNING:
		return false
	
	var construction_cost = calculate_construction_cost(build_zone)
	
	if not spend_money(construction_cost):
		return false
	
	change_state(GameState.BUILDING)
	
	# Создаем новую плотину
	var dam = Dam.new()
	dam.initialize(build_zone, skip_survey)
	built_dams.append(dam)
	
	# Добавляем в сцену
	if current_level:
		current_level.add_child(dam)
	
	dam_built.emit(build_zone.global_position)
	
	# Запускаем строительство (можно добавить анимацию/таймер)
	await get_tree().create_timer(2.0).timeout
	
	change_state(GameState.OPERATING)
	dam.start_operation()
	
	return true

func calculate_construction_cost(build_zone: BuildZone) -> int:
	# Базовая стоимость + модификаторы от сложности местности
	var cost = base_construction_cost
	cost += build_zone.difficulty_modifier * 10000
	return cost

# [Cursor] Новые методы для работы с BuildController
func _on_build_confirmed(position: Vector2, material: int):
	print("[Cursor] Строительство подтверждено в позиции: ", position, " материал: ", material)
	
	# [Cursor] Находим ближайшую BuildZone
	var build_zone = find_build_zone_at_position(position)
	if not build_zone:
		print("[Cursor] Ошибка: не найдена BuildZone в позиции")
		return
	
	# [Cursor] Строим плотину с выбранным материалом
	build_dam_with_material(build_zone, material)

func find_build_zone_at_position(position: Vector2) -> BuildZone:
	var build_zones = get_tree().get_nodes_in_group("build_zones")
	var min_distance = 100.0  # Максимальное расстояние для поиска
	var closest_zone = null
	
	for zone in build_zones:
		var distance = position.distance_to(zone.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_zone = zone
	
	return closest_zone

func build_dam_with_material(build_zone: BuildZone, material: int) -> bool:
	if current_state != GameState.PLANNING:
		return false
	
	var construction_cost = calculate_construction_cost(build_zone)
	
	if not spend_money(construction_cost):
		print("[Cursor] Недостаточно денег для строительства")
		return false
	
	change_state(GameState.BUILDING)
	
	# [Cursor] Создаем новую плотину с материалом
	var dam = Dam.new()
	dam.initialize(build_zone, build_zone.is_surveyed, material)
	built_dams.append(dam)
	
	# Добавляем в сцену
	if current_level:
		current_level.add_child(dam)
	
	dam_built.emit(build_zone.global_position)
	
	# Запускаем строительство (можно добавить анимацию/таймер)
	await get_tree().create_timer(2.0).timeout
	
	# [Cursor] Занимаем зону после успешного строительства
	if build_zone and build_zone.has_method("occupy"):
		build_zone.occupy()
		print("[Build] Зона ", build_zone.zone_id, " занята")
	elif build_zone:
		build_zone.is_occupied = true
		if build_zone.has_method("update_visual"):
			build_zone.update_visual()
		print("[Build] Зона ", build_zone.zone_id, " помечена как занятая")
	
	change_state(GameState.OPERATING)
	dam.start_operation()
	
	return true

# [Cursor] API для доступа к RiverSystem из HUD
func get_river_system():
	return river_system
