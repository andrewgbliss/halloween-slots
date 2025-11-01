@tool
class_name GameConfig extends Resource

var balance: int = 100
		
func _init():
	init_restore()

func save():
	return {
		"balance": balance,
	}

func restore(data):
	if data.has("balance"):
		balance = int(data["balance"])

func init_restore():
	var data = FilesUtil.restore_or_create("user://game_config.json", save())
	if data != null:
		restore(data)

func save_to_file():
	FilesUtil.save("user://game_config.json", save())

func reset():
	save_to_file()

func add_money(cents: int):
	balance += cents
	save_to_file()

func subtract_money(cents: int):
	balance -= cents
	save_to_file()

func get_balance() -> int:
	return balance

func set_balance(cents: int):
	balance = cents
	save_to_file()

func cash_out():
	balance = 0
	save_to_file()
