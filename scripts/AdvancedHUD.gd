# ========== AdvancedHUD.gd ==========
extends CanvasLayer

var selected_build_zone: BuildZone = null
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
# [Cursor] Новые лейблы для прочности
@onready var current_strength_label = $MainInterface/LeftPanel/StrengthPanel/CurrentStrengthLabel
@onready var planned_strength_label = $MainInterface/LeftPanel/StrengthPanel/PlannedStrengthLabel

func _ready():
	add_to_group("hud")
	setup_connections()
	setup_material_options()
	update_all_ui()
	# [Cursor] Подключаемся к BuildController для превью
	await get_tree().process_frame
	var build_controller = get_tree().get_first_node_in_group("build_controller")
	if build_controller:
		build_controller.preview_moved.connect(_on_preview_moved)
		build_controller.preview_started.connect(_on_preview_started)
		build_controller.preview_ended.connect(_on_preview_ended)

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
	
	# Подключаемся к системам
	await get_tree().process_frame
	var weather_system = get_tree().get_first_node_in_group("weather_system")
	if weather_system:
		weather_system.weather_changed.connect(_on_weather_changed)
	
	var river_system = get_tree().get_first_node_in_group("river_system")
	if river_system:
		river_system.flow_changed.connect(_on_river_flow_changed)
	
	var event_system = get_tree().get_first_node_in_group("event_system")
	if event_system:
		event_system.event_triggered.connect(_on_event_triggered)
	
	# Подключаемся к зонам строительства
	for zone in get_tree().get_nodes_in_group("build_zones"):
		zone.zone_selected.connect(_on_zone_selected)

func setup_material_options():
	if material_option:
		material_option.clear()
		# [Cursor] Используем новые материалы из MaterialSystem
		var material_system = get_tree().get_first_node_in_group("material_system")
		if material_system:
			for material in material_system.get_all_materials():
				material_option.add_item(material.name)
		else:
			# [Cursor] Fallback если система не готова
			material_option.add_item("Дерево")
			material_option.add_item("Земляная насыпь")
			material_option.add_item("Камень")
			material_option.add_item("Сталь")
			material_option.add_item("Бетон")

func _on_resources_changed(money: int, reputation: int):
	if money_label:
		money_label.text = "Деньги: $" + str(money)
	if reputation_label:
		reputation_label.text = "Репутация: " + str(reputation) + "/100"
	update_button_states()

func _on_game_state_changed(new_state):
	if state_label:
		state_label.text = "Состояние: " + GameManager.GameState.keys()[new_state]
	update_button_states()

func _on_weather_changed(_weather_type, _intensity):
	if weather_label:
		var weather_system = get_tree().get_first_node_in_group("weather_system")
		if weather_system:
			weather_label.text = "Погода: " + weather_system.get_weather_string()

func _on_river_flow_changed(new_flow):
	if river_flow_label:
		river_flow_label.text = "Поток реки: " + str(int(new_flow)) + " м³/с"

func _on_zone_selected(zone: BuildZone):
	selected_build_zone = zone
	print("Выбрана зона: ", zone.zone_id)
	update_button_states()

func _on_material_selected(index: int):
	selected_material = index

func _on_survey_pressed():
	if GameManager and GameManager.start_survey():
		print("[Survey] Начата георазведка")
		for zone in get_tree().get_nodes_in_group("build_zones"):
			zone.perform_survey()
		
		# [Cursor] Авто-возврат из SURVEYING в PLANNING через 2 секунды
		await get_tree().create_timer(2.0).timeout
		print("[Survey] Завершена георазведка, возврат в PLANNING")
		if GameManager:
			GameManager.change_state(GameManager.GameState.PLANNING)

func _on_build_pressed():
	var bc = get_tree().get_first_node_in_group("build_controller")
	if not bc:
		push_warning("[HUD] BuildController not found")
		return
	
	if bc.current_state == 1: # PREVIEW state
		# [Cursor] Подтверждаем строительство
		print("[HUD] Подтверждение строительства")
		if bc.can_build_at(bc.preview_position):
			bc.confirm_build()
		else:
			print("[HUD] Нельзя строить в этой позиции")
	else:
		# [Cursor] Запускаем превью
		print("[HUD] Запуск превью строительства")
		bc.start_preview(selected_material)
		var preview = get_tree().get_first_node_in_group("dam_preview")
		if preview:
			preview.show_preview()

func _on_dam_built(_location):
	update_dam_list()
	update_total_power()

func _on_dam_failed(_location, _reason):
	update_dam_list()
	update_total_power()

func _on_event_triggered(event_data):
	show_event_dialog(event_data)

func show_event_dialog(event):
	if event_title:
		event_title.text = event.title
	if event_description:
		event_description.text = event.description
	
	# Очищаем старые кнопки выбора
	if choices_container:
		for child in choices_container.get_children():
			child.queue_free()
		
		# Создаем новые кнопки выбора
		for i in range(event.choices.size()):
			var choice = event.choices[i]
			var button = Button.new()
			button.text = choice.text
			button.pressed.connect(func(): _on_event_choice_selected(event, i))
			choices_container.add_child(button)
	
	if event_dialog:
		event_dialog.popup_centered()

func _on_event_choice_selected(event, choice_index: int):
	var event_system = get_tree().get_first_node_in_group("event_system")
	if event_system:
		event_system.resolve_event(event, choice_index)
	if event_dialog:
		event_dialog.hide()

func update_dam_list():
	if not dam_list:
		return
	
	# Очищаем старые виджеты
	for widget in dam_info_widgets:
		widget.queue_free()
	dam_info_widgets.clear()
	
	# Создаем новые виджеты для каждой плотины
	if GameManager and GameManager.built_dams:
		for dam in GameManager.built_dams:
			# Создаем простой виджет плотины
			var widget = Control.new()
			var label = Label.new()
			label.text = "Плотина " + str(dam.get_index()) + " - " + str(int(dam.power_output)) + " МВт"
			widget.add_child(label)
			dam_list.add_child(widget)
			dam_info_widgets.append(widget)

func update_total_power():
	if total_power_label and GameManager:
		var total_power: float = 0.0
		for dam in GameManager.built_dams:
			total_power += dam.power_output
		total_power_label.text = "Общая мощность: " + str(int(total_power)) + " МВт"

func update_button_states():
	var can_survey = false
	var can_build = false
	
	if GameManager:
		can_survey = GameManager.current_state == GameManager.GameState.PLANNING and GameManager.can_afford(GameManager.survey_cost)
		
		# [Cursor] Кнопка "построить" активна в PLANNING, если есть хотя бы одна свободная зона
		if GameManager.current_state == GameManager.GameState.PLANNING:
			for zone in get_tree().get_nodes_in_group("build_zones"):
				if not zone.is_occupied:
					can_build = true
					break
	
	if survey_button:
		survey_button.disabled = not can_survey
	if build_button:
		build_button.disabled = not can_build

func update_all_ui():
	if GameManager:
		_on_resources_changed(GameManager.money, GameManager.reputation)
		_on_game_state_changed(GameManager.current_state)
	update_button_states()
	update_dam_list()
	update_total_power()

# [Cursor] Методы для работы с превью
func _on_preview_started(material: int):
	print("Превью начато с материалом: ", material)
	# [Cursor] Показываем планируемую прочность
	if planned_strength_label:
		planned_strength_label.visible = true
	# [Cursor] Активируем кнопку строительства
	if build_button:
		build_button.disabled = false

func _on_preview_moved(position: Vector2, _material: int):
	# [Cursor] Обновляем планируемую прочность
	if planned_strength_label:
		var build_controller = get_tree().get_first_node_in_group("build_controller")
		if build_controller:
			var planned_strength = build_controller.get_planned_strength(position)
			planned_strength_label.text = "Планируемая прочность: {} ед.".format(int(planned_strength))

func _on_preview_ended():
	print("[Build] Превью завершено")
	# [Cursor] Скрываем планируемую прочность
	if planned_strength_label:
		planned_strength_label.visible = false
	# [Cursor] Скрываем призрак
	var preview = get_tree().get_first_node_in_group("dam_preview")
	if preview:
		preview.hide_preview()
	# [Cursor] Обновляем кнопки
	update_button_states()

# [Cursor] Метод для обновления HUD после загрузки
func refresh():
	update_all_ui()
	print("HUD обновлен")
