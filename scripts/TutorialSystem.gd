# ========== TutorialSystem.gd ==========
class_name TutorialSystem
extends Control

signal tutorial_completed
signal tutorial_step_completed(step_id)

enum TutorialStep {
	WELCOME,
	SURVEY_EXPLANATION,
	BUILD_ZONE_SELECTION,
	DAM_CONSTRUCTION,
	MONITORING,
	COMPLETED
}

var current_step: TutorialStep = TutorialStep.WELCOME
var tutorial_active: bool = false
var step_data: Dictionary = {}

# Временно отключаем UI элементы для TutorialSystem
# @onready var tutorial_panel = $TutorialPanel
# @onready var step_title = $TutorialPanel/VBox/StepTitle
# @onready var step_description = $TutorialPanel/VBox/StepDescription
# @onready var next_button = $TutorialPanel/VBox/ButtonContainer/NextButton
# @onready var skip_button = $TutorialPanel/VBox/ButtonContainer/SkipButton

func _ready():
	add_to_group("ui")
	setup_tutorial_data()
	# Временно отключаем подключение кнопок
	# if next_button:
	# 	next_button.pressed.connect(_on_next_pressed)
	# if skip_button:
	# 	skip_button.pressed.connect(_on_skip_pressed)
	visible = false

func setup_tutorial_data():
	step_data[TutorialStep.WELCOME] = {
		"title": "Добро пожаловать в HydroSim!",
		"description": "Вы - инженер-гидротехник. Ваша задача - построить эффективную гидроэлектростанцию.\n\nОсновные ресурсы:\n• Деньги - для строительства и операций\n• Репутация - влияет на доступные контракты"
	}
	
	step_data[TutorialStep.SURVEY_EXPLANATION] = {
		"title": "Геологическая разведка",
		"description": "Перед строительством рекомендуется провести геологическую разведку.\n\n• Стоимость: $5000\n• Показывает безопасные зоны (зеленые)\n• Опасные зоны (красные) увеличивают риск аварий"
	}
	
	step_data[TutorialStep.BUILD_ZONE_SELECTION] = {
		"title": "Выбор места строительства",
		"description": "Кликните на одну из синих зон вдоль реки.\n\n• Каждая зона имеет разные характеристики\n• Сложность влияет на стоимость\n• Потенциал мощности определяет доходность"
	}
	
	step_data[TutorialStep.DAM_CONSTRUCTION] = {
		"title": "Строительство плотины",
		"description": "После выбора зоны нажмите 'Построить плотину'.\n\n• Строительство занимает время\n• Следите за структурной целостностью\n• Плотины требуют регулярного обслуживания"
	}
	
	step_data[TutorialStep.MONITORING] = {
		"title": "Мониторинг и управление",
		"description": "Следите за показателями:\n\n• Поток реки влияет на выработку\n• Погода может повредить оборудование\n• События требуют принятия решений\n• Контракты приносят доход"
	}

func start_tutorial():
	tutorial_active = true
	current_step = TutorialStep.WELCOME
	visible = true
	show_current_step()

func show_current_step():
	if not step_data.has(current_step):
		complete_tutorial()
		return
	
	var data = step_data[current_step]
	# Временно отключаем обновление UI
	# if step_title:
	# 	step_title.text = data.get("title", "")
	# if step_description:
	# 	step_description.text = data.get("description", "")
	
	# if tutorial_panel:
	# 	tutorial_panel.visible = true

func _on_next_pressed():
	tutorial_step_completed.emit(current_step)
	advance_tutorial()

func _on_skip_pressed():
	complete_tutorial()

func advance_tutorial():
	match current_step:
		TutorialStep.WELCOME:
			current_step = TutorialStep.SURVEY_EXPLANATION
		TutorialStep.SURVEY_EXPLANATION:
			current_step = TutorialStep.BUILD_ZONE_SELECTION
		TutorialStep.BUILD_ZONE_SELECTION:
			current_step = TutorialStep.DAM_CONSTRUCTION
		TutorialStep.DAM_CONSTRUCTION:
			current_step = TutorialStep.MONITORING
		TutorialStep.MONITORING:
			complete_tutorial()
			return
		_:
			complete_tutorial()
			return
	
	show_current_step()

func complete_tutorial():
	tutorial_active = false
	current_step = TutorialStep.COMPLETED
	visible = false
	tutorial_completed.emit()
	print("Обучение завершено!")

func hide_tutorial():
	visible = false
	# if tutorial_panel:
	# 	tutorial_panel.visible = false

func show_step(step: TutorialStep):
	current_step = step
	show_current_step()

func is_tutorial_active() -> bool:
	return tutorial_active

