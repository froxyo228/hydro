# ========== BuildController.gd ==========
# [Cursor] Контроллер строительства - управляет превью и строительством плотин
extends Node

enum State { IDLE, PREVIEW, CONFIRM, CANCEL }

# [Cursor] Текущее состояние и выбранный материал
var current_state: State = State.IDLE
var selected_material: MaterialSystem.MaterialType = MaterialSystem.MaterialType.CONCRETE
var preview_position: Vector2 = Vector2.ZERO

# [Cursor] Сигналы для HUD
signal preview_moved(position: Vector2, material: MaterialSystem.MaterialType)
signal preview_started(material: MaterialSystem.MaterialType)
signal preview_ended()
signal build_confirmed(position: Vector2, material: MaterialSystem.MaterialType)

# [Cursor] Ссылки на системы
var geo_data: Node = null
var material_system: MaterialSystem = null

func _ready():
	add_to_group("build_controller")
	# [Cursor] Подключаемся к системам
	await get_tree().process_frame
	geo_data = get_tree().get_first_node_in_group("geo_data")
	material_system = get_tree().get_first_node_in_group("material_system")

# [Cursor] Начать превью с выбранным материалом
func start_preview(material: MaterialSystem.MaterialType):
	selected_material = material
	current_state = State.PREVIEW
	preview_started.emit(material)
	print("[Cursor] Превью начато с материалом: ", material_system.get_material(material).name)

# [Cursor] Обновить позицию превью (вызывается из DamPreview)
func update_preview_position(position: Vector2):
	if current_state != State.PREVIEW:
		return
	
	# [Cursor] Ограничиваем позицию только BuildZone или рекой
	var valid_position = get_valid_build_position(position)
	preview_position = valid_position
	
	# [Cursor] Эмитим сигнал для HUD
	preview_moved.emit(valid_position, selected_material)

# [Cursor] Получить валидную позицию для строительства
func get_valid_build_position(target_position: Vector2) -> Vector2:
	if not geo_data:
		return target_position
	
	# [Cursor] Сначала пробуем найти ближайшую BuildZone
	var nearest_zone_position = geo_data.get_nearest_build_position(target_position)
	
	# [Cursor] Если нашли зону рядом - используем её позицию
	if nearest_zone_position.distance_to(target_position) < 100.0:
		return nearest_zone_position
	
	# [Cursor] Иначе возвращаем исходную позицию (будет ограничена в DamPreview)
	return target_position

# [Cursor] Подтвердить строительство
func confirm_build() -> bool:
	if current_state != State.PREVIEW:
		return false
	
	current_state = State.CONFIRM
	build_confirmed.emit(preview_position, selected_material)
	print("[Cursor] Строительство подтверждено в позиции: ", preview_position)
	
	# [Cursor] Сбрасываем состояние
	current_state = State.IDLE
	preview_ended.emit()
	return true

# [Cursor] Отменить превью
func cancel_preview():
	if current_state == State.PREVIEW:
		current_state = State.CANCEL
		preview_ended.emit()
		print("[Cursor] Превью отменено")

# [Cursor] Получить планируемую прочность в позиции
func get_planned_strength(position: Vector2) -> float:
	if not material_system:
		return 0.0
	
	var base_strength = material_system.get_base_strength(selected_material)
	
	# [Cursor] Если есть георазведка - учитываем коэффициент почвы
	if geo_data and geo_data.has_survey(position):
		var soil_coeff = geo_data.get_soil_coefficient(position)
		return base_strength * soil_coeff
	
	# [Cursor] Без георазведки - только базовая прочность
	return base_strength

# [Cursor] Проверить, можно ли строить в позиции
func can_build_at(position: Vector2) -> bool:
	if current_state != State.PREVIEW:
		return false
	
	# [Cursor] Проверяем, что позиция находится в BuildZone
	var build_zones = get_tree().get_nodes_in_group("build_zones")
	for zone in build_zones:
		if zone.has_method("get_rect") and zone.get_rect().has_point(position - zone.global_position):
			return not zone.is_occupied
	
	return false
