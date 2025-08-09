# ========== EconomicSystem.gd ==========
class_name EconomicSystem
extends Node

signal income_received(amount, source)
signal expense_occurred(amount, reason)
signal contract_completed(contract_id)

class PowerContract:
	var id: String
	var power_required: float
	var price_per_mwh: float
	var duration: float
	var penalty: float

var active_contracts: Array[PowerContract] = []
var total_power_generated: float = 0.0
var monthly_expenses: float = 5000

func _ready():
	var timer = Timer.new()
	timer.wait_time = 30.0
	timer.timeout.connect(_monthly_calculation)
	timer.autostart = true
	add_child(timer)

func add_contract(power_req: float, price: float, duration: float) -> String:
	var contract = PowerContract.new()
	contract.id = "contract_" + str(randi())
	contract.power_required = power_req
	contract.price_per_mwh = price
	contract.duration = duration
	contract.penalty = price * power_req * 0.1
	active_contracts.append(contract)
	return contract.id

func _monthly_calculation():
	var total_income: float = 0.0
	var total_penalties: float = 0.0
	for contract in active_contracts:
		if total_power_generated >= contract.power_required:
			var income = contract.power_required * contract.price_per_mwh
			total_income += income
			income_received.emit(income, "Контракт " + contract.id)
		else:
			total_penalties += contract.penalty
			expense_occurred.emit(contract.penalty, "Штраф по контракту " + contract.id)
		contract.duration -= 1.0
		if contract.duration <= 0:
			contract_completed.emit(contract.id)
	active_contracts = active_contracts.filter(func(c): return c.duration > 0)
	expense_occurred.emit(monthly_expenses, "Операционные расходы")
	if GameManager:
		var net_income = total_income - total_penalties - monthly_expenses
		if net_income > 0:
			GameManager.money += int(net_income)
		else:
			GameManager.spend_money(int(abs(net_income)))
		GameManager.resources_changed.emit(GameManager.money, GameManager.reputation)
	total_power_generated = 0.0

func add_power_generation(amount: float):
	total_power_generated += amount

