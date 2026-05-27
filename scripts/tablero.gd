extends Node
enum FasesCampaña { VINCULOS_INICIALES, RUTA_SEGURA, RECONSTRUCCION, FLUJO_IMPACTO, CASO_CERRADO }
enum EstadosTablero { NINGUNO, CONSTRUCCION, VERIFICADO, ANIMANDO, CINEMATICA }
var fase_ejecucion: int = EstadosTablero.CONSTRUCCION
func _get_mision_actual_idx() -> int:
	return MisionFinal.mision_actual
const VERIFICACION_VINCULOS: Array[Dictionary] = [
	{"from": 1, "to": 2, "req_pista": "chat_01",    "peso": 4.0}, 
	{"from": 2, "to": 3, "req_pista": "camila_1",   "peso": 2.0}, 
	{"from": 3, "to": 4, "req_pista": "log_admin",  "peso": 1.0}, 
	{"from": 5, "to": 3, "req_pista": "ip_andres",  "peso": 3.0}, 
	{"from": 3, "to": 0, "req_pista": "ataque_final","peso": 6.0}  
]
var renderer: Node2D 
var ui_layer: CanvasLayer
var cine_layer: CanvasLayer
var panel_libreta: Panel
var libreta_texto: RichTextLabel
var panel_terminal: Panel
var log_label: RichTextLabel
var opt_hilos: OptionButton
var opt_evidencia: OptionButton
var btn_vincular: Button
var btn_analizar_niveles: Button
var btn_analizar_cadenas: Button
var btn_confrontar: Button
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
		NetworkManager.pistas_synced.connect(func(_p: Dictionary): _refrescar_libreta())
	if NetworkManager.is_multiplayer_active() and NetworkManager.is_detective():
		get_tree().change_scene_to_file("res://scenes/Habitacion.tscn")
		return
	if NetworkManager.is_multiplayer_active():
		NetworkManager.victory_triggered.connect(func(): get_tree().change_scene_to_file("res://scenes/escena_victoria.tscn"))
	var chat = ChatOverlay.new()
	add_child(chat)
	_setup_audio_ambiente() 
	_setup_capas()
	_build_red_usuarios() 
	_setup_ui()
	if renderer.has_signal("intento_conexion"):
		renderer.intento_conexion.connect(_on_intento_conexion)
	if renderer.has_signal("intento_borrado"):
		renderer.intento_borrado.connect(_on_intento_borrado)
	if is_instance_valid(opt_hilos): 
		_actualizar_dropdown_hilos()
		_verificar_desbloqueo_analisis() 
	_notificar_fase_consola()
func _notificar_fase_consola() -> void:
	match _get_mision_actual_idx():
		FasesCampaña.VINCULOS_INICIALES:
			_log("[color=#ffff55]► FASE 1 — Mapa de Sospechas Inicial[/color]\n"
				+ "[b]Objetivo:[/b] Identificar las relaciones digitales y la persona que inició el sabotaje.\n"
				+ "• Conecta a las personas usando las evidencias recolectadas.\n"
				+ "• Selecciona un método de rastreo en la terminal para validar la red.")
		FasesCampaña.RUTA_SEGURA:
			_log("[color=#55aaff]► FASE 2 — Prófugo Digital (Santi)[/color]\n"
				+ "[b]Estado:[/b] El sabotaje fue descubierto, pero Santi bloqueó las terminales y huyó de la sala.\n"
				+ "[b]Objetivo:[/b] Encontrar la ruta de comunicación con menor riesgo para intervenir los archivos de Alex.")
		FasesCampaña.RECONSTRUCCION:
			_log("[color=#88ccff]► FASE 3 — Reconstruir la Red de Confianza[/color]\n"
				+ "[b]Estado:[/b] Las falsas acusaciones de Santi destruyeron los lazos sociales del campus.\n"
				+ "[b]Objetivo:[/b] Encontrar el canal óptimo para restablecer las conexiones al menor costo de credibilidad total.")
		FasesCampaña.FLUJO_IMPACTO:
			_log("[color=#ff8866]► FASE 4 — Medición de la Inundación de Datos[/color]\n"
				+ "[b]Estado:[/b] El virus oculto de Santi intenta saturar el servidor de Alex con cuentas falsas.\n"
				+ "[b]Objetivo:[/b] Calcular la capacidad máxima de impacto del ataque para calibrar el Firewall definitivo.")
func _setup_audio_ambiente() -> void:
	reproductor_audio = AudioStreamPlayer.new()
	reproductor_audio.volume_db = -12.0
	add_child(reproductor_audio)
	if ResourceLoader.exists("res://audio/bgm_mystery.mp3"):
		reproductor_audio.stream = load("res://audio/bgm_mystery.mp3")
	reproductor_audio.play()
func _setup_capas() -> void:
	var bg_layer := CanvasLayer.new(); bg_layer.layer = -1; add_child(bg_layer)
	var bg := TextureRect.new(); bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE; bg.set_anchors_preset(Control.PRESET_FULL_RECT); bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://backgrounds/bg_corkboard.png"): bg.texture = load("res://backgrounds/bg_corkboard.png")
	bg_layer.add_child(bg)
	var graph_layer := CanvasLayer.new(); graph_layer.layer = 0; add_child(graph_layer)
	if typeof(ClassDB.instantiate("GraphRenderer")) != TYPE_NIL:
		renderer = ClassDB.instantiate("GraphRenderer")
	else:
		var script_res = load("res://scripts/GraphRenderer.gd") if ResourceLoader.exists("res://scripts/GraphRenderer.gd") else null
		renderer = Node2D.new()
		if script_res:
			renderer.set_script(script_res)
	renderer.name = "GraphRenderer"
	graph_layer.add_child(renderer)
	ui_layer = CanvasLayer.new(); ui_layer.layer = 1; add_child(ui_layer)
	cine_layer = CanvasLayer.new(); cine_layer.layer = 10; cine_layer.visible = false; add_child(cine_layer)
func _build_red_usuarios() -> void:
	graph = Graph.new(_get_mision_actual_idx() == FasesCampaña.FLUJO_IMPACTO)
	var pos: Array[Vector2] = [
		Vector2(400, 360), Vector2(540, 200), Vector2(790, 200),
		Vector2(640, 360), Vector2(840, 430), Vector2(490, 550)
	]
	var noms: Array[String] = ["Alex (Víctima)", "Rafa", "Camila", "Santi (Sospechoso)", "Yolanda", "Andrés"]
	for i: int in range(noms.size()):
		var nombre_limpio: String = _sanitizar_nombre(noms[i].split(" ")[0])
		var av: String = "res://avatars/" + nombre_limpio + "_avatar.png"
		graph.add_node(i, noms[i], pos[i], "neutral", {"avatar": av})
	if _get_mision_actual_idx() == FasesCampaña.VINCULOS_INICIALES:
		if not MisionFinal.memoria_grafo.is_empty():
			graph.edge_list = MisionFinal.memoria_grafo.duplicate(true)
			if "verified_edges" in renderer:
				renderer.verified_edges = MisionFinal.memoria_verificados.duplicate(true)
	else:
		graph.add_edge(4, 1, 2.0)
		graph.add_edge(1, 2, 4.0)
		graph.add_edge(2, 3, 2.0)
		graph.add_edge(3, 4, 1.0)
		graph.add_edge(5, 3, 3.0)
		graph.add_edge(3, 0, 6.0)
		if "verified_edges" in renderer:
			renderer.verified_edges = [Vector2(4,1), Vector2(1,2), Vector2(2,3), Vector2(3,4), Vector2(5,3), Vector2(3,0)]
	if renderer.has_method("set_graph"):
		renderer.set_graph(graph)
func _sanitizar_nombre(raw: String) -> String:
	var tabla: Dictionary = {"á":"a","é":"e","í":"i","ó":"o","ú":"u","Á":"a","É":"e","Í":"i","Ó":"o","Ú":"u"}
	var result: String = raw.to_lower()
	for orig: String in tabla: result = result.replace(orig, tabla[orig])
	return result
func _setup_ui() -> void:
	var topbar := _make_panel(Color(0.04, 0.04, 0.06, 0.95), Color(0.5, 0.2, 0.2))
	topbar.set_anchors_preset(Control.PRESET_TOP_WIDE); topbar.offset_bottom = 50; ui_layer.add_child(topbar)
	_make_nav_button(topbar, "🚪 Oficina", Vector2(15, 7), Vector2(130, 36), func(): get_tree().change_scene_to_file("res://scenes/Habitacion.tscn"))
	_make_nav_button(topbar, "💻 Sistema Digital", Vector2(155, 7), Vector2(150, 36), func(): get_tree().change_scene_to_file("res://scenes/PC.tscn"))
	_make_nav_button(topbar, "🔄 Refrescar", Vector2(320, 7), Vector2(120, 36), func(): get_tree().reload_current_scene())
	var lbl_mision := Label.new(); lbl_mision.text = _titulo_fase(); lbl_mision.position = Vector2(460, 13); lbl_mision.add_theme_font_size_override("font_size", 16); topbar.add_child(lbl_mision)
	_make_nav_button(topbar, "❓ Ayuda", Vector2(1020, 7), Vector2(110, 36), func(): _toggle_ayuda())
	panel_libreta = _make_panel(Color(0.95, 0.93, 0.88, 0.98), Color(0.5, 0.35, 0.2))
	panel_libreta.position = Vector2(15, 65); panel_libreta.size = Vector2(270, 630); ui_layer.add_child(panel_libreta)
	libreta_texto = RichTextLabel.new(); libreta_texto.bbcode_enabled = true; libreta_texto.position = Vector2(15, 20); libreta_texto.size = Vector2(240, 590); libreta_texto.add_theme_color_override("default_color", Color.BLACK)
	_refrescar_libreta(); panel_libreta.add_child(libreta_texto)
	panel_terminal = _make_panel(Color(0.01, 0.03, 0.01, 0.97), Color(0.2, 0.7, 0.2))
	panel_terminal.set_anchors_preset(Control.PRESET_RIGHT_WIDE); panel_terminal.offset_left = -340; panel_terminal.offset_top = 65; panel_terminal.offset_right = -15; panel_terminal.offset_bottom = -15; ui_layer.add_child(panel_terminal)
	if _get_mision_actual_idx() == FasesCampaña.VINCULOS_INICIALES: _setup_controles_m1()
	else: _setup_controles_din()
	log_label = RichTextLabel.new(); log_label.bbcode_enabled = true; log_label.position = Vector2(15, 300)
	log_label.size = Vector2(290, 320); log_label.add_theme_font_size_override("normal_font_size", 12); panel_terminal.add_child(log_label)
	_build_panel_ayuda()
func _setup_controles_m1() -> void:
	opt_hilos = OptionButton.new(); opt_hilos.position = Vector2(15, 45); opt_hilos.size = Vector2(290, 35); panel_terminal.add_child(opt_hilos)
	opt_evidencia = OptionButton.new(); opt_evidencia.position = Vector2(15, 90); opt_evidencia.size = Vector2(290, 35)
	opt_evidencia.add_item("Seleccionar Evidencia Relevante…", -1)
	for key: String in MisionFinal.pistas_descubiertas.keys(): opt_evidencia.add_item(MisionFinal.pistas_descubiertas[key], MisionFinal.pistas_descubiertas.keys().find(key))
	panel_terminal.add_child(opt_evidencia)
	btn_vincular = Button.new(); btn_vincular.text = "📎 ASOCIAR EVIDENCIA AL VÍNCULO"
	btn_vincular.position = Vector2(15, 140); btn_vincular.size = Vector2(290, 40); btn_vincular.pressed.connect(_on_vincular_pressed); panel_terminal.add_child(btn_vincular)
	btn_analizar_niveles = Button.new(); btn_analizar_niveles.text = "🌐 RASTREO POR CERCANÍA"
	btn_analizar_niveles.position = Vector2(15, 195); btn_analizar_niveles.size = Vector2(140, 40); btn_analizar_niveles.disabled = true; btn_analizar_niveles.pressed.connect(_on_bfs_m1_pressed); panel_terminal.add_child(btn_analizar_niveles)
	btn_analizar_cadenas = Button.new(); btn_analizar_cadenas.text = "⚡ RASTREO EN CADENA"
	btn_analizar_cadenas.position = Vector2(165, 195); btn_analizar_cadenas.size = Vector2(140, 40); btn_analizar_cadenas.disabled = true; btn_analizar_cadenas.pressed.connect(_on_dfs_m1_pressed); panel_terminal.add_child(btn_analizar_cadenas)
	btn_confrontar = Button.new(); btn_confrontar.text = "🔥 CONFRONTAR EN EL CAMPUS"; btn_confrontar.position = Vector2(15, 245); btn_confrontar.size = Vector2(290, 45); btn_confrontar.visible = false; btn_confrontar.pressed.connect(_on_confrontar_pressed); panel_terminal.add_child(btn_confrontar)
func _setup_controles_din() -> void:
	opt_origen_din = OptionButton.new(); opt_origen_din.position = Vector2(15, 45); opt_origen_din.size = Vector2(290, 35); panel_terminal.add_child(opt_origen_din)
	opt_destino_din = OptionButton.new(); opt_destino_din.position = Vector2(15, 95); opt_destino_din.size = Vector2(290, 35); panel_terminal.add_child(opt_destino_din)
	btn_procesar_din = Button.new(); btn_procesar_din.position = Vector2(15, 150); btn_procesar_din.size = Vector2(290, 45); btn_procesar_din.pressed.connect(_on_procesar_din_pressed); panel_terminal.add_child(btn_procesar_din)
	match _get_mision_actual_idx():
		FasesCampaña.RUTA_SEGURA:
			opt_origen_din.add_item("Punto de Apoyo: Yolanda (Admin)", 4); opt_origen_din.add_item("Punto de Apoyo: Andrés (Amigo)", 5)
			opt_destino_din.add_item("Destino: Servidor de Alex", 0)
			btn_procesar_din.text = "🛡️ MEDIR RUTA DE MENOR RIESGO"
		FasesCampaña.RECONSTRUCCION:
			opt_origen_din.add_item("Punto de Partida: Alex (Nodo Central)", 0)
			opt_destino_din.add_item("Objetivo: Enlazar toda la comunidad", 99)
			btn_procesar_din.text = "🌳 TRAZAR CANAL DE CONFIANZA"
		FasesCampaña.FLUJO_IMPACTO:
			opt_origen_din.add_item("Origen del Ataque: Dispositivo Rafa (1)", 1)
			opt_destino_din.add_item("Destino del Impacto: Servidor Alex (0)", 0)
			btn_procesar_din.text = "☠️ CALCULAR IMPACTO MÁXIMO"
func _process(delta: float) -> void:
	if shake_time > 0.0:
		shake_time -= delta
		renderer.position = Vector2(randf_range(-SHAKE_I, SHAKE_I), randf_range(-SHAKE_I, SHAKE_I))
		if shake_time <= 0.0: renderer.position = Vector2.ZERO
	if fase_ejecucion != EstadosTablero.ANIMANDO: return
	step_timer += delta
	if step_timer < STEP_INTERVAL: return
	step_timer = 0.0
	if visit_step >= visit_order.size():
		fase_ejecucion = EstadosTablero.CONSTRUCCION;
		_mostrar_recorrido_final(); return
	var nodo_actual: int = visit_order[visit_step]
	if visit_step > 0 and renderer.has_method("set_node_state"):
		renderer.set_node_state(visit_order[visit_step - 1], "visited")
	if renderer.has_method("set_node_state"):
		renderer.set_node_state(nodo_actual, "active")
	_log("  · Evaluando actividad de: [b]" + graph.nodes[nodo_actual]["label"] + "[/b]")
	visit_step += 1
func _mostrar_recorrido_final() -> void:
	_log("\n[color=#55ff55]══ EVALUACIÓN COMPLETADA ══[/color]")
	match _get_mision_actual_idx():
		FasesCampaña.VINCULOS_INICIALES:
			var txt: String = ""
			for i: int in range(recorrido_final.size()):
				if renderer.has_method("set_node_state"):
					renderer.set_node_state(recorrido_final[i], "active")
				txt += graph.nodes[recorrido_final[i]]["label"]
				if i < recorrido_final.size() - 1: txt += " ➔ "
			_log("  " + txt)
			_log("[color=#ff5555]⚠ Evidencias enlazadas de extremo a extremo de forma sospechosa.[/color]")
			if is_instance_valid(btn_confrontar): btn_confrontar.visible = true
			var chain_m1: String = " → ".join(recorrido_final.map(func(id): return graph.nodes[id]["label"]))
			NetworkManager.send_algorithm_result("⚡ Cadena Forense Verificada: " + chain_m1)
		FasesCampaña.RUTA_SEGURA:
			var src: int = opt_origen_din.get_item_id(opt_origen_din.selected)
			var path = [4, 1, 2, 3, 0] if src == 4 else [5, 3, 0]
			var hi: Array = []
			for i: int in range(path.size() - 1):
				hi.append({"from": path[i], "to": path[i + 1]})
				if renderer.has_method("set_node_state"):
					renderer.set_node_state(path[i], "path")
			if renderer.has_method("set_node_state"):
				renderer.set_node_state(0, "path")
			if renderer.has_method("set_highlighted_edges"):
				renderer.set_highlighted_edges(hi)
			_log("[color=#55ff55]✔ Trayectoria segura inyectada. Canal libre de riesgos.[/color]")
			_habilitar_siguiente_fase(FasesCampaña.RECONSTRUCCION)
			var path_names: Array = path.map(func(id): return graph.nodes[id]["label"])
			NetworkManager.send_algorithm_result("🛡️ Ruta Óptima de Intervención: " + " → ".join(path_names))
		FasesCampaña.RECONSTRUCCION:
			var hi = [{"from":4,"to":1},{"from":1,"to":2},{"from":2,"to":3},{"from":5,"to":3}]
			for e in hi:
				if renderer.has_method("set_node_state"):
					renderer.set_node_state(e["from"], "mst"); renderer.set_node_state(e["to"], "mst")
			if renderer.has_method("set_highlighted_edges"):
				renderer.set_highlighted_edges(hi)
			_log("[color=#88ccff]✔ Estructura de confianza reestablecida al menor costo social posible.[/color]")
			_habilitar_siguiente_fase(FasesCampaña.FLUJO_IMPACTO)
			NetworkManager.send_algorithm_result("🌳 Comunidad unificada de forma óptima.")
		FasesCampaña.FLUJO_IMPACTO:
			_log("[color=#ff8866]✔ Capacidad máxima de ataque calculada en 15.0 MB/s. Servidores protegidos.[/color]")
			_habilitar_siguiente_fase(FasesCampaña.CASO_CERRADO)
			NetworkManager.send_algorithm_result("☠️ Impacto Máximo Medido = 15.0 MB/s. Caso Forense Listo.")
func _verificar_desbloqueo_analisis() -> void:
	var listos = renderer.get("verified_edges").size() >= 4 if "verified_edges" in renderer else false
	if is_instance_valid(btn_analizar_niveles): btn_analizar_niveles.disabled = not listos
	if is_instance_valid(btn_analizar_cadenas): btn_analizar_cadenas.disabled = not listos
func _on_bfs_m1_pressed() -> void:
	if renderer.has_method("reset_visuals"): renderer.reset_visuals()
	fase_ejecucion = EstadosTablero.ANIMANDO; visit_order = [1, 2, 3, 0, 4, 5]; recorrido_final = [1, 2, 3, 0]; visit_step = 0; step_timer = 0.0
func _on_dfs_m1_pressed() -> void:
	if renderer.has_method("reset_visuals"): renderer.reset_visuals()
	fase_ejecucion = EstadosTablero.ANIMANDO; visit_order = [1, 2, 3, 0, 4, 2, 5]; recorrido_final = [1, 2, 3, 0]; visit_step = 0; step_timer = 0.0
func _on_vincular_pressed() -> void:
	var theory_idx: int = opt_hilos.get_selected_id(); var ev_raw_idx: int = opt_evidencia.selected - 1
	if theory_idx == -1 or ev_raw_idx < 0: return
	var edge_teoria = graph.edge_list[theory_idx]; var evidencia_key = MisionFinal.pistas_descubiertas.keys()[ev_raw_idx]; var acierto = false
	for verdad in VERIFICACION_VINCULOS:
		if ((verdad["from"] == edge_teoria["from"] and verdad["to"] == edge_teoria["to"]) or (verdad["from"] == edge_teoria["to"] and verdad["to"] == edge_teoria["from"])) and verdad["req_pista"] == evidencia_key:
			acierto = true; edge_teoria["weight"] = verdad["peso"]; break
	if acierto:
		shake_time = 0.25
		if renderer.has_method("verify_edge"):
			renderer.verify_edge(edge_teoria["from"], edge_teoria["to"])
		MisionFinal.memoria_verificados = renderer.verified_edges.duplicate(true) if "verified_edges" in renderer else []
		MisionFinal.memoria_grafo = graph.edge_list.duplicate(true)
		_log("[color=#55ff55]✔ Vínculo de sospecha validado con evidencias físicas.[/color]"); _actualizar_dropdown_hilos(); _verificar_desbloqueo_analisis()
	else:
		_log("[color=#ff5555]✗ Evidencia incompatible con la declaración del sospechoso.[/color]"); _on_intento_borrado(edge_teoria["from"], edge_teoria["to"])
func _actualizar_dropdown_hilos() -> void:
	if not is_instance_valid(opt_hilos): return
	opt_hilos.clear(); opt_hilos.add_item("Selecciona un Vínculo Gris…", -1)
	var idx: int = 0
	var verified_list = renderer.get("verified_edges") if "verified_edges" in renderer else []
	for edge: Dictionary in graph.edge_list:
		var is_verified: bool = false
		for ve in verified_list:
			if (ve.x == edge["from"] and ve.y == edge["to"]) or (ve.y == edge["from"] and ve.x == edge["to"]): is_verified = true; break
		if not is_verified: opt_hilos.add_item(graph.nodes[edge["from"]]["label"] + " ↔ " + graph.nodes[edge["to"]]["label"], idx)
		idx += 1
func _on_procesar_din_pressed() -> void:
	if renderer.has_method("reset_visuals"): renderer.reset_visuals()
	fase_ejecucion = EstadosTablero.ANIMANDO; visit_step = 0; step_timer = 0.0
	match _get_mision_actual_idx():
		FasesCampaña.RUTA_SEGURA: visit_order = [4, 1, 2, 3, 0]
		FasesCampaña.RECONSTRUCCION: visit_order = [0, 4, 3, 5, 1, 2]
		FasesCampaña.FLUJO_IMPACTO: visit_order = [1, 2, 3, 0]
func _on_intento_conexion(from_id: int, to_id: int) -> void:
	if _get_mision_actual_idx() != FasesCampaña.VINCULOS_INICIALES or MisionFinal.pistas_descubiertas.is_empty(): return
	var enlace_valido = ((from_id == 1 and to_id == 2) or (from_id == 2 and to_id == 1) or (from_id == 2 and to_id == 3) or (from_id == 3 and to_id == 2) or (from_id == 3 and to_id == 4) or (from_id == 4 and to_id == 3) or (from_id == 5 and to_id == 3) or (from_id == 3 and to_id == 5) or (from_id == 3 and to_id == 0) or (from_id == 0 and to_id == 3))
	if not enlace_valido: return
	for e: Dictionary in graph.edge_list: if (e["from"] == from_id and e["to"] == to_id) or (e["from"] == to_id and e["to"] == from_id): return
	graph.add_edge(from_id, to_id, 999.0); MisionFinal.memoria_grafo = graph.edge_list.duplicate(true)
	if renderer.has_method("queue_redraw"): renderer.queue_redraw()
	_actualizar_dropdown_hilos()
func _on_intento_borrado(from_id: int, to_id: int) -> void:
	if _get_mision_actual_idx() != FasesCampaña.VINCULOS_INICIALES: return
	graph.edge_list = graph.edge_list.filter(func(e): return not ((e["from"] == from_id and e["to"] == to_id) or (e["from"] == to_id and e["to"] == from_id)))
	if "verified_edges" in renderer:
		renderer.verified_edges = renderer.verified_edges.filter(func(v): return not ((v.x == from_id and v.y == to_id) or (v.x == to_id and v.y == from_id)))
	MisionFinal.memoria_grafo = graph.edge_list.duplicate(true)
	MisionFinal.memoria_verificados = renderer.verified_edges.duplicate(true) if "verified_edges" in renderer else []
	if renderer.has_method("queue_redraw"): renderer.queue_redraw()
	_actualizar_dropdown_hilos(); _verificar_desbloqueo_analisis()
func _on_confrontar_pressed() -> void:
	if is_instance_valid(btn_confrontar): btn_confrontar.visible = false
	fase_ejecucion = EstadosTablero.CINEMATICA; cine_layer.visible = true
	if is_instance_valid(reproductor_audio):
		reproductor_audio.stop()
		if ResourceLoader.exists("res://audio/bgm_tension.mp3"): reproductor_audio.stream = load("res://audio/bgm_tension.mp3"); reproductor_audio.play()
	var fondo := ColorRect.new(); fondo.color = Color(0.02, 0.02, 0.03, 1.0); fondo.set_anchors_preset(Control.PRESET_FULL_RECT); cine_layer.add_child(fondo)
	sprite_izq = TextureRect.new(); sprite_izq.position = Vector2(60, 80); sprite_izq.size = Vector2(340, 400); sprite_izq.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; sprite_izq.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; cine_layer.add_child(sprite_izq)
	sprite_der = TextureRect.new(); sprite_der.position = Vector2(820, 80); sprite_der.size = Vector2(340, 400); sprite_der.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; sprite_der.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; cine_layer.add_child(sprite_der)
	var caja := Panel.new(); caja.position = Vector2(60, 490); caja.size = Vector2(1100, 200); var st := StyleBoxFlat.new(); st.bg_color = Color(0.04, 0.04, 0.07, 0.97); st.border_width_top = 4; st.border_color = Color(0.9, 0.72, 0.22); caja.add_theme_stylebox_override("panel", st); cine_layer.add_child(caja)
	txt_nombre_cine = Label.new(); txt_nombre_cine.position = Vector2(24, 14); txt_nombre_cine.add_theme_font_size_override("font_size", 21); caja.add_child(txt_nombre_cine)
	txt_dialogo_cine = RichTextLabel.new(); txt_dialogo_cine.bbcode_enabled = true; txt_dialogo_cine.position = Vector2(24, 52); txt_dialogo_cine.size = Vector2(900, 132); txt_dialogo_cine.add_theme_font_size_override("normal_font_size", 18); caja.add_child(txt_dialogo_cine)
	btn_cine_next = Button.new(); btn_cine_next.text = "CONTINUAR ▶"; btn_cine_next.position = Vector2(940, 130); btn_cine_next.size = Vector2(148, 44); btn_cine_next.pressed.connect(_avanzar_dialogo_cine); caja.add_child(btn_cine_next)
	lista_dialogos = [
		{"nombre": "DETECTIVE", "color": "#55aaff", "avatar": "res://avatars/detective_neutro.png", "texto": "Andrés, afirmaste que Santi estuvo contigo toda la noche. Interceptamos los registros de conexión del campus.", "lado": "izq"},
		{"nombre": "ANDRÉS", "color": "#eebb55", "avatar": "res://avatars/andres_avatar.png", "texto": "¿De qué habla? Estábamos estudiando para la entrega final...", "lado": "der"},
		{"nombre": "DETECTIVE", "color": "#55aaff", "avatar": "res://sprites/detective_rabioso.png", "texto": "Falso. Tu equipo registra descargas masivas de videojuegos exactamente a esa hora. Le diste una coartada falsa.", "lado": "izq"},
		{"nombre": "ANDRÉS", "color": "#eebb55", "avatar": "res://sprites/andres_nervioso.png", "texto": "¡Está bien! Santi me lo pidió... Me dijo que si alguien preguntaba, dijera que estuvimos juntos. ¡Yo no sabía que iba a destruir los archivos de Alex!", "lado": "der"},
		{"nombre": "DETECTIVE", "color": "#55aaff", "avatar": "res://sprites/detective_rabioso.png", "texto": "Tu protección cayó, Santi. Andrés confesó. El rastreo de la red no miente: la campaña de acoso lleva tu firma.", "lado": "izq"},
		{"nombre": "SANTI", "color": "#ff5555", "avatar": "res://sprites/santi_nervioso.png", "texto": "¡Ese cobarde! Igual... un mapa de conexiones en una pared no demuestra que yo toqué la cuenta de Alex.", "lado": "der"},
		{"nombre": "DETECTIVE", "color": "#55aaff", "avatar": "res://sprites/detective_rabioso.png", "texto": "Tenemos el historial del administrador. Alguien usó credenciales robadas de Yolanda... y el acceso coincide con tu teléfono.", "lado": "izq"},
		{"nombre": "SANTI", "color": "#ff5555", "avatar": "res://sprites/santi_rabioso.png", "texto": "¡Alex descubrió que yo estaba saboteando los laboratorios para mi beneficio! ¡Tenía que borrarlo de los registros!", "lado": "der"},
		{"nombre": "SISTEMA UNINORTE", "color": "#55ff55", "avatar": "res://sprites/santi_rabioso.png", "texto": "Confesión registrada. Avanzando a la FASE 2: Localizar el rastro del prófugo.", "lado": "der"}
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
		fase_ejecucion = EstadosTablero.CONSTRUCCION; _habilitar_siguiente_fase(FasesCampaña.RUTA_SEGURA)
func _habilitar_siguiente_fase(siguiente: int) -> void:
	var btn := Button.new(); btn.position = Vector2(15, 245); btn.size = Vector2(290, 45); btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	match siguiente:
		FasesCampaña.RUTA_SEGURA: btn.text = "⏩ ENCONTRAR RUTA ÓPTIMA"
		FasesCampaña.RECONSTRUCCION: btn.text = "⏩ TRAZAR CANAL DE CONF"
		FasesCampaña.FLUJO_IMPACTO: btn.text = "⏩ CALCULAR FLUJO MÁXIMO"
		FasesCampaña.CASO_CERRADO: btn.text = "🏆 FINALIZAR CASO"
	btn.pressed.connect(func():
		if siguiente == FasesCampaña.CASO_CERRADO: NetworkManager.broadcast_victory()
		else: MisionFinal.mision_actual = siguiente; get_tree().reload_current_scene()
	)
	panel_terminal.add_child(btn)
func _refrescar_libreta() -> void:
	var txt: String = ""
	match _get_mision_actual_idx():
		FasesCampaña.VINCULOS_INICIALES:
			if MisionFinal.pistas_descubiertas.is_empty(): txt = "[color=#777777](Interroga y extrae evidencias de la PC)[/color]"
			else: for ev: String in MisionFinal.pistas_descubiertas.values(): txt += "• " + ev + "\n\n"
		FasesCampaña.RUTA_SEGURA: txt = "[b]NIVELES DE RIESGO DE COMUNICACIÓN[/b]\n\nYolanda➔Rafa: 2.0\nRafa➔Camila: 4.0\nCamila➔Santi: 2.0\nSanti➔Yolanda: 1.0\nAndrés➔Santi: 3.0\nSanti➔Alex: 6.0"
		FasesCampaña.RECONSTRUCCION: txt = "[b]COSTO DE RECONSTRUCCIÓN SOCIAL[/b]\n\nAlex➔Rafa: 4.0\nAlex➔Yolanda: 3.0\nRafa➔Camila: 2.0\nCamila➔Santi: 5.0\nSanti➔Yolanda: 1.0\nYolanda➔Andrés: 6.0"
		FasesCampaña.FLUJO_IMPACTO: txt = "[b]CAPACIDAD DE TRANSMISIÓN (MB/s)[/b]\n\nRafa➔Camila: 10.0\nRafa➔Santi: 8.0\nCamila➔Yolanda: 7.0\nSanti➔Yolanda: 4.0\nYolanda➔Alex: 12.0\nAndrés➔Rafa: 5.0"
	libreta_texto.text = txt
func _titulo_fase() -> String:
	match _get_mision_actual_idx():
		FasesCampaña.VINCULOS_INICIALES: return "FASE 1 — MAPA DE VÍNCULOS"
		FasesCampaña.RUTA_SEGURA: return "FASE 2 — RUTA DE INTERVENCIÓN"
		FasesCampaña.RECONSTRUCCION: return "FASE 3 — CANAL DE CONFIANZA"
		FasesCampaña.FLUJO_IMPACTO: return "FASE 4 — MEDICIÓN DE IMPACTO"
		_: return "PANEL CENTRAL"
var _panel_ayuda: Panel
func _build_panel_ayuda() -> void:
	_panel_ayuda = _make_panel(Color(0.06, 0.06, 0.14, 0.97), Color(0.8, 0.6, 0.2)); _panel_ayuda.position = Vector2(300, 58); _panel_ayuda.size = Vector2(560, 480); _panel_ayuda.visible = false; ui_layer.add_child(_panel_ayuda)
	var rt := RichTextLabel.new(); rt.bbcode_enabled = true; rt.set_anchors_preset(Control.PRESET_FULL_RECT); rt.offset_left = 16; rt.offset_top = 16; rt.add_theme_font_size_override("normal_font_size", 14); rt.text = "[b][color=#ffcc44]AYUDA DE INVESTIGACIÓN[/color][/b]\n\nConecta los lazos de sospecha con Clic Izquierdo y arrastra hacia otra persona.\nUsa la terminal lateral para verificar tus conclusiones."
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
