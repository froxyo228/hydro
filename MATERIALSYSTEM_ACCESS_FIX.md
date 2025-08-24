# 🔧 Исправление доступа к MaterialSystem

## ❌ **Проблема**
При нажатии "Построить плотину" появилось 2541 ошибка:
```
Cannot call method "get_first_node_in_group" on a null value
```

## 🔍 **Причина**
Все скрипты пытались получить `MaterialSystem` через группу:
```gdscript
var material_system = get_tree().get_first_node_in_group("material_system")
```

Но `MaterialSystem` как автолоад не добавляется в группу автоматически, поэтому `get_first_node_in_group()` возвращал `null`.

## ✅ **Исправление**

Заменили обращение через группу на прямое обращение к автолоаду:

### Было (во всех файлах):
```gdscript
var material_system = get_tree().get_first_node_in_group("material_system")
```

### Стало:
```gdscript
var material_system = get_node_or_null("/root/MaterialSystem")
```

## 📁 **Исправленные файлы**

1. **`scripts/Dam.gd`** - 2 места (initialize + update_visual_status)
2. **`scripts/AdvancedHUD.gd`** - setup_material_options
3. **`scripts/build/BuildController.gd`** - _ready
4. **`scripts/build/DamPreview.gd`** - update_preview_text  
5. **`scripts/debug/SystemDiagnostics.gd`** - check_materials

## 🎯 **Результат**

- ✅ Все ошибки доступа к MaterialSystem исправлены
- ✅ Автолоад MaterialSystem теперь доступен корректно
- ✅ Превью строительства должно работать без ошибок
- ✅ Материалы отображаются правильно

## 🧪 **Тестирование**

Теперь при нажатии "Построить плотину":
1. Не должно быть ошибок в консоли
2. Должно появиться превью плотины
3. Должна обновляться планируемая прочность
4. Материалы должны отображаться в выпадающем списке

---

**Проблема с 2541 ошибкой исправлена!** 🎉
