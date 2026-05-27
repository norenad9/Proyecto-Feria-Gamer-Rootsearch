class_name GraphRenderer
extends Node2D
var graph: Graph = null
var node_states: Dictionary = {}
var highlighted_edges: Array = []
var verified_edges: Array = []
var dragging: bool = false
var drag_from: int = -1
var drag_mouse_pos: Vector2 = Vector2.ZERO
var _avatar_cache: Dictionary = {}
signal intento_conexion(from_id: int, to_id: int)
signal intento_borrado(from_id: int, to_id: int)
const CARD_W: float = 110.0
const CARD_H: float = 130.0
const PHOTO_MARGIN: float = 8.0
const PHOTO_SIZE: float = CARD_W - PHOTO_MARGIN * 2
const COLOR_BG := Color(0.04, 0.04, 0.06)
const COLOR_EDGE := Color(0.35, 0.35, 0.45)
const COLOR_VERIFIED := Color(0.2, 0.85, 0.35)
const COLOR_PATH := Color(0.3, 0.7, 1.0)
const COLOR_MST := Color(0.5, 1.0, 0.5)
const COLOR_ACTIVE := Color(1.0, 0.8, 0.2)
const COLOR_ORIGIN := Color(0.2, 0.6, 1.0)
const COLOR_SINK := Color(1.0, 0.3, 0.5)
func set_graph(g: Graph) -> void:
	graph = g
	queue_redraw()
func set_node_state(id: int, state: String) -> void:
	node_states[id] = state
	queue_redraw()
func set_highlighted_edges(edges: Array) -> void:
	highlighted_edges = edges
	queue_redraw()
func verify_edge(from_id: int, to_id: int) -> void:
	var pair := Vector2(from_id, to_id)
	if not verified_edges.has(pair):
		verified_edges.append(pair)
	queue_redraw()
func reset_visuals() -> void:
	node_states.clear()
	highlighted_edges.clear()
	queue_redraw()
func get_node_at(pos: Vector2) -> int:
	if graph == null: return -1
	for id in graph.nodes:
		var np: Vector2 = graph.nodes[id]["pos"]
		var r := Rect2(np.x - CARD_W * 0.5, np.y - CARD_H * 0.5, CARD_W, CARD_H)
		if r.has_point(pos):
			return id
	return -1
func _draw() -> void:
	if graph == null: return
	_draw_edges()
	_draw_highlighted_edges()
	if dragging and drag_from >= 0:
		var from_pos: Vector2 = graph.nodes[drag_from]["pos"]
		draw_line(from_pos, drag_mouse_pos, Color(0.6, 0.8, 1.0, 0.6), 3.0)
		_draw_dotted_circle(drag_mouse_pos)
	_draw_nodes()
func _draw_edges() -> void:
	for edge in graph.edge_list:
		var from_pos: Vector2 = graph.nodes[edge["from"]]["pos"]
		var to_pos: Vector2 = graph.nodes[edge["to"]]["pos"]
		var col := COLOR_EDGE
		var is_verified := false
		for v in verified_edges:
			if (v.x == edge["from"] and v.y == edge["to"]) or (v.y == edge["from"] and v.x == edge["to"]):
				is_verified = true; break
		if is_verified: col = COLOR_VERIFIED
		elif highlighted_edges.any(func(e): return (e["from"] == edge["from"] and e["to"] == edge["to"]) or (e["from"] == edge["to"] and e["to"] == edge["from"])):
			col = COLOR_PATH
		draw_line(from_pos, to_pos, col, 2.5 if is_verified else 1.5)
		var mid: Vector2 = (from_pos + to_pos) * 0.5
		draw_string(ThemeDB.fallback_font, mid + Vector2(4, -6), str(edge["weight"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.8, 0.8))
func _draw_highlighted_edges() -> void:
	for edge in highlighted_edges:
		if graph.nodes.has(edge["from"]) and graph.nodes.has(edge["to"]):
			var fp: Vector2 = graph.nodes[edge["from"]]["pos"]
			var tp: Vector2 = graph.nodes[edge["to"]]["pos"]
			draw_line(fp, tp, Color(0.3, 1.0, 0.5, 0.7), 4.0)
func _draw_nodes() -> void:
	for id in graph.nodes:
		var pos: Vector2 = graph.nodes[id]["pos"]
		var label: String = graph.nodes[id]["label"]
		var state: String = node_states.get(id, "")
		var border_col: Color
		match state:
			"active": border_col = COLOR_ACTIVE
			"visited": border_col = Color(0.6, 0.6, 0.8, 0.7)
			"path": border_col = COLOR_PATH
			"mst": border_col = COLOR_MST
			"origin": border_col = COLOR_ORIGIN
			"sink": border_col = COLOR_SINK
			_: border_col = Color(0.5, 0.5, 0.55)
		var cx: float = pos.x - CARD_W * 0.5
		var cy: float = pos.y - CARD_H * 0.5
		draw_rect(Rect2(cx + 3, cy + 4, CARD_W, CARD_H), Color(0, 0, 0, 0.3), false, 0.0, true)
		draw_rect(Rect2(cx, cy, CARD_W, CARD_H), Color(0.96, 0.96, 0.93))
		draw_rect(Rect2(cx, cy, CARD_W, CARD_H), border_col, false, 2.0)
		var photo_y: float = cy + 26.0
		draw_rect(Rect2(cx + PHOTO_MARGIN, photo_y, PHOTO_SIZE, PHOTO_SIZE), Color(0.85, 0.85, 0.85))
		var photo_center := Vector2(pos.x, photo_y + PHOTO_SIZE * 0.5)
		_draw_avatar(id, photo_center, PHOTO_SIZE, PHOTO_SIZE)
		var pin_pos := Vector2(pos.x, cy + 6)
		draw_circle(pin_pos, 8.0, Color(0.78, 0.08, 0.08))
		draw_circle(pin_pos, 8.0, Color(0.55, 0.05, 0.05), false, 1.5)
		draw_circle(pin_pos + Vector2(-2, -3), 2.5, Color(1.0, 0.5, 0.5, 0.55))
		var name_y: float = cy + CARD_H - 10.0
		var font: Font = ThemeDB.fallback_font
		var text_w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, Vector2(pos.x - text_w * 0.5, name_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.2, 0.2, 0.22))
func _draw_avatar(id: int, center: Vector2, w: float, h: float) -> void:
	var avatar_path: String = graph.nodes[id].get("avatar", "")
	if avatar_path == "":
		return
	if not _avatar_cache.has(avatar_path):
		if ResourceLoader.exists(avatar_path):
			_avatar_cache[avatar_path] = load(avatar_path)
		else:
			_avatar_cache[avatar_path] = null
	var tex: Texture2D = _avatar_cache.get(avatar_path)
	if tex == null:
		return
	draw_texture_rect(tex, Rect2(center.x - w * 0.5, center.y - h * 0.5, w, h), false)
func _draw_dotted_circle(pos: Vector2) -> void:
	var r: float = 20.0
	for i in range(0, 360, 15):
		var rad: float = deg_to_rad(i)
		var p: Vector2 = pos + Vector2(cos(rad), sin(rad)) * r
		draw_circle(p, 2.0, Color(0.6, 0.8, 1.0, 0.4))
func _unhandled_input(event: InputEvent) -> void:
	if graph == null: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var id := get_node_at(event.position)
			if id >= 0:
				dragging = true; drag_from = id; drag_mouse_pos = event.position
		elif dragging:
			dragging = false
			var target := get_node_at(event.position)
			if target >= 0 and target != drag_from:
				intento_conexion.emit(drag_from, target)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			var id := get_node_at(event.position)
			if id >= 0:
				var target := get_node_at(event.position)
				for edge in graph.edge_list:
					if (edge["from"] == id and edge["to"] == target) or (edge["from"] == target and edge["to"] == id):
						intento_borrado.emit(id, target)
						break
	elif event is InputEventMouseMotion and dragging:
		drag_mouse_pos = event.position
		queue_redraw()
