# ========== EventSystem.gd ==========
class_name EventSystem
extends Node

signal event_triggered(event_data)

class GameEvent:
	var id: String
	var title: String
	var description: String
	var choices: Array[EventChoice] = []
	var auto_resolve_time: float = 0.0

class EventChoice:
	var text: String
	var money_cost: int = 0
	var reputation_change: int = 0
	var success_chance: float = 1.0
	var consequences: String = ""

var active_events: Array[GameEvent] = []
var event_probability: float = 0.02

func _ready():
	add_to_group("event_system")
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_check_for_events)
	timer.autostart = true
	add_child(timer)

func _check_for_events():
	if randf() < event_probability and active_events.size() < 3:
		generate_random_event()

func generate_random_event():
	var events = [
		create_environmental_inspection(),
		create_equipment_failure(),
		create_investment_opportunity(),
		create_weather_damage(),
		create_public_concern()
	]
	var event = events[randi() % events.size()]
	active_events.append(event)
	event_triggered.emit(event)

func create_environmental_inspection() -> GameEvent:
	var event = GameEvent.new()
	event.id = "env_inspection_" + str(randi())
	event.title = "Экологическая проверка"
	event.description = "Экологи требуют провести дополнительную проверку влияния ГЭС на местную экосистему."
	var choice1 = EventChoice.new()
	choice1.text = "Пригласить независимых экспертов (-$15000, +репутация)"
	choice1.money_cost = 15000
	choice1.reputation_change = 10
	choice1.success_chance = 0.9
	var choice2 = EventChoice.new()
	choice2.text = "Провести проверку своими силами (-$5000)"
	choice2.money_cost = 5000
	choice2.reputation_change = -5
	choice2.success_chance = 0.6
	var choice3 = EventChoice.new()
	choice3.text = "Игнорировать требования (-репутация)"
	choice3.reputation_change = -15
	choice3.success_chance = 0.3
	event.choices = [choice1, choice2, choice3]
	return event

func create_equipment_failure() -> GameEvent:
	var event = GameEvent.new()
	event.id = "equipment_failure_" + str(randi())
	event.title = "Поломка оборудования"
	event.description = "В турбине обнаружена неисправность. Требуется срочный ремонт."
	var choice1 = EventChoice.new()
	choice1.text = "Экстренный ремонт (-$25000, быстро)"
	choice1.money_cost = 25000
	choice1.consequences = "Работа восстанавливается через 1 день"
	var choice2 = EventChoice.new()
	choice2.text = "Плановый ремонт (-$15000, медленно)"
	choice2.money_cost = 15000
	choice2.consequences = "Работа восстанавливается через 7 дней"
	event.choices = [choice1, choice2]
	return event

func create_investment_opportunity() -> GameEvent:
	var event = GameEvent.new()
	event.id = "investment_" + str(randi())
	event.title = "Инвестиционное предложение"
	event.description = "Крупная энергетическая компания предлагает партнерство и модернизацию оборудования."
	var choice1 = EventChoice.new()
	choice1.text = "Принять предложение (+$50000, -20% доходов в будущем)"
	choice1.money_cost = -50000
	choice1.reputation_change = 5
	var choice2 = EventChoice.new()
	choice2.text = "Отклонить предложение"
	choice2.reputation_change = -2
	event.choices = [choice1, choice2]
	return event

func create_weather_damage() -> GameEvent:
	var event = GameEvent.new()
	event.id = "weather_damage_" + str(randi())
	event.title = "Повреждения от непогоды"
	event.description = "Сильный шторм повредил часть инфраструктуры ГЭС."
	var choice1 = EventChoice.new()
	choice1.text = "Немедленно устранить (-$20000)"
	choice1.money_cost = 20000
	choice1.success_chance = 1.0
	var choice2 = EventChoice.new()
	choice2.text = "Отложить ремонт (риск усугубления)"
	choice2.success_chance = 0.4
	choice2.consequences = "Возможны дополнительные поломки"
	event.choices = [choice1, choice2]
	return event

func create_public_concern() -> GameEvent:
	var event = GameEvent.new()
	event.id = "public_concern_" + str(randi())
	event.title = "Обеспокоенность жителей"
	event.description = "Местные жители выражают беспокойство о безопасности плотины."
	var choice1 = EventChoice.new()
	choice1.text = "Пресс-конференция (-$10000, +репутация)"
	choice1.money_cost = 10000
	choice1.reputation_change = 15
	var choice2 = EventChoice.new()
	choice2.text = "Экскурсия (-$5000, +репутация)"
	choice2.money_cost = 5000
	choice2.reputation_change = 8
	var choice3 = EventChoice.new()
	choice3.text = "Не реагировать (-репутация)"
	choice3.reputation_change = -10
	event.choices = [choice1, choice2, choice3]
	return event

func resolve_event(event: GameEvent, choice_index: int):
	if choice_index >= 0 and choice_index < event.choices.size():
		var choice = event.choices[choice_index]
		if randf() <= choice.success_chance:
			if GameManager:
				GameManager.spend_money(choice.money_cost)
				GameManager.change_reputation(choice.reputation_change)
		else:
			if GameManager:
				GameManager.change_reputation(-5)
				GameManager.spend_money(choice.money_cost / 2)
	active_events.erase(event)
