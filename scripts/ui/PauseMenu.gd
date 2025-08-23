# ========== PauseMenu.gd ==========
# [Cursor] Скрипт меню паузы
extends CanvasLayer

# [Cursor] UI элементы
@onready var continue_button = $MenuPanel/VBox/ContinueButton
@onready var save_button = $MenuPanel/VBox/SaveButton
@onready var load_button = $MenuPanel/VBox/LoadButton
@onready var exit_button = $MenuPanel/VBox/ExitButton

# [Cursor] Ссылки на системы
var save_system: Node = null
var hud: Node = null

func _ready():
	# [Cursor] Изначально скрываем меню
	visible = false
	# [Cursor] Устанавливаем процесс-режим, чтобы меню работало во время паузы
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# [Cursor] Подключаем кнопки
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
	
	# [Cursor] Подключаемся к системам
	await get_tree().process_frame
	save_system = get_tree().get_first_node_in_group("save_system")
	hud = get_tree().get_first_node_in_group("hud")

# [Cursor] Показать меню паузы
func show_pause_menu():
	visible = true
	get_tree().paused = true
	print("[Cursor] Меню паузы показано")

# [Cursor] Скрыть меню паузы
func hide_pause_menu():
	visible = false
	get_tree().paused = false
	print("[Cursor] Меню паузы скрыто")

# [Cursor] Обработка нажатия "Продолжить"
func _on_continue_pressed():
	hide_pause_menu()

# [Cursor] Обработка нажатия "Сохранить"
func _on_save_pressed():
	if save_system:
		if save_system.save_game():
			print("[Cursor] Игра сохранена")
			# [Cursor] Показываем уведомление об успешном сохранении
			show_save_notification("Игра сохранена!")
		else:
			print("[Cursor] Ошибка сохранения")
			show_save_notification("Ошибка сохранения!")
	else:
		print("[Cursor] SaveSystem не найден")

# [Cursor] Обработка нажатия "Загрузить"
func _on_load_pressed():
	if save_system:
		if save_system.load_game():
			print("[Cursor] Игра загружена")
			# [Cursor] Обновляем HUD после загрузки
			if hud and hud.has_method("refresh"):
				hud.refresh()
			show_save_notification("Игра загружена!")
		else:
			print("[Cursor] Ошибка загрузки")
			show_save_notification("Ошибка загрузки!")
	else:
		print("[Cursor] SaveSystem не найден")

# [Cursor] Обработка нажатия "Выход"
func _on_exit_pressed():
	# [Cursor] Возвращаемся в главное меню
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# [Cursor] Показать уведомление о сохранении/загрузке
func show_save_notification(message: String):
	# [Cursor] Создаем временное уведомление
	var save_notification = Label.new()
	save_notification.text = message
	save_notification.add_theme_color_override("font_color", Color.WHITE)
	save_notification.add_theme_font_size_override("font_size", 24)
	save_notification.position = Vector2(400, 300)
	add_child(save_notification)
	
	# [Cursor] Удаляем через 2 секунды
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func(): save_notification.queue_free())
	add_child(timer)
	timer.start()

# [Cursor] Обработка ввода для ESC
func _input(event):
	if event.is_action_pressed("ui_pause"):
		if visible:
			hide_pause_menu()
		else:
			show_pause_menu()
