# 🔧 Исправление ошибок парсинга level.tscn

## ❌ **Проблема**
При добавлении BuildZone в level.tscn возникли ошибки парсинга:
```
Could not parse global class "BuildZone" from "res://scripts/BuildZone.gd"
Parser Error: Could not parse global class "BuildZone"
Function "update_visual" has the same name as a previously declared function
```

## 🔍 **Причина**
1. Пытались задать свойства экспортированных переменных прямо в .tscn файле
2. Дублировали зоны - они уже создавались программно в Level.gd
3. Конфликт с существующим кодом генерации зон

## ✅ **Исправление**

### 1. **Убрали зоны из level.tscn**
```gdscript
# Было в level.tscn:
[node name="BuildZone1" parent="." instance=ExtResource("2_build_zone")]
position = Vector2(376, 324)
zone_id = "zone_1"  # ← Это вызывало ошибки парсинга
power_potential = 120.0
geological_stability = 0.8

# Стало:
# Зоны убраны из .tscn - создаются только программно
```

### 2. **Улучшили программное создание зон в Level.gd**

#### Было (случайные позиции):
```gdscript
for i in range(num_build_zones):
    var zone = preload("res://scenes/build_zone.tscn").instantiate()
    zone.position = Vector2(i * spacing - river_length/2, randf_range(-50, 50))
    # Случайные характеристики
```

#### Стало (фиксированные удобные позиции):
```gdscript
var zone_configs = [
    {"id": "zone_1", "pos": Vector2(-200, 0), "power": 120.0, "stability": 0.8, "surveyed": false},
    {"id": "zone_2", "pos": Vector2(0, -100), "power": 100.0, "stability": 0.9, "surveyed": true, "safe": true},
    {"id": "zone_3", "pos": Vector2(200, 0), "power": 80.0, "stability": 0.6, "surveyed": false},
    {"id": "zone_4", "pos": Vector2(0, 100), "power": 150.0, "stability": 0.4, "surveyed": true, "safe": false}
]

for i in range(min(zone_configs.size(), num_build_zones)):
    var config = zone_configs[i]
    var zone = preload("res://scenes/build_zone.tscn").instantiate()
    zone.zone_id = config.id
    zone.position = river_pos + config.pos  # Относительно реки в центре
    
    # Настраиваем характеристики из конфига
    zone.power_potential = config.power
    zone.geological_stability = config.stability
    zone.is_surveyed = config.get("surveyed", false)
    zone.is_safe = config.get("safe", false)
```

### 3. **Результат - чистый level.tscn**
```gdscript
[gd_scene load_steps=2 format=3 uid="uid://bwgpspjbsngii"]

[ext_resource type="Script" uid="uid://d0fhhiqthjp0c" path="res://scripts/Level.gd" id="1_2q6dc"]

[node name="Level" type="Node2D"]
script = ExtResource("1_2q6dc")

[node name="River" type="Node2D" parent="."]
position = Vector2(576, 324)  # Река в центре

[node name="RiverRect" type="ColorRect" parent="River"]
# ... только визуал реки
```

## 🎮 **Расположение зон (относительно реки в центре)**

```
        Zone2 (безопасная, 100 МВт)
              ↑
Zone1 (120 МВт) ← РЕКА → Zone3 (80 МВт)  
              ↓
        Zone4 (мощная 150 МВт, опасная)
```

## 🎯 **Результат**

- ✅ **Ошибки парсинга исправлены** - убрали конфликтующие свойства из .tscn
- ✅ **Зоны создаются программно** - полный контроль над характеристиками
- ✅ **Река в центре** - удобно для тестирования
- ✅ **Предсказуемые позиции** - не случайные, а фиксированные
- ✅ **Разнообразие зон** - есть безопасные и опасные для тестирования

## 🧪 **Для тестирования**

- **Zone2** (сверху) - безопасная, уже разведана (зеленая)
- **Zone4** (снизу) - мощная, но опасная, разведана (красная)
- **Zone1, Zone3** (слева/справа) - требуют георазведки

---

**Ошибки парсинга исправлены, зоны в удобных местах!** 🎉
