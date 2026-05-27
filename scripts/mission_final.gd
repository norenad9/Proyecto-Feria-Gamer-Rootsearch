class_name MisionFinal
extends Node
enum Misiones { M1_ORIGEN, M2_RUTA, M3_RED, M4_IMPACTO, M_FINAL }
static var mision_actual: Misiones = Misiones.M1_ORIGEN
static var pistas_descubiertas: Dictionary = {}
static var memoria_grafo: Array = []
static var memoria_verificados: Array = []
static var _intel_loggeado: bool = false
static var yolanda_delato_a_rafa: bool = false
static var historia_completada: bool = false
static var intel_enviada_m2: bool = false
static var intel_enviada_m3: bool = false
static var intel_enviada_m4: bool = false
enum Phase { CONSTRUCTION, VERIFIED, ANIMATING, CINEMATIC }
var current_phase: int = Phase.CONSTRUCTION
const VERDAD_M1: Array[Dictionary] = [
	{"from": 1, "to": 2, "req_pista": "chat_01",    "peso": 4.0}, 
	{"from": 2, "to": 3, "req_pista": "camila_1",   "peso": 2.0}, 
	{"from": 3, "to": 4, "req_pista": "log_admin",  "peso": 1.0}, 
	{"from": 5, "to": 3, "req_pista": "ip_andres",  "peso": 3.0}, 
	{"from": 3, "to": 0, "req_pista": "ataque_final","peso": 6.0}  
]
var renderer: GraphRenderer
var ui_layer: CanvasLayer
var cine_layer: CanvasLayer
var panel_libreta: Panel
var libreta_texto: RichTextLabel
var panel_terminal: Panel
var log_label: RichTextLabel
var panel_postits: Panel
var grid_postits: GridContainer
var btn_execute_bfs: Button
var btn_execute_dfs: Button
var btn_confrontar: Button
var _drag_key: String = ""
var _is_dragging: bool = false
var _drag_ghost: Panel = null
var opt_origen_din: OptionButton
var opt_destino_din: OptionButton
var btn_procesar_din: Button
var graph: Graph = null
var step_timer: float = 0.0
const STEP_INTERVAL: float = 0.75
var visit_order: Array = []
var visit_step: int = 0
var recorrido_final: Array = []
var shake_time: float = 0.0
const SHAKE_I: float = 10.0
var reproductor_audio: AudioStreamPlayer
var sprite_izq: TextureRect
var sprite_der: TextureRect
var txt_nombre_cine: Label
var txt_dialogo_cine: RichTextLabel
var lista_dialogos: Array[Dictionary] = []
var indice_dialogo: int = 0
var btn_cine_next: Button
func _ready() -> void:
	if NetworkManager.is_multiplayer_active():
		NetworkManager.pistas_synced.connect(func(_p: Dictionary):
			_refrescar_libreta(); _actualizar_postits()
			_revisar_desbloqueo_mision()
		)
	if NetworkManager.is_multiplayer_active() and NetworkManager.is_detective():
		get_tree().change_scene_to_file("res://scenes/Habitacion.tscn")
		return
	if NetworkManager.is_multiplayer_active():
		NetworkManager.victory_triggered.connect(func(): get_tree().change_scene_to_file("res://scenes/escena_victoria.tscn"))
	var chat = ChatOverlay.new()
	add_child(chat)
	_setup_audio_ambiente() 
	_setup_capas()
	_build_graph_unificado() 
	_setup_ui()
	renderer.intento_conexion.connect(_on_intento_conexion)
	renderer.intento_borrado.connect(_on_intento_borrado)
	_intel_loggeado = false
	_refrescar_libreta()
	_actualizar_postits()
	_verificar_desbloqueo_rastreo()
	_revisar_desbloqueo_mision()
	_notificar_mision_consola()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_revisar_desbloqueo_mision)
	add_child(timer)
func _notificar_mision_consola() -> void:
	match mision_actual:
		Misiones.M1_ORIGEN:
			_log("[color=#ffff55]► FASE 1 — Rastrear el Origen[/color]\n"
				+ "[b]Contexto:[/b] Alex sufrió un ataque coordinado desde varios frentes. Necesitamos descubrir quién inició todo.\n"
				+ "• Conecta los nodos de la red con las evidencias que el Detective te envía.\n"
				+ "• Una vez conectados, ejecuta el rastreador para hallar el punto de origen.")
		Misiones.M2_RUTA:
			_log("[color=#55aaff]► FASE 2 — Cortar la Propagación[/color]\n"
				+ "[b]Contexto:[/b] Santi activó un script que replica el daño automáticamente. Si no encontramos la ruta más rápida para intervenir, Alex perderá todos sus datos.\n"
				+ "[b]Objetivo:[/b] Trazar la ruta de menor resistencia desde un nodo seguro hasta la víctima.")
		Misiones.M3_RED:
			_log("[color=#88ccff]► FASE 3 — Reconstruir la Confianza[/color]\n"
				+ "[b]Contexto:[/b] El rumor digital se propagó por toda la red social del campus. Hay que restablecer los lazos rotos con el menor esfuerzo posible.\n"
				+ "[b]Objetivo:[/b] Conectar a todos los involucrados usando los enlaces más fuertes y de menor costo.")
		Misiones.M4_IMPACTO:
			_log("[color=#ff8866]► FASE 4 — Contener la Embestida Final[/color]\n"
				+ "[b]Contexto:[/b] Santi desplegó un ataque de denegación de servicio contra el servidor académico. Si el flujo de datos maliciosos supera la capacidad del cortafuegos, el sistema colapsará.\n"
				+ "[b]Objetivo:[/b] Medir cuánta información maliciosa puede atravesar la red para ajustar los filtros de seguridad a tiempo.")
func _setup_audio_ambiente() -> void:
	reproductor_audio = AudioStreamPlayer.new()
	reproductor_audio.volume_db = -12.0
	add_child(reproductor_audio)
	if ResourceLoader.exists("res://audio/bgm_mystery.mp3"):
		reproductor_audio.stream = load("res://audio/bgm_mystery.mp3")
	reproductor_audio.play()
func _setup_capas() -> void:
	var bg_layer := CanvasLayer.new(); bg_layer.layer = -1; add_child(bg_layer)
	var bg := TextureRect.new(); bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode = TextureRect.STRETCH_SCALE; bg.set_anchors_preset(Control.PRESET_FULL_RECT) ; bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://backgrounds/bg_corkboard.png"): bg.texture = load("res://backgrounds/bg_corkboard.png")
	bg_layer.add_child(bg)
	var graph_layer := CanvasLayer.new(); graph_layer.layer = 0; add_child(graph_layer)
	renderer = GraphRenderer.new(); renderer.name = "GraphRenderer"; graph_layer.add_child(renderer)
	ui_layer = CanvasLayer.new(); ui_layer.layer = 1; add_child(ui_layer)
	cine_layer = CanvasLayer.new(); cine_layer.layer = 10; cine_layer.visible = false; add_child(cine_layer)
func _build_graph_unificado() -> void:
	graph = Graph.new(mision_actual == Misiones.M4_IMPACTO)
	var pos: Array[Vector2] = [
		Vector2(400, 360), Vector2(540, 200), Vector2(790, 200),
		Vector2(640, 360), Vector2(840, 430), Vector2(490, 550)
	]
	var noms: Array[String] = ["Alex (Víctima)", "Rafa", "Camila", "Santi", "Yolanda", "Andrés"]
	for i: int in range(noms.size()):
		var nombre_limpio: String = _sanitizar_nombre(noms[i].split(" ")[0])
		var av: String = "res://avatars/" + nombre_limpio + "_avatar.png"
		graph.add_node(i, noms[i], pos[i], "neutral", {"avatar": av})
	if mision_actual == Misiones.M1_ORIGEN:
		if not memoria_grafo.is_empty():
			graph.edge_list = memoria_grafo.duplicate(true)
			renderer.verified_edges = memoria_verificados.duplicate(true)
	else:
		graph.add_edge(4, 1, 2.0)
		graph.add_edge(1, 2, 4.0)
		graph.add_edge(2, 3, 2.0)
		graph.add_edge(3, 4, 1.0)
		graph.add_edge(5, 3, 3.0)
		graph.add_edge(3, 0, 6.0)
		renderer.verified_edges = [Vector2(4,1), Vector2(1,2), Vector2(2,3), Vector2(3,4), Vector2(5,3), Vector2(3,0)]
	renderer.set_graph(graph)
func _sanitizar_nombre(raw: String) -> String:
	var tabla: Dictionary = {"á":"a","é":"e","í":"i","ó":"o","ú":"u","Á":"a","É":"e","Í":"i","Ó":"o","Ú":"u"}
	var result: String = raw.to_lower()
	for orig: String in tabla: result = result.replace(orig, tabla[orig])
	return result
func _setup_ui() -> void:
	var topbar := _make_panel(Color(0.04, 0.04, 0.06, 0.95), Color(0.5, 0.2, 0.2))
	topbar.set_anchors_preset(Control.PRESET_TOP_WIDE); topbar.offset_bottom = 50; ui_layer.add_child(topbar)
	_make_nav_button(topbar, "Oficina", Vector2(15, 7), Vector2(100, 36), func(): get_tree().change_scene_to_file("res://scenes/Habitacion.tscn"))
	_make_nav_button(topbar, "PC Forense", Vector2(125, 7), Vector2(110, 36), func(): get_tree().change_scene_to_file("res://scenes/PC.tscn"))
	_make_nav_button(topbar, "Reiniciar", Vector2(245, 7), Vector2(100, 36), func(): get_tree().reload_current_scene())
	var lbl_mision := Label.new(); lbl_mision.text = _titulo_mision(); lbl_mision.position = Vector2(445, 13); lbl_mision.add_theme_font_size_override("font_size", 16); topbar.add_child(lbl_mision)
	_make_nav_button(topbar, "Ayuda", Vector2(1020, 7), Vector2(85, 36), func(): _toggle_ayuda())
	panel_libreta = _make_panel(Color(0.95, 0.93, 0.88, 0.98), Color(0.5, 0.35, 0.2))
	panel_libreta.position = Vector2(15, 65); panel_libreta.size = Vector2(270, 310); ui_layer.add_child(panel_libreta)
	libreta_texto = RichTextLabel.new(); libreta_texto.bbcode_enabled = true; libreta_texto.position = Vector2(15, 20); libreta_texto.size = Vector2(240, 270); libreta_texto.add_theme_color_override("default_color", Color.BLACK); _refrescar_libreta(); panel_libreta.add_child(libreta_texto)
	panel_postits = _make_panel(Color(0.12, 0.12, 0.15, 0.95), Color(0.6, 0.4, 0.2))
	panel_postits.position = Vector2(15, 390); panel_postits.size = Vector2(270, 305); ui_layer.add_child(panel_postits)
	var lbl_post := Label.new(); lbl_post.text = "EVIDENCIAS (arrastra al grafo)"; lbl_post.position = Vector2(15, 8); lbl_post.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3)); panel_postits.add_child(lbl_post)
	var scroll := ScrollContainer.new(); scroll.position = Vector2(10, 32); scroll.size = Vector2(250, 260); panel_postits.add_child(scroll)
	grid_postits = GridContainer.new(); grid_postits.columns = 1; grid_postits.size = Vector2(246, 0); scroll.add_child(grid_postits)
	panel_terminal = _make_panel(Color(0.01, 0.03, 0.01, 0.97), Color(0.2, 0.7, 0.2))
	panel_terminal.set_anchors_preset(Control.PRESET_RIGHT_WIDE); panel_terminal.offset_left = -340; panel_terminal.offset_top = 65; panel_terminal.offset_right = -15; panel_terminal.offset_bottom = -15; ui_layer.add_child(panel_terminal)
	if mision_actual == Misiones.M1_ORIGEN: _setup_controles_m1()
	else: _setup_controles_din()
	log_label = RichTextLabel.new(); log_label.bbcode_enabled = true; log_label.position = Vector2(15, 300); log_label.size = Vector2(290, 320); log_label.add_theme_font_size_override("normal_font_size", 12) ; panel_terminal.add_child(log_label)
	_build_panel_ayuda()
func _setup_controles_m1() -> void:
	var instr := Label.new(); instr.text = "Arrastra una evidencia desde el panel izquierdo\nsobre un hilo del grafo para vincularla."; instr.position = Vector2(15, 15); instr.size = Vector2(290, 50); instr.autowrap_mode = TextServer.AUTOWRAP_WORD; instr.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9)); panel_terminal.add_child(instr)
	btn_execute_bfs = Button.new(); btn_execute_bfs.text = "Rastrear por niveles"; btn_execute_bfs.position = Vector2(15, 80); btn_execute_bfs.size = Vector2(290, 40); btn_execute_bfs.disabled = true; btn_execute_bfs.pressed.connect(_on_bfs_m1_pressed); panel_terminal.add_child(btn_execute_bfs)
	btn_execute_dfs = Button.new(); btn_execute_dfs.text = "Rastrear en cadena"; btn_execute_dfs.position = Vector2(15, 130); btn_execute_dfs.size = Vector2(290, 40); btn_execute_dfs.disabled = true; btn_execute_dfs.pressed.connect(_on_dfs_m1_pressed); panel_terminal.add_child(btn_execute_dfs)
	btn_confrontar = Button.new(); btn_confrontar.text = "ENCARAR SOSPECHOSOS"; btn_confrontar.position = Vector2(15, 190); btn_confrontar.size = Vector2(290, 45); btn_confrontar.visible = false; btn_confrontar.pressed.connect(_on_confrontar_pressed); panel_terminal.add_child(btn_confrontar)
func _setup_controles_din() -> void:
	var lbl_requisito := Label.new()
	lbl_requisito.name = "lbl_requisito"
	lbl_requisito.position = Vector2(15, 15); lbl_requisito.size = Vector2(290, 30)
	lbl_requisito.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_requisito.add_theme_font_size_override("font_size", 11)
	panel_terminal.add_child(lbl_requisito)
	opt_origen_din = OptionButton.new(); opt_origen_din.position = Vector2(15, 50); opt_origen_din.size = Vector2(290, 35); panel_terminal.add_child(opt_origen_din)
	opt_destino_din = OptionButton.new(); opt_destino_din.position = Vector2(15, 100); opt_destino_din.size = Vector2(290, 35); panel_terminal.add_child(opt_destino_din)
	btn_procesar_din = Button.new(); btn_procesar_din.position = Vector2(15, 155); btn_procesar_din.size = Vector2(290, 45); btn_procesar_din.pressed.connect(_on_procesar_din_pressed); panel_terminal.add_child(btn_procesar_din)
	match mision_actual:
		Misiones.M2_RUTA:
			opt_origen_din.add_item("Origen: Yolanda (Admin)", 4); opt_origen_din.add_item("Origen: Andres (Aliado)", 5)
			opt_destino_din.add_item("Destino: Alex (Victima)", 0); btn_procesar_din.text = "CALCULAR RUTA SEGURA"
			var ok_m2: bool = pistas_descubiertas.has("m2_ruta_intel")
			btn_procesar_din.disabled = not ok_m2
			if not ok_m2: lbl_requisito.text = "[color=#ffaa44]Esperando: Detective debe revisar el ARCHIVO del caso.[/color]"
			else: lbl_requisito.text = "[color=#55ff55]Intel del Detective recibido. Puedes proceder.[/color]"
		Misiones.M3_RED:
			opt_origen_din.add_item("Semilla Base: Alex", 0); opt_destino_din.add_item("Objetivo: Toda la red social", 99)
			btn_procesar_din.text = "RECONSTRUIR CONEXIONES"
			var ok_m3: bool = pistas_descubiertas.has("m3_red_intel")
			btn_procesar_din.disabled = not ok_m3
			if not ok_m3: lbl_requisito.text = "[color=#ffaa44]Esperando: Detective debe enviar el reporte de confianza.[/color]"
			else: lbl_requisito.text = "[color=#55ff55]Intel del Detective recibido. Red lista para reconstruir.[/color]"
		Misiones.M4_IMPACTO:
			opt_origen_din.add_item("Fuente: Red de Rafa", 1); opt_destino_din.add_item("Destino: Servidor de Alex", 0)
			btn_procesar_din.text = "MEDIR CAPACIDAD DE RED"
			var ok_m4: bool = pistas_descubiertas.has("m4_impacto_intel")
			btn_procesar_din.disabled = not ok_m4
			if not ok_m4: lbl_requisito.text = "[color=#ffaa44]Esperando: Detective debe enviar las especificaciones del servidor.[/color]"
			else: lbl_requisito.text = "[color=#55ff55]Intel del Detective recibido. Capacidad conocida.[/color]"
func _process(delta: float) -> void:
	if shake_time > 0.0:
		shake_time -= delta
		renderer.position = Vector2(randf_range(-SHAKE_I, SHAKE_I), randf_range(-SHAKE_I, SHAKE_I))
		if shake_time <= 0.0: renderer.position = Vector2.ZERO
	if current_phase != Phase.ANIMATING: return
	step_timer += delta
	if step_timer < STEP_INTERVAL: return
	step_timer = 0.0
	if visit_step >= visit_order.size():
		current_phase = Phase.CONSTRUCTION; _mostrar_recorrido_final(); return
	var nodo_actual: int = visit_order[visit_step]
	if visit_step > 0: renderer.set_node_state(visit_order[visit_step - 1], "visited")
	renderer.set_node_state(nodo_actual, "active")
	_log("  · Computando nodo: [b]" + graph.nodes[nodo_actual]["label"] + "[/b]")
	visit_step += 1
func _mostrar_recorrido_final() -> void:
	_log("\n[color=#55ff55]══ ANÁLISIS COMPLETADO ══[/color]")
	match mision_actual:
		Misiones.M1_ORIGEN:
			var txt: String = ""
			for i: int in range(recorrido_final.size()):
				renderer.set_node_state(recorrido_final[i], "active")
				txt += graph.nodes[recorrido_final[i]]["label"]
				if i < recorrido_final.size() - 1: txt += " ➔ "
			_log("  " + txt)
			_log("[color=#ff5555]Cadena de conexiones completa. El origen del ataque queda al descubierto.[/color]")
			if is_instance_valid(btn_confrontar): btn_confrontar.visible = true
			var chain_m1: String = " → ".join(recorrido_final.map(func(id): return graph.nodes[id]["label"]))
			NetworkManager.send_algorithm_result("Cadena de rastreo: " + chain_m1 + " - Rastreo completado. Datos listos para confrontar.")
		Misiones.M2_RUTA:
			var src: int = opt_origen_din.get_item_id(opt_origen_din.selected)
			var path = [4, 1, 2, 3, 0] if src == 4 else [5, 3, 0]
			var hi: Array = []
			for i: int in range(path.size() - 1):
				hi.append({"from": path[i], "to": path[i + 1]})
				renderer.set_node_state(path[i], "path")
			renderer.set_node_state(0, "path")
			renderer.set_highlighted_edges(hi)
			_log("[color=#55ff55]Ruta de intervencion calculada sin riesgos.[/color]")
			_habilitar_siguiente_mision(Misiones.M3_RED)
			var path_names: Array = path.map(func(id): return graph.nodes[id]["label"])
			NetworkManager.send_algorithm_result("Ruta segura encontrada: " + " → ".join(path_names) + " - Propagacion contenida.")
		Misiones.M3_RED:
			var hi = [{"from":4,"to":1},{"from":1,"to":2},{"from":2,"to":3},{"from":5,"to":3}]
			for e in hi:
				renderer.set_node_state(e["from"], "mst"); renderer.set_node_state(e["to"], "mst")
			renderer.set_highlighted_edges(hi)
			_log("[color=#88ccff]Red de confianza reconstruida. Todos los nodos conectados.[/color]")
			_habilitar_siguiente_mision(Misiones.M4_IMPACTO)
			NetworkManager.send_algorithm_result("Red social reconstruida. Lazos de confianza restablecidos.")
		Misiones.M4_IMPACTO:
			_log("[color=#ff8866]Capacidad de red calculada: 15.0 MB/s. Cortafuegos calibrado.[/color]")
			_habilitar_siguiente_mision(Misiones.M_FINAL)
			NetworkManager.send_algorithm_result("Analisis de capacidad completado. Cortafuegos listo para el ataque.")
func _verificar_desbloqueo_rastreo() -> void:
	var listos = renderer.verified_edges.size() >= 4
	if is_instance_valid(btn_execute_bfs): btn_execute_bfs.disabled = not listos
	if is_instance_valid(btn_execute_dfs): btn_execute_dfs.disabled = not listos
func _on_bfs_m1_pressed() -> void:
	renderer.reset_visuals(); current_phase = Phase.ANIMATING; visit_order = [1, 2, 3, 0, 4, 5]; recorrido_final = [1, 2, 3, 0]; visit_step = 0; step_timer = 0.0
func _on_dfs_m1_pressed() -> void:
	renderer.reset_visuals(); current_phase = Phase.ANIMATING; visit_order = [1, 2, 3, 0, 4, 2, 5]; recorrido_final = [1, 2, 3, 0]; visit_step = 0; step_timer = 0.0
func _input(event: InputEvent) -> void:
	if _is_dragging and event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish_drag(event.position)
	if _is_dragging and event is InputEventMouseMotion:
		if is_instance_valid(_drag_ghost):
			_drag_ghost.position = event.position - _drag_ghost.size / 2
func _start_drag(evidence_key: String) -> void:
	if mision_actual != Misiones.M1_ORIGEN or _is_dragging:
		return
	_drag_key = evidence_key
	_is_dragging = true
	_drag_ghost = Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.95, 0.92, 0.7, 0.85)
	st.border_color = Color(0.8, 0.7, 0.3)
	st.border_width_left = 2; st.border_width_top = 2; st.border_width_right = 2; st.border_width_bottom = 2
	st.corner_radius_top_left = 4; st.corner_radius_top_right = 4; st.corner_radius_bottom_left = 4; st.corner_radius_bottom_right = 4
	_drag_ghost.add_theme_stylebox_override("panel", st)
	_drag_ghost.size = Vector2(220, 0)
	var lbl := Label.new()
	lbl.text = pistas_descubiertas.get(evidence_key, "")
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.size = Vector2(208, 0)
	lbl.custom_minimum_size = Vector2(208, 0)
	lbl.add_theme_color_override("font_color", Color(0.15, 0.1, 0.0))
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.position = Vector2(6, 6)
	_drag_ghost.add_child(lbl)
	ui_layer.add_child(_drag_ghost)
	_drag_ghost.size = Vector2(220, 70)
	_drag_ghost.position = get_viewport().get_mouse_position() - _drag_ghost.size / 2
func _finish_drag(screen_pos: Vector2) -> void:
	_is_dragging = false
	if is_instance_valid(_drag_ghost):
		_drag_ghost.queue_free(); _drag_ghost = null
	if _drag_key == "":
		return
	var vp: Vector2 = get_viewport().size
	if screen_pos.x < 300 or screen_pos.x > vp.x - 350:
		_drag_key = ""
		return
	var edge := _find_edge_at_screen_pos(screen_pos)
	if edge.is_empty():
		_drag_key = ""
		return
	_validate_evidence_with_edge(_drag_key, edge)
	_drag_key = ""
func _find_edge_at_screen_pos(screen_pos: Vector2) -> Dictionary:
	var closest: Dictionary = {}
	var min_dist: float = 25.0
	for edge: Dictionary in graph.edge_list:
		var a: Vector2 = graph.nodes[edge["from"]]["pos"]
		var b: Vector2 = graph.nodes[edge["to"]]["pos"]
		var ok: bool = true
		for ve: Vector2 in renderer.verified_edges:
			if (ve.x == edge["from"] and ve.y == edge["to"]) or (ve.x == edge["to"] and ve.y == edge["from"]):
				ok = false; break
		if not ok:
			continue
		var ab: Vector2 = b - a
		var ap: Vector2 = screen_pos - a
		var t: float = clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
		var closest_p: Vector2 = a + t * ab
		var d: float = screen_pos.distance_to(closest_p)
		if d < min_dist:
			min_dist = d; closest = edge
	return closest
func _validate_evidence_with_edge(evidence_key: String, edge: Dictionary) -> void:
	for verdad in VERDAD_M1:
		if ((verdad["from"] == edge["from"] and verdad["to"] == edge["to"]) or (verdad["from"] == edge["to"] and verdad["to"] == edge["from"])) and verdad["req_pista"] == evidence_key:
			edge["weight"] = verdad["peso"]
			shake_time = 0.25
			renderer.verify_edge(edge["from"], edge["to"])
			memoria_verificados = renderer.verified_edges.duplicate(true)
			memoria_grafo = graph.edge_list.duplicate(true)
			_log("[color=#55ff55]Hilo validado con la evidencia![/color]")
			_verificar_desbloqueo_rastreo()
			return
	_log("[color=#ff5555]Evidencia incompatible con este hilo.[/color]")
	_on_intento_borrado(edge["from"], edge["to"])
func _revisar_desbloqueo_mision() -> void:
	if mision_actual in [Misiones.M1_ORIGEN, Misiones.M_FINAL]:
		return
	if not is_instance_valid(btn_procesar_din):
		return
	var desbloquear: bool = false
	var req_texto: String = ""
	if mision_actual == Misiones.M2_RUTA:
		desbloquear = pistas_descubiertas.has("m2_ruta_intel")
		if not desbloquear: req_texto = "[color=#ffaa44]Esperando: Detective debe revisar el ARCHIVO.[/color]"
		else: req_texto = "[color=#55ff55]Intel recibido. Puedes proceder.[/color]"
	elif mision_actual == Misiones.M3_RED:
		desbloquear = pistas_descubiertas.has("m3_red_intel")
		if not desbloquear: req_texto = "[color=#ffaa44]Esperando: Detective debe enviar reporte de confianza.[/color]"
		else: req_texto = "[color=#55ff55]Intel recibido. Red lista.[/color]"
	elif mision_actual == Misiones.M4_IMPACTO:
		desbloquear = pistas_descubiertas.has("m4_impacto_intel")
		if not desbloquear: req_texto = "[color=#ffaa44]Esperando: Detective debe enviar especificaciones.[/color]"
		else: req_texto = "[color=#55ff55]Intel recibido. Capacidad conocida.[/color]"
	btn_procesar_din.disabled = not desbloquear
	var lbl_r = panel_terminal.get_node_or_null("lbl_requisito")
	if lbl_r is Label:
		lbl_r.text = req_texto
	if desbloquear and not _intel_loggeado:
		_intel_loggeado = true
		_log("[color=#55ff55][Sistema] Datos del Detective recibidos. Unidad lista para operar.[/color]")
func _on_procesar_din_pressed() -> void:
	renderer.reset_visuals(); current_phase = Phase.ANIMATING; visit_step = 0; step_timer = 0.0
	match mision_actual:
		Misiones.M2_RUTA: visit_order = [4, 1, 2, 3, 0]
		Misiones.M3_RED: visit_order = [0, 4, 3, 5, 1, 2]
		Misiones.M4_IMPACTO: visit_order = [1, 2, 3, 0]
func _on_intento_conexion(from_id: int, to_id: int) -> void:
	if mision_actual != Misiones.M1_ORIGEN or pistas_descubiertas.size() < 2: return
	var enlace_valido = ((from_id == 1 and to_id == 2) or (from_id == 2 and to_id == 1) or (from_id == 2 and to_id == 3) or (from_id == 3 and to_id == 2) or (from_id == 3 and to_id == 4) or (from_id == 4 and to_id == 3) or (from_id == 5 and to_id == 3) or (from_id == 3 and to_id == 5) or (from_id == 3 and to_id == 0) or (from_id == 0 and to_id == 3))
	if not enlace_valido: return
	for e: Dictionary in graph.edge_list: if (e["from"] == from_id and e["to"] == to_id) or (e["from"] == to_id and e["to"] == from_id): return
	graph.add_edge(from_id, to_id, 999.0); memoria_grafo = graph.edge_list.duplicate(true); renderer.queue_redraw()
func _on_intento_borrado(from_id: int, to_id: int) -> void:
	if mision_actual != Misiones.M1_ORIGEN: return
	graph.edge_list = graph.edge_list.filter(func(e): return not ((e["from"] == from_id and e["to"] == to_id) or (e["from"] == to_id and e["to"] == from_id)))
	renderer.verified_edges = renderer.verified_edges.filter(func(v): return not ((v.x == from_id and v.y == to_id) or (v.x == to_id and v.y == from_id)))
	memoria_grafo = graph.edge_list.duplicate(true); memoria_verificados = renderer.verified_edges.duplicate(true); renderer.queue_redraw(); _verificar_desbloqueo_rastreo()
func _on_confrontar_pressed() -> void:
	if is_instance_valid(btn_confrontar): btn_confrontar.visible = false
	current_phase = Phase.CINEMATIC; cine_layer.visible = true
	if is_instance_valid(reproductor_audio):
		reproductor_audio.stop()
		if ResourceLoader.exists("res://audio/bgm_tension.mp3"): reproductor_audio.stream = load("res://audio/bgm_tension.mp3"); reproductor_audio.play()
	var fondo := ColorRect.new(); fondo.color = Color(0.02, 0.02, 0.03, 1.0); fondo.set_anchors_preset(Control.PRESET_FULL_RECT); cine_layer.add_child(fondo)
	sprite_izq = TextureRect.new(); sprite_izq.position = Vector2(60, 80); sprite_izq.size = Vector2(340, 400); sprite_izq.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; sprite_izq.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cine_layer.add_child(sprite_izq)
	sprite_der = TextureRect.new(); sprite_der.position = Vector2(820, 80); sprite_der.size = Vector2(340, 400); sprite_der.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; sprite_der.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cine_layer.add_child(sprite_der)
	var caja := Panel.new(); caja.position = Vector2(60, 490); caja.size = Vector2(1100, 200); var st := StyleBoxFlat.new(); st.bg_color = Color(0.04, 0.04, 0.07, 0.97); st.border_width_top = 4; st.border_color = Color(0.9, 0.72, 0.22); caja.add_theme_stylebox_override("panel", st); cine_layer.add_child(caja)
	txt_nombre_cine = Label.new(); txt_nombre_cine.position = Vector2(24, 14); txt_nombre_cine.add_theme_font_size_override("font_size", 21); caja.add_child(txt_nombre_cine)
	txt_dialogo_cine = RichTextLabel.new(); txt_dialogo_cine.bbcode_enabled = true; txt_dialogo_cine.position = Vector2(24, 52); txt_dialogo_cine.size = Vector2(900, 132); txt_dialogo_cine.add_theme_font_size_override("normal_font_size", 18); caja.add_child(txt_dialogo_cine)
	btn_cine_next = Button.new(); btn_cine_next.text = "CONTINUAR ▶"; btn_cine_next.position = Vector2(940, 130); btn_cine_next.size = Vector2(148, 44); btn_cine_next.pressed.connect(_avanzar_dialogo_cine); caja.add_child(btn_cine_next)
	lista_dialogos = [
		{"nombre": "DETECTIVE", "color": "#55aaff", "avatar": "res://avatars/detective_neutro.png", "texto": "Andrés, afirmaste que Santi estuvo contigo toda la noche del hackeo. Interceptamos los registros de la red local universitaria.", "lado": "izq"},
		{"nombre": "ANDRÉS", "color": "#eebb55", "avatar": "res://avatars/andres_avatar.png", "texto": "¿De qué habla? Estábamos estudiando para el examen de Estructuras de Datos...", "lado": "der"},
		{"nombre": "DETECTIVE", "color": "#55aaff", "avatar": "res://sprites/detective_rabioso.png", "texto": "Falso. Tu IP estuvo enviando tráfico UDP masivo a servidores de Steam exactamente a la hora del ataque. Le diste una coartada falsa.", "lado": "izq"},
		{"nombre": "ANDRÉS", "color": "#eebb55", "avatar": "res://sprites/andres_nervioso.png", "texto": "¡Está bien! Santi me lo pidió... Me dijo que si alguien preguntaba, dijera que estuvimos juntos. ¡Yo no sabía que iba a tumbar el sistema de Alex!", "lado": "der"},
		{"nombre": "DETECTIVE", "color": "#55aaff", "avatar": "res://sprites/detective_rabioso.png", "texto": "Tu escudo cayo, Santi. Andres confeso. El rastreo de conexiones no miente: todo el acoso digital lleva tu firma.", "lado": "izq"},
		{"nombre": "SANTI", "color": "#ff5555", "avatar": "res://sprites/santi_nervioso.png", "texto": "¡Ese cobarde! Igual... un mapa de nodos en un corcho no prueba que yo toqué la computadora de Alex.", "lado": "der"},
		{"nombre": "DETECTIVE", "color": "#55aaff", "avatar": "res://sprites/detective_rabioso.png", "texto": "Tenemos el log forense del administrador. Alguien usó credenciales robadas de Yolanda... y el acceso se validó desde la MAC de tu teléfono.", "lado": "izq"},
		{"nombre": "SANTI", "color": "#ff5555", "avatar": "res://sprites/santi_rabioso.png", "texto": "¡Alex descubrió que yo estaba vendiendo las respuestas del laboratorio en la Dark Web! ¡Tenía que borrarlo del sistema!", "lado": "der"},
		{"nombre": "SISTEMA UNINORTE", "color": "#55ff55", "avatar": "res://sprites/santi_rabioso.png", "texto": "Declaracion registrada. Nuevos analisis disponibles en la terminal del Informatico.", "lado": "der"}
	]
	indice_dialogo = 0; _actualizar_pantalla_cine()
func _actualizar_pantalla_cine() -> void:
	if indice_dialogo >= lista_dialogos.size(): return
	var data: Dictionary = lista_dialogos[indice_dialogo]; txt_nombre_cine.text = data["nombre"]; txt_nombre_cine.add_theme_color_override("font_color", Color.from_string(data["color"], Color.WHITE)); txt_dialogo_cine.text = data["texto"]
	var av_path = _resolver_avatar(data.get("avatar", ""))
	if data.get("lado", "der") == "izq":
		if av_path != "": sprite_izq.texture = load(av_path)
		sprite_izq.modulate = Color(1.1, 1.1, 1.1); sprite_der.modulate = Color(0.3, 0.3, 0.3)
	else:
		if av_path != "": sprite_der.texture = load(av_path)
		sprite_der.modulate = Color(1.1, 1.1, 1.1); sprite_izq.modulate = Color(0.3, 0.3, 0.3)
func _resolver_avatar(raw: String) -> String:
	if ResourceLoader.exists(raw): return raw
	var sanitized = _sanitizar_nombre(raw.get_file())
	for d in ["res://avatars/", "res://sprites/"]:
		if ResourceLoader.exists(d + sanitized): return d + sanitized
	return ""
func _avanzar_dialogo_cine() -> void:
	indice_dialogo += 1
	if indice_dialogo < lista_dialogos.size(): _actualizar_pantalla_cine()
	else:
		cine_layer.visible = false; for ch in cine_layer.get_children(): ch.queue_free()
		current_phase = Phase.CONSTRUCTION; _habilitar_siguiente_mision(Misiones.M2_RUTA)
func _habilitar_siguiente_mision(siguiente: Misiones) -> void:
	var btn := Button.new(); btn.position = Vector2(15, 245); btn.size = Vector2(290, 45); btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	match siguiente:
		Misiones.M2_RUTA: btn.text = "SIGUIENTE FASE > Cortar Propagacion"
		Misiones.M3_RED:      btn.text = "SIGUIENTE FASE > Reconstruir Red"
		Misiones.M4_IMPACTO:     btn.text = "SIGUIENTE FASE > Contener Embestida"
		Misiones.M_FINAL:     btn.text = "IDENTIFICAR CULPABLE > Cerrar el Caso"
	btn.pressed.connect(func():
		if siguiente == Misiones.M_FINAL: NetworkManager.broadcast_victory()
		else:
			mision_actual = siguiente
			if NetworkManager.is_multiplayer_active():
				NetworkManager.broadcast_mission()
			get_tree().reload_current_scene()
	)
	panel_terminal.add_child(btn)
func _refrescar_libreta() -> void:
	var txt: String = ""
	match mision_actual:
		Misiones.M1_ORIGEN:
			if pistas_descubiertas.is_empty(): txt = "[color=#777777](Esperando evidencias del Detective...)[/color]"
			else:
				txt = "[b][color=#ffcc44]EVIDENCIAS DEL DETECTIVE[/color][/b]\n\n"
				for ev: String in pistas_descubiertas.values(): txt += "• " + ev + "\n\n"
		Misiones.M2_RUTA:
			txt = "[b]MATRIZ DE RIESGOS[/b]\n\nYolanda➔Rafa:  2.0\nRafa➔Camila:    4.0\nCamila➔Santi:  2.0\nSanti➔Yolanda: 1.0\nAndres➔Santi:  3.0\nSanti➔Alex:     6.0\n\n"
			txt += "[b][color=#ffcc44]INTEL DEL DETECTIVE[/color][/b]"
			if pistas_descubiertas.is_empty(): txt += "\n[color=#777777](Esperando datos...)[/color]"
			else:
				for ev: String in pistas_descubiertas.values():
					if ev.begins_with("["): txt += "\n• " + ev
				for ev: String in pistas_descubiertas.values():
					if ev.begins_with("Yolanda") or ev.begins_with("Capacidad"): txt += "\n• " + ev
		Misiones.M3_RED:
			txt = "[b]ENLACES SOCIALES[/b]\n\nAlex➔Rafa:     4.0\nAlex➔Yolanda: 3.0\nRafa➔Camila:   2.0\nCamila➔Santi: 5.0\nSanti➔Yolanda: 1.0\nYolanda➔Andres: 6.0\n\n"
			txt += "[b][color=#ffcc44]INTEL DEL DETECTIVE[/color][/b]"
			if pistas_descubiertas.is_empty(): txt += "\n[color=#777777](Esperando datos...)[/color]"
			else:
				for ev: String in pistas_descubiertas.values():
					if ev.begins_with("["): txt += "\n• " + ev
		Misiones.M4_IMPACTO:
			txt = "[b]CAPACIDAD DE RED (MB/s)[/b]\n\nRafa➔Camila:   10.0\nRafa➔Santi:      8.0\nCamila➔Yolanda: 7.0\nSanti➔Yolanda:   4.0\nYolanda➔Alex:    12.0\nAndres➔Rafa:     5.0\n\n"
			txt += "[b][color=#ffcc44]INTEL DEL DETECTIVE[/color][/b]"
			if pistas_descubiertas.is_empty(): txt += "\n[color=#777777](Esperando datos...)[/color]"
			else:
				for ev: String in pistas_descubiertas.values():
					if ev.begins_with("["): txt += "\n• " + ev
	libreta_texto.text = txt
func _actualizar_postits() -> void:
	for c in grid_postits.get_children(): c.queue_free()
	if mision_actual == Misiones.M1_ORIGEN:
		for key: String in pistas_descubiertas.keys():
			var card := Panel.new()
			card.custom_minimum_size = Vector2(240, 76)
			var st := StyleBoxFlat.new()
			st.bg_color = Color(0.97, 0.93, 0.52, 0.97)
			st.border_color = Color(0.7, 0.6, 0.2)
			st.border_width_left = 1; st.border_width_top = 1; st.border_width_right = 1; st.border_width_bottom = 1
			st.corner_radius_top_left = 4; st.corner_radius_top_right = 4
			st.corner_radius_bottom_left = 4; st.corner_radius_bottom_right = 4
			card.add_theme_stylebox_override("panel", st)
			var cinta := ColorRect.new()
			cinta.color = Color(0.85, 0.85, 0.8, 0.4)
			cinta.size = Vector2(14, 14)
			cinta.position = Vector2(0, 0)
			cinta.mouse_filter = Control.MOUSE_FILTER_PASS
			card.add_child(cinta)
			var lbl := Label.new()
			lbl.text = pistas_descubiertas[key]
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			lbl.size = Vector2(220, 52)
			lbl.position = Vector2(10, 14)
			lbl.add_theme_color_override("font_color", Color(0.15, 0.1, 0.0))
			lbl.add_theme_font_size_override("font_size", 10)
			card.add_child(lbl)
			card.mouse_default_cursor_shape = Control.CURSOR_DRAG
			var captured_key: String = key
			card.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					_start_drag(captured_key)
			)
			grid_postits.add_child(card)
func _titulo_mision() -> String:
	match mision_actual:
		Misiones.M1_ORIGEN: return "F1 — RASTREAR ORIGEN"
		Misiones.M2_RUTA: return "F2 — CORTAR PROPAGACION"
		Misiones.M3_RED: return "F3 — RECONSTRUIR RED"
		Misiones.M4_IMPACTO: return "F4 — CONTENER EMBESTIDA"
		_: return "PANEL CENTRAL"
var _panel_ayuda: Panel
func _build_panel_ayuda() -> void:
	_panel_ayuda = _make_panel(Color(0.06, 0.06, 0.14, 0.97), Color(0.8, 0.6, 0.2)); _panel_ayuda.position = Vector2(300, 58); _panel_ayuda.size = Vector2(560, 480); _panel_ayuda.visible = false; ui_layer.add_child(_panel_ayuda)
	var rt := RichTextLabel.new(); rt.bbcode_enabled = true; rt.set_anchors_preset(Control.PRESET_FULL_RECT); rt.offset_left = 16; rt.offset_top = 16; rt.add_theme_font_size_override("normal_font_size", 14); rt.text = "[b][color=#ffcc44]MANUAL DEL INFORMATICO[/color][/b]\n\nConecta nodos arrastrando desde uno hacia otro.\nArrastra evidencias (post-its amarillos) sobre los hilos del grafo para validarlos.\nUsa la terminal para ejecutar los analisis.\nEl Detective te envia pistas desde la escena."
	_panel_ayuda.add_child(rt)
	var btn_c := Button.new(); btn_c.text = "Cerrar"; btn_c.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); btn_c.offset_left = -100; btn_c.offset_top = -40; btn_c.pressed.connect(func(): _panel_ayuda.visible = false); _panel_ayuda.add_child(btn_c)
func _toggle_ayuda() -> void:
	if is_instance_valid(_panel_ayuda): _panel_ayuda.visible = !_panel_ayuda.visible
func _make_panel(bg: Color, border: Color) -> Panel:
	var p := Panel.new(); var st := StyleBoxFlat.new(); st.bg_color = bg; st.border_width_left = 2; st.border_width_top = 2; st.border_width_right = 2; st.border_width_bottom = 2; st.border_color = border; p.add_theme_stylebox_override("panel", st); return p
func _make_nav_button(parent: Node, txt: String, pos: Vector2, sz: Vector2, cb: Callable) -> Button:
	var b := Button.new(); b.text = txt; b.position = pos; b.size = sz; b.pressed.connect(cb); parent.add_child(b); return b
func _log(msg: String) -> void:
	if is_instance_valid(log_label): log_label.append_text(msg + "\n")
