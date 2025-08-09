# ========== DamInfoWidget.gd ==========
extends Control

var dam_reference: Dam

@onready var name_label = $HBox/NameLabel
@onready var status_label = $HBox/StatusLabel
@onready var power_label = $HBox/PowerLabel
@onready var integrity_bar = $VBox/IntegrityBar
@onready var maintenance_button = $VBox/MaintenanceButton

func _ready():
	if maintenance_button:
		maintenance_button.pressed.connect(_on_maintenance_pressed)

func setup_dam(dam: Dam):
	dam_reference = dam
	if dam:
		dam.dam_status_changed.connect(_on_dam_status_changed)
		dam.power_generated.connect(_on_power_generated)
		dam.maintenance_required.connect(_on_maintenance_required)
	update_display()

func update_display():
	if not dam_reference:
		return
	
	if name_label:
		name_label.text = "Плотина " + str(dam_reference.get_index())
	
	if status_label:
		var status_text = ""
		match dam_reference.current_status:
			Dam.DamStatus.UNDER_CONSTRUCTION:
				status_text = "Строительство"
			Dam.DamStatus.OPERATIONAL:
				status_text = "Работает"
			Dam.DamStatus.MAINTENANCE_NEEDED:
				status_text = "Требует ремонта"
			Dam.DamStatus.CRITICAL_FAILURE:
				status_text = "Критическое состояние"
			Dam.DamStatus.DESTROYED:
				status_text = "Разрушена"
		status_label.text = status_text
	
	if power_label:
		power_label.text = str(int(dam_reference.power_output)) + " МВт"
	
	if integrity_bar:
		integrity_bar.value = dam_reference.structural_integrity
		# Цветовая индикация
		if dam_reference.structural_integrity > 60:
			integrity_bar.modulate = Color.GREEN
		elif dam_reference.structural_integrity > 30:
			integrity_bar.modulate = Color.YELLOW
		else:
			integrity_bar.modulate = Color.RED
	
	if maintenance_button:
		maintenance_button.visible = dam_reference.current_status == Dam.DamStatus.MAINTENANCE_NEEDED
		maintenance_button.disabled = not GameManager or not GameManager.can_afford(10000)

func _on_dam_status_changed(_status):
	update_display()

func _on_power_generated(_amount):
	update_display()

func _on_maintenance_required():
	update_display()

func _on_maintenance_pressed():
	if dam_reference and GameManager:
		var cost = dam_reference.perform_maintenance()
		if cost > 0:
			GameManager.spend_money(cost)
			print("Выполнен ремонт плотины за $", cost)
