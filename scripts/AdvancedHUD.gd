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

func _ready():
	add_to_group("hud")
	setup_connections()
	setup_material_options()
	update_all_ui()

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
		material_option.add_item("Бетон")
		material_option.add_item("Сталь")
		material_option.add_item("Железобетон")
		material_option.add_item("Композит")

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
		for zone in get_tree().get_nodes_in_group("build_zones"):
			zone.perform_survey()

func _on_build_pressed():
	if selected_build_zone and GameManager:
		var skip_survey = not selected_build_zone.is_surveyed
		if await GameManager.build_dam(selected_build_zone, skip_survey):
			selected_build_zone.occupy()
			selected_build_zone = null
			update_button_states()

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
		can_build = selected_build_zone != null and not selected_build_zone.is_occupied and GameManager.current_state == GameManager.GameState.PLANNING
	
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
