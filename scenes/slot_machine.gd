class_name SlotMachine extends Node2D

@export var num_reels: int = 3
@export var reel_start_delay: float = 0.2
@export var auto_calculate_wins: bool = true
@export var result_label: Label
@export var money_label: Label
@export var spins_label: Label
@export var bet_amount_label: Label
@export var minimize_button: TextureButton
@export var close_button: TextureButton

var items = {
	"Pumpkin": {
		"index": 0,
		"rarity": "Legendary"
	},
	"Skull": {
		"index": 1,
		"rarity": "Rare"
	},
	"Hat": {
		"index": 2,
		"rarity": "Common"
	},
	"Bat": {
		"index": 3,
		"rarity": "Rare"
	},
	"Ghost": {
		"index": 4,
		"rarity": "Common"
	},
	"Cat": {
		"index": 5,
		"rarity": "Common"
	},
	"Spider": {
		"index": 6,
		"rarity": "Rare"
	},
	"Eyes": {
		"index": 7,
		"rarity": "Epic"
	},
	"Cauldron": {
		"index": 8,
		"rarity": "Epic"
	},
	"Potion": {
		"index": 9,
		"rarity": "Rare"
	},
	"Gravestone": {
		"index": 10,
		"rarity": "Epic"
	},
	"Candle": {
		"index": 11,
		"rarity": "Legendary"
	}
}

const WIN_PATTERNS = {
	"three_of_a_kind": 3,
	"two_of_a_kind": 2,
}

const WIN_PAYOUTS_BASE = {
	"three_of_a_kind": 15,
	"two_of_a_kind": 5,
}

const RARITY_MULTIPLIERS = {
	"Common": 1.0,
	"Rare": 5.0,
	"Epic": 10.0,
	"Legendary": 100.0
}

const RARITY_WEIGHTS_DEFAULT: Array[int] = [50, 30, 16, 4]
const RARITIES: Array[String] = ["Common", "Rare", "Epic", "Legendary"]

var bet_amount: int = 1
var is_spinning: bool = false
var reels: Array[SlotMachineSlot] = []
var spin_count_since_last_win: int = 0
var current_targets: Array[int] = []

func _ready() -> void:
	if OS.has_feature("web"):
		minimize_button.visible = false
		close_button.visible = false
	_find_reels()
	
	for reel in reels:
		reel.spin_complete.connect(_on_reel_complete)

	call_deferred("_after_ready")
	
func _after_ready() -> void:
	_update_money_display()
	_update_spins_display()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		generate_targets()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func spin_random() -> void:
	if not is_busy():
		spin()

func spin_with_targets(targets: Array[int]) -> void:
	if not is_busy():
		spin(targets)

func _on_spin_started() -> void:
	if result_label:
		result_label.text = ""
		result_label.hide()

func _on_spin_complete() -> void:
	is_spinning = false

func _find_reels() -> void:
	reels.clear()
	for child in get_children():
		if child is SlotMachineSlot:
			reels.append(child)
	reels.sort_custom(func(a, b): return a.position.x < b.position.x)

func spin(targets: Array[int] = []) -> void:
	if is_spinning:
		return
	
	if reels.is_empty():
		push_error("No SlotMachineSlot reels found!")
		return
	
	# Check if player has enough money
	if GameManager.game_config.balance < bet_amount:
		result_label.text = "Not enough money! Balance: " + _format_money(GameManager.game_config.balance)
		return
	
	subtract_money(bet_amount)
	
	# Increment spin count when spin starts
	spin_count_since_last_win += 1
	_update_spins_display()
	
	is_spinning = true
	_on_spin_started()
	
	# Store targets for win checking
	current_targets.clear()
	current_targets.resize(reels.size())
	
	# Start each reel with a staggered start time
	for i in range(reels.size()):
		var target = targets[i] if i < targets.size() else -1
		current_targets[i] = target if target >= 0 else randi() % 12
		var start_delay = float(i) * reel_start_delay
		var duration = randf_range(2.0, 5.0)
		var random_min_spins = randi_range(5, 10)
		reels[i].spin(current_targets[i], start_delay, duration, random_min_spins)

func _on_reel_complete() -> void:
	# Check if all reels are done
	var all_complete = true
	for reel in reels:
		if reel.is_spinning:
			all_complete = false
			break
	
	if all_complete:
		_on_all_reels_complete()

func _on_all_reels_complete() -> void:
	is_spinning = false
	_on_spin_complete()
	
	if auto_calculate_wins:
		_check_for_wins()
	else:
		# If auto-calculate is off, still increment the counter
		spin_count_since_last_win += 1
		_update_spins_display()

func _check_for_wins() -> void:
	if current_targets.is_empty():
		return

	var symbol_counts: Dictionary = {}
	for symbol in current_targets:
		if symbol in symbol_counts:
			symbol_counts[symbol] += 1
		else:
			symbol_counts[symbol] = 1
	
	var max_count = 0
	var winning_symbol = -1
	for symbol in symbol_counts:
		if symbol_counts[symbol] > max_count:
			max_count = symbol_counts[symbol]
			winning_symbol = symbol
	
	if max_count >= 3:
		var winning_rarity = _get_rarity_by_index(winning_symbol)
		var rarity_multiplier = RARITY_MULTIPLIERS.get(winning_rarity, 1.0)
		var base_payout = WIN_PAYOUTS_BASE["three_of_a_kind"]
		var payout = int(base_payout * rarity_multiplier * bet_amount)
		
		add_money(payout)
		spin_count_since_last_win = 0
		_update_spins_display()
		
		var message = "THREE OF A KIND!\n" + winning_rarity + "\nYOU WIN " + _format_money(payout) + "!"
		_show_result_label(message, Color.GOLD)
	elif max_count >= 2:
		var winning_rarity = _get_rarity_by_index(winning_symbol)
		var rarity_multiplier = RARITY_MULTIPLIERS.get(winning_rarity, 1.0)
		var base_payout = WIN_PAYOUTS_BASE["two_of_a_kind"]
		var payout = int(base_payout * rarity_multiplier * bet_amount)
		
		add_money(payout * bet_amount)
		spin_count_since_last_win = 0
		_update_spins_display()
		
		var message = "TWO OF A KIND!\n" + winning_rarity + "\nYOU WIN " + _format_money(payout) + "!"
		_show_result_label(message, Color.GREEN)
	else:
		_show_result_label("NO MATCH\nTRY AGAIN!", Color.WHITE)

func _show_result_label(message: String, color: Color = Color.WHITE) -> void:
	if result_label:
		result_label.text = message
		result_label.modulate = color
		result_label.show()

func _format_money(cents: int) -> String:
	var dollars = int(cents / 100.0)
	var remaining_cents = cents % 100
	return "$%d.%02d" % [dollars, remaining_cents]

func _update_money_display() -> void:
	if money_label:
		money_label.text = _format_money(GameManager.game_config.balance)

func _update_spins_display() -> void:
	if spins_label:
		if spin_count_since_last_win == 0:
			spins_label.text = "Spins: 0"
		else:
			spins_label.text = "Spins: %d" % spin_count_since_last_win
			
func _update_bet_amount_display() -> void:
	if bet_amount_label:
		bet_amount_label.text = "Bet: %d" % bet_amount

func get_balance() -> int:
	return GameManager.game_config.balance

func add_money(cents: int) -> void:
	GameManager.game_config.add_money(cents)
	_update_money_display()

func subtract_money(cents: int) -> void:
	GameManager.game_config.subtract_money(cents)
	_update_money_display()

func is_busy() -> bool:
	return is_spinning
	
func _weighted_random(choices: Array, weights: Array) -> Variant:
	if choices.is_empty() or weights.is_empty() or choices.size() != weights.size():
		return null
	
	var total_weight = 0
	for weight in weights:
		total_weight += weight
	
	if total_weight <= 0:
		return choices[0] if not choices.is_empty() else null
	
	var random = randf() * total_weight
	
	var cumulative = 0
	for i in range(choices.size()):
		cumulative += weights[i]
		if random < cumulative:
			return choices[i]
	
	return choices[-1]

func _get_rarity_weights() -> Array[int]:
	var weights: Array[int] = RARITY_WEIGHTS_DEFAULT.duplicate()
	
	# If player hasn't won in 5-10 spins, adjust weights to favor higher rarities
	if spin_count_since_last_win >= 5 and spin_count_since_last_win <= 10:
		# Calculate adjustment factor (more adjustment as spins increase)
		var adjustment_factor = float(spin_count_since_last_win - 4) / 6.0 # 0.167 to 1.0
		
		# Reduce Common weight
		weights[0] = int(weights[0] * (1.0 - adjustment_factor * 0.3)) # Reduce by up to 30%
		
		# Slightly reduce Rare
		weights[1] = int(weights[1] * (1.0 - adjustment_factor * 0.15)) # Reduce by up to 15%
		
		# Increase Epic
		weights[2] = int(weights[2] * (1.0 + adjustment_factor * 0.5)) # Increase by up to 50%
		
		# Increase Legendary more significantly
		weights[3] = int(weights[3] * (1.0 + adjustment_factor * 2.0)) # Increase by up to 200%
		
		# Ensure weights don't go negative
		for i in range(weights.size()):
			weights[i] = max(weights[i], 1)
	
	return weights

func _get_items_by_rarity(rarity: String) -> Array[int]:
	var item_indices: Array[int] = []
	for item_name in items:
		var item_data = items[item_name]
		if item_data.get("rarity") == rarity:
			item_indices.append(item_data.get("index"))
	return item_indices

func _get_rarity_by_index(index: int) -> String:
	for item_name in items:
		var item_data = items[item_name]
		if item_data.get("index") == index:
			return item_data.get("rarity", "Common")
	return "Common" # Fallback

func _select_weighted_item() -> int:
	var rarity_weights = _get_rarity_weights()
	var selected_rarity = _weighted_random(RARITIES, rarity_weights)
	var items_of_rarity = _get_items_by_rarity(selected_rarity)
	if items_of_rarity.is_empty():
		return randi_range(0, 11)
	return items_of_rarity[randi() % items_of_rarity.size()]

func generate_targets():
	if not is_busy():
		var random_targets: Array[int] = []
		
		var guaranteed_win_threshold = randi_range(5, 15)
		
		if spin_count_since_last_win >= guaranteed_win_threshold:
			var win_type = randi() % 2
			var guaranteed_item = _select_weighted_item()
			
			if win_type == 0:
				for i in range(3):
					random_targets.append(guaranteed_item)
			else:
				random_targets.append(guaranteed_item)
				random_targets.append(guaranteed_item)
				
				var third_item = _select_weighted_item()
				if third_item == guaranteed_item:
					third_item = _select_weighted_item()
				random_targets.append(third_item)
		else:
			var first_item = _select_weighted_item()
			random_targets.append(first_item)
			
			var second_item = _select_weighted_item()
			if second_item == first_item:
				if randf() > 0.20:
					second_item = _select_weighted_item()
			random_targets.append(second_item)
			
			var third_item = _select_weighted_item()
			if third_item == first_item or third_item == second_item:
				if randf() > 0.20:
					third_item = _select_weighted_item()
			random_targets.append(third_item)
		
		spin_with_targets(random_targets)

func _on_spin_button_pressed() -> void:
	bet_amount = 1
	_update_bet_amount_display()
	generate_targets()

func _on_max_bet_button_pressed() -> void:
	bet_amount = 5
	_update_bet_amount_display()
	generate_targets()

func _on_cash_out_button_pressed() -> void:
	result_label.text = "You cashed out! Balance: " + _format_money(GameManager.game_config.balance)
	GameManager.game_config.cash_out()
	_update_money_display()
	
func _on_add_money_slot_button_pressed() -> void:
	result_label.text = "You added $1.00!"
	GameManager.game_config.add_money(100)
	_update_money_display()

func _on_minimize_button_pressed() -> void:
	if OS.has_feature("web"):
		return
	get_tree().root.mode = Window.MODE_MINIMIZED
	
func _on_close_button_pressed() -> void:
	if OS.has_feature("web"):
		return
	get_tree().quit()
