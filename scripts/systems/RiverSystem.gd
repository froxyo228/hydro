# ========== RiverSystem.gd ==========
# Система реки - управляет потоком воды и сезонными изменениями
extends Node2D

signal flow_changed(new_flow)

@export var base_flow: float = 100.0  # м³/с
@export var seasonal_variation: float = 0.3
@export var weather_factor: float = 1.0

var current_flow: float
var time_elapsed: float = 0.0

func _ready():
	current_flow = base_flow
	add_to_group("river_system")
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.timeout.connect(_update_flow)
	timer.autostart = true
	add_child(timer)
	print("[SYSTEM] RiverSystem инициализирован")

## Обновить поток реки с учетом сезонности и погоды
func _update_flow():
	time_elapsed += 5.0
	var seasonal_modifier = 1.0 + seasonal_variation * sin(time_elapsed / 365.0 * 2 * PI)
	weather_factor += randf_range(-0.1, 0.1)
	weather_factor = clamp(weather_factor, 0.5, 2.0)
	current_flow = base_flow * seasonal_modifier * weather_factor
	flow_changed.emit(current_flow)

## Получить коэффициент мощности на основе текущего потока
func get_power_coefficient() -> float:
	return current_flow / base_flow
