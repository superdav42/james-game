extends Node2D

const BOARD_SIZE := 600.0
const BOARD_ORIGIN := Vector2(60.0, 260.0)

const ARTILLERY := "artillery"
const SPYGLASS := "spyglass"
const TURRET := "turret"
const BASE := "base"
const RED := "red"
const BLUE := "blue"

const TEAM_COLORS := {
	RED: Color("d94f4f"),
	BLUE: Color("4d8ee8"),
}
const UNIT_LETTERS := {
	ARTILLERY: "A",
	SPYGLASS: "S",
	TURRET: "T",
	BASE: "B",
}

var units: Dictionary[String, Vector2i] = {}
var mountains: Array[Vector2i] = []
var trees: Array[Vector2i] = []
var impact_cells: Array[Vector2i] = []
var grid_size := 10
var cell_size := 60.0
var active_team := RED
var selected_unit := ""
var selected_artillery := "red_artillery"
var valid_moves: Array[Vector2i] = []
var valid_targets: Array[String] = []
var unit_serial := 1
var game_over := false

@onready var turn_label: Label = $Hud/TurnLabel
@onready var status_label: Label = $Hud/StatusLabel
@onready var coordinate_input: LineEdit = $Hud/CoordinateInput
@onready var fire_button: Button = $Hud/FireButton
@onready var grid_size_input: SpinBox = $Hud/GridSizeInput
@onready var reset_button: Button = $Hud/ResetButton
@onready var make_spyglass_button: Button = $Hud/MakeSpyglassButton
@onready var make_turret_button: Button = $Hud/MakeTurretButton


func _ready() -> void:
	randomize()
	coordinate_input.text_submitted.connect(_on_coordinate_submitted)
	fire_button.pressed.connect(_fire_at_entered_coordinate)
	reset_button.pressed.connect(_apply_grid_size)
	make_spyglass_button.pressed.connect(_produce_unit.bind(SPYGLASS))
	make_turret_button.pressed.connect(_produce_unit.bind(TURRET))
	grid_size_input.value = grid_size
	_create_new_board()


func _unhandled_input(event: InputEvent) -> void:
	if game_over:
		return

	var click_position := Vector2.ZERO
	var was_pressed := false

	if event is InputEventMouseButton:
		was_pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		click_position = event.position
	elif event is InputEventScreenTouch:
		was_pressed = event.pressed
		click_position = event.position

	if not was_pressed:
		return

	var cell := _screen_to_cell(click_position)
	if not _is_inside_grid(cell):
		return

	var clicked_unit := _unit_at(cell)
	if selected_unit != "" and clicked_unit in valid_targets:
		_fire_turret_at(clicked_unit)
	elif clicked_unit != "" and _unit_team(clicked_unit) == active_team:
		_select_unit(clicked_unit)
	elif selected_unit != "" and cell in valid_moves:
		units[selected_unit] = cell
		var move_message := "%s moved to %s." % [_display_name(selected_unit), _cell_to_coordinate(cell)]
		selected_unit = ""
		valid_moves.clear()
		valid_targets.clear()
		_end_turn(move_message)
	elif selected_unit != "":
		status_label.text = "That square cannot be reached this move."


func _draw() -> void:
	var font := ThemeDB.fallback_font

	for row in range(grid_size):
		for column in range(grid_size):
			var cell := Vector2i(column, row)
			var rect := Rect2(BOARD_ORIGIN + Vector2(cell) * cell_size, Vector2.ONE * cell_size)
			var cell_color := Color("d8c99b") if (row + column) % 2 == 0 else Color("c9b783")
			draw_rect(rect, cell_color)
			if cell in valid_moves:
				var highlight_inset := minf(4.0, cell_size * 0.1)
				draw_rect(rect.grow(-highlight_inset), Color(0.25, 0.85, 0.45, 0.48))
			draw_rect(rect, Color("4a493f"), false, minf(1.5, cell_size * 0.08))

	for tree in trees:
		var center := _cell_center(tree)
		var canopy_radius := minf(18.0, cell_size * 0.3)
		var trunk_width := minf(6.0, cell_size * 0.12)
		draw_rect(Rect2(center + Vector2(-trunk_width * 0.5, canopy_radius * 0.2), Vector2(trunk_width, canopy_radius)), Color("71482b"))
		draw_circle(center + Vector2(0.0, -canopy_radius * 0.25), canopy_radius, Color("3f7d3b"))
		draw_circle(center + Vector2(-canopy_radius * 0.45, 0.0), canopy_radius * 0.65, Color("4d9146"))
		draw_circle(center + Vector2(canopy_radius * 0.45, 0.0), canopy_radius * 0.65, Color("2f6b35"))

	for mountain in mountains:
		var center := _cell_center(mountain)
		var mountain_half_width := minf(24.0, cell_size * 0.42)
		var mountain_half_height := minf(22.0, cell_size * 0.38)
		var peak := PackedVector2Array([
			center + Vector2(-mountain_half_width, mountain_half_height),
			center + Vector2(0.0, -mountain_half_height),
			center + Vector2(mountain_half_width, mountain_half_height),
		])
		draw_colored_polygon(peak, Color("696d6f"))
		draw_polyline(PackedVector2Array([peak[0], peak[1], peak[2], peak[0]]), Color("e1e5e8"), minf(2.0, cell_size * 0.1))

	for impact_cell in impact_cells:
		var center := _cell_center(impact_cell)
		var impact_radius := minf(17.0, cell_size * 0.3)
		var impact_width := minf(4.0, cell_size * 0.15)
		draw_circle(center, impact_radius, Color(1.0, 0.45, 0.08, 0.8), false, impact_width)
		draw_line(center + Vector2(-impact_radius, -impact_radius), center + Vector2(impact_radius, impact_radius), Color("3a1710"), impact_width)
		draw_line(center + Vector2(impact_radius, -impact_radius), center + Vector2(-impact_radius, impact_radius), Color("3a1710"), impact_width)

	if selected_unit != "" and _unit_type(selected_unit) == SPYGLASS:
		for cell in valid_moves:
			var label_position := BOARD_ORIGIN + Vector2(cell) * cell_size + Vector2(3.0, minf(15.0, cell_size * 0.32))
			var coordinate_font_size := clampi(roundi(cell_size * 0.24), 4, 14)
			draw_string(font, label_position, _cell_to_coordinate(cell), HORIZONTAL_ALIGNMENT_LEFT, -1.0, coordinate_font_size, Color("102818"))

	for unit_id in units:
		if _unit_team(unit_id) != active_team:
			continue
		var center: Vector2 = _cell_center(units[unit_id])
		var is_selected: bool = unit_id == selected_unit or unit_id == selected_artillery
		var unit_radius := minf(23.0, cell_size * 0.38)
		if is_selected:
			draw_circle(center, unit_radius + minf(4.0, cell_size * 0.1), Color.WHITE)
		draw_circle(center, unit_radius, TEAM_COLORS[_unit_team(unit_id)])
		var unit_font_size := clampi(roundi(cell_size * 0.4), 4, 24)
		draw_string(font, center + Vector2(-unit_radius, unit_font_size * 0.38), UNIT_LETTERS[_unit_type(unit_id)], HORIZONTAL_ALIGNMENT_CENTER, unit_radius * 2.0, unit_font_size, Color.WHITE)


func _apply_grid_size() -> void:
	grid_size = int(grid_size_input.value)
	cell_size = BOARD_SIZE / float(grid_size)
	_create_new_board()


func _create_new_board() -> void:
	var cells: Array[Vector2i] = []
	for row in range(grid_size):
		for column in range(grid_size):
			cells.append(Vector2i(column, row))
	cells.shuffle()

	units = {
		"red_artillery": cells.pop_back(),
		"red_spyglass": cells.pop_back(),
		"red_turret": cells.pop_back(),
		"red_base": cells.pop_back(),
		"blue_artillery": cells.pop_back(),
		"blue_spyglass": cells.pop_back(),
		"blue_turret": cells.pop_back(),
		"blue_base": cells.pop_back(),
	}
	mountains.clear()
	var mountain_count := mini(500, maxi(5, roundi(grid_size * grid_size * 0.14)))
	for index in range(mountain_count):
		mountains.append(cells.pop_back())
	trees.clear()
	var tree_count := mini(400, maxi(4, roundi(grid_size * grid_size * 0.1)))
	for index in range(tree_count):
		trees.append(cells.pop_back())

	impact_cells.clear()
	active_team = RED
	selected_unit = ""
	selected_artillery = "red_artillery"
	valid_moves.clear()
	valid_targets.clear()
	unit_serial = 1
	game_over = false
	coordinate_input.clear()
	coordinate_input.editable = true
	fire_button.disabled = false
	make_spyglass_button.disabled = false
	make_turret_button.disabled = false
	status_label.text = "Red artillery armed with unlimited range. Enemy units are hidden."
	_update_turn_label()
	queue_redraw()


func _select_unit(unit_id: String) -> void:
	if _unit_team(unit_id) != active_team:
		status_label.text = "It is %s's turn." % active_team.capitalize()
		return

	if _unit_type(unit_id) == ARTILLERY:
		selected_artillery = unit_id
		selected_unit = ""
		valid_moves.clear()
		valid_targets.clear()
		status_label.text = "%s armed. Unlimited range: enter %s." % [_display_name(unit_id), _coordinate_range_text()]
	elif _unit_type(unit_id) == BASE:
		selected_unit = unit_id
		valid_moves.clear()
		valid_targets.clear()
		status_label.text = "%s selected. Use a production button to make a unit." % _display_name(unit_id)
	else:
		selected_unit = unit_id
		valid_moves = _get_valid_moves(unit_id)
		valid_targets = _get_turret_targets(unit_id)
		if _unit_type(unit_id) == SPYGLASS:
			status_label.text = "%s: move up to 3 spaces; coordinates show possible destinations." % _display_name(unit_id)
		else:
			status_label.text = "%s: move up to 4 spaces, or enter a coordinate to shoot a hidden spyglass." % _display_name(unit_id)
	queue_redraw()


func _get_valid_moves(unit_id: String) -> Array[Vector2i]:
	if _unit_type(unit_id) == SPYGLASS:
		return _spyglass_moves(unit_id)
	if _unit_type(unit_id) == TURRET:
		return _turret_moves(unit_id)
	return []


func _produce_unit(unit_type: String) -> void:
	if game_over:
		return

	var base_id := "%s_base" % active_team
	if not units.has(base_id):
		status_label.text = "%s has no base remaining." % active_team.capitalize()
		return
	if selected_unit != base_id:
		status_label.text = "Select your base before producing a unit."
		return

	var directions: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]
	directions.shuffle()
	var spawn_cell := Vector2i(-1, -1)
	for direction in directions:
		var candidate: Vector2i = units[base_id] + direction
		if _is_inside_grid(candidate) and candidate not in mountains and _unit_at(candidate) == "":
			spawn_cell = candidate
			break

	if not _is_inside_grid(spawn_cell):
		status_label.text = "The base is surrounded. Clear an adjacent square first."
		return

	var new_unit_id := "%s_%s_%d" % [active_team, unit_type, unit_serial]
	unit_serial += 1
	units[new_unit_id] = spawn_cell
	_end_turn("%s produced %s at %s." % [_display_name(base_id), _display_name(new_unit_id), _cell_to_coordinate(spawn_cell)])


func _spyglass_moves(unit_id: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var start: Vector2i = units[unit_id]
	for row in range(grid_size):
		for column in range(grid_size):
			var cell := Vector2i(column, row)
			var distance: int = maxi(absi(cell.x - start.x), absi(cell.y - start.y))
			if distance > 0 and distance <= 3 and _unit_at(cell) == "":
				result.append(cell)
	return result


func _turret_moves(unit_id: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var start: Vector2i = units[unit_id]
	var frontier: Array[Vector2i] = [start]
	var distances: Dictionary[Vector2i, int] = {start: 0}
	var directions: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]

	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		var distance: int = distances[current]
		if distance >= 4:
			continue
		for direction in directions:
			var next_cell: Vector2i = current + direction
			if not _is_inside_grid(next_cell) or next_cell in distances:
				continue
			if next_cell in mountains or _unit_at(next_cell) != "":
				continue
			distances[next_cell] = distance + 1
			frontier.append(next_cell)
			result.append(next_cell)

	return result


func _get_turret_targets(unit_id: String) -> Array[String]:
	var result: Array[String] = []
	if _unit_type(unit_id) != TURRET:
		return result

	var start: Vector2i = units[unit_id]
	for target_id in units:
		if _unit_team(target_id) == _unit_team(unit_id) or _unit_type(target_id) != SPYGLASS:
			continue
		var target: Vector2i = units[target_id]
		var distance: int = maxi(absi(target.x - start.x), absi(target.y - start.y))
		if distance <= 4:
			result.append(target_id)
	return result


func _fire_turret_at(target_id: String) -> void:
	_fire_turret_at_coordinate(units[target_id])


func _fire_turret_at_coordinate(target: Vector2i) -> void:
	var attacker_id := selected_unit
	var start: Vector2i = units[attacker_id]
	var distance: int = maxi(absi(target.x - start.x), absi(target.y - start.y))
	if distance > 4:
		status_label.text = "That coordinate is beyond the turret's 4-square range."
		return

	var hit_unit := _unit_at(target)
	if hit_unit != "" and _unit_team(hit_unit) == active_team:
		status_label.text = "Cannot fire on a friendly unit at %s." % _cell_to_coordinate(target)
		return

	impact_cells.append(target)
	if impact_cells.size() > 6:
		impact_cells.pop_front()

	var fire_message := "%s fired at %s: miss." % [_display_name(attacker_id), _cell_to_coordinate(target)]
	if hit_unit != "" and _unit_type(hit_unit) == SPYGLASS:
		units.erase(hit_unit)
		fire_message = "%s shot %s at %s!" % [_display_name(attacker_id), _display_name(hit_unit), _cell_to_coordinate(target)]

	coordinate_input.clear()
	selected_unit = ""
	valid_moves.clear()
	valid_targets.clear()
	if hit_unit != "" and _unit_type(hit_unit) == SPYGLASS and _check_for_winner(_unit_team(hit_unit)):
		return
	_end_turn(fire_message)


func _on_coordinate_submitted(_coordinate: String) -> void:
	_fire_at_entered_coordinate()


func _fire_at_entered_coordinate() -> void:
	if game_over:
		return

	var target := _coordinate_to_cell(coordinate_input.text)
	if not _is_inside_grid(target):
		status_label.text = "Invalid coordinate. Enter %s." % _coordinate_range_text()
		return

	if selected_unit != "" and _unit_type(selected_unit) == TURRET:
		_fire_turret_at_coordinate(target)
		return

	if selected_artillery == "" or not units.has(selected_artillery):
		status_label.text = "Select one of the remaining artillery units first."
		return
	if _unit_team(selected_artillery) != active_team:
		status_label.text = "Only %s artillery can fire this turn." % active_team.capitalize()
		return

	var hit_unit := _unit_at(target)
	if hit_unit != "" and _unit_team(hit_unit) == _unit_team(selected_artillery):
		status_label.text = "Cannot fire on a friendly unit at %s." % _cell_to_coordinate(target)
		return

	impact_cells.append(target)
	if impact_cells.size() > 6:
		impact_cells.pop_front()

	var fire_message := ""
	if hit_unit == "":
		fire_message = "%s fired at %s: miss." % [_display_name(selected_artillery), _cell_to_coordinate(target)]
	else:
		units.erase(hit_unit)
		if selected_unit == hit_unit:
			selected_unit = ""
			valid_moves.clear()
			valid_targets.clear()
		fire_message = "%s fired at %s and hit %s!" % [_display_name(selected_artillery), _cell_to_coordinate(target), _display_name(hit_unit)]

	coordinate_input.clear()
	if hit_unit != "" and _check_for_winner(_unit_team(hit_unit)):
		return
	_end_turn(fire_message)


func _check_for_winner(defeated_team: String) -> bool:
	var artillery_alive := units.has("%s_artillery" % defeated_team)
	var support_unit_alive := false
	for unit_id in units:
		if _unit_team(unit_id) == defeated_team and _unit_type(unit_id) != ARTILLERY:
			support_unit_alive = true
			break

	if artillery_alive and support_unit_alive:
		return false

	game_over = true
	var winner := BLUE if defeated_team == RED else RED
	var defeat_reason := "artillery destroyed" if not artillery_alive else "all support units destroyed"
	selected_unit = ""
	selected_artillery = ""
	valid_moves.clear()
	valid_targets.clear()
	coordinate_input.editable = false
	fire_button.disabled = true
	make_spyglass_button.disabled = true
	make_turret_button.disabled = true
	turn_label.text = "%s WINS!" % winner.to_upper()
	turn_label.modulate = TEAM_COLORS[winner]
	status_label.text = "%s wins — %s's %s. Press Apply / New Map to play again." % [winner.capitalize(), defeated_team.capitalize(), defeat_reason]
	queue_redraw()
	return true


func _end_turn(action_message: String) -> void:
	active_team = BLUE if active_team == RED else RED
	selected_unit = ""
	valid_moves.clear()
	valid_targets.clear()
	selected_artillery = "%s_artillery" % active_team if units.has("%s_artillery" % active_team) else ""
	status_label.text = "%s %s's turn." % [action_message, active_team.capitalize()]
	_update_turn_label()
	queue_redraw()


func _update_turn_label() -> void:
	turn_label.text = "%s TURN" % active_team.to_upper()
	turn_label.modulate = TEAM_COLORS[active_team]


func _coordinate_to_cell(coordinate: String) -> Vector2i:
	var cleaned := coordinate.strip_edges().to_upper()
	if cleaned.length() < 2 or cleaned.length() > 5:
		return Vector2i(-1, -1)

	var split_index := 0
	while split_index < cleaned.length():
		var character_code := cleaned.unicode_at(split_index)
		if character_code < 65 or character_code > 90:
			break
		split_index += 1
	if split_index == 0 or split_index == cleaned.length():
		return Vector2i(-1, -1)

	var column := 0
	for index in range(split_index):
		column = column * 26 + cleaned.unicode_at(index) - 64
	var row_text := cleaned.substr(split_index)
	if not row_text.is_valid_int():
		return Vector2i(-1, -1)
	return Vector2i(column - 1, row_text.to_int() - 1)


func _cell_to_coordinate(cell: Vector2i) -> String:
	var column_number := cell.x + 1
	var column_letters := ""
	while column_number > 0:
		column_number -= 1
		column_letters = String.chr(65 + column_number % 26) + column_letters
		column_number = int(column_number / 26)
	return "%s%d" % [column_letters, cell.y + 1]


func _coordinate_range_text() -> String:
	return "A1 through %s" % _cell_to_coordinate(Vector2i(grid_size - 1, grid_size - 1))


func _unit_at(cell: Vector2i) -> String:
	for unit_id in units:
		if units[unit_id] == cell:
			return unit_id
	return ""


func _unit_team(unit_id: String) -> String:
	return RED if unit_id.begins_with("red_") else BLUE


func _unit_type(unit_id: String) -> String:
	return unit_id.get_slice("_", 1)


func _screen_to_cell(screen_position: Vector2) -> Vector2i:
	var local_position := screen_position - BOARD_ORIGIN
	return Vector2i(floori(local_position.x / cell_size), floori(local_position.y / cell_size))


func _cell_center(cell: Vector2i) -> Vector2:
	return BOARD_ORIGIN + Vector2(cell) * cell_size + Vector2.ONE * cell_size * 0.5


func _is_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_size and cell.y >= 0 and cell.y < grid_size


func _display_name(unit_id: String) -> String:
	return "%s %s" % [_unit_team(unit_id).capitalize(), _unit_type(unit_id).capitalize()]
