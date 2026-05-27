extends Node
@onready var renderer: Node2D            = $GraphRenderer
@onready var log_label: RichTextLabel    = $UI/Panel/VBox/LogLabel
@onready var btn_run: Button             = $UI/Panel/VBox/HBoxButtons/BtnRun
@onready var btn_reset: Button           = $UI/Panel/VBox/HBoxButtons/BtnReset
@onready var btn_next: Button            = $UI/Panel/VBox/BtnNext
@onready var status_label: Label         = $UI/Panel/VBox/StatusLabel
@onready var source_option: OptionButton = $UI/Panel/VBox/HBoxInputs/SourceOption
@onready var target_option: OptionButton = $UI/Panel/VBox/HBoxInputs/TargetOption
var graph: Graph = null
var calculo_result: Dictionary = {}
var path_nodes: Array = []
var current_step: int = 0
var animating: bool = false
var step_timer: float = 0.0
const STEP_INTERVAL: float = 0.6
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
	MisionFinal.mision_actual = MisionFinal.Misiones.M2_RUTA
	NetworkManager.broadcast_mission()
	var chat := ChatOverlay.new()
	add_child(chat)
	btn_run.pressed.connect(_on_run_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_next.pressed.connect(_on_next_mission)
	btn_next.visible = false
	_setup_extra_ui()
	_build_red_conexiones()
	_populate_option_buttons()
	_log("[color=#aaddff]FASE 2 — Cortar la Propagacion[/color]")
	_log("Santi activo un script que replica el dano automaticamente.")
	_log("Cada conexion tiene un nivel de riesgo de ser interceptados.")
	_log("Selecciona desde donde intervenir y hacia donde, para trazar la ruta de menor riesgo.")
	status_label.text = "Red cargada. Elige los puntos de intervencion."
	_show_intro_dialog()
func _setup_extra_ui() -> void:
	btn_back = Button.new()
	btn_back.text = "← Panel Central"
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
	panel_ayuda.size = Vector2(360, 320)
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
		"[b][color=#ffcc44]AYUDA — ANALISIS DE RIESGO[/color][/b]\n\n"
		+ "[color=#aaddff]Cual es el objetivo?[/color]\n"
		+ "Encontrar el camino de comunicacion mas seguro\n"
		+ "desde un aliado hasta los archivos bloqueados.\n\n"
		+ "[color=#aaddff]Por que importa aqui?[/color]\n"
		+ "Cada enlace tiene un valor = riesgo de ser detectados.\n"
		+ "El sistema garantiza llegar a Alex por el\n"
		+ "canal MENOS arriesgado posible.\n\n"
		+ "[color=#aaddff]Como usarlo:[/color]\n"
		+ "1. Selecciona el PUNTO DE APOYO (origen).\n"
		+ "2. Selecciona la VICTIMA (destino).\n"
		+ "3. Pulsa [b]Calcular Ruta Optima[/b].\n"
		+ "4. Observa como se construye el canal seguro.\n\n"
		+ "Amarillo: Evaluando  Verde: En la ruta  Rojo: Origen  Violeta: Destino"
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
	dialog_box.offset_top = -130; dialog_box.offset_bottom = -8
	dialog_box.offset_left = 8; dialog_box.offset_right = -8
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.04, 0.04, 0.08, 0.95)
	ds.border_width_top = 3; ds.border_color = Color(0.3, 0.7, 0.3)
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
	dialog_text.position = Vector2(16, 36)
	dialog_text.size = Vector2(900, 82)
	dialog_text.add_theme_font_size_override("normal_font_size", 18)
	dialog_box.add_child(dialog_text)
func _show_intro_dialog() -> void:
	dialog_box.visible = true
	name_label_diag.text = "Sistema Forense"
	dialog_text.text = ("El sabotaje fue identificado. La terminal requiere la [color=#55ff55]ruta mas segura[/color] para intervenir los archivos de Alex. El analisis encontrara el camino de menor impacto de riesgo.")
	await get_tree().create_timer(4.0).timeout
	dialog_box.visible = false
func _on_ayuda_pressed() -> void:
	panel_ayuda.visible = !panel_ayuda.visible
func _build_red_conexiones() -> void:
	graph = Graph.new(false)
	var positions: Array = [
		Vector2(300, 120), Vector2(150, 280), Vector2(450, 280),
		Vector2(600, 120), Vector2(100, 440), Vector2(300, 440),
		Vector2(520, 440), Vector2(200, 560), Vector2(440, 560),
	]
	var labels: Array = [
		"Apoyo_A", "Moderador", "Admin", "Apoyo_B",
		"Amigo1", "Amigo2", "Amigo3", "Victima_A", "Victima_B"
	]
	for i: int in range(labels.size()): graph.add_node(i, labels[i], positions[i])
	graph.add_edge(0, 1, 2.0); graph.add_edge(0, 2, 5.0)
	graph.add_edge(3, 2, 3.0); graph.add_edge(1, 4, 1.0)
	graph.add_edge(1, 5, 4.0); graph.add_edge(2, 5, 2.0)
	graph.add_edge(2, 6, 6.0); graph.add_edge(4, 7, 3.0)
	graph.add_edge(5, 7, 1.0); graph.add_edge(5, 8, 3.0)
	graph.add_edge(6, 8, 2.0)
	if renderer.has_method("set_graph"):
		renderer.set_graph(graph)
func _populate_option_buttons() -> void:
	source_option.clear(); target_option.clear()
	for id in graph.nodes:
		var lbl: String = graph.nodes[id]["label"]
		source_option.add_item(lbl, id)
		target_option.add_item(lbl, id)
	source_option.select(0); target_option.select(7)
func _process(delta: float) -> void:
	if not animating or path_nodes.is_empty(): return
	step_timer += delta
	if step_timer >= STEP_INTERVAL:
		step_timer = 0.0
		_advance_path_step()
func _advance_path_step() -> void:
	if current_step >= path_nodes.size():
		animating = false; _finish_route(); return
	var node_id: int = path_nodes[current_step]
	if current_step > 0 and renderer.has_method("set_node_state"): 
		renderer.set_node_state(path_nodes[current_step - 1], "path")
	if renderer.has_method("set_node_state"):
		renderer.set_node_state(node_id, "active")
	var dist_val: float = calculo_result["dist"][node_id]
	_log("→ " + graph.nodes[node_id]["label"] + "  (riesgo acum: " + str(snapped(dist_val, 0.01)) + ")")
	current_step += 1
func _finish_route() -> void:
	var hi_edges: Array = []
	for i: int in range(path_nodes.size() - 1):
		hi_edges.append({"from": path_nodes[i], "to": path_nodes[i + 1]})
		if renderer.has_method("set_node_state"):
			renderer.set_node_state(path_nodes[i], "path")
	if path_nodes.size() > 0 and renderer.has_method("set_node_state"): 
		renderer.set_node_state(path_nodes[-1], "path")
	if renderer.has_method("set_highlighted_edges"):
		renderer.set_highlighted_edges(hi_edges)
	var total: float = calculo_result["dist"][path_nodes[-1]]
	var string_camino: String = _path_to_names(path_nodes)
	_log("\n[color=#66ff99]✅ Ruta de menor riesgo establecida de extremo a extremo.[/color]")
	_log("Canal: " + string_camino)
	_log("Costo total de exposición: " + str(snapped(total, 0.01)))
	status_label.text = "Inyección completada. Riesgo total: " + str(snapped(total, 0.01))
	NetworkManager.send_algorithm_result("🛡️ RUTA ESTABLECIDA SIN RIESGOS:\nCanal seguro inyectado: " + string_camino + "\nÍndice de exposición: " + str(snapped(total, 0.01)))
	dialog_box.visible = true
	name_label_diag.text = "Informático"
	dialog_text.text = ("Acceso seguro enviado en tiempo real al panel del Detective. Conexiones estables.")
	btn_next.visible = true
func _on_run_pressed() -> void:
	var source_id: int = source_option.get_item_id(source_option.selected)
	var target_id: int = target_option.get_item_id(target_option.selected)
	if source_id == target_id: return
	if renderer.has_method("reset_visuals"): renderer.reset_visuals()
	dialog_box.visible = false
	if renderer.has_method("set_node_state"):
		renderer.set_node_state(source_id, "origin")
		renderer.set_node_state(target_id, "sink")
	_log("\n[color=#ffdd88]Evaluando la seguridad de las trayectorias de datos...[/color]")
	calculo_result = graph.dijkstra(source_id)
	path_nodes = graph.reconstruct_path(calculo_result["prev"], source_id, target_id)
	if path_nodes.is_empty():
		status_label.text = "Ruta bloqueada o imposible."; return
	current_step = 0; step_timer = 0.0; animating = true; btn_run.disabled = true
	status_label.text = "Rastreo de seguridad en ejecución..."
func _on_reset_pressed() -> void:
	animating = false; current_step = 0; path_nodes.clear(); btn_run.disabled = false; btn_next.visible = false; dialog_box.visible = false
	if renderer.has_method("reset_visuals"): renderer.reset_visuals()
	log_label.clear()
	status_label.text = "Fase reiniciada. Selecciona puntos de acceso."
func _on_next_mission() -> void:
	get_tree().change_scene_to_file("res://scenes/mission3.tscn")
func _path_to_names(path: Array) -> String:
	var names: Array = []
	for id in path: if graph.nodes.has(id): names.append(graph.nodes[id]["label"])
	return " → ".join(names)
func _log(text: String) -> void: log_label.append_text(text + "\n")
