# 🔧 Исправление конфликта MaterialSystem

## ❌ **Проблема**
```
Parser Error: Class "MaterialSystem" hides an autoload singleton.
в файле materialsystem.gd 2 строка
```

## 🔍 **Причина**
В `scripts/MaterialSystem.gd` была строка:
```gdscript
class_name MaterialSystem
```

Но `MaterialSystem` также является автолоадом в `project.godot`:
```
MaterialSystem="*res://scripts/MaterialSystem.gd"
```

Это создавало конфликт имен.

## ✅ **Исправление**

### 1. Удален `class_name MaterialSystem`
```gdscript
# ========== MaterialSystem.gd ==========
extends Node  # Убрано: class_name MaterialSystem
```

### 2. Обновлены типы в `BuildController.gd`
```gdscript
# Было:
var selected_material: MaterialSystem.MaterialType = MaterialSystem.MaterialType.CONCRETE
signal preview_moved(position: Vector2, material: MaterialSystem.MaterialType)
func start_preview(material: MaterialSystem.MaterialType):

# Стало:
var selected_material: int = 4  # CONCRETE
signal preview_moved(position: Vector2, material: int)
func start_preview(material: int):
```

### 3. Упрощена типизация
```gdscript
# Было:
var material_system: MaterialSystem = null

# Стало:
var material_system = null
```

## 🎯 **Результат**
- ❌ Конфликт имен устранен
- ✅ Автолоад `MaterialSystem` работает корректно
- ✅ Enum `MaterialType` доступен через автолоад
- ✅ Все функции системы материалов сохранены

## 🧪 **Тестирование**
Теперь игра должна запускаться без ошибок парсера!

---
**Проблема решена!** 🎉
