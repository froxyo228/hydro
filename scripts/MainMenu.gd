# ========== MainMenu.gd ==========
extends Control

@onready var new_game_button = $VBox/NewGameButton
@onready var continue_button = $VBox/ContinueButton
@onready var settings_button = $VBox/SettingsButton
@onready var quit_button = $VBox/QuitButton

var save_system

func _ready():
	save_system = preload("res://scripts/SaveSystem.gd").new()
	add_child(save_system)
	
	setup_buttons()
	update_continue_button()

func setup_buttons():
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func update_continue_button():
	if continue_button and save_system:
		continue_button.disabled = not save_system.has_save_file()

func _on_new_game_pressed():
	print("Начинаем новую игру")
	# Проверяем, нужно ли показать обучение
	var config_manager = get_node("/root/ConfigManager")
	if config_manager and not config_manager.is_tutorial_completed():
		start_tutorial_game()
	else:
		start_new_game()

func _on_continue_pressed():
	if save_system and save_system.has_save_file():
		print("Загружаем сохраненную игру")
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		# Загрузка произойдет в Main сцене
		await get_tree().process_frame
		save_system.load_game()
	else:
		print("Файл сохранения не найден")

func _on_settings_pressed():
	print("Открываем настройки")
	# Здесь можно открыть диалог настроек
	show_settings_dialog()

func _on_quit_pressed():
	print("Выход из игры")
	get_tree().quit()

func start_new_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func start_tutorial_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	# Обучение запустится автоматически в Main сцене

func show_settings_dialog():
	# Простой диалог настроек
	var dialog = AcceptDialog.new()
	dialog.title = "Настройки"
	dialog.dialog_text = "Настройки будут добавлены в следующих версиях"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())
