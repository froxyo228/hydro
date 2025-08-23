# CHANGELOG - HydroSim 2.0

## [Unreleased] - 2024-12-19

### Added
- **MaterialSystem**: Новые типы материалов (WOOD, EARTHFILL, STONE, STEEL, CONCRETE) с базовыми прочностями
- **GeoData**: Провайдер геоданных, читающий существующие BuildZone
- **BuildController**: Автолоад-синглтон для управления превью и строительством
- **DamPreview**: Сцена и скрипт для превью плотины с ограничением по реке
- **Preview System**: Система превью с планируемой прочностью и ограничением позиций

### Changed
- **MaterialSystem**: Переработан с новыми материалами и API `get_base_strength()`
- **Level**: EventSystem отключен, добавлены группы для систем
- **project.godot**: Добавлены автолоады BuildController, MaterialSystem, GeoData

### Technical
- Все новые системы добавлены в соответствующие группы
- Превью ограничено только BuildZone (меньше багов с установкой "в лесу")
- GeoData читает существующие BuildZone вместо создания дублирующих источников
- BuildController добавлен как автолоад-синглтон для доступа из HUD

### Files Added
- `scripts/world/GeoData.gd`
- `scripts/build/BuildController.gd`
- `scripts/build/DamPreview.gd`
- `scenes/build/DamPreview.tscn`

### Files Modified
- `scripts/MaterialSystem.gd`
- `scripts/Level.gd`
- `scripts/RiverSystem.gd`
- `scripts/WeatherSystem.gd`
- `scripts/EconomicSystem.gd`
- `scripts/SaveSystem.gd`
- `project.godot`
- `scenes/main.tscn`

## [Unreleased] - 2024-12-19 (Коммит 2)

### Added
- **HUD Updates**: Новые лейблы "Текущая прочность" и "Планируемая прочность"
- **Material Integration**: HUD использует новые материалы из MaterialSystem
- **Pause Menu**: Полноценное меню паузы с CanvasLayer
- **Save/Load Integration**: Сохранение/загрузка с обновлением HUD
- **RiverSystem State**: Сохранение состояния реки в SaveSystem
- **ESC Key Support**: Действие ui_pause для открытия меню паузы

### Changed
- **AdvancedHUD**: Обновлен с новыми материалами и лейблами прочности
- **SaveSystem**: Расширен для сохранения RiverSystem состояния
- **project.godot**: Добавлено действие ui_pause (ESC)

### Technical
- HUD автоматически обновляется после load_game() через метод refresh()
- Превью интегрировано с HUD через BuildController сигналы
- Меню паузы использует CanvasLayer для правильного отображения
- Все новые UI элементы добавлены в соответствующие панели

### Files Added
- `scenes/ui/PauseMenu.tscn`
- `scripts/ui/PauseMenu.gd`

### Files Modified
- `scripts/AdvancedHUD.gd`
- `scenes/AdvancedHUD.tscn`
- `scripts/SaveSystem.gd`
- `project.godot`
- `scenes/main.tscn`

## [Unreleased] - 2024-12-19 (Коммит 3)

### Added
- **Dam Material Integration**: Dam.gd интегрирован с MaterialSystem
- **Current Strength System**: Новое поле current_strength в Dam.gd
- **UNSURVEYED_DECAY**: Ускоренная деградация для неразведанных плотин
- **BuildController Integration**: Полная интеграция с GameManager
- **Material-Based Construction**: Строительство с выбором материала
- **Enhanced Dam Visuals**: Отображение материала и прочности на плотинах

### Changed
- **Dam.gd**: Добавлены поля material_type, current_strength, max_strength
- **GameManager.gd**: Новые методы для работы с BuildController
- **AdvancedHUD.gd**: Интеграция с превью строительства
- **SaveSystem.gd**: Сохранение материалов и прочности плотин
- **DamPreview.gd**: Добавлена в группу dam_preview

### Technical
- Деградация плотин основана на current_strength вместо structural_integrity
- Неразведанные плотины деградируют в 2x быстрее (unsurveyed_decay_multiplier)
- Дополнительный риск на нестабильной почве (geological_stability < 0.7)
- BuildController полностью интегрирован с GameManager через сигналы
- Превью показывает планируемую прочность с учетом георазведки

### Bug Fixes
- Исправлены предупреждения линтера о shadowed variables
- Исправлены неиспользуемые параметры функций

### Files Modified
- `scripts/Dam.gd`
- `scripts/GameManager.gd`
- `scripts/AdvancedHUD.gd`
- `scripts/build/DamPreview.gd`
- `scripts/SaveSystem.gd`
