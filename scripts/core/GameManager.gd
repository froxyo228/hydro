# ========== GameManager.gd ==========
# Основной менеджер игры - управляет состояниями, ресурсами и игровым процессом
extends Node

enum GameState {
	PLANNING,
	SURVEYING, 
	BUILDING,
	OPERATING,
	FAILED
}

signal game_state_changed(new_state)
signal resources_changed(money, reputation)
signal dam_built(dam)
signal dam_failed(dam)

# Состояние игры
var current_state: GameState = GameState.PLANNING

# Ресурсы
var money: int = 100000
var reputation: int = 50
var base_construction_cost: int = 50000

# Системы
var economic_system
var river_system
var build_controller

func _ready():
	print("[STATE] GameManager инициализирован")
	
	# Ждем полной инициализации всех узлов
	await get_tree().process_frame
	await get_tree().process_frame  # Дополнительный фрейм для HUD
	
	# Ждем, пока HUD появится в группе
	print("[STATE] Ожидаем инициализации HUD...")
	while get_tree().get_nodes_in_group("hud").size() == 0:
		await get_tree().process_frame
		print("[STATE] HUD еще не найден, ждем...")
	
	print("[STATE] HUD найден, начинаем подключение систем...")
	setup_system_connections()

## Настройка подключений к другим системам
func setup_system_connections():
	# Подключаемся к экономической системе
	economic_system = get_tree().get_first_node_in_group("economic_system")
	if economic_system and economic_system.has_signal("income_changed"):
		economic_system.income_changed.connect(_on_income_changed)
	
	# Подключаемся к системе строительства
	build_controller = get_node_or_null("/root/BuildController")
	if build_controller and build_controller.has_signal("build_confirmed"):
		build_controller.build_confirmed.connect(_on_build_confirmed)
	
	# Подключаемся к HUD для получения запросов пользователя
	var hud = get_tree().get_first_node_in_group("hud")
	print("[STATE] Подключение к HUD...")
	if hud:
		print("[STATE] HUD найден: ", hud.name)
		if hud.has_signal("survey_requested"):
			hud.survey_requested.connect(_on_survey_requested)
			print("[STATE] Сигнал survey_requested подключен")
		else:
			print("[STATE] ОШИБКА: HUD не имеет сигнала survey_requested!")
		
		if hud.has_signal("build_requested"):
			hud.build_requested.connect(_on_build_requested)
			print("[STATE] Сигнал build_requested подключен")
		else:
			print("[STATE] ОШИБКА: HUD не имеет сигнала build_requested!")
		
		print("[STATE] HUD подключен")
	else:
		print("[STATE] ОШИБКА: HUD не найден после ожидания!")
	
	print("[STATE] Системы подключены")

## Изменить состояние игры
func change_state(new_state: GameState):
	if current_state != new_state:
		current_state = new_state
		print("[STATE] Состояние -> %s" % GameState.keys()[new_state])
		game_state_changed.emit(new_state)

## Потратить деньги
func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		resources_changed.emit(money, reputation)
		print("[RESOURCE] Потрачено: %d, осталось: %d" % [amount, money])
		return true
	else:
		print("[RESOURCE] Недостаточно средств: нужно %d, есть %d" % [amount, money])
		return false

## Начать георазведку
func start_survey() -> bool:
	if current_state != GameState.PLANNING:
		print("[SURVEY] Георазведка недоступна в текущем состоянии")
		return false
	
	var survey_cost = 10000
	if not spend_money(survey_cost):
		return false
	
	change_state(GameState.SURVEYING)
	
	# Выполняем георазведку всех зон
	var zones = get_tree().get_nodes_in_group("build_zones")
	print("[SURVEY] Найдено зон для георазведки: ", zones.size())
	
	for zone in zones:
		print("[SURVEY] Обрабатываем зону: ", zone.zone_id)
		if zone.has_method("perform_survey"):
			zone.perform_survey()
			print("[SURVEY] Георазведка зоны ", zone.zone_id, " завершена")
		else:
			print("[SURVEY] ОШИБКА: зона ", zone.zone_id, " не имеет метода perform_survey")
	
	print("[SURVEY] Георазведка начата")
	
	# Автоматический возврат через 2 секунды
	await get_tree().create_timer(2.0).timeout
	print("[SURVEY] Георазведка завершена, возврат в PLANNING")
	change_state(GameState.PLANNING)
	
	return true

func _on_survey_completed():
	print("[SURVEY] Георазведка завершена")
	change_state(GameState.PLANNING)

func build_dam(build_zone, skip_survey: bool = false) -> bool:
	if current_state != GameState.PLANNING:
		return false
	
	var construction_cost = calculate_construction_cost(build_zone)
	
	if not spend_money(construction_cost):
		print("[BUILD] Недостаточно средств для строительства")
		return false
	
	# Создаем плотину
	var dam_scene = preload("res://scenes/dam.tscn")
	var dam = dam_scene.instantiate()
	dam.initialize(build_zone, not skip_survey)
	
	# Добавляем в сцену
	get_tree().current_scene.add_child(dam)
	
	print("[BUILD] Плотина построена в зоне %s" % build_zone.zone_id)
	change_state(GameState.BUILDING)
	
	# Переход в эксплуатацию через 2 секунды
	await get_tree().create_timer(2.0).timeout
	change_state(GameState.OPERATING)
	dam.start_operation()
	
	return true

func calculate_construction_cost(build_zone) -> int:
	# Базовая стоимость + модификаторы от сложности местности
	var cost = base_construction_cost
	cost += build_zone.difficulty_modifier * 10000
	return cost

func _on_income_changed(new_income):
	money += new_income
	resources_changed.emit(money, reputation)

## Обработчик запроса на георазведку от HUD
func _on_survey_requested():
	print("[SURVEY] Получен запрос на георазведку от HUD")
	print("[SURVEY] Вызываем start_survey()")
	start_survey()
	print("[SURVEY] start_survey() завершен")

## Обработчик запроса на строительство от HUD
func _on_build_requested(material: int):
	print("[BUILD] Получен запрос на строительство с материалом %d от HUD" % material)
	if build_controller:
		print("[BUILD] BuildController найден, вызываем start_preview")
		build_controller.start_preview(material)
		print("[BUILD] start_preview вызван")
	else:
		print("[BUILD] ОШИБКА: BuildController не найден!")

## Обработка подтверждения строительства от BuildController
func _on_build_confirmed(position: Vector2, material: int):
	print("[BUILD] Подтверждение строительства в позиции %s с материалом %d" % [position, material])
	
	# [Cursor] Пробуем найти BuildZone, но если нет - строим виртуальную
	var build_zone = find_build_zone_at_position(position)
	if not build_zone:
		build_zone = create_virtual_build_zone(position)
	
	# [Cursor] Строим плотину с выбранным материалом
	build_dam_with_material(build_zone, material)

func find_build_zone_at_position(position: Vector2):
	var build_zones = get_tree().get_nodes_in_group("build_zones")
	var min_distance = 100.0  # Максимальное расстояние для поиска
	var closest_zone = null
	
	for zone in build_zones:
		var distance = zone.global_position.distance_to(position)
		if distance < min_distance:
			min_distance = distance
			closest_zone = zone
	
	return closest_zone

# [Cursor] Создать виртуальную зону для строительства где угодно
func create_virtual_build_zone(position: Vector2):
	var virtual_zone = preload("res://scenes/build/build_zone.tscn").instantiate()
	virtual_zone.global_position = position
	virtual_zone.zone_id = "virtual_" + str(Time.get_unix_time_from_system())
	virtual_zone.is_surveyed = false  # Без георазведки - будет быстрее ломаться
	virtual_zone.geological_stability = 0.5  # Средняя стабильность
	virtual_zone.difficulty_modifier = 2.0  # Дороже строить
	virtual_zone.power_potential = 80.0  # Меньше потенциала
	virtual_zone.is_occupied = false
	
	# Добавляем в группу build_zones
	virtual_zone.add_to_group("build_zones")
	
	print("[BUILD] Виртуальная зона создана: ", virtual_zone.zone_id)
	return virtual_zone

func build_dam_with_material(build_zone, material: int) -> bool:
	if current_state != GameState.PLANNING:
		return false
	
	var construction_cost = calculate_construction_cost(build_zone)
	
	if not spend_money(construction_cost):
		print("[BUILD] Недостаточно средств для строительства")
		return false
	
	# Создаем плотину с материалом
	var dam_scene = preload("res://scenes/dam.tscn")
	var dam = dam_scene.instantiate()
	dam.initialize(build_zone, build_zone.is_surveyed, material)
	
	# Добавляем в сцену
	get_tree().current_scene.add_child(dam)
	
	print("[BUILD] Плотина построена в зоне %s с материалом %d" % [build_zone.zone_id, material])
	
	# [Cursor] Помечаем зону как занятую
	if build_zone.has_method("occupy"):
		build_zone.occupy()
		print("[BUILD] Зона ", build_zone.zone_id, " занята")
	else:
		# [Cursor] Fallback для виртуальных зон
		build_zone.is_occupied = true
		if build_zone.has_method("update_zone_visual"):
			# Проверяем, что zone_visual существует
			if build_zone.zone_visual:
				build_zone.update_zone_visual()
			else:
				print("[BUILD] Виртуальная зона не имеет zone_visual, пропускаем обновление")
		print("[BUILD] Виртуальная зона помечена как занятой")
	
	change_state(GameState.OPERATING)
	dam.start_operation()
	
	return true

## Получить систему реки (для HUD)
func get_river_system():
	if not river_system:
		river_system = get_tree().get_first_node_in_group("river_system")
	return river_system
