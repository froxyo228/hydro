# ========== MaterialSystem.gd ==========
class_name MaterialSystem
extends Node

enum MaterialType { CONCRETE, STEEL, COMPOSITE, REINFORCED_CONCRETE }

class DamMaterial:
	var type: MaterialType
	var name: String
	var cost_multiplier: float
	var durability: float
	var strength: float
	var maintenance_cost: float

var available_materials: Dictionary = {}

func _ready():
	initialize_materials()

func initialize_materials():
	var concrete = DamMaterial.new()
	concrete.type = MaterialType.CONCRETE
	concrete.name = "Бетон"
	concrete.cost_multiplier = 1.0
	concrete.durability = 0.6
	concrete.strength = 0.7
	concrete.maintenance_cost = 0.3
	available_materials[MaterialType.CONCRETE] = concrete

	var steel = DamMaterial.new()
	steel.type = MaterialType.STEEL
	steel.name = "Сталь"
	steel.cost_multiplier = 1.5
	steel.durability = 0.8
	steel.strength = 0.9
	steel.maintenance_cost = 0.5
	available_materials[MaterialType.STEEL] = steel

	var composite = DamMaterial.new()
	composite.type = MaterialType.COMPOSITE
	composite.name = "Композитные материалы"
	composite.cost_multiplier = 2.2
	composite.durability = 0.95
	composite.strength = 0.95
	composite.maintenance_cost = 0.2
	available_materials[MaterialType.COMPOSITE] = composite

	var reinforced = DamMaterial.new()
	reinforced.type = MaterialType.REINFORCED_CONCRETE
	reinforced.name = "Железобетон"
	reinforced.cost_multiplier = 1.3
	reinforced.durability = 0.75
	reinforced.strength = 0.8
	reinforced.maintenance_cost = 0.25
	available_materials[MaterialType.REINFORCED_CONCRETE] = reinforced

func get_material(type: MaterialType) -> DamMaterial:
	return available_materials.get(type)

func get_all_materials() -> Array[DamMaterial]:
	return available_materials.values()
