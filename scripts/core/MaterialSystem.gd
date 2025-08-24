# ========== MaterialSystem.gd ==========
# Система материалов - управляет типами материалов для строительства плотин
extends Node

# Типы материалов с базовыми прочностями
enum MaterialType { WOOD, EARTHFILL, STONE, STEEL, CONCRETE }

# Базовые прочности материалов (условные единицы)
const BASE_STRENGTHS = {
	MaterialType.WOOD: 10.0,
	MaterialType.EARTHFILL: 30.0,
	MaterialType.STONE: 50.0,
	MaterialType.STEEL: 80.0,
	MaterialType.CONCRETE: 100.0
}

## Класс материала плотины
class DamMaterial:
	var type: MaterialType
	var name: String
	var cost_multiplier: float
	var durability: float
	var strength: float
	var maintenance_cost: float

var available_materials: Dictionary = {}

func _ready():
	add_to_group("material_system")
	initialize_materials()
	print("[SYSTEM] MaterialSystem инициализирован")

## Инициализация всех доступных материалов
func initialize_materials():
	var wood = DamMaterial.new()
	wood.type = MaterialType.WOOD
	wood.name = "Дерево"
	wood.cost_multiplier = 0.3
	wood.durability = 0.3
	wood.strength = 0.1
	wood.maintenance_cost = 0.1
	available_materials[MaterialType.WOOD] = wood

	var earthfill = DamMaterial.new()
	earthfill.type = MaterialType.EARTHFILL
	earthfill.name = "Земляная насыпь"
	earthfill.cost_multiplier = 0.5
	earthfill.durability = 0.4
	earthfill.strength = 0.3
	earthfill.maintenance_cost = 0.2
	available_materials[MaterialType.EARTHFILL] = earthfill

	var stone = DamMaterial.new()
	stone.type = MaterialType.STONE
	stone.name = "Камень"
	stone.cost_multiplier = 0.8
	stone.durability = 0.6
	stone.strength = 0.5
	stone.maintenance_cost = 0.3
	available_materials[MaterialType.STONE] = stone

	var steel = DamMaterial.new()
	steel.type = MaterialType.STEEL
	steel.name = "Сталь"
	steel.cost_multiplier = 1.5
	steel.durability = 0.8
	steel.strength = 0.8
	steel.maintenance_cost = 0.5
	available_materials[MaterialType.STEEL] = steel

	var concrete = DamMaterial.new()
	concrete.type = MaterialType.CONCRETE
	concrete.name = "Бетон"
	concrete.cost_multiplier = 1.0
	concrete.durability = 0.7
	concrete.strength = 1.0
	concrete.maintenance_cost = 0.4
	available_materials[MaterialType.CONCRETE] = concrete

## Получить базовую прочность материала
func get_base_strength(type: MaterialType) -> float:
	return BASE_STRENGTHS.get(type, 50.0)

## Получить объект материала по типу
func get_material(type: MaterialType) -> DamMaterial:
	return available_materials.get(type)

## Получить все доступные материалы
func get_all_materials() -> Array[DamMaterial]:
	var out: Array[DamMaterial] = []
	for v in available_materials.values():
		out.append(v)
	return out
