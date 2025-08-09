# ========== ConfigManager.gd ==========
extends Node

const CONFIG_FILE = "user://hydrosim_config.cfg"

var config: ConfigFile
var default_settings: Dictionary = {
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.9,
		"muted": false
	},
	"graphics": {
		"fullscreen": false,
		"vsync": true,
		"resolution": "1920x1080"
	},
	"gameplay": {
		"tutorial_completed": false,
		"auto_save": true,
		"difficulty": "normal",
		"language": "ru"
	}
}

func _ready():
	config = ConfigFile.new()
	load_config()

func load_config():
	var err = config.load(CONFIG_FILE)
	if err != OK:
		print("Создание нового конфигурационного файла")
		create_default_config()
		save_config()
	else:
		print("Конфигурация загружена")
	
	apply_settings()

func create_default_config():
	for section in default_settings:
		for key in default_settings[section]:
			config.set_value(section, key, default_settings[section][key])

func save_config():
	var err = config.save(CONFIG_FILE)
	if err == OK:
		print("Конфигурация сохранена")
	else:
		print("Ошибка сохранения конфигурации: ", err)

func get_setting(section: String, key: String, default_value = null):
	return config.get_value(section, key, default_value)

func set_setting(section: String, key: String, value):
	config.set_value(section, key, value)
	save_config()
	apply_setting(section, key, value)

func apply_settings():
	# Применяем аудио настройки
	var master_volume = get_setting("audio", "master_volume", 1.0)
	var _music_volume = get_setting("audio", "music_volume", 0.8)
	var _sfx_volume = get_setting("audio", "sfx_volume", 0.9)
	var muted = get_setting("audio", "muted", false)
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 
		linear_to_db(master_volume if not muted else 0.0))
	
	# Применяем графические настройки
	var fullscreen = get_setting("graphics", "fullscreen", false)
	var vsync = get_setting("graphics", "vsync", true)
	
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)

func apply_setting(section: String, key: String, value):
	match section:
		"audio":
			match key:
				"master_volume":
					AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 
						linear_to_db(value if not get_setting("audio", "muted", false) else 0.0))
				"muted":
					var volume = get_setting("audio", "master_volume", 1.0)
					AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 
						linear_to_db(volume if not value else 0.0))
		"graphics":
			match key:
				"fullscreen":
					if value:
						DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
					else:
						DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				"vsync":
					DisplayServer.window_set_vsync_mode(
						DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED
					)

func reset_to_defaults():
	config.clear()
	create_default_config()
	save_config()
	apply_settings()
	print("Настройки сброшены к значениям по умолчанию")

func is_tutorial_completed() -> bool:
	return get_setting("gameplay", "tutorial_completed", false)

func mark_tutorial_completed():
	set_setting("gameplay", "tutorial_completed", true)

static func get_instance():
	return Engine.get_singleton("ConfigManager")
