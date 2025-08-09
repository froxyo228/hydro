# ========== WeatherSystem.gd ==========
class_name WeatherSystem
extends Node

signal weather_changed(weather_type, intensity)
signal extreme_weather_warning(weather_type)

enum WeatherType { CLEAR, RAIN, STORM, DROUGHT, FLOOD }

var current_weather: WeatherType = WeatherType.CLEAR
var weather_intensity: float = 0.5
var weather_duration: float = 0.0

func _ready():
	add_to_group("weather_system")
	var timer = Timer.new()
	timer.wait_time = 20.0
	timer.timeout.connect(_change_weather)
	timer.autostart = true
	add_child(timer)

func _change_weather():
	match current_weather:
		WeatherType.CLEAR:
			current_weather = WeatherType.RAIN if randf() > 0.7 else WeatherType.CLEAR
		WeatherType.RAIN:
			if randf() > 0.8:
				current_weather = WeatherType.STORM
			elif randf() > 0.5:
				current_weather = WeatherType.CLEAR
		WeatherType.STORM:
			if randf() > 0.6:
				current_weather = WeatherType.RAIN
			elif randf() > 0.95:
				current_weather = WeatherType.FLOOD
		WeatherType.DROUGHT:
			current_weather = WeatherType.CLEAR if randf() > 0.8 else WeatherType.DROUGHT
		WeatherType.FLOOD:
			current_weather = WeatherType.RAIN if randf() > 0.7 else WeatherType.CLEAR
	weather_intensity = randf_range(0.2, 1.0)
	weather_duration = randf_range(10.0, 60.0)
	if current_weather in [WeatherType.STORM, WeatherType.FLOOD, WeatherType.DROUGHT] and weather_intensity > 0.7:
		extreme_weather_warning.emit(current_weather)
	weather_changed.emit(current_weather, weather_intensity)
	var river_system = get_tree().get_first_node_in_group("river_system")
	if river_system:
		apply_weather_effects(river_system)

func apply_weather_effects(river_system):
	match current_weather:
		WeatherType.CLEAR:
			river_system.weather_factor = 1.0
		WeatherType.RAIN:
			river_system.weather_factor = 1.0 + weather_intensity * 0.3
		WeatherType.STORM:
			river_system.weather_factor = 1.0 + weather_intensity * 0.6
		WeatherType.DROUGHT:
			river_system.weather_factor = 1.0 - weather_intensity * 0.5
		WeatherType.FLOOD:
			river_system.weather_factor = 1.0 + weather_intensity * 1.2

func get_weather_string() -> String:
	var weather_names = ["Ясно", "Дождь", "Шторм", "Засуха", "Наводнение"]
	return weather_names[current_weather]
