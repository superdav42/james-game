extends Node2D

const BOARD_SIZE := 600.0
const BOARD_TOP := 250.0
const MAX_ZOOM := 10.0
const PAN_SPEED := 520.0

const ARTILLERY := "artillery"
const SPYGLASS := "spyglass"
const TURRET := "turret"
const BASE := "base"
const RED := "red"
const BLUE := "blue"

const BACKGROUND_COLOR := Color("0c1120")
const PANEL_COLOR := Color("151d30")
const TEXT_COLOR := Color("e7edf5")
const MUTED_TEXT_COLOR := Color("aab6c8")
const GOLD_COLOR := Color("f4c95d")
const ERROR_COLOR := Color("ff8b7d")
const TEAM_COLORS := {
	RED: Color("f05252"),
	BLUE: Color("35a7ff"),
}
const UNIT_LETTERS := {
	ARTILLERY: "A",
	SPYGLASS: "S",
	TURRET: "T",
	BASE: "B",
}

const GROUND_TEXTURES := [
	preload("res://assets/kenney/tiny_battle/ground.png"),
	preload("res://assets/kenney/tiny_battle/ground_detail.png"),
	preload("res://assets/kenney/tiny_battle/ground_flowers.png"),
]
const MOUNTAIN_TEXTURE := preload("res://assets/kenney/tiny_battle/mountain.png")
const TREE_TEXTURE := preload("res://assets/kenney/tiny_battle/trees.png")
const UNIT_TEXTURES := {
	RED: {
		ARTILLERY: preload("res://assets/kenney/tiny_battle/red_artillery.png"),
		SPYGLASS: preload("res://assets/kenney/tiny_battle/red_spyglass.png"),
		TURRET: preload("res://assets/kenney/tiny_battle/red_turret.png"),
		BASE: preload("res://assets/kenney/tiny_battle/red_base.png"),
	},
	BLUE: {
		ARTILLERY: preload("res://assets/kenney/tiny_battle/blue_artillery.png"),
		SPYGLASS: preload("res://assets/kenney/tiny_battle/blue_spyglass.png"),
		TURRET: preload("res://assets/kenney/tiny_battle/blue_turret.png"),
		BASE: preload("res://assets/kenney/tiny_battle/blue_base.png"),
	},
}

const CLICK_SOUND := preload("res://assets/kenney/audio/click.ogg")
const SELECT_SOUND := preload("res://assets/kenney/audio/select.ogg")
const CONFIRM_SOUND := preload("res://assets/kenney/audio/confirm.ogg")
const ERROR_SOUND := preload("res://assets/kenney/audio/error.ogg")
const MOVE_SOUND := preload("res://assets/kenney/audio/move.ogg")
const IMPACT_SOUND := preload("res://assets/kenney/audio/impact.ogg")
const VICTORY_SOUND := preload("res://assets/kenney/audio/victory.ogg")

var units: Dictionary[String, Vector2i] = {}
var mountains: Array[Vector2i] = []
var trees: Array[Vector2i] = []
var impact_cells: Array[Vector2i] = []
var grid_size := 10
var cell_size := 60.0
var board_origin := Vector2(60.0, BOARD_TOP)
var board_pan := Vector2.ZERO
var zoom_level := 1.0
var active_team := RED
var selected_unit := ""
var selected_artillery := "red_artillery"
var valid_moves: Array[Vector2i] = []
var valid_targets: Array[String] = []
var unit_serial := 1
var turn_number := 1
var game_over := false
var handoff_pending := true
var pending_handoff_message := ""
var sound_enabled := true
var drag_active := false
var drag_moved := false
var drag_start := Vector2.ZERO
var drag_pan_start := Vector2.ZERO
var impact_flash_time := 0.0

@onready var background: ColorRect = $Background
@onready var turn_label: Label = $Hud/TurnLabel
@onready var status_label: Label = $Hud/StatusLabel
@onready var coordinate_input: LineEdit = $Hud/CoordinateInput
@onready var fire_button: Button = $Hud/FireButton
@onready var grid_size_input: SpinBox = $Hud/GridSizeInput
@onready var reset_button: Button = $Hud/ResetButton
@onready var make_spyglass_button: Button = $Hud/MakeSpyglassButton
@onready var make_turret_button: Button = $Hud/MakeTurretButton
@onready var zoom_label: Label = $Hud/ZoomLabel
@onready var zoom_out_button: Button = $Hud/ZoomOutButton
@onready var zoom_in_button: Button = $Hud/ZoomInButton
@onready var fit_button: Button = $Hud/FitButton
@onready var sound_button: Button = $Hud/SoundButton
@onready var handoff_overlay: ColorRect = $Hud/HandoffOverlay
@onready var handoff_title: Label = $Hud/HandoffOverlay/HandoffCard/HandoffMargin/HandoffContent/HandoffTitle
@onready var handoff_message: Label = $Hud/HandoffOverlay/HandoffCard/HandoffMargin/HandoffContent/HandoffMessage
@onready var begin_turn_button: Button = $Hud/HandoffOverlay/HandoffCard/HandoffMargin/HandoffContent/BeginTurnButton
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer
@onready var jingle_player: AudioStreamPlayer = $JinglePlayer


func _ready() -> void:
	randomize()
	coordinate_input.text_submitted.connect(_on_coordinate_submitted)
	fire_button.pressed.connect(_fire_at_entered_coordinate)
	reset_button.pressed.connect(_apply_grid_size)
	make_spyglass_button.pressed.connect(_produce_unit.bind(SPYGLASS))
	make_turret_button.pressed.connect(_produce_unit.bind(TURRET))
	zoom_out_button.pressed.connect(_change_zoom.bind(0.5))
	zoom_in_button.pressed.connect(_change_zoom.bind(2.0))
	fit_button.pressed.connect(_reset_zoom)
	sound_button.pressed.connect(_toggle_sound)
	begin_turn_button.pressed.connect(_begin_turn)
	get_viewport().size_changed.connect(_layout_hud)
	_apply_visual_theme()
	_layout_hud()
	grid_size_input.value = grid_size
	_create_new_board()


func _process(delta: float) -> void:
	if impact_flash_time > 0.0:
		impact_flash_time = maxf(0.0, impact_flash_time - delta)
		queue_redraw()

	if handoff_pending or game_over or zoom_level <= 1.0 or coordinate_input.has_focus():
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		board_pan -= direction * PAN_SPEED * delta
		_clamp_board_pan()
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if handoff_pending or game_over:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed and _board_rect().has_point(event.position):
			_change_zoom(1.2, event.position)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed and _board_rect().has_point(event.position):
			_change_zoom(1.0 / 1.2, event.position)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _board_rect().has_point(event.position):
				_begin_board_drag(event.position)
			elif not event.pressed and drag_active:
				_finish_board_drag(event.position)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and drag_active:
		_update_board_drag(event.position)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenTouch:
		if event.pressed and _board_rect().has_point(event.position):
			_begin_board_drag(event.position)
		elif not event.pressed and drag_active:
			_finish_board_drag(event.position)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenDrag and drag_active:
		_update_board_drag(event.position)
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var board_rect := _board_rect()
	draw_rect(Rect2(board_rect.position + Vector2(7.0, 9.0), board_rect.size), Color(0.0, 0.0, 0.0, 0.32), true)
	draw_rect(board_rect, Color("75b85a"), true)

	var visible_bounds := _visible_cell_bounds()
	for row in range(visible_bounds.position.y, visible_bounds.end.y):
		for column in range(visible_bounds.position.x, visible_bounds.end.x):
			var cell := Vector2i(column, row)
			var rect := _cell_rect(cell)
			var pattern := absi(column * 17 + row * 31) % 19
			var ground_index := 2 if pattern == 0 else (1 if pattern < 5 else 0)
			draw_texture_rect(GROUND_TEXTURES[ground_index], rect, false)
			if (row + column) % 2 == 1:
				draw_rect(rect, Color(0.05, 0.12, 0.04, 0.07), true)
			if cell in valid_moves:
				var highlight_inset := minf(5.0, rect.size.x * 0.1)
				draw_rect(rect.grow(-highlight_inset), Color(0.35, 0.95, 0.55, 0.42), true)
				draw_rect(rect.grow(-highlight_inset), Color("a8ffb8"), false, maxf(1.0, rect.size.x * 0.045))
			if rect.size.x >= 12.0:
				draw_rect(rect, Color(0.07, 0.13, 0.08, 0.34), false, minf(1.5, rect.size.x * 0.05))

	for tree in trees:
		if _is_cell_visible(tree):
			_draw_cell_texture(TREE_TEXTURE, tree, 0.92)

	for mountain in mountains:
		if _is_cell_visible(mountain):
			_draw_cell_texture(MOUNTAIN_TEXTURE, mountain, 0.88)

	var font := ThemeDB.fallback_font
	if selected_unit != "" and _unit_type(selected_unit) == SPYGLASS and _effective_cell_size() >= 24.0:
		for cell in valid_moves:
			if not _is_cell_visible(cell):
				continue
			var rect := _cell_rect(cell)
			var coordinate_font_size := clampi(roundi(rect.size.x * 0.2), 8, 13)
			draw_string(font, rect.position + Vector2(3.0, coordinate_font_size + 2.0), _cell_to_coordinate(cell), HORIZONTAL_ALIGNMENT_LEFT, -1.0, coordinate_font_size, Color("112819"))

	for impact_cell in impact_cells:
		if _is_cell_visible(impact_cell):
			_draw_impact(impact_cell)

	for unit_id in units:
		if not _is_unit_visible_to_active_team(unit_id) or not _is_cell_visible(units[unit_id]):
			continue
		_draw_unit(unit_id, font)

	# Mask overflow from partially visible edge cells before drawing the crisp frame.
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, Vector2(viewport_size.x, board_origin.y)), BACKGROUND_COLOR, true)
	draw_rect(Rect2(Vector2(0.0, board_origin.y + BOARD_SIZE), Vector2(viewport_size.x, maxf(0.0, viewport_size.y - board_origin.y - BOARD_SIZE))), BACKGROUND_COLOR, true)
	draw_rect(Rect2(Vector2(0.0, board_origin.y), Vector2(board_origin.x, BOARD_SIZE)), BACKGROUND_COLOR, true)
	draw_rect(Rect2(Vector2(board_origin.x + BOARD_SIZE, board_origin.y), Vector2(maxf(0.0, viewport_size.x - board_origin.x - BOARD_SIZE), BOARD_SIZE)), BACKGROUND_COLOR, true)
	draw_rect(board_rect, Color("30496a"), false, 4.0)


func _draw_cell_texture(texture: Texture2D, cell: Vector2i, scale: float) -> void:
	var rect := _cell_rect(cell)
	var sprite_size := rect.size * scale
	var sprite_rect := Rect2(rect.get_center() - sprite_size * 0.5, sprite_size)
	draw_texture_rect(texture, sprite_rect, false)


func _draw_unit(unit_id: String, font: Font) -> void:
	var cell: Vector2i = units[unit_id]
	var rect := _cell_rect(cell)
	var center := rect.get_center()
	var team := _unit_team(unit_id)
	var unit_type := _unit_type(unit_id)
	var is_selected := unit_id == selected_unit
	var is_armed := unit_id == selected_artillery
	var is_revealed_enemy := team != active_team
	var ring_radius := rect.size.x * 0.43
	if is_revealed_enemy:
		draw_circle(center, ring_radius, GOLD_COLOR, false, maxf(2.0, rect.size.x * 0.07))
	if is_selected:
		draw_circle(center, ring_radius, Color.WHITE, false, maxf(2.0, rect.size.x * 0.08))
	elif is_armed:
		draw_circle(center, ring_radius, Color("8fe7ff"), false, maxf(1.5, rect.size.x * 0.055))

	var shadow_size := rect.size * 0.58
	_draw_unit_shadow(center + Vector2(0.0, rect.size.y * 0.22), shadow_size.x * 0.5, shadow_size.y * 0.18, Color(0.0, 0.0, 0.0, 0.34))
	var team_textures: Dictionary = UNIT_TEXTURES[team]
	var texture: Texture2D = team_textures[unit_type]
	var sprite_size := rect.size * 0.8
	draw_texture_rect(texture, Rect2(center - sprite_size * 0.5, sprite_size), false)

	if rect.size.x >= 34.0:
		var badge_radius := clampf(rect.size.x * 0.13, 6.0, 11.0)
		var badge_center := rect.position + Vector2(rect.size.x - badge_radius - 3.0, badge_radius + 3.0)
		draw_circle(badge_center, badge_radius, Color("111827"))
		draw_string(font, badge_center + Vector2(-badge_radius, badge_radius * 0.52), UNIT_LETTERS[unit_type], HORIZONTAL_ALIGNMENT_CENTER, badge_radius * 2.0, roundi(badge_radius * 1.35), Color.WHITE)


func _draw_unit_shadow(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(20):
		var angle := TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)


func _draw_impact(cell: Vector2i) -> void:
	var rect := _cell_rect(cell)
	var center := rect.get_center()
	var pulse := 1.0 + impact_flash_time * 0.6
	var radius := minf(rect.size.x * 0.34 * pulse, 24.0)
	var width := maxf(2.0, rect.size.x * 0.07)
	draw_circle(center, radius, Color(1.0, 0.42, 0.08, 0.9), false, width)
	draw_line(center + Vector2(-radius * 0.7, -radius * 0.7), center + Vector2(radius * 0.7, radius * 0.7), Color("611d12"), width)
	draw_line(center + Vector2(radius * 0.7, -radius * 0.7), center + Vector2(-radius * 0.7, radius * 0.7), Color("611d12"), width)


func _apply_grid_size() -> void:
	grid_size = int(grid_size_input.value)
	cell_size = BOARD_SIZE / float(grid_size)
	_reset_zoom()
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
	turn_number = 1
	game_over = false
	coordinate_input.clear()
	coordinate_input.editable = true
	fire_button.disabled = false
	make_spyglass_button.disabled = false
	make_turret_button.disabled = false
	turn_label.modulate = Color.WHITE
	_set_status("Red artillery armed with unlimited range. Enemy units remain hidden until scouted.")
	_update_turn_label()
	_show_handoff("New battlefield ready. Red deploys first.")
	queue_redraw()


func _begin_board_drag(position: Vector2) -> void:
	drag_active = true
	drag_moved = false
	drag_start = position
	drag_pan_start = board_pan


func _update_board_drag(position: Vector2) -> void:
	var offset := position - drag_start
	if offset.length() > 10.0:
		drag_moved = true
	if drag_moved and zoom_level > 1.0:
		board_pan = drag_pan_start + offset
		_clamp_board_pan()
		queue_redraw()


func _finish_board_drag(position: Vector2) -> void:
	var should_tap := not drag_moved and _board_rect().has_point(position)
	drag_active = false
	if should_tap:
		_handle_board_tap(position)


func _handle_board_tap(position: Vector2) -> void:
	var cell := _screen_to_cell(position)
	if not _is_inside_grid(cell):
		return
	var clicked_unit := _unit_at(cell)
	if selected_unit != "" and clicked_unit in valid_targets:
		_fire_turret_at(clicked_unit)
	elif clicked_unit != "" and _unit_team(clicked_unit) == active_team:
		_select_unit(clicked_unit)
	elif selected_unit != "" and cell in valid_moves:
		units[selected_unit] = cell
		_play_sfx(MOVE_SOUND)
		var move_message := "%s moved to %s." % [_display_name(selected_unit), _cell_to_coordinate(cell)]
		selected_unit = ""
		valid_moves.clear()
		valid_targets.clear()
		_end_turn(move_message)
	elif selected_unit != "":
		_set_status("That square cannot be reached this move.", true)


func _select_unit(unit_id: String) -> void:
	if _unit_team(unit_id) != active_team:
		_set_status("It is %s's turn." % active_team.capitalize(), true)
		return

	_play_sfx(SELECT_SOUND)
	if _unit_type(unit_id) == ARTILLERY:
		selected_artillery = unit_id
		selected_unit = ""
		valid_moves.clear()
		valid_targets.clear()
		_set_status("%s armed · Unlimited range · Enter %s." % [_display_name(unit_id), _coordinate_range_text()])
	elif _unit_type(unit_id) == BASE:
		selected_unit = unit_id
		valid_moves.clear()
		valid_targets.clear()
		_set_status("%s selected · Choose a production order below." % _display_name(unit_id))
	else:
		selected_unit = unit_id
		valid_moves = _get_valid_moves(unit_id)
		valid_targets = _get_turret_targets(unit_id)
		if _unit_type(unit_id) == SPYGLASS:
			_set_status("%s · Scout and move up to 3 spaces." % _display_name(unit_id))
		else:
			_set_status("%s · Move up to 4 spaces, or fire at a coordinate." % _display_name(unit_id))
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
		_set_status("%s has no base remaining." % active_team.capitalize(), true)
		return
	if selected_unit != base_id:
		_set_status("Select your base before producing a unit.", true)
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
		_set_status("The base is surrounded. Clear an adjacent square first.", true)
		return

	var new_unit_id := "%s_%s_%d" % [active_team, unit_type, unit_serial]
	unit_serial += 1
	units[new_unit_id] = spawn_cell
	_play_sfx(CONFIRM_SOUND)
	_end_turn("%s produced %s at %s." % [_display_name(base_id), _display_name(new_unit_id), _cell_to_coordinate(spawn_cell)])


func _spyglass_moves(unit_id: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var start: Vector2i = units[unit_id]
	for row in range(grid_size):
		for column in range(grid_size):
			var cell := Vector2i(column, row)
			var offset := cell - start
			var distance_squared: int = offset.x * offset.x + offset.y * offset.y
			if distance_squared > 0 and distance_squared <= 9 and _unit_at(cell) == "":
				result.append(cell)
	return result


func _turret_moves(unit_id: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var start: Vector2i = units[unit_id]
	var frontier: Array[Vector2i] = [start]
	var distances: Dictionary[Vector2i, float] = {start: 0.0}
	var directions: Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]

	while not frontier.is_empty():
		var closest_index := 0
		for index in range(1, frontier.size()):
			if distances[frontier[index]] < distances[frontier[closest_index]]:
				closest_index = index
		var current: Vector2i = frontier.pop_at(closest_index)
		var distance: float = distances[current]
		for direction in directions:
			var next_cell: Vector2i = current + direction
			if not _is_inside_grid(next_cell):
				continue
			if next_cell in mountains or _unit_at(next_cell) != "":
				continue
			var step_cost := sqrt(2.0) if direction.x != 0 and direction.y != 0 else 1.0
			var next_distance: float = distance + step_cost
			if next_distance > 4.0:
				continue
			if distances.has(next_cell) and distances[next_cell] <= next_distance:
				continue
			distances[next_cell] = next_distance
			if next_cell not in frontier:
				frontier.append(next_cell)
			if next_cell not in result:
				result.append(next_cell)
	return result


func _is_unit_visible_to_active_team(unit_id: String) -> bool:
	if _unit_team(unit_id) == active_team:
		return true
	var target: Vector2i = units[unit_id]
	var target_is_in_tree := target in trees
	for observer_id in units:
		if _unit_team(observer_id) != active_team or _unit_type(observer_id) != SPYGLASS:
			continue
		var observer: Vector2i = units[observer_id]
		var offset := target - observer
		if target_is_in_tree:
			if maxi(absi(offset.x), absi(offset.y)) <= 1:
				return true
		elif offset.x * offset.x + offset.y * offset.y <= 9:
			return true
	return false


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
		_set_status("That coordinate is beyond the turret's 4-square range.", true)
		return
	var hit_unit := _unit_at(target)
	if hit_unit != "" and _unit_team(hit_unit) == active_team:
		_set_status("Cannot fire on a friendly unit at %s." % _cell_to_coordinate(target), true)
		return

	_record_impact(target)
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
	if game_over or handoff_pending:
		return
	var target := _coordinate_to_cell(coordinate_input.text)
	if not _is_inside_grid(target):
		_set_status("Invalid coordinate. Enter %s." % _coordinate_range_text(), true)
		return
	if selected_unit != "" and _unit_type(selected_unit) == TURRET:
		_fire_turret_at_coordinate(target)
		return
	if selected_artillery == "" or not units.has(selected_artillery):
		_set_status("Select one of the remaining artillery units first.", true)
		return
	if _unit_team(selected_artillery) != active_team:
		_set_status("Only %s artillery can fire this turn." % active_team.capitalize(), true)
		return

	var hit_unit := _unit_at(target)
	if hit_unit != "" and _unit_team(hit_unit) == _unit_team(selected_artillery):
		_set_status("Cannot fire on a friendly unit at %s." % _cell_to_coordinate(target), true)
		return

	_record_impact(target)
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


func _record_impact(target: Vector2i) -> void:
	impact_cells.append(target)
	if impact_cells.size() > 6:
		impact_cells.pop_front()
	impact_flash_time = 0.5
	_play_sfx(IMPACT_SOUND)
	queue_redraw()


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
	turn_label.text = "%s VICTORY" % winner.to_upper()
	turn_label.modulate = TEAM_COLORS[winner]
	_set_status("%s wins — %s's %s. Start a new map to play again." % [winner.capitalize(), defeated_team.capitalize(), defeat_reason])
	_play_jingle(VICTORY_SOUND)
	queue_redraw()
	return true


func _end_turn(action_message: String) -> void:
	active_team = BLUE if active_team == RED else RED
	turn_number += 1
	selected_unit = ""
	valid_moves.clear()
	valid_targets.clear()
	selected_artillery = "%s_artillery" % active_team if units.has("%s_artillery" % active_team) else ""
	_set_status("%s %s command is next." % [action_message, active_team.capitalize()])
	_update_turn_label()
	_show_handoff(action_message)
	queue_redraw()


func _show_handoff(action_message: String) -> void:
	handoff_pending = true
	pending_handoff_message = action_message
	handoff_title.text = "%s COMMAND" % active_team.to_upper()
	handoff_title.modulate = TEAM_COLORS[active_team]
	if turn_number == 1:
		handoff_message.text = "Pass the device to Red.\nThe battlefield stays hidden until they are ready."
	else:
		handoff_message.text = "Pass the device to %s.\n\nPrevious action: %s" % [active_team.capitalize(), action_message]
	begin_turn_button.text = "BEGIN %s TURN" % active_team.to_upper()
	handoff_overlay.show()


func _begin_turn() -> void:
	handoff_pending = false
	handoff_overlay.hide()
	_set_status("%s command ready · Select a unit or enter a target coordinate." % active_team.capitalize())
	_play_sfx(CONFIRM_SOUND)
	queue_redraw()


func _update_turn_label() -> void:
	turn_label.text = "%s COMMAND  ·  TURN %d" % [active_team.to_upper(), turn_number]
	turn_label.modulate = TEAM_COLORS[active_team]


func _change_zoom(factor: float, focus := Vector2(-1.0, -1.0)) -> void:
	if focus.x < 0.0:
		focus = _board_rect().get_center()
	var old_zoom := zoom_level
	var new_zoom := clampf(zoom_level * factor, 1.0, MAX_ZOOM)
	if is_equal_approx(old_zoom, new_zoom):
		return
	var focus_cell_position := (focus - board_origin - board_pan) / (cell_size * old_zoom)
	zoom_level = new_zoom
	board_pan = focus - board_origin - focus_cell_position * cell_size * zoom_level
	_clamp_board_pan()
	_update_zoom_controls()
	queue_redraw()


func _reset_zoom() -> void:
	zoom_level = 1.0
	board_pan = Vector2.ZERO
	_update_zoom_controls()
	queue_redraw()


func _clamp_board_pan() -> void:
	var minimum := BOARD_SIZE - BOARD_SIZE * zoom_level
	board_pan.x = clampf(board_pan.x, minimum, 0.0)
	board_pan.y = clampf(board_pan.y, minimum, 0.0)


func _update_zoom_controls() -> void:
	zoom_label.text = "%d%%" % roundi(zoom_level * 100.0)
	zoom_out_button.disabled = zoom_level <= 1.001
	zoom_in_button.disabled = zoom_level >= MAX_ZOOM - 0.001


func _toggle_sound() -> void:
	sound_enabled = not sound_enabled
	sound_button.text = "SOUND ON" if sound_enabled else "SOUND OFF"
	if sound_enabled:
		_play_sfx(CONFIRM_SOUND)
	else:
		sfx_player.stop()
		jingle_player.stop()


func _play_sfx(stream: AudioStream) -> void:
	if not sound_enabled:
		return
	sfx_player.stream = stream
	sfx_player.play()


func _play_jingle(stream: AudioStream) -> void:
	if not sound_enabled:
		return
	jingle_player.stream = stream
	jingle_player.play()


func _set_status(message: String, is_error := false) -> void:
	status_label.text = message
	status_label.modulate = ERROR_COLOR if is_error else TEXT_COLOR
	if is_error:
		_play_sfx(ERROR_SOUND)


func _layout_hud() -> void:
	var viewport_size := get_viewport_rect().size
	background.position = Vector2.ZERO
	background.size = viewport_size
	var left := maxf(24.0, (viewport_size.x - BOARD_SIZE) * 0.5)
	board_origin = Vector2(left, BOARD_TOP)

	$Hud/TopPanel.position = Vector2(left, 16.0)
	$Hud/TopPanel.size = Vector2(BOARD_SIZE, 214.0)
	$Hud/TitleLabel.position = Vector2(left + 20.0, 28.0)
	$Hud/TitleLabel.size = Vector2(560.0, 42.0)
	$Hud/SubtitleLabel.position = Vector2(left + 20.0, 70.0)
	$Hud/SubtitleLabel.size = Vector2(560.0, 22.0)
	turn_label.position = Vector2(left + 20.0, 99.0)
	turn_label.size = Vector2(560.0, 32.0)
	$Hud/LegendLabel.position = Vector2(left + 20.0, 134.0)
	$Hud/LegendLabel.size = Vector2(560.0, 24.0)
	$Hud/StatusPanel.position = Vector2(left + 12.0, 166.0)
	$Hud/StatusPanel.size = Vector2(576.0, 54.0)
	status_label.position = Vector2(left + 26.0, 172.0)
	status_label.size = Vector2(548.0, 42.0)
	$Hud/BoardFrame.position = board_origin - Vector2(6.0, 6.0)
	$Hud/BoardFrame.size = Vector2(612.0, 612.0)

	sound_button.position = board_origin + Vector2(12.0, 12.0)
	sound_button.size = Vector2(104.0, 42.0)
	fit_button.position = board_origin + Vector2(354.0, 12.0)
	fit_button.size = Vector2(68.0, 42.0)
	zoom_out_button.position = board_origin + Vector2(430.0, 12.0)
	zoom_out_button.size = Vector2(44.0, 42.0)
	zoom_label.position = board_origin + Vector2(478.0, 12.0)
	zoom_label.size = Vector2(70.0, 42.0)
	zoom_in_button.position = board_origin + Vector2(552.0, 12.0)
	zoom_in_button.size = Vector2(36.0, 42.0)

	$Hud/InstructionsLabel.position = Vector2(left + 16.0, 864.0)
	$Hud/InstructionsLabel.size = Vector2(568.0, 46.0)
	$Hud/ControlPanel.position = Vector2(left, 918.0)
	$Hud/ControlPanel.size = Vector2(BOARD_SIZE, 208.0)
	coordinate_input.position = Vector2(left + 16.0, 934.0)
	coordinate_input.size = Vector2(350.0, 54.0)
	fire_button.position = Vector2(left + 380.0, 934.0)
	fire_button.size = Vector2(204.0, 54.0)
	$Hud/GridSizeLabel.position = Vector2(left + 16.0, 1000.0)
	$Hud/GridSizeLabel.size = Vector2(108.0, 52.0)
	grid_size_input.position = Vector2(left + 128.0, 1000.0)
	grid_size_input.size = Vector2(102.0, 52.0)
	reset_button.position = Vector2(left + 244.0, 1000.0)
	reset_button.size = Vector2(340.0, 52.0)
	make_spyglass_button.position = Vector2(left + 16.0, 1064.0)
	make_spyglass_button.size = Vector2(272.0, 48.0)
	make_turret_button.position = Vector2(left + 312.0, 1064.0)
	make_turret_button.size = Vector2(272.0, 48.0)
	$Hud/FooterLabel.position = Vector2(left + 16.0, 1140.0)
	$Hud/FooterLabel.size = Vector2(568.0, 44.0)
	_clamp_board_pan()
	queue_redraw()


func _apply_visual_theme() -> void:
	var normal := _make_style(Color("202b43"), Color("3b4c6c"), 10, 2)
	var hover := _make_style(Color("2b3b59"), GOLD_COLOR, 10, 2)
	var pressed := _make_style(Color("10182a"), Color("8fe7ff"), 10, 2)
	var disabled := _make_style(Color("171e2d"), Color("29344a"), 10, 1)
	for node in get_tree().get_nodes_in_group("action_button"):
		var button := node as Button
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("focus", hover)
		button.add_theme_stylebox_override("disabled", disabled)
		button.add_theme_color_override("font_color", TEXT_COLOR)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
		button.add_theme_color_override("font_disabled_color", Color("667085"))
		button.button_down.connect(_play_sfx.bind(CLICK_SOUND))

	fire_button.add_theme_stylebox_override("normal", _make_style(Color("9f2f35"), Color("ff7b72"), 10, 2))
	fire_button.add_theme_stylebox_override("hover", _make_style(Color("c13d42"), GOLD_COLOR, 10, 2))
	begin_turn_button.add_theme_stylebox_override("normal", _make_style(Color("d9a72e"), Color("ffe39a"), 12, 2))
	begin_turn_button.add_theme_stylebox_override("hover", _make_style(Color("f0be43"), Color.WHITE, 12, 2))
	begin_turn_button.add_theme_color_override("font_color", Color("111827"))
	begin_turn_button.add_theme_color_override("font_hover_color", Color("111827"))

	var input_style := _make_style(Color("0d1424"), Color("3b4c6c"), 10, 2)
	var input_focus := _make_style(Color("101a2e"), GOLD_COLOR, 10, 2)
	coordinate_input.add_theme_stylebox_override("normal", input_style)
	coordinate_input.add_theme_stylebox_override("focus", input_focus)
	coordinate_input.add_theme_color_override("font_color", TEXT_COLOR)
	coordinate_input.add_theme_color_override("font_placeholder_color", Color("718096"))
	grid_size_input.add_theme_stylebox_override("normal", input_style)
	grid_size_input.add_theme_stylebox_override("focus", input_focus)
	_update_zoom_controls()


func _make_style(background_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


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
	var local_position := screen_position - board_origin - board_pan
	var effective_size := _effective_cell_size()
	return Vector2i(floori(local_position.x / effective_size), floori(local_position.y / effective_size))


func _cell_rect(cell: Vector2i) -> Rect2:
	var effective_size := _effective_cell_size()
	return Rect2(board_origin + board_pan + Vector2(cell) * effective_size, Vector2.ONE * effective_size)


func _effective_cell_size() -> float:
	return cell_size * zoom_level


func _board_rect() -> Rect2:
	return Rect2(board_origin, Vector2.ONE * BOARD_SIZE)


func _visible_cell_bounds() -> Rect2i:
	var effective_size := _effective_cell_size()
	var first_column := clampi(floori(-board_pan.x / effective_size) - 1, 0, grid_size - 1)
	var first_row := clampi(floori(-board_pan.y / effective_size) - 1, 0, grid_size - 1)
	var last_column := clampi(ceili((BOARD_SIZE - board_pan.x) / effective_size) + 1, 1, grid_size)
	var last_row := clampi(ceili((BOARD_SIZE - board_pan.y) / effective_size) + 1, 1, grid_size)
	return Rect2i(Vector2i(first_column, first_row), Vector2i(last_column - first_column, last_row - first_row))


func _is_cell_visible(cell: Vector2i) -> bool:
	return _cell_rect(cell).intersects(_board_rect())


func _is_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_size and cell.y >= 0 and cell.y < grid_size


func _display_name(unit_id: String) -> String:
	return "%s %s" % [_unit_team(unit_id).capitalize(), _unit_type(unit_id).capitalize()]
