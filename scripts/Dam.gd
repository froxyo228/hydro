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

# [Cursor] Новые поля для материалов и прочности
var material_type: int = 0  # MaterialSystem.MaterialType
var current_strength: float = 0.0  # Текущая прочность в единицах
var max_strength: float = 0.0  # Максимальная прочность при постройке

# Параметры деградации
var base_degradation_rate: float = 0.1  # % в секунду
var failure_chance_multiplier: float = 1.0
# [Cursor] Ускоренная деградация для неразведанных плотин
var unsurveyed_decay_multiplier: float = 2.0

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

func initialize(zone: BuildZone, surveyed: bool, dam_material: int = 0):
	build_zone = zone
	was_surveyed = surveyed
	material_type = dam_material
	global_position = zone.global_position
	
	# [Cursor] Рассчитываем начальную прочность на основе материала
	var material_system = get_tree().get_first_node_in_group("material_system")
	if material_system:
		var base_strength = material_system.get_base_strength(material_type)
		
		# [Cursor] Если есть георазведка - учитываем коэффициент почвы
		if was_surveyed and zone.has_method("get_geological_stability"):
			var soil_coeff = zone.geological_stability
			max_strength = base_strength * soil_coeff
		else:
			max_strength = base_strength
		
		current_strength = max_strength
	else:
		# [Cursor] Fallback если система не готова
		max_strength = 50.0
		current_strength = max_strength
	
	# Если не было георазведки, увеличиваем деградацию
	if not was_surveyed:
		failure_chance_multiplier = unsurveyed_decay_multiplier
		# [Cursor] Дополнительный риск на нестабильной почве
		if zone.geological_stability < 0.7:
			failure_chance_multiplier *= 1.5

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
	
	# Учитываем поток реки
	var river_system = get_tree().get_first_node_in_group("river_system")
	var flow_coefficient = 1.0
	if river_system:
		flow_coefficient = river_system.get_power_coefficient()
	
	return base_power * efficiency * flow_coefficient

func _update_dam_status():
	if current_status == DamStatus.UNDER_CONSTRUCTION:
		return
	
	operational_time += 1.0
	
	# [Cursor] Деградация на основе прочности
	var strength_degradation = 0.5 * failure_chance_multiplier  # единиц прочности в секунду
	current_strength -= strength_degradation
	
	# [Cursor] Обновляем structural_integrity на основе прочности
	if max_strength > 0:
		structural_integrity = (current_strength / max_strength) * 100.0
	else:
		structural_integrity = 0.0
	
	# Проверяем критические состояния
	if current_strength <= 0 or structural_integrity <= 0:
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
		
		# Добавляем мощность в экономическую систему
		var economic_system = get_tree().get_first_node_in_group("economic_system")
		if economic_system:
			economic_system.add_power_generation(power_output)
	
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
	# [Cursor] Получаем название материала для отображения
	var material_name = "Неизвестно"
	var material_system = get_tree().get_first_node_in_group("material_system")
	if material_system:
		var dam_material_obj = material_system.get_material(material_type)
		if dam_material_obj:
			material_name = dam_material_obj.name
	
	match current_status:
		DamStatus.UNDER_CONSTRUCTION:
			status_label.text = "Строительство\n{}".format([material_name])
			sprite.modulate = Color.GRAY
		DamStatus.OPERATIONAL:
			status_label.text = "{}\nПрочность: {}/{}".format([material_name, int(current_strength), int(max_strength)])
			sprite.modulate = Color.GREEN
		DamStatus.MAINTENANCE_NEEDED:
			status_label.text = "{}\nРемонт! {}/{}".format([material_name, int(current_strength), int(max_strength)])
			sprite.modulate = Color.YELLOW
		DamStatus.CRITICAL_FAILURE:
			status_label.text = "{}\nКРИТИЧНО! {}/{}".format([material_name, int(current_strength), int(max_strength)])
			sprite.modulate = Color.ORANGE
		DamStatus.DESTROYED:
			status_label.text = "{}\nРАЗРУШЕНА".format([material_name])
			sprite.modulate = Color.RED
