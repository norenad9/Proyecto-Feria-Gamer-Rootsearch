extends Node
@onready var renderer: Node2D = $GraphRenderer
@onready var log_label: RichTextLabel = $UI/Panel/VBox/LogLabel
@onready var btn_run: Button = $UI/Panel/VBox/HBoxButtons/BtnRun
@onready var btn_reset: Button = $UI/Panel/VBox/HBoxButtons/BtnReset
@onready var btn_next: Button = $UI/Panel/VBox/BtnNext
@onready var status_label: Label = $UI/Panel/VBox/StatusLabel
@onready var source_option: OptionButton = $UI/Panel/VBox/HBoxInputs/SourceOption
@onready var target_option: OptionButton = $UI/Panel/VBox/HBoxInputs/TargetOption
var graph: Graph = null
var calculo_result: Dictionary = {}
var flow_log: Array = []
var current_step: int = 0
var animating: bool = false
var step_timer: float = 0.0
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
	MisionFinal.mision_actual = MisionFinal.Misiones.M4_IMPACTO
	NetworkManager.broadcast_mission()
	var chat := ChatOverlay.new()
	add_child(chat)
	btn_run.pressed.connect(_on_run_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_next.pressed.connect(_on_next_mission)
	btn_next.visible = false
	_setup_extra_ui()
	_build_red_flujo()
	_populate_option_buttons()
	_log("[color=#ff8866]FASE 4 — Contener la Embestida Final[/color]")
	_log("Santi desplego un ataque masivo contra el servidor academico.")
	_log("Cada conexion tiene una capacidad maxima de datos maliciosos.")
	_log("Selecciona el punto de entrada y salida del ataque, y mide el flujo.")
	status_label.text = "Red cargada. Elige origen y destino del ataque."
	_show_intro_dialog()
func _setup_extra_ui() -> void:
	btn_back = Button.new()
	btn_back.text = "← Panel Central"
	btn_back.position = Vector2(14, 14)
	btn_back.custom_minimum_size = Vector2(120, 36)
	btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/mission_final.tscn"))
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
		"[b][color=#ffcc44]AYUDA — MEDIR CAPACIDAD DE RED[/color][/b]\n\n"
		+ "[color=#aaddff]Cual es el objetivo?[/color]\n"
		+ "Medir cuanta informacion maliciosa puede\n"
		+ "atravesar la red desde el origen del ataque\n"
		+ "hasta el servidor de Alex.\n\n"
		+ "[color=#aaddff]Como funciona:[/color]\n"
		+ "El sistema analiza cada conexion de la red\n"
		+ "y calcula la capacidad maxima de transmision\n"
		+ "que el cortafuegos debe soportar.\n\n"
		+ "El resultado indica si el cortafuegos actual\n"
		+ "es suficiente para contener el ataque."
	)
	panel_ayuda.add_child(help_text)
	var btn_cerrar := Button.new()
	btn_cerrar.text = "Cerrar"
	btn_cerrar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_cerrar.offset_left = -100; btn_cerrar.offset_top = -38
	btn_cerrar.offset_right = -8; btn_cerrar.offset_bottom = -8
	btn_cerrar.pressed.connect(func(): panel_ayuda.visible = false)
	panel_ayuda.add_child(btn_cerrar)
	dialog_box = Panel.new()
	dialog_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_box.offset_top = -130; dialog_box.offset_bottom = -8
	dialog_box.offset_left = 8; dialog_box.offset_right = -8
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.04, 0.04, 0.08, 0.95)
	ds.border_width_top = 3; ds.border_color = Color(0.8, 0.4, 0.2)
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
	dialog_text.text = ("El ataque de Santi intenta saturar el servidor de Alex con datos maliciosos. " +
		"Debemos calcular el flujo maximo del ataque para calibrar el firewall.")
	await get_tree().create_timer(4.0).timeout
	dialog_box.visible = false
func _on_ayuda_pressed() -> void:
	panel_ayuda.visible = !panel_ayuda.visible
func _build_red_flujo() -> void:
	graph = Graph.new(true)
	var positions: Array = [
		Vector2(200, 300), Vector2(400, 150), Vector2(400, 450),
		Vector2(600, 150), Vector2(600, 450), Vector2(800, 300),
	]
	var labels: Array = ["Rafa(Botnet)", "Camila", "Santi", "Yolanda", "Andres", "Alex(Servidor)"]
	for i: int in range(labels.size()): graph.add_node(i, labels[i], positions[i])
	graph.add_edge(0, 1, 10.0); graph.add_edge(0, 2, 8.0)
	graph.add_edge(1, 3, 7.0); graph.add_edge(2, 3, 4.0)
	graph.add_edge(3, 5, 12.0); graph.add_edge(1, 4, 5.0)
	graph.add_edge(4, 3, 3.0)
	if renderer.has_method("set_graph"):
		renderer.set_graph(graph)
func _populate_option_buttons() -> void:
	source_option.clear(); target_option.clear()
	for id in graph.nodes:
		var lbl: String = graph.nodes[id]["label"]
		source_option.add_item(lbl, id)
		target_option.add_item(lbl, id)
	source_option.select(0); target_option.select(5)
func _process(delta: float) -> void:
	if not animating: return
	step_timer += delta
	if step_timer >= STEP_INTERVAL:
		step_timer = 0.0
		_advance_flow_step()
func _advance_flow_step() -> void:
	if current_step >= flow_log.size():
		animating = false; _finish_flow(); return
	var step_data: Dictionary = flow_log[current_step]
	_log("Caudal: " + str(step_data["bottleneck"]) + " MB/s — Ruta: " + _path_to_names(step_data["path"]))
	current_step += 1
func _finish_flow() -> void:
	var total: float = calculo_result.get("max_flow", 0.0)
	_log("\n[color=#66ff99]Flujo maximo calculado: " + str(total) + " MB/s[/color]")
	status_label.text = "Firewall calibrado. Flujo max: " + str(total) + " MB/s"
	NetworkManager.send_algorithm_result("Analisis de capacidad completado. Flujo maximo: " + str(total) + " MB/s. Cortafuegos calibrado.")
	dialog_box.visible = true
	name_label_diag.text = "Informatico"
	dialog_text.text = ("Analisis de impacto enviado al Detective. Firewall calibrado exitosamente.")
	btn_next.visible = true
func _on_run_pressed() -> void:
	var source_id: int = source_option.get_item_id(source_option.selected)
	var target_id: int = target_option.get_item_id(target_option.selected)
	if source_id == target_id: return
	if renderer.has_method("reset_visuals"): renderer.reset_visuals()
	dialog_box.visible = false
	_log("\n[color=#ffdd88]Calculando capacidad de transmision...[/color]")
	calculo_result = graph.ford_fulkerson(source_id, target_id)
	flow_log = calculo_result.get("flow_log", [])
	if flow_log.is_empty():
		status_label.text = "No se encontraron caminos de flujo."
		return
	current_step = 0; step_timer = 0.0; animating = true; btn_run.disabled = true
	status_label.text = "Calculando flujo maximo..."
func _on_reset_pressed() -> void:
	animating = false; current_step = 0; flow_log.clear(); btn_run.disabled = false
	btn_next.visible = false; dialog_box.visible = false
	if renderer.has_method("reset_visuals"): renderer.reset_visuals()
	log_label.clear()
	status_label.text = "Reiniciado. Selecciona fuente y sumidero."
func _on_next_mission() -> void:
	NetworkManager.broadcast_victory()
func _path_to_names(path: Array) -> String:
	var names: Array = []
	for id in path:
		if graph.nodes.has(id): names.append(graph.nodes[id]["label"])
	return " → ".join(names)
func _log(text: String) -> void: log_label.append_text(text + "\n")
