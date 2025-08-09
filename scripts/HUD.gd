extends CanvasLayer

# Переменные
var selected_build_zone: BuildZone = null

# Сигналы для кнопок
signal exploration_requested
signal construction_requested

# Методы для инициализации
func _ready():
	# Подключение к GameManager
	if GameManager:
		GameManager.resources_changed.connect(_on_resources_changed)
		GameManager.game_state_changed.connect(_on_game_state_changed)
	
	# Подключение кнопок к правильным обработчикам
	var survey_button = $VBox/SurveyButton
	if survey_button:
		survey_button.pressed.connect(_on_survey_pressed)
	
	var build_button = $VBox/BuildButton
	if build_button:
		build_button.pressed.connect(_on_build_pressed)
	
	# Ждем инициализации сцены и подключаем зоны
	await get_tree().process_frame
	for zone in get_tree().get_nodes_in_group("build_zones"):
		zone.zone_selected.connect(_on_zone_selected)
	
	# Обновляем начальное состояние
	update_button_states()

# Обработчики ресурсов и состояния игры
func _on_resources_changed(money: int, reputation: int):
	var money_label = $VBox/ResourcesPanel/VBoxContainer/MoneyLabel
	if money_label:
		money_label.text = "Деньги: $" + str(money)
	
	var reputation_label = $VBox/ResourcesPanel/VBoxContainer/ReputationLabel
	if reputation_label:
		reputation_label.text = "Репутация: " + str(reputation) + "/100"

func _on_game_state_changed(new_state):
	var state_label = $VBox/ResourcesPanel/VBoxContainer/StateLabel
	if state_label:
		state_label.text = "Состояние: " + GameManager.GameState.keys()[new_state]
	update_button_states()

# Обработчик выбора зоны
func _on_zone_selected(zone: BuildZone):
	selected_build_zone = zone
	print("Выбрана зона: ", zone.zone_id)
	update_button_states()

# Обработчики кнопок
func _on_survey_pressed():
	print("Нажата кнопка георазведки")
	if GameManager and GameManager.start_survey():
		for zone in get_tree().get_nodes_in_group("build_zones"):
			zone.perform_survey()

func _on_build_pressed():
	print("Нажата кнопка строительства")
	if selected_build_zone and GameManager:
		var skip_survey = not selected_build_zone.is_surveyed
		if await GameManager.build_dam(selected_build_zone, skip_survey):
			selected_build_zone.occupy()
			selected_build_zone = null
			update_button_states()

# Обновление состояния кнопок
func update_button_states():
	var can_survey = false
	var can_build = false
	
	if GameManager:
		can_survey = GameManager.current_state == GameManager.GameState.PLANNING and GameManager.can_afford(GameManager.survey_cost)
		can_build = selected_build_zone != null and not selected_build_zone.is_occupied and GameManager.current_state == GameManager.GameState.PLANNING
	
	var survey_button = $VBox/SurveyButton
	if survey_button:
		survey_button.disabled = not can_survey
	
	var build_button = $VBox/BuildButton
	if build_button:
		build_button.disabled = not can_build

# Дополнительные методы для сигналов (если нужны)
func _on_exploration_button_pressed():
	emit_signal("exploration_requested")

func _on_construction_button_pressed():
	emit_signal("construction_requested")