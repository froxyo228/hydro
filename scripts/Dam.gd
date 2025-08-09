extends Node2D

# Импорты необходимых классов
class_name Dam
signal dam_status_changed(status)
signal power_generated(amount)
signal maintenance_required()

enum DamStatus {
	UNDER_CONSTRUCTION,
	OPERATIONAL,
	MAINTENANCE_NEEDED,
	CRITICAL_FAILURE,
	DESTROYED
}

# Характеристики плотины
var build_zone: BuildZone
var was_surveyed: bool
var current_status: DamStatus = DamStatus.UNDER_CONSTRUCTION
var structural_integrity: float = 100.0  # 0-100%
var power_output: float = 0.0
var operational_time: float = 0.0

# Параметры деградации
var base_degradation_rate: float = 0.1  # % в секунду
var failure_chance_multiplier: float = 1.0

# Визуальные компоненты
var sprite: Sprite2D
var status_label: Label

func _ready():
	setup_visuals()
	
	# Запускаем регулярные проверки состояния
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_dam_status)
	timer.autostart = true
	add_child(timer)

func initialize(zone: BuildZone, surveyed: bool):
	build_zone = zone
	was_surveyed = surveyed
	global_position = zone.global_position
	
	# Если не было георазведки, увеличиваем шанс проблем
	if not was_surveyed:
		failure_chance_multiplier = 3.0
		structural_integrity = randf_range(60.0, 90.0)  # Начинаем с пониженной прочности

func setup_visuals():
	# Создаем спрайт плотины
	sprite = Sprite2D.new()
	sprite.texture = preload("res://sprites/dam_placeholder.png")  # Замени на реальную текстуру
	add_child(sprite)
	
	# Создаем лейбл статуса
	status_label = Label.new()
	status_label.position = Vector2(-50, -60)
	status_label.text = "Строительство"
	add_child(status_label)

func start_operation():
	current_status = DamStatus.OPERATIONAL
	power_output = calculate_power_output()
	dam_status_changed.emit(current_status)
	update_visual_status()

func calculate_power_output() -> float:
	# Базовая мощность зависит от характеристик зоны строительства
	var base_power = build_zone.power_potential
	
	# Учитываем структурную целостность
	var efficiency = structural_integrity / 100.0
	
	return base_power * efficiency

func _update_dam_status():
	if current_status == DamStatus.UNDER_CONSTRUCTION:
		return
	
	operational_time += 1.0
	
	# Деградация структурной целостности
	var degradation = base_degradation_rate * failure_chance_multiplier
	structural_integrity -= degradation
	
	# Проверяем критические состояния
	if structural_integrity <= 0:
		trigger_dam_failure()
	elif structural_integrity <= 30:
		if current_status != DamStatus.CRITICAL_FAILURE:
			current_status = DamStatus.CRITICAL_FAILURE
			dam_status_changed.emit(current_status)
	elif structural_integrity <= 60:
		if current_status != DamStatus.MAINTENANCE_NEEDED:
			current_status = DamStatus.MAINTENANCE_NEEDED
			maintenance_required.emit()
			dam_status_changed.emit(current_status)
	
	# Генерируем энергию если плотина работает
	if current_status == DamStatus.OPERATIONAL:
		power_output = calculate_power_output()
		power_generated.emit(power_output)
	
	update_visual_status()

func trigger_dam_failure():
	current_status = DamStatus.DESTROYED
	structural_integrity = 0
	power_output = 0
	
	dam_status_changed.emit(current_status)
	
	# Уведомляем GameManager
	if GameManager:
		GameManager.dam_failed.emit(global_position, "Разрушение конструкции")
		GameManager.change_reputation(-30)
	
	update_visual_status()

func perform_maintenance() -> int:
	if current_status != DamStatus.MAINTENANCE_NEEDED:
		return 0
	
	var maintenance_cost = int(10000 * (1.0 - structural_integrity / 100.0))
	structural_integrity = min(structural_integrity + 40, 95.0)  # Не восстанавливаем до 100%
	
	if structural_integrity > 60:
		current_status = DamStatus.OPERATIONAL
		dam_status_changed.emit(current_status)
	
	update_visual_status()
	return maintenance_cost

func update_visual_status():
	match current_status:
		DamStatus.UNDER_CONSTRUCTION:
			status_label.text = "Строительство"
			sprite.modulate = Color.GRAY
		DamStatus.OPERATIONAL:
			status_label.text = "Работает ({}%)".format(structural_integrity)
			sprite.modulate = Color.GREEN
		DamStatus.MAINTENANCE_NEEDED:
			status_label.text = "Ремонт! ({}%)".format(structural_integrity)
			sprite.modulate = Color.YELLOW
		DamStatus.CRITICAL_FAILURE:
			status_label.text = "КРИТИЧНО! ({}%)".format(structural_integrity)
			sprite.modulate = Color.ORANGE
		DamStatus.DESTROYED:
			status_label.text = "РАЗРУШЕНА"
			sprite.modulate = Color.RED
