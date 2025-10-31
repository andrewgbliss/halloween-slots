class_name SlotMachine extends Node2D

@export var num_reels: int = 3
@export var reel_start_delay: float = 0.2 # Delay between each reel starting
@export var auto_calculate_wins: bool = true
@export var result_label: Label # Label to show win/lose results
@export var money_label: Label # Label to show win/lose results

## Win patterns (for 3 reels)
const WIN_PATTERNS = {
	"three_of_a_kind": 3, # All three symbols match
	"two_of_a_kind": 2, # Two symbols match
}

## Win payouts (in cents)
const WIN_PAYOUTS = {
	"three_of_a_kind": 50, # 50 cents for three of a kind
	"two_of_a_kind": 10, # 10 cents for two of a kind
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
	
	# Find the most common symbol
	var max_count = 0
	for symbol in symbol_counts:
		if symbol_counts[symbol] > max_count:
			max_count = symbol_counts[symbol]
	
	# Determine win type and award money
	if max_count >= 3:
		var payout = WIN_PAYOUTS["three_of_a_kind"]
		balance_cents += payout
		_update_money_display()
		_on_win("three_of_a_kind", current_targets)
		spin_count_since_last_win = 0
		_show_result_label("🎉 THREE OF A KIND! 🎉\nYOU WIN " + _format_money(payout) + "!", Color.GOLD)
		print("Win! Payout: ", _format_money(payout), " | New balance: ", _format_money(balance_cents))
	elif max_count >= 2:
		var payout = WIN_PAYOUTS["two_of_a_kind"]
		balance_cents += payout
		_update_money_display()
		_on_win("two_of_a_kind", current_targets)
		spin_count_since_last_win = 0
		_show_result_label("✨ TWO OF A KIND! ✨\nYOU WIN " + _format_money(payout) + "!", Color.GREEN)
		print("Win! Payout: ", _format_money(payout), " | New balance: ", _format_money(balance_cents))
	else:
		spin_count_since_last_win += 1
		print("No win. Spins since last win: ", spin_count_since_last_win)
		_show_result_label("NO MATCH\nTRY AGAIN!", Color.DARK_GRAY)

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

func generate_targets():
	if not is_busy():
		var random_targets: Array[int] = [randi_range(0, 11), randi_range(0, 11), randi_range(0, 11)]
		spin_with_targets(random_targets)
