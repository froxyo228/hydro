# ========== BuildZone.gd ==========
# Зона строительства - место где можно построить плотину
extends Area2D

signal zone_selected(zone)

# Характеристики зоны
@export var zone_id: String = ""
@export var is_safe: bool = false  # Определяется георазведкой
@export var is_surveyed: bool = false
@export var difficulty_modifier: int = 0  # 0-5, влияет на стоимость
@export var power_potential: float = 100.0  # Потенциальная мощность
@export var geological_stability: float = 1.0  # 0.1-1.0

var zone_visual: ColorRect
var is_highlighted: bool = false
var is_occupied: bool = false

func _ready():
	# Настраиваем визуал
	setup_zone_visual()
	
	# Подключаем сигналы
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup_zone_visual():
	zone_visual = ColorRect.new()
	zone_visual.size = Vector2(80, 40)
	zone_visual.position = Vector2(-40, -20)
	zone_visual.color = Color.BLUE
	zone_visual.color.a = 0.3
	add_child(zone_visual)
	
	update_zone_visual()

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_occupied:
			zone_selected.emit(self)

func _on_mouse_entered():
	is_highlighted = true
	update_zone_visual()

func _on_mouse_exited():
	is_highlighted = false
	update_zone_visual()

func perform_survey():
	is_surveyed = true
	
	# Определяем безопасность зоны на основе геологической стабильности
	var random_factor = randf()
	is_safe = geological_stability > 0.6 and random_factor > 0.3
	
	update_zone_visual()

func update_zone_visual():
	if is_occupied:
		zone_visual.color = Color.GRAY
		return
	
	var base_color: Color
	
	if is_surveyed:
		base_color = Color.GREEN if is_safe else Color.RED
	else:
		base_color = Color.BLUE
	
	if is_highlighted:
		base_color = base_color.lightened(0.3)
	
	base_color.a = 0.5
	zone_visual.color = base_color

func occupy():
	is_occupied = true
	update_zone_visual()
