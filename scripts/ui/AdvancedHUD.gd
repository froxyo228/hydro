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
@onready var total_power_label = $MainInterface/InfoPanel/InfoContainer/TotalPowerLabel
@onready var event_dialog = $EventDialog
@onready var event_title = $EventDialog/VBox/EventTitle
@onready var event_description = $EventDialog/VBox/EventDescription
@onready var choices_container = $EventDialog/VBox/ChoicesContainer
@onready var current_strength_label = $MainInterface/LeftPanel/StrengthPanel/CurrentStrengthLabel
@onready var planned_strength_label = $MainInterface/LeftPanel/StrengthPanel/PlannedStrengthLabel

func _ready():
	add_to_group("hud")
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
	
	print("[UI] AdvancedHUD инициализирован")

## Настройка подключений к игровым системам
func setup_connections():
	if GameManager:
		GameManager.resources_changed.connect(_on_resources_changed)
		GameManager.game_state_changed.connect(_on_game_state_changed)
		GameManager.dam_built.connect(_on_dam_built)
		GameManager.dam_failed.connect(_on_dam_failed)
	
	if survey_button:
		survey_button.pressed.connect(_on_survey_pressed)
	if build_button:
		build_button.pressed.connect(_on_build_pressed)
	if material_option:
		material_option.item_selected.connect(_on_material_selected)
	
	# Подключаемся к зонам строительства
	for zone in get_tree().get_nodes_in_group("build_zones"):
		if zone.has_signal("zone_selected"):
			zone.zone_selected.connect(_on_zone_selected)

## Настройка опций материалов в выпадающем списке
func setup_material_options():
	if not material_option:
		return
	
	material_option.clear()
	var material_system = get_node_or_null("/root/MaterialSystem")
	if material_system:
		var materials = material_system.get_all_materials()
		for material in materials:
			material_option.add_item(material.name)

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
	if GameManager and state_label:
		var state_names = ["Планирование", "Георазведка", "Строительство", "Эксплуатация", "Авария"]
		state_label.text = "Состояние: " + state_names[GameManager.current_state]

## Обновить состояние кнопок
func update_button_states():
	if not GameManager:
		return
	
	var can_survey = GameManager.current_state == GameManager.GameState.PLANNING
	var can_build = GameManager.current_state == GameManager.GameState.PLANNING
	
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
	survey_requested.emit()

## Обработчик нажатия кнопки строительства
func _on_build_pressed():
	var build_controller = get_node_or_null("/root/BuildController")
	if not build_controller:
		return
	
	if build_controller.current_state == build_controller.State.PREVIEW:
		# Если уже в режиме превью - подтверждаем строительство
		build_controller.confirm_build()
		print("[UI] Подтверждение строительства")
	else:
		# Начинаем режим превью
		print("[UI] Запрос на строительство с материалом %d" % selected_material)
		build_requested.emit(selected_material)

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
