# ========== AdvancedHUD.gd ==========
# Продвинутый интерфейс игры - управляет отображением информации и взаимодействием с пользователем
extends CanvasLayer

# Сигналы для взаимодействия с игровыми системами
signal survey_requested
signal build_requested(material: int)
signal material_selected(material_type: int)

var selected_build_zone = null
var selected_material: int = 0
var dam_info_widgets: Array = []

# UI узлы
@onready var money_label = $MainInterface/TopPanel/ResourcesContainer/MoneyLabel
@onready var reputation_label = $MainInterface/TopPanel/ResourcesContainer/ReputationLabel
@onready var state_label = $MainInterface/TopPanel/StatusContainer/StateLabel
@onready var weather_label = $MainInterface/TopPanel/StatusContainer/WeatherLabel
@onready var survey_button = $MainInterface/LeftPanel/ActionPanel/SurveyButton
@onready var build_button = $MainInterface/LeftPanel/ActionPanel/BuildButton
@onready var material_option = $MainInterface/LeftPanel/MaterialPanel/MaterialOption
@onready var dam_list = $MainInterface/RightPanel/DamInfoPanel/ScrollContainer/DamList
@onready var river_flow_label = $MainInterface/InfoPanel/InfoContainer/RiverFlowLabel
@onready var total_power_label = $MainInterface/RightPanel/DamInfoPanel/TotalPowerLabel
@onready var event_dialog = $EventDialog
@onready var event_title = $EventDialog/VBox/EventTitle
@onready var event_description = $EventDialog/VBox/EventDescription
@onready var choices_container = $EventDialog/VBox/ChoicesContainer
@onready var current_strength_label = $MainInterface/LeftPanel/StrengthPanel/CurrentStrengthLabel
@onready var planned_strength_label = $MainInterface/LeftPanel/StrengthPanel/PlannedStrengthLabel

func _ready():
	print("[UI] AdvancedHUD _ready() начат")
	
	# Ждем полной инициализации
	await get_tree().process_frame
	
	add_to_group("hud")
	print("[UI] Добавлен в группу 'hud'")
	
	# Проверяем, что действительно добавлен в группу
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	print("[UI] Всего узлов в группе 'hud': ", hud_nodes.size())
	for node in hud_nodes:
		print("[UI] Узел в группе 'hud': ", node.name, " (", node.get_class(), ")")
	
	setup_connections()
	setup_material_options()
	update_all_ui()
	
	# Подключаемся к BuildController для превью
	await get_tree().process_frame
	var build_controller = get_node_or_null("/root/BuildController")
	if build_controller:
		build_controller.preview_moved.connect(_on_preview_moved)
		build_controller.preview_started.connect(_on_preview_started)
		build_controller.preview_ended.connect(_on_preview_ended)
		print("[UI] BuildController подключен")
	else:
		print("[UI] BuildController не найден")
	
	print("[UI] AdvancedHUD инициализирован")

## Настройка подключений к игровым системам
func setup_connections():
	# Подключаемся к GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		if game_manager.has_signal("resources_changed"):
			game_manager.resources_changed.connect(_on_resources_changed)
		if game_manager.has_signal("game_state_changed"):
			game_manager.game_state_changed.connect(_on_game_state_changed)
		if game_manager.has_signal("dam_built"):
			game_manager.dam_built.connect(_on_dam_built)
		if game_manager.has_signal("dam_failed"):
			game_manager.dam_failed.connect(_on_dam_failed)
		print("[UI] Подключен к GameManager")
	else:
		print("[UI] ОШИБКА: GameManager не найден!")
	
	# Подключаем кнопки
	if survey_button:
		survey_button.pressed.connect(_on_survey_pressed)
		print("[UI] Кнопка георазведки подключена")
	if build_button:
		build_button.pressed.connect(_on_build_pressed)
		print("[UI] Кнопка строительства подключена")
	if material_option:
		material_option.item_selected.connect(_on_material_selected)
		print("[UI] Выбор материала подключен")
	
	# Подключаемся к зонам строительства
	await get_tree().process_frame
	for zone in get_tree().get_nodes_in_group("build_zones"):
		if zone.has_signal("zone_selected"):
			zone.zone_selected.connect(_on_zone_selected)
			print("[UI] Зона ", zone.zone_id, " подключена")

## Настройка опций материалов в выпадающем списке
func setup_material_options():
	if not material_option:
		print("[UI] ОШИБКА: material_option не найден!")
		return
	
	material_option.clear()
	print("[UI] Настройка материалов...")
	
	# Ждем инициализации MaterialSystem
	await get_tree().process_frame
	var material_system = get_node_or_null("/root/MaterialSystem")
	if material_system:
		print("[UI] MaterialSystem найден, загружаем материалы...")
		var materials = material_system.get_all_materials()
		print("[UI] Найдено материалов: ", materials.size())
		for material in materials:
			material_option.add_item(material.name)
			print("[UI] Добавлен материал: ", material.name)
	else:
		print("[UI] ОШИБКА: MaterialSystem не найден!")
		# Добавляем заглушки для тестирования
		material_option.add_item("Дерево")
		material_option.add_item("Земляная насыпь")
		material_option.add_item("Камень")
		material_option.add_item("Сталь")
		material_option.add_item("Бетон")
		print("[UI] Добавлены заглушки материалов")

## Обновить весь интерфейс
func update_all_ui():
	update_resources()
	update_game_state()
	update_button_states()
	update_dam_list()

## Обновить отображение ресурсов
func update_resources():
	if GameManager:
		if money_label:
			money_label.text = "Деньги: " + str(GameManager.money) + " руб"
		if reputation_label:
			reputation_label.text = "Репутация: " + str(GameManager.reputation)

## Обновить отображение состояния игры
func update_game_state():
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and state_label:
		var state_names = ["Планирование", "Георазведка", "Строительство", "Эксплуатация", "Авария"]
		state_label.text = "Состояние: " + state_names[game_manager.current_state]
	else:
		if state_label:
			state_label.text = "Состояние: Планирование"

## Обновить состояние кнопок
func update_button_states():
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		# Если GameManager не найден, активируем кнопки для тестирования
		if survey_button:
			survey_button.disabled = false
		if build_button:
			build_button.disabled = false
		return
	
	var can_survey = game_manager.current_state == game_manager.GameState.PLANNING
	var can_build = game_manager.current_state == game_manager.GameState.PLANNING
	
	# Проверяем наличие свободных зон для строительства
	if can_build:
		var has_free_zones = false
		for zone in get_tree().get_nodes_in_group("build_zones"):
			if not zone.is_occupied:
				has_free_zones = true
				break
		can_build = has_free_zones
	
	if survey_button:
		survey_button.disabled = not can_survey
	if build_button:
		build_button.disabled = not can_build

## Обновить список плотин
func update_dam_list():
	if not dam_list:
		return
	
	# Очищаем старые виджеты
	for widget in dam_info_widgets:
		if is_instance_valid(widget):
			widget.queue_free()
	dam_info_widgets.clear()
	
	# Добавляем новые виджеты для каждой плотины
	for dam in get_tree().get_nodes_in_group("dams"):
		var widget = preload("res://scenes/DamInfoWidget.tscn").instantiate()
		widget.setup_dam_info(dam)
		dam_list.add_child(widget)
		dam_info_widgets.append(widget)

## Обработчик нажатия кнопки георазведки
func _on_survey_pressed():
	print("[UI] Запрос на георазведку")
	print("[UI] Эмитим сигнал survey_requested")
	survey_requested.emit()
	print("[UI] Сигнал survey_requested эмитнут")

## Обработчик нажатия кнопки строительства
func _on_build_pressed():
	var build_controller = get_node_or_null("/root/BuildController")
	if not build_controller:
		print("[UI] ОШИБКА: BuildController не найден!")
		return
	
	if build_controller.current_state == build_controller.State.PREVIEW:
		# Если уже в режиме превью - подтверждаем строительство
		build_controller.confirm_build()
		print("[UI] Подтверждение строительства")
	else:
		# Начинаем режим превью
		print("[UI] Запрос на строительство с материалом %d" % selected_material)
		print("[UI] Эмитим сигнал build_requested")
		build_requested.emit(selected_material)
		print("[UI] Сигнал build_requested эмитнут")

## Обработчик выбора материала
func _on_material_selected(index: int):
	selected_material = index
	material_selected.emit(index)
	print("[UI] Выбран материал: %d" % index)

## Обработчик выбора зоны строительства
func _on_zone_selected(zone):
	selected_build_zone = zone
	print("[UI] Выбрана зона: %s" % zone.zone_id)
	update_button_states()

## Обработчик изменения ресурсов
func _on_resources_changed(money: int, reputation: int):
	update_resources()

## Обработчик изменения состояния игры
func _on_game_state_changed(new_state):
	update_game_state()
	update_button_states()

## Обработчик постройки плотины
func _on_dam_built(dam):
	update_dam_list()
	print("[UI] Плотина построена, обновляем интерфейс")

## Обработчик аварии плотины
func _on_dam_failed(dam):
	update_dam_list()
	print("[UI] Авария плотины, обновляем интерфейс")

## Обработчик изменения потока реки
func _on_river_flow_changed(new_flow):
	if river_flow_label:
		river_flow_label.text = "Поток реки: " + str(int(new_flow)) + " м³/с"

## Обработчики превью строительства
func _on_preview_started():
	print("[UI] Превью строительства начато")
	if build_button:
		build_button.text = "Подтвердить"

func _on_preview_ended():
	print("[UI] Превью строительства завершено")
	if build_button:
		build_button.text = "Построить плотину"
	update_button_states()

func _on_preview_moved(position: Vector2, planned_strength: float):
	if planned_strength_label:
		planned_strength_label.text = "Планируемая прочность: %.0f" % planned_strength

## Обновить интерфейс после загрузки игры
func refresh():
	update_all_ui()
	print("[UI] Интерфейс обновлен после загрузки")

## Показать диалог события
func show_event_dialog(title: String, description: String, choices: Array):
	if not event_dialog:
		return
	
	event_title.text = title
	event_description.text = description
	
	# Очищаем старые кнопки выбора
	for child in choices_container.get_children():
		child.queue_free()
	
	# Добавляем новые кнопки
	for i in range(choices.size()):
		var button = Button.new()
		button.text = choices[i]
		button.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(button)
	
	event_dialog.show()

## Обработчик выбора в диалоге события
func _on_choice_selected(choice_index: int):
	event_dialog.hide()
	print("[UI] Выбор в событии: %d" % choice_index)
