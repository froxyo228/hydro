# ========== DamPreview.gd ==========
# [Cursor] Скрипт превью плотины - следует за курсором по реке
extends Node2D

# [Cursor] Ссылки на системы
var build_controller: Node = null
var geo_data: Node = null

# [Cursor] Визуальные элементы
@onready var preview_sprite = $PreviewSprite
@onready var preview_label = $PreviewLabel

func _ready():
	add_to_group("dam_preview")
	# [Cursor] Подключаемся к системам
	await get_tree().process_frame
	build_controller = get_tree().get_first_node_in_group("build_controller")
	var geo_data_nodes = get_tree().get_nodes_in_group("geo_data")
	if geo_data_nodes.size() > 0:
		geo_data = geo_data_nodes[0]
	
	# [Cursor] Изначально скрываем превью
	visible = false

func _process(_delta):
	# [Cursor] Обновляем позицию превью только если активно
	if build_controller and build_controller.current_state == 1: # PREVIEW state
		var mouse_pos = get_global_mouse_position()
		update_preview_position(mouse_pos)

# [Cursor] Обновить позицию превью
func update_preview_position(target_position: Vector2):
	if not build_controller:
		return
	
	# [Cursor] Получаем валидную позицию от BuildController
	var valid_position = build_controller.get_valid_build_position(target_position)
	global_position = valid_position
	
	# [Cursor] Обновляем позицию в контроллере
	build_controller.update_preview_position(valid_position)
	
	# [Cursor] Обновляем текст превью
	update_preview_text(valid_position)

# [Cursor] Обновить текст превью
func update_preview_text(preview_position: Vector2):
	if not build_controller:
		return
	
	var planned_strength = build_controller.get_planned_strength(preview_position)
	var material_name = "Неизвестно"
	
	# [Cursor] Получаем название материала
	var material_system = get_tree().get_first_node_in_group("material_system")
	if material_system:
		var dam_material_obj = material_system.get_material(build_controller.selected_material)
		if dam_material_obj:
			material_name = dam_material_obj.name
	
	# [Cursor] Формируем текст превью
	var preview_text = "{} - {} ед.".format(material_name, str(int(planned_strength)))
	preview_label.text = preview_text

# [Cursor] Показать превью
func show_preview():
	visible = true
	print("[Cursor] Превью показано")

# [Cursor] Скрыть превью
func hide_preview():
	visible = false
	print("[Cursor] Превью скрыто")

# [Cursor] Обработка ввода для подтверждения/отмены
func _input(event):
	if not build_controller or build_controller.current_state != 1: # PREVIEW state
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# [Cursor] ЛКМ - подтвердить строительство
			if build_controller.can_build_at(global_position):
				build_controller.confirm_build()
				hide_preview()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# [Cursor] ПКМ - отменить превью
			build_controller.cancel_preview()
			hide_preview()
