class_name SlotMachine extends Node2D

@export var num_reels: int = 3
@export var reel_start_delay: float = 0.2 # Delay between each reel starting
@export var auto_calculate_wins: bool = true
@export var result_label: Label # Label to show win/lose results
@export var money_label: Label # Label to show win/lose results

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

## Win patterns (for 3 reels)
const WIN_PATTERNS = {
	"three_of_a_kind": 3, # All three symbols match
	"two_of_a_kind": 2, # Two symbols match
}

## Base win payouts (in cents) - will be multiplied by rarity
const WIN_PAYOUTS_BASE = {
	"three_of_a_kind": 50, # Base 50 cents for three of a kind
	"two_of_a_kind": 10, # Base 10 cents for two of a kind
}

## Rarity multipliers for payouts
const RARITY_MULTIPLIERS = {
	"Common": 1.0,
	"Rare": 2.0,
	"Epic": 4.0,
	"Legendary": 10.0
}

## Money system
const SPIN_COST: int = 1 # Cost per spin in cents

## State
var is_spinning: bool = false
var reels: Array[SlotMachineSlot] = []
var spin_count_since_last_win: int = 0
var current_targets: Array[int] = [] # Stores the current spin targets
var balance_cents: int = 100 # Starting balance in cents ($1.00)

func _ready() -> void:
	_find_reels()
	
	for reel in reels:
		reel.spin_complete.connect(_on_reel_complete)
	
	# Initialize money display
	_update_money_display()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # SPACE key
		generate_targets()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func spin_random() -> void:
	if not is_busy():
		print("\n=== SPINNING ===")
		spin()

func spin_with_targets(targets: Array[int]) -> void:
	if not is_busy():
		print("\n=== SPINNING (Targeted) ===", targets)
		spin(targets)

func _on_spin_started() -> void:
	print("Reels are spinning...")
	
	# Clear the result label when starting a new spin
	if result_label:
		result_label.text = ""
		result_label.hide()

func _on_spin_complete() -> void:
	print("\n=== SPIN COMPLETE ===")
	is_spinning = false
	
func _on_win(win_type: String, symbols: Array[int]) -> void:
	"""Called when there's a winning combination."""
	print("\n🎉🎉🎉 WIN! 🎉🎉🎉")
	print("Win Type: ", win_type)
	print("Symbols: ", symbols)
	print("🎉🎉🎉🎉🎉🎉🎉🎉🎉")

func _find_reels() -> void:
	reels.clear()
	for child in get_children():
		if child is SlotMachineSlot:
			reels.append(child)
	
	# Sort reels by position (left to right)
	reels.sort_custom(func(a, b): return a.position.x < b.position.x)

func spin(targets: Array[int] = []) -> void:
	if is_spinning:
		return
	
	if reels.is_empty():
		push_error("No SlotMachineSlot reels found!")
		return
	
	# Check if player has enough money
	if balance_cents < SPIN_COST:
		print("Not enough money! Balance: ", _format_money(balance_cents))
		return
	
	# Deduct spin cost
	balance_cents -= SPIN_COST
	_update_money_display()
	print("Spin cost: ", _format_money(SPIN_COST), " | Remaining: ", _format_money(balance_cents))
	
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

func _check_for_wins() -> void:
	if current_targets.is_empty():
		return
	
	print("Checking wins for targets: ", current_targets)
	
	# Count symbol occurrences
	var symbol_counts: Dictionary = {}
	for symbol in current_targets:
		if symbol in symbol_counts:
			symbol_counts[symbol] += 1
		else:
			symbol_counts[symbol] = 1
	
	# Find the most common symbol and its count
	var max_count = 0
	var winning_symbol = -1
	for symbol in symbol_counts:
		if symbol_counts[symbol] > max_count:
			max_count = symbol_counts[symbol]
			winning_symbol = symbol
	
	# Determine win type and award money
	if max_count >= 3:
		# Get rarity of winning symbol and calculate payout
		var winning_rarity = _get_rarity_by_index(winning_symbol)
		var rarity_multiplier = RARITY_MULTIPLIERS.get(winning_rarity, 1.0)
		var base_payout = WIN_PAYOUTS_BASE["three_of_a_kind"]
		var payout = int(base_payout * rarity_multiplier)
		
		balance_cents += payout
		_update_money_display()
		_on_win("three_of_a_kind", current_targets)
		spin_count_since_last_win = 0
		
		# Create win message with rarity
		var rarity_emoji = _get_rarity_emoji(winning_rarity)
		var message = "🎉 THREE OF A KIND! 🎉\n" + rarity_emoji + " " + winning_rarity + " " + rarity_emoji + "\nYOU WIN " + _format_money(payout) + "!"
		_show_result_label(message, Color.GOLD)
		print("Win! Payout: ", _format_money(payout), " | Rarity: ", winning_rarity, " | New balance: ", _format_money(balance_cents))
	elif max_count >= 2:
		# Get rarity of winning symbol and calculate payout
		var winning_rarity = _get_rarity_by_index(winning_symbol)
		var rarity_multiplier = RARITY_MULTIPLIERS.get(winning_rarity, 1.0)
		var base_payout = WIN_PAYOUTS_BASE["two_of_a_kind"]
		var payout = int(base_payout * rarity_multiplier)
		
		balance_cents += payout
		_update_money_display()
		_on_win("two_of_a_kind", current_targets)
		spin_count_since_last_win = 0
		
		# Create win message with rarity
		var rarity_emoji = _get_rarity_emoji(winning_rarity)
		var message = "✨ TWO OF A KIND! ✨\n" + rarity_emoji + " " + winning_rarity + " " + rarity_emoji + "\nYOU WIN " + _format_money(payout) + "!"
		_show_result_label(message, Color.GREEN)
		print("Win! Payout: ", _format_money(payout), " | Rarity: ", winning_rarity, " | New balance: ", _format_money(balance_cents))
	else:
		spin_count_since_last_win += 1
		print("No win. Spins since last win: ", spin_count_since_last_win)
		_show_result_label("NO MATCH\nTRY AGAIN!", Color.DARK_GRAY)

func _get_rarity_emoji(rarity: String) -> String:
	"""Get an emoji representation for each rarity."""
	match rarity:
		"Common":
			return "⚪"
		"Rare":
			return "🔵"
		"Epic":
			return "🟣"
		"Legendary":
			return "🟡"
		_:
			return "⚪"

func _show_result_label(message: String, color: Color = Color.WHITE) -> void:
	"""Display the result message on the label."""
	if result_label:
		result_label.text = message
		result_label.modulate = color
		result_label.show()

func _format_money(cents: int) -> String:
	"""Format cents as dollar string (e.g., 150 cents = '$1.50')"""
	var dollars = int(cents / 100.0)
	var remaining_cents = cents % 100
	return "$%d.%02d" % [dollars, remaining_cents]

func _update_money_display() -> void:
	"""Update the money label with current balance."""
	if money_label:
		money_label.text = _format_money(balance_cents)

func get_balance() -> int:
	"""Returns the current balance in cents."""
	return balance_cents

func add_money(cents: int) -> void:
	"""Add money to the balance."""
	balance_cents += cents
	_update_money_display()
	print("Added ", _format_money(cents), " | New balance: ", _format_money(balance_cents))

func is_busy() -> bool:
	return is_spinning


func _on_texture_button_pressed() -> void:
	generate_targets()


# const rarities = ["Common", "Uncommon", "Rare", "Epic", "Legendary"];
#   const rarityWeightDefaults = [50, 30, 16, 4, 0]; // Adjust 
# const rarity = weightedRandom(rarities, rarityWeights);
# function weightedRandom(choices, weights) {
#   const totalWeight = weights.reduce((acc, w) => acc + w, 0);
#   const random = Math.random() * totalWeight;

#   let cumulative = 0;
#   for (let i = 0; i < choices.length; i++) {
#     cumulative += weights[i];
#     if (random < cumulative) return choices[i];
#   }
# }

## Rarity weights (default)
## Based on the JavaScript code: [Common, Rare, Epic, Legendary]
const RARITY_WEIGHTS_DEFAULT: Array[int] = [50, 30, 16, 4]
const RARITIES: Array[String] = ["Common", "Rare", "Epic", "Legendary"]

func _weighted_random(choices: Array, weights: Array) -> Variant:
	"""Weighted random selection converted from JavaScript.
	Selects a random choice based on weights."""
	if choices.is_empty() or weights.is_empty() or choices.size() != weights.size():
		return null
	
	# Calculate total weight
	var total_weight = 0
	for weight in weights:
		total_weight += weight
	
	if total_weight <= 0:
		return choices[0] if not choices.is_empty() else null
	
	# Generate random value
	var random = randf() * total_weight
	
	# Find the choice based on cumulative weights
	var cumulative = 0
	for i in range(choices.size()):
		cumulative += weights[i]
		if random < cumulative:
			return choices[i]
	
	# Fallback (shouldn't happen)
	return choices[-1]

func _get_rarity_weights() -> Array[int]:
	"""Get rarity weights, adjusted based on spin_count_since_last_win.
	If player hasn't won in 5-10 spins, increase weights for higher rarities."""
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
	"""Get all item indices for a given rarity."""
	var item_indices: Array[int] = []
	for item_name in items:
		var item_data = items[item_name]
		if item_data.get("rarity") == rarity:
			item_indices.append(item_data.get("index"))
	return item_indices

func _get_rarity_by_index(index: int) -> String:
	"""Get the rarity of an item by its index."""
	for item_name in items:
		var item_data = items[item_name]
		if item_data.get("index") == index:
			return item_data.get("rarity", "Common")
	return "Common" # Fallback

func _select_weighted_item() -> int:
	"""Select a random item using weighted rarity selection."""
	# Get adjusted rarity weights
	var rarity_weights = _get_rarity_weights()
	
	# Select a rarity based on weights
	var selected_rarity = _weighted_random(RARITIES, rarity_weights)
	
	# Get all items of this rarity
	var items_of_rarity = _get_items_by_rarity(selected_rarity)
	
	# Select a random item from this rarity
	if items_of_rarity.is_empty():
		# Fallback: select completely random item
		return randi_range(0, 11)
	
	return items_of_rarity[randi() % items_of_rarity.size()]

func generate_targets():
	"""Generate three target items using weighted random selection based on rarity.
	Weights are adjusted if player hasn't won in 5-10 spins."""
	if not is_busy():
		var random_targets: Array[int] = []
		
		# Generate 3 targets using weighted selection
		for i in range(3):
			var target = _select_weighted_item()
			random_targets.append(target)
		
		spin_with_targets(random_targets)
