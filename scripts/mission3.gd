extends Node
@onready var renderer: GraphRenderer  = $GraphRenderer
@onready var log_label: RichTextLabel = $UI/Panel/VBox/LogLabel
@onready var btn_kruskal: Button      = $UI/Panel/VBox/HBoxButtons/BtnKruskal
@onready var btn_prim: Button         = $UI/Panel/VBox/HBoxButtons/BtnPrim
@onready var btn_reset: Button        = $UI/Panel/VBox/HBoxButtons/BtnReset
@onready var btn_next: Button         = $UI/Panel/VBox/BtnNext
@onready var status_label: Label      = $UI/Panel/VBox/StatusLabel
var graph: Graph = null
var mst_edges: Array = []
var current_step: int = 0
var animating: bool = false
var step_timer: float = 0.0
var highlighted_so_far: Array = []
const STEP_INTERVAL: float = 0.8
var btn_back: Button
var btn_ayuda: Button
var panel_ayuda: Panel
var dialog_box: Panel
var dialog_text: RichTextLabel
var name_label_diag: Label
func _ready() -> void:
	if NetworkManager.is_multiplayer_active() and NetworkManager.is_detective():
		get_tree().change_scene_to_file("res://scenes/Habitacion.tscn")
		return
	MisionFinal.mision_actual = MisionFinal.Misiones.M3_RED
	NetworkManager.broadcast_mission()
	var chat := ChatOverlay.new()
	add_child(chat)
	btn_kruskal.pressed.connect(_on_kruskal_pressed)
	btn_prim.pressed.connect(_on_prim_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_next.pressed.connect(_on_next_mission)
	btn_next.visible = false
	_setup_extra_ui()
	_build_graph()
	_log("[color=#88ccff]FASE 3 — Reconstruir la Red de Confianza[/color]")
	_log("El rumor digital se propago por toda la red social del campus.")
	_log("Debemos conectar a todos los involucrados con los lazos mas fuertes posibles.")
	status_label.text = "Analiza la red y reconstruye los enlaces."
	_show_intro_dialog()
func _setup_extra_ui() -> void:
	btn_back = Button.new()
	btn_back.text = "← Tablero"
	btn_back.position = Vector2(14, 14)
	btn_back.custom_minimum_size = Vector2(120, 36)
	btn_back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/mission_final.tscn"))
	add_child(btn_back)
	btn_ayuda = Button.new()
	btn_ayuda.text = "❓ Ayuda"
	btn_ayuda.position = Vector2(144, 14)
	btn_ayuda.custom_minimum_size = Vector2(110, 36)
	btn_ayuda.pressed.connect(_on_ayuda_pressed)
	add_child(btn_ayuda)
	panel_ayuda = Panel.new()
	panel_ayuda.position = Vector2(14, 56)
	panel_ayuda.size = Vector2(360, 360)
	panel_ayuda.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.14, 0.97)
	style.border_width_left = 2; style.border_width_top = 2
	style.border_width_right = 2; style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.6, 0.2)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	panel_ayuda.add_theme_stylebox_override("panel", style)
	add_child(panel_ayuda)
	var help_text := RichTextLabel.new()
	help_text.bbcode_enabled = true
	help_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_text.offset_left = 12; help_text.offset_top = 12
	help_text.offset_right = -12; help_text.offset_bottom = -44
	help_text.text = (
		"[b][color=#ffcc44]AYUDA — RECONSTRUIR CONEXIONES[/color][/b]\n\n"
		+ "[color=#aaddff]Cual es el objetivo?[/color]\n"
		+ "Conectar a todos los involucrados\n"
		+ "usando los lazos de confianza mas fuertes,\n"
		+ "al menor costo social posible.\n\n"
		+ "[color=#aaddff]Como funciona:[/color]\n"
		+ "El sistema evalua todas las conexiones posibles\n"
		+ "y selecciona las mas solidas para reconstruir\n"
		+ "la red social del campus.\n\n"
		+ "[color=#aaddff]Como usarlo:[/color]\n"
		+ "1. Pulsa [b]Reconstruir[/b] para iniciar el analisis.\n"
		+ "2. Observa como se restablecen los lazos.\n"
		+ "3. Una vez completo, avanza a la siguiente fase."
	)
	panel_ayuda.add_child(help_text)
	var btn_cerrar := Button.new()
	btn_cerrar.text = "Cerrar"
	btn_cerrar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_cerrar.offset_left = -100; btn_cerrar.offset_top = -38
	btn_cerrar.offset_right = -8; btn_cerrar.offset_bottom = -8
	btn_cerrar.pressed.connect(func() -> void: panel_ayuda.visible = false)
	panel_ayuda.add_child(btn_cerrar)
	dialog_box = Panel.new()
	dialog_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_box.offset_top = -120; dialog_box.offset_bottom = -8
	dialog_box.offset_left = 8; dialog_box.offset_right = -8
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.04, 0.04, 0.08, 0.95)
	ds.border_width_top = 3; ds.border_color = Color(0.3, 0.7, 0.8)
	dialog_box.add_theme_stylebox_override("panel", ds)
	dialog_box.visible = false
	add_child(dialog_box)
	name_label_diag = Label.new()
	name_label_diag.position = Vector2(16, 8)
	name_label_diag.add_theme_font_size_override("font_size", 18)
	name_label_diag.add_theme_color_override("font_color", Color(0.95, 0.75, 0.25))
	dialog_box.add_child(name_label_diag)
	dialog_text = RichTextLabel.new()
	dialog_text.bbcode_enabled = true
	dialog_text.position = Vector2(16, 34)
	dialog_text.size = Vector2(900, 76)
	dialog_text.add_theme_font_size_override("normal_font_size", 17)
	dialog_box.add_child(dialog_text)
func _show_intro_dialog() -> void:
	dialog_box.visible = true
	name_label_diag.text = "Sistema Forense"
	dialog_text.text = ("El acoso fragmento la red social de la Uninorte. Reconstruye los lazos de confianza para sanar los canales del campus.")
	await get_tree().create_timer(4.0).timeout
	dialog_box.visible = false
func _on_ayuda_pressed() -> void:
	panel_ayuda.visible = !panel_ayuda.visible
func _build_graph() -> void:
	graph = Graph.new(false)
	var positions: Array = [
		Vector2(400, 100), Vector2(180, 220), Vector2(620, 220),
		Vector2(100, 380), Vector2(340, 380), Vector2(560, 380),
		Vector2(240, 540), Vector2(460, 540),
	]
	var labels: Array = [
		"Central", "Grupo_A", "Grupo_B", "Nodo_3",
		"Nodo_4",  "Nodo_5",  "Nodo_6",  "Nodo_7"
	]
	for i: int in range(labels.size()): graph.add_node(i, labels[i], positions[i])
	graph.add_edge(0, 1, 4.0); graph.add_edge(0, 2, 6.0)
	graph.add_edge(1, 3, 3.0); graph.add_edge(1, 4, 2.0)
	graph.add_edge(2, 4, 5.0); graph.add_edge(2, 5, 1.0)
	graph.add_edge(3, 6, 4.0); graph.add_edge(4, 6, 3.0)
	graph.add_edge(4, 7, 5.0); graph.add_edge(5, 7, 2.0)
	graph.add_edge(6, 7, 6.0)
	renderer.set_graph(graph)
func _process(delta: float) -> void:
	if not animating or mst_edges.is_empty(): return
	step_timer += delta
	if step_timer >= STEP_INTERVAL:
		step_timer = 0.0
		_advance_mst_step()
func _advance_mst_step() -> void:
	if current_step >= mst_edges.size():
		animating = false; _finish_mst(); return
	var edge: Dictionary = mst_edges[current_step]
	highlighted_so_far.append({"from": edge["from"], "to": edge["to"]})
	renderer.set_highlighted_edges(highlighted_so_far)
	renderer.set_node_state(edge["from"], "mst"); renderer.set_node_state(edge["to"], "mst")
	_log("✅ Agrega: " + graph.nodes[edge["from"]]["label"] + " ↔ " + graph.nodes[edge["to"]]["label"] + "  costo=" + str(snapped(edge["weight"], 0.01)))
	current_step += 1
func _finish_mst() -> void:
	var total: float = 0.0
	for e: Dictionary in mst_edges: total += e["weight"]
	_log("\n[color=#66ff99]✅ Red social unificada con éxito.[/color]")
	status_label.text = "Red reconstruida. Costo total: " + str(snapped(total, 0.01))
	NetworkManager.send_algorithm_result("Red social reconstruida. Costo total: " + str(snapped(total, 0.01)) + ". Lazos de confianza restablecidos.")
	dialog_box.visible = true
	name_label_diag.text = "Informático"
	dialog_text.text = ("Topología de confianza enviada con éxito al panel del Detective.")
	btn_next.visible = true
func _start_mst(edges: Array, algo_name: String) -> void:
	mst_edges = edges; highlighted_so_far.clear(); current_step = 0; step_timer = 0.0; animating = true; dialog_box.visible = false
	renderer.reset_visuals(); btn_kruskal.disabled = true; btn_prim.disabled = true
	_log("\n[color=#ffdd88]Ejecutando " + algo_name + "...[/color]")
	status_label.text = algo_name + " en ejecución..."
func _on_kruskal_pressed() -> void: _start_mst(graph.kruskal(), "Kruskal")
func _on_prim_pressed() -> void: _start_mst(graph.prim(0), "Prim")
func _on_reset_pressed() -> void:
	animating = false; current_step = 0; mst_edges.clear(); highlighted_so_far.clear(); btn_kruskal.disabled = false; btn_prim.disabled = false; btn_next.visible = false; dialog_box.visible = false
	renderer.reset_visuals(); log_label.clear()
	status_label.text = "Reiniciado. Elige un metodo de reconstruccion."
func _on_next_mission() -> void:
	get_tree().change_scene_to_file("res://scenes/mission4.tscn")
func _log(text: String) -> void: log_label.append_text(text + "\n")
