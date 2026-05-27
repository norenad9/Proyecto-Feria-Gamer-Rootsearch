extends Node
var intro_layer: CanvasLayer
var room_layer: CanvasLayer
var bg_intro: TextureRect
var sprite_left: TextureRect
var sprite_right: TextureRect
var dialog_box: Panel
var dialog_text: RichTextLabel
var name_label: Label
var btn_continuar: Button
var bg_oficina: TextureRect
var hint_pc: Panel          
var hint_tablero: Panel     
var hint_puerta: Panel
var hint_archivo: Panel
var panel_objetivos: Panel
var _area_btn_enviar: Rect2 = Rect2()
var _area_btn_cerrar: Rect2 = Rect2()
var _key_intel_pendiente: String = ""
var panel_bloqueo: Panel
var lbl_bloqueo: Label
var dialog_queue: Array = []
var is_typing: bool = false
var current_full_text: String = ""
var bgm_player: AudioStreamPlayer
const ZONE_PC      := Rect2(380, 290, 260, 200)
const ZONE_TABLERO := Rect2(580, 120, 260, 220)
const ZONE_PUERTA  := Rect2(50, 150, 250, 500)
const ZONE_ARCHIVO := Rect2(310, 510, 200, 130)
var panel_descubrimiento: Panel
var txt_descubrimiento: RichTextLabel
var descubrimiento_activo: bool = false
var _puzzle_panel: Panel
var _puzzle_pieces_placed: int = 0
var _puzzle_total: int = 0
var _puzzle_dragged: Control = null
var _puzzle_drag_offset: Vector2 = Vector2()
var _puzzle_solved: bool = false
var _puzzle_key_intel: String = ""
var _puzzle_slots: Array = []
var _puzzle_fragments: Array = []
var _enviar_label_ref: Label = null
func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	bgm_player.volume_db = -12.0
	if ResourceLoader.exists("res://audio/bgm_mystery.mp3"):
		bgm_player.stream = load("res://audio/bgm_mystery.mp3")
		bgm_player.play()
	if NetworkManager.is_multiplayer_active() and NetworkManager.is_informatico():
		get_tree().change_scene_to_file("res://scenes/mission_final.tscn")
		return
	if not MisionFinal.historia_completada:
		_build_intro_layer()
		_cargar_guion()
		_play_next_dialog()
	else:
		_build_room_layer()
func _build_intro_layer() -> void:
	intro_layer = CanvasLayer.new()
	intro_layer.layer = 10
	add_child(intro_layer)
	bg_intro = TextureRect.new()
	bg_intro.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_intro.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_intro.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists("res://backgrounds/bg_campus.png"): bg_intro.texture = load("res://backgrounds/bg_campus.png")
	intro_layer.add_child(bg_intro)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.38)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro_layer.add_child(overlay)
	sprite_left = TextureRect.new()
	sprite_left.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sprite_left.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite_left.position = Vector2(40, 60)
	sprite_left.size = Vector2(360, 580)
	intro_layer.add_child(sprite_left)
	sprite_right = TextureRect.new()
	sprite_right.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sprite_right.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite_right.position = Vector2(700, 60)
	sprite_right.size = Vector2(380, 580)
	intro_layer.add_child(sprite_right)
	dialog_box = Panel.new()
	dialog_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_box.offset_top = -195; dialog_box.offset_bottom = -14
	dialog_box.offset_left = 50; dialog_box.offset_right = -50
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.04, 0.04, 0.08, 0.96)
	st.border_width_top = 4
	st.border_color = Color(0.78, 0.52, 0.18)
	dialog_box.add_theme_stylebox_override("panel", st)
	intro_layer.add_child(dialog_box)
	name_label = Label.new()
	name_label.position = Vector2(28, 12)
	name_label.add_theme_font_size_override("font_size", 23)
	dialog_box.add_child(name_label)
	dialog_text = RichTextLabel.new()
	dialog_text.bbcode_enabled = true
	dialog_text.position = Vector2(28, 52)
	dialog_text.size = Vector2(870, 112)
	dialog_text.add_theme_font_size_override("normal_font_size", 21)
	dialog_box.add_child(dialog_text)
	btn_continuar = Button.new()
	btn_continuar.text = "Continuar →"
	btn_continuar.position = Vector2(720, 128)
	btn_continuar.custom_minimum_size = Vector2(230, 48)
	btn_continuar.pressed.connect(_on_continuar_pressed)
	dialog_box.add_child(btn_continuar)
	var chat = ChatOverlay.new()
	add_child(chat)
func _cargar_guion() -> void:
	_q("Detective", "*La lluvia golpea la ventana. Reviso los archivos del caso en mi escritorio...*", "res://sprites/detective_pensativo.png", false)
	_q("Dra. Márquez", "¡Detective! Gracias por venir. Tenemos una situación grave en Ingeniería de Sistemas.", "res://sprites/marquez_urgente.png", true)
	_q("Detective", "Buenas tardes, doctora. ¿De qué se trata?", "res://sprites/detective_neutro.png", false)
	_q("Dra. Márquez", "Es Alex, uno de nuestros estudiantes más prometedores. Alguien borró su expediente académico completo del servidor y está difundiendo rumores falsos sobre él.", "res://sprites/marquez_urgente.png", true)
	_q("Dra. Márquez", "Todos señalan a Rafa porque tuvieron una discusión pública, pero las conexiones son más complejas de lo que parecen.", "res://sprites/marquez_urgente.png", true)
	_q("Detective", "Voy a necesitar revisar los accesos al sistema y hablar con el círculo cercano. ¿Quiénes interactuaban con Alex?", "res://sprites/detective_pensativo.png", false)
	_q("Dra. Márquez", "Yolanda es la administradora de la red. También están Camila, Andrés... y Santi, que siempre ha estado muy involucrado en los servidores del campus.", "res://sprites/marquez_urgente.png", true)
	_q("Detective", "Perfecto. Revisaré la PC de la oficina, interrogaré a los sospechosos y mi compañero Informático analizará la red en paralelo. Entre los dos resolveremos esto.", "res://sprites/detective_neutro.png", false)
func _q(speaker: String, text: String, sprite: String, left: bool) -> void:
	dialog_queue.append({"speaker": speaker, "text": text, "sprite": sprite, "left": left})
func _play_next_dialog() -> void:
	if dialog_queue.is_empty():
		_finish_intro()
		return
	var data: Dictionary = dialog_queue.pop_front()
	name_label.text = data["speaker"]
	name_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.25) if data["speaker"] == "Detective" else Color(0.4, 0.8, 1.0))
	var spr: String = data["sprite"]
	if spr != "" and ResourceLoader.exists(spr):
		var tex: Texture2D = load(spr)
		if data["left"]:
			sprite_left.texture = tex; sprite_left.modulate = Color(1, 1, 1); sprite_right.modulate = Color(0.35, 0.35, 0.35)
		else:
			sprite_right.texture = tex
			sprite_right.modulate = Color(1, 1, 1); sprite_left.modulate = Color(0.35, 0.35, 0.35)
	_typewriter(data["text"])
func _typewriter(full_text: String) -> void:
	is_typing = true; current_full_text = full_text
	dialog_text.text = ""; btn_continuar.text = "Saltar ▶▶"
	for i: int in range(full_text.length()):
		if not is_instance_valid(self) or not is_inside_tree() or not is_typing: break
		dialog_text.text += full_text[i]
		await get_tree().create_timer(0.015).timeout
	is_typing = false
	dialog_text.text = full_text
	if dialog_queue.is_empty():
		btn_continuar.text = "[ INICIAR CASO ]"
		btn_continuar.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		btn_continuar.text = "Continuar →"
func _on_continuar_pressed() -> void:
	if is_typing:
		is_typing = false
		dialog_text.text = current_full_text
		if dialog_queue.is_empty(): btn_continuar.text = "[ INICIAR CASO ]";
		btn_continuar.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else: _play_next_dialog()
func _finish_intro() -> void:
	MisionFinal.historia_completada = true
	if intro_layer: intro_layer.queue_free()
	intro_layer = null
	_build_room_layer()
func _build_room_layer() -> void:
	room_layer = CanvasLayer.new()
	room_layer.layer = 5
	add_child(room_layer)
	bg_oficina = TextureRect.new()
	bg_oficina.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_oficina.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if ResourceLoader.exists("res://backgrounds/bg_oficina.png"): bg_oficina.texture = load("res://backgrounds/bg_oficina.png")
	room_layer.add_child(bg_oficina)
	hint_pc      = _make_hint("💻  SISTEMA DIGITAL\n[Exclusivo del Informático]", Vector2(ZONE_PC.position.x, ZONE_PC.position.y - 58))
	hint_tablero = _make_hint("🔴  PANEL DE CONEXIONES\n[Exclusivo del Informático]", Vector2(ZONE_TABLERO.position.x - 20, ZONE_TABLERO.position.y - 58))
	var puerta_texto: String = "🚪  SALIR AL CAMPUS\n[Interrogar Sospechosos]"
	match MisionFinal.mision_actual:
		MisionFinal.Misiones.M1_ORIGEN: puerta_texto = "🚪  SALIR AL CAMPUS\n[Interrogar Sospechosos]"
		MisionFinal.Misiones.M2_RUTA: puerta_texto = "🚪  SALIR AL CAMPUS\n[Interrogar sobre rutas de red]"
		MisionFinal.Misiones.M3_RED: puerta_texto = "🚪  SALIR AL CAMPUS\n[Indagar sobre relaciones]"
		MisionFinal.Misiones.M4_IMPACTO: puerta_texto = "🚪  SALIR AL CAMPUS\n[Preguntar por capacidad de red]"
	hint_puerta  = _make_hint(puerta_texto, Vector2(ZONE_PUERTA.position.x, ZONE_PUERTA.position.y + 200))
	var hint_archivo_texto: String = "📁  ARCHIVO DEL CASO\n[Investiga documentos]"
	hint_archivo = _make_hint(hint_archivo_texto, Vector2(ZONE_ARCHIVO.position.x, ZONE_ARCHIVO.position.y))
	room_layer.add_child(hint_pc)
	room_layer.add_child(hint_tablero); room_layer.add_child(hint_puerta); room_layer.add_child(hint_archivo) 
	panel_bloqueo = Panel.new()
	panel_bloqueo.position = Vector2(390, 560)
	panel_bloqueo.size = Vector2(500, 80)
	panel_bloqueo.visible = false
	var st_b := StyleBoxFlat.new()
	st_b.bg_color = Color(0.18, 0.02, 0.02, 0.96)
	st_b.border_width_left = 2; st_b.border_width_top = 2; st_b.border_width_right = 2; st_b.border_width_bottom = 2
	st_b.border_color = Color(0.9, 0.2, 0.2)
	st_b.corner_radius_top_left = 4; st_b.corner_radius_top_right = 4
	st_b.corner_radius_bottom_left = 4; st_b.corner_radius_bottom_right = 4
	panel_bloqueo.add_theme_stylebox_override("panel", st_b)
	room_layer.add_child(panel_bloqueo)
	lbl_bloqueo = Label.new()
	lbl_bloqueo.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_bloqueo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_bloqueo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_bloqueo.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_bloqueo.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	panel_bloqueo.add_child(lbl_bloqueo)
	_build_overlay_ui()
	if NetworkManager.is_multiplayer_active():
		if not NetworkManager.victory_triggered.is_connected(_ir_victoria):
			NetworkManager.victory_triggered.connect(_ir_victoria)
		if not NetworkManager.algorithm_result_received.is_connected(_on_resultado_informatico):
			NetworkManager.algorithm_result_received.connect(_on_resultado_informatico)
		if not NetworkManager.mission_synced.is_connected(_on_mission_synced):
			NetworkManager.mission_synced.connect(_on_mission_synced)
		_build_panel_resultados()
func _on_mission_synced(_mission_idx: int) -> void:
	var txt: String = ""
	match MisionFinal.mision_actual:
		MisionFinal.Misiones.M1_ORIGEN: txt = "🚪  SALIR AL CAMPUS\n[Interrogar Sospechosos]"
		MisionFinal.Misiones.M2_RUTA: txt = "🚪  SALIR AL CAMPUS\n[Interrogar sobre rutas de red]"
		MisionFinal.Misiones.M3_RED: txt = "🚪  SALIR AL CAMPUS\n[Indagar sobre relaciones]"
		MisionFinal.Misiones.M4_IMPACTO: txt = "🚪  SALIR AL CAMPUS\n[Preguntar por capacidad de red]"
	if is_instance_valid(hint_puerta) and hint_puerta.get_child_count() > 0:
		var lbl = hint_puerta.get_child(0)
		if lbl is RichTextLabel:
			lbl.text = "[center]" + txt + "[/center]"
func _make_hint(text: String, pos: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = Vector2(230, 58); p.visible = false
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.05, 0.08, 0.92)
	st.border_width_left = 2; st.border_width_top = 2
	st.border_width_right = 2; st.border_width_bottom = 2
	st.border_color = Color(0.9, 0.7, 0.2)
	p.add_theme_stylebox_override("panel", st)
	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true; lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 8; lbl.offset_top = 4
	lbl.add_theme_font_size_override("normal_font_size", 14)
	lbl.text = "[center]" + text + "[/center]"
	p.add_child(lbl)
	return p
func _build_overlay_ui() -> void:
	var btn_libreta := Button.new()
	btn_libreta.text = "📓 Libreta del Caso"
	btn_libreta.position = Vector2(930, 16)
	btn_libreta.custom_minimum_size = Vector2(200, 44) 
	btn_libreta.pressed.connect(func() -> void: panel_objetivos.visible = !panel_objetivos.visible)
	room_layer.add_child(btn_libreta)
	panel_objetivos = Panel.new()
	panel_objetivos.position = Vector2(720, 66); panel_objetivos.size = Vector2(410, 300) 
	panel_objetivos.visible = false
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.08, 0.1, 0.96)
	st.border_width_left = 2; st.border_width_top = 2; st.border_width_right = 2; st.border_width_bottom = 2
	st.border_color = Color(0.3, 0.85, 0.3)
	panel_objetivos.add_theme_stylebox_override("panel", st)
	var t_obj := RichTextLabel.new()
	t_obj.bbcode_enabled = true; t_obj.set_anchors_preset(Control.PRESET_FULL_RECT)
	t_obj.offset_left = 14; t_obj.offset_top = 14
	t_obj.add_theme_font_size_override("normal_font_size", 15)
	var txt_mision: String = _texto_libreta()
	t_obj.text = txt_mision
	panel_objetivos.add_child(t_obj)
	room_layer.add_child(panel_objetivos)
func _abrir_archivo() -> void:
	if descubrimiento_activo:
		return
	var mision: int = MisionFinal.mision_actual
	var titulo: String = ""
	var contenido: String = ""
	var key_intel: String = ""
	var enviado: bool = false
	match mision:
		MisionFinal.Misiones.M1_ORIGEN:
			titulo = "EXPEDIENTE DEL CASO"
			var pistas := MisionFinal.pistas_descubiertas
			if pistas.is_empty():
				contenido = "Aún no hay evidencias recolectadas.\n\nDebes interrogar a los sospechosos en el campus\ny revisar la PC forense para reunir pistas."
			else:
				var lista: String = ""
				for key: String in pistas:
					lista += "• " + pistas[key] + "\n"
				contenido = "Evidencias recolectadas hasta ahora:\n\n" + lista
			key_intel = ""
		MisionFinal.Misiones.M2_RUTA:
			titulo = "DIAGRAMA DE RED"
			contenido = "Encuentras un diagrama de la topología de red.\nMuestra que Yolanda tiene acceso directo a la\ninfraestructura principal, mientras Andrés solo\ntiene un punto de acceso limitado.\n\nEl Informático necesita este dato para trazar\nla ruta de intervención más segura."
			key_intel = "m2_ruta_intel"
			enviado = MisionFinal.intel_enviada_m2
		MisionFinal.Misiones.M3_RED:
			titulo = "REPORTE DE CONFIANZA SOCIAL"
			contenido = "Revisas un informe de relaciones interpersonales.\nLos niveles de confianza entre los involucrados son:\n  • Yolanda→Rafa:    Baja (0.2)\n  • Rafa→Camila:      Media (0.5)\n  • Camila→Santi:     Alta (0.8)\n  • Andrés→Santi:     Baja (0.3)\n\nEl Informático necesita esta data para reconstruir\nla red de confianza."
			key_intel = "m3_red_intel"
			enviado = MisionFinal.intel_enviada_m3
		MisionFinal.Misiones.M4_IMPACTO:
			titulo = "ESPECIFICACIONES DEL SERVIDOR"
			contenido = "Encuentras el informe técnico del servidor.\n  Capacidad máxima: 15.0 MB/s\n  Cortafuegos:       Configurable\n  Protocolo:         TCP/UDP\n\nEl Informático necesita estos datos para calcular\nel flujo máximo y calibrar los filtros de seguridad."
			key_intel = "m4_impacto_intel"
			enviado = MisionFinal.intel_enviada_m4
	if mision != MisionFinal.Misiones.M1_ORIGEN and key_intel != "" and not enviado:
		_mostrar_puzzle_documento(titulo, contenido, key_intel, enviado)
	else:
		_mostrar_descubrimiento(titulo, contenido, key_intel, enviado)
func _mostrar_descubrimiento(titulo: String, contenido: String, key_intel: String, ya_enviado: bool = false) -> void:
	descubrimiento_activo = true
	panel_descubrimiento = Panel.new()
	panel_descubrimiento.position = Vector2(200, 80)
	panel_descubrimiento.size = Vector2(560, 490)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.06, 0.06, 0.1, 0.97)
	st.border_width_left = 3; st.border_width_top = 3; st.border_width_right = 3; st.border_width_bottom = 3
	st.border_color = Color(0.9, 0.72, 0.15)
	st.corner_radius_top_left = 6; st.corner_radius_top_right = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	panel_descubrimiento.add_theme_stylebox_override("panel", st)
	room_layer.add_child(panel_descubrimiento)
	var fondo_archivo := TextureRect.new()
	fondo_archivo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo_archivo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo_archivo.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists("res://backgrounds/notebook_bg.png"):
		fondo_archivo.texture = load("res://backgrounds/notebook_bg.png")
	fondo_archivo.z_index = -1
	panel_descubrimiento.add_child(fondo_archivo)
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.55)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_PASS
	fondo.z_index = -1
	room_layer.add_child(fondo)
	var lbl_titulo := Label.new()
	lbl_titulo.text = "📁 " + titulo
	lbl_titulo.position = Vector2(24, 16)
	lbl_titulo.add_theme_font_size_override("font_size", 18)
	lbl_titulo.add_theme_color_override("font_color", Color(0.95, 0.75, 0.2))
	panel_descubrimiento.add_child(lbl_titulo)
	var card := Panel.new()
	card.position = Vector2(24, 52)
	card.size = Vector2(510, 340)
	var st_card := StyleBoxFlat.new()
	st_card.bg_color = Color(0.92, 0.9, 0.85)
	st_card.border_width_left = 1; st_card.border_width_top = 1; st_card.border_width_right = 1; st_card.border_width_bottom = 1
	st_card.border_color = Color(0.35, 0.3, 0.2)
	card.add_theme_stylebox_override("panel", st_card)
	panel_descubrimiento.add_child(card)
	var lbl_doc := Label.new()
	lbl_doc.text = "📄  " + titulo
	lbl_doc.position = Vector2(16, 12)
	lbl_doc.add_theme_font_size_override("font_size", 15)
	lbl_doc.add_theme_color_override("font_color", Color(0.15, 0.1, 0.05))
	card.add_child(lbl_doc)
	var line := ColorRect.new()
	line.color = Color(0.3, 0.25, 0.15, 0.3)
	line.position = Vector2(16, 42)
	line.size = Vector2(478, 1)
	card.add_child(line)
	txt_descubrimiento = RichTextLabel.new()
	txt_descubrimiento.bbcode_enabled = true
	txt_descubrimiento.position = Vector2(16, 56)
	txt_descubrimiento.size = Vector2(478, 200)
	txt_descubrimiento.add_theme_font_size_override("normal_font_size", 13)
	txt_descubrimiento.add_theme_color_override("default_color", Color(0.15, 0.12, 0.08))
	txt_descubrimiento.text = contenido
	card.add_child(txt_descubrimiento)
	var sello := Label.new()
	sello.text = "CONFIDENCIAL"
	sello.position = Vector2(370, 270)
	sello.add_theme_font_size_override("font_size", 11)
	sello.add_theme_color_override("font_color", Color(0.7, 0.1, 0.1, 0.4))
	sello.rotation = 0.15
	card.add_child(sello)
	var area_enviar: Rect2 = Rect2()
	if key_intel != "":
		var lbl_enviar := Label.new()
		_enviar_label_ref = lbl_enviar
		lbl_enviar.position = Vector2(24, 402)
		lbl_enviar.size = Vector2(510, 42)
		lbl_enviar.add_theme_font_size_override("font_size", 14)
		lbl_enviar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_enviar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if ya_enviado:
			lbl_enviar.text = "✓ ENVIADO"
			lbl_enviar.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
			lbl_enviar.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		else:
			lbl_enviar.text = "📤 ENVIAR AL INFORMÁTICO"
			lbl_enviar.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		var st_env := StyleBoxFlat.new()
		st_env.bg_color = Color(0.06, 0.06, 0.12, 0.95)
		st_env.border_width_left = 1; st_env.border_width_top = 1; st_env.border_width_right = 1; st_env.border_width_bottom = 1
		st_env.border_color = Color(0.3, 0.6, 0.3)
		lbl_enviar.add_theme_stylebox_override("normal", st_env)
		panel_descubrimiento.add_child(lbl_enviar)
		area_enviar = Rect2(200 + 24, 80 + 402, 510, 42)
	var lbl_cerrar := Label.new()
	lbl_cerrar.position = Vector2(24, 450)
	lbl_cerrar.size = Vector2(510, 34)
	lbl_cerrar.text = "CERRAR"
	lbl_cerrar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_cerrar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_cerrar.add_theme_font_size_override("font_size", 15)
	lbl_cerrar.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	var st_cer := StyleBoxFlat.new()
	st_cer.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	st_cer.border_width_left = 1; st_cer.border_width_top = 1; st_cer.border_width_right = 1; st_cer.border_width_bottom = 1
	st_cer.border_color = Color(0.4, 0.4, 0.5)
	lbl_cerrar.add_theme_stylebox_override("normal", st_cer)
	panel_descubrimiento.add_child(lbl_cerrar)
	var area_cerrar := Rect2(200 + 24, 80 + 450, 510, 34)
	_area_btn_enviar = area_enviar
	_area_btn_cerrar = area_cerrar
	_key_intel_pendiente = key_intel if not ya_enviado else ""
func _mostrar_puzzle_documento(titulo: String, contenido: String, key_intel: String, ya_enviado: bool) -> void:
	descubrimiento_activo = true
	_puzzle_solved = ya_enviado
	_puzzle_key_intel = key_intel
	_puzzle_pieces_placed = 0
	_puzzle_dragged = null
	_puzzle_slots.clear()
	_puzzle_fragments.clear()
	_puzzle_panel = Panel.new()
	_puzzle_panel.position = Vector2(150, 50)
	_puzzle_panel.size = Vector2(700, 560)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.06, 0.06, 0.1, 0.97)
	st.border_width_left = 3; st.border_width_top = 3; st.border_width_right = 3; st.border_width_bottom = 3
	st.border_color = Color(0.9, 0.72, 0.15)
	st.corner_radius_top_left = 6; st.corner_radius_top_right = 6
	st.corner_radius_bottom_left = 6; st.corner_radius_bottom_right = 6
	_puzzle_panel.add_theme_stylebox_override("panel", st)
	room_layer.add_child(_puzzle_panel)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.z_index = -1
	room_layer.add_child(overlay)
	var lbl_tit := Label.new()
	lbl_tit.text = "🧩 " + titulo + " — Restaurar documento"
	lbl_tit.position = Vector2(20, 14)
	lbl_tit.add_theme_font_size_override("font_size", 18)
	lbl_tit.add_theme_color_override("font_color", Color(0.95, 0.75, 0.2))
	_puzzle_panel.add_child(lbl_tit)
	var lbl_inst := Label.new()
	lbl_inst.text = "Arrastra cada fragmento al recuadro correspondiente para reconstruir el documento."
	lbl_inst.position = Vector2(20, 44)
	lbl_inst.add_theme_font_size_override("font_size", 12)
	lbl_inst.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	_puzzle_panel.add_child(lbl_inst)
	_puzzle_fragments = _dividir_en_fragmentos(contenido, 4)
	_puzzle_total = _puzzle_fragments.size()
	var cols := 2
	var slot_w := 195
	var slot_h := 155
	var start_x := 24
	var start_y := 80
	for i in _puzzle_total:
		var col := i % cols
		var row := i / cols
		var sx := start_x + col * (slot_w + 14)
		var sy := start_y + row * (slot_h + 14)
		var slot := Panel.new()
		slot.position = Vector2(sx, sy)
		slot.size = Vector2(slot_w, slot_h)
		slot.set_meta("slot_ix", i)
		var ss := StyleBoxFlat.new()
		ss.bg_color = Color(0.2, 0.2, 0.25, 0.25)
		ss.border_width_left = 2; ss.border_width_top = 2; ss.border_width_right = 2; ss.border_width_bottom = 2
		ss.border_color = Color(0.5, 0.5, 0.6, 0.35)
		slot.add_theme_stylebox_override("panel", ss)
		_puzzle_panel.add_child(slot)
		_puzzle_slots.append(slot)
	var indices := range(_puzzle_total)
	indices.shuffle()
	for i in _puzzle_total:
		var ix: int = indices[i] as int
		var piece := Panel.new()
		piece.size = Vector2(slot_w, slot_h)
		piece.set_meta("piece_ix", ix)
		piece.set_meta("placed", false)
		piece.set_meta("orig_pos", Vector2(490 + (i % 2) * 100, 80 + (i / 2) * 170))
		var ps := _crear_estilo_troceado()
		piece.add_theme_stylebox_override("panel", ps)
		var lb := Label.new()
		lb.text = _puzzle_fragments[ix]
		lb.set_anchors_preset(Control.PRESET_FULL_RECT)
		lb.offset_left = 8; lb.offset_top = 6
		lb.offset_right = -6; lb.offset_bottom = -6
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD
		lb.add_theme_font_size_override("font_size", 11)
		lb.add_theme_color_override("font_color", Color(0.12, 0.08, 0.04))
		piece.add_child(lb)
		piece.position = piece.get_meta("orig_pos")
		_puzzle_panel.add_child(piece)
	var lbl_cerrar := Label.new()
	lbl_cerrar.position = Vector2(24, 500)
	lbl_cerrar.size = Vector2(650, 34)
	lbl_cerrar.text = "CERRAR"
	lbl_cerrar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_cerrar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_cerrar.add_theme_font_size_override("font_size", 15)
	lbl_cerrar.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	var sc := StyleBoxFlat.new()
	sc.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	sc.border_width_left = 1; sc.border_width_top = 1; sc.border_width_right = 1; sc.border_width_bottom = 1
	sc.border_color = Color(0.4, 0.4, 0.5)
	lbl_cerrar.add_theme_stylebox_override("normal", sc)
	_puzzle_panel.add_child(lbl_cerrar)
	_area_btn_enviar = Rect2()
	_area_btn_cerrar = Rect2(150 + 24, 50 + 500, 650, 34)
	_key_intel_pendiente = ""
func _dividir_en_fragmentos(texto: String, n: int) -> Array:
	var lineas := texto.split("\n")
	var total := lineas.size()
	if total <= n:
		var result: Array = []
		for i in total:
			result.append(lineas[i].strip_edges())
		while result.size() < n:
			result.append("")
		return result
	var lines_per: float = ceil(float(total) / n)
	var frags: Array = []
	var idx: int = 0
	for f in n:
		var chunk: String = ""
		var count := 0
		while idx < total and count < lines_per:
			if chunk != "":
				chunk += "\n"
			chunk += lineas[idx]
			idx += 1
			count += 1
		frags.append(chunk)
	return frags
func _crear_estilo_troceado() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.92, 0.9, 0.85)
	s.border_width_left = 1; s.border_width_top = 1; s.border_width_right = 1; s.border_width_bottom = 1
	s.border_color = Color(0.35, 0.3, 0.2)
	s.corner_radius_top_left = 4; s.corner_radius_top_right = 2
	s.corner_radius_bottom_left = 2; s.corner_radius_bottom_right = 4
	s.shadow_size = 3
	s.shadow_offset = Vector2(1, 1)
	s.shadow_color = Color(0, 0, 0, 0.25)
	return s
func _on_puzzle_solved() -> void:
	_puzzle_solved = true
	for child in _puzzle_panel.get_children():
		if child is Panel and child.has_meta("slot_ix"):
			var ss := StyleBoxFlat.new()
			ss.bg_color = Color(0.15, 0.25, 0.15, 0.3)
			ss.set_border_width_all(2)
			ss.border_color = Color(0.3, 0.8, 0.3, 0.6)
			child.add_theme_stylebox_override("panel", ss)
	var feedback := Label.new()
	feedback.text = "✓ Documento restaurado"
	feedback.position = Vector2(20, 470)
	feedback.add_theme_font_size_override("font_size", 16)
	feedback.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	_puzzle_panel.add_child(feedback)
	if _puzzle_key_intel != "":
		_enviar_label_ref = Label.new()
		var lbl_env := _enviar_label_ref
		lbl_env.position = Vector2(300, 500)
		lbl_env.size = Vector2(170, 34)
		lbl_env.text = "📤 ENVIAR AL INFORMÁTICO"
		lbl_env.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_env.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_env.add_theme_font_size_override("font_size", 14)
		lbl_env.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		var se := StyleBoxFlat.new()
		se.bg_color = Color(0.06, 0.06, 0.12, 0.95)
		se.border_width_left = 1; se.border_width_top = 1; se.border_width_right = 1; se.border_width_bottom = 1
		se.border_color = Color(0.3, 0.6, 0.3)
		lbl_env.add_theme_stylebox_override("normal", se)
		_puzzle_panel.add_child(lbl_env)
		_area_btn_enviar = Rect2(150 + 300, 50 + 500, 170, 34)
		_key_intel_pendiente = _puzzle_key_intel
func _enviar_intel(key: String) -> void:
	if key == "m2_ruta_intel":
		MisionFinal.pistas_descubiertas[key] = "Yolanda tiene acceso directo a la infraestructura."
		MisionFinal.intel_enviada_m2 = true
	elif key == "m3_red_intel":
		MisionFinal.pistas_descubiertas[key] = "Niveles de confianza: Yolanda→Rafa baja, Rafa→Camila media, Camila→Santi alta, Andres→Santi baja."
		MisionFinal.intel_enviada_m3 = true
	elif key == "m4_impacto_intel":
		MisionFinal.pistas_descubiertas[key] = "Capacidad del servidor: 15.0 MB/s. Cortafuegos configurable."
		MisionFinal.intel_enviada_m4 = true
	if NetworkManager.is_multiplayer_active():
		NetworkManager.sync_pistas_to_partner()
	_key_intel_pendiente = ""
	_area_btn_enviar = Rect2()
	if is_instance_valid(_enviar_label_ref):
		_enviar_label_ref.text = "✓ ENVIADO"
		_enviar_label_ref.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	_enviar_label_ref = null
func _cerrar_descubrimiento() -> void:
	descubrimiento_activo = false
	if is_instance_valid(panel_descubrimiento):
		panel_descubrimiento.queue_free(); panel_descubrimiento = null
	if is_instance_valid(_puzzle_panel):
		_puzzle_panel.queue_free(); _puzzle_panel = null
	_puzzle_dragged = null
	_puzzle_slots.clear()
	_puzzle_fragments.clear()
	_enviar_label_ref = null
	for c in room_layer.get_children():
		if c is ColorRect and c.color == Color(0, 0, 0, 0.55) and c.z_index == -1:
			c.queue_free(); break
func _input(event: InputEvent) -> void:
	if room_layer == null or not room_layer.visible: return
	if descubrimiento_activo:
		if event.is_action_pressed("ui_cancel"):
			_cerrar_descubrimiento(); return
		if is_instance_valid(_puzzle_panel) and not _puzzle_solved:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				var me := event as InputEventMouseButton
				for child in _puzzle_panel.get_children():
					if child is Panel and child.has_meta("piece_ix") and not child.get_meta("placed"):
						var gpos: Vector2 = child.global_position if "global_position" in child else _puzzle_panel.position + child.position
						var global_rect := Rect2(gpos, child.size)
						if global_rect.has_point(me.position):
							_puzzle_dragged = child
							_puzzle_drag_offset = me.position - gpos
							child.z_index = 100
							return
			if event is InputEventMouseMotion and _puzzle_dragged != null:
				var me := event as InputEventMouseMotion
				var new_global := me.position - _puzzle_drag_offset
				if "global_position" in _puzzle_dragged:
					_puzzle_dragged.global_position = new_global
				else:
					_puzzle_dragged.position = new_global - _puzzle_panel.position
				return
			if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _puzzle_dragged != null:
				var me := event as InputEventMouseButton
				var piece_ix: int = _puzzle_dragged.get_meta("piece_ix") as int
				var snapped := false
				var dragged_gpos: Vector2 = _puzzle_dragged.global_position if "global_position" in _puzzle_dragged else _puzzle_panel.position + _puzzle_dragged.position
				var center: Vector2 = dragged_gpos + _puzzle_dragged.size * 0.5
				for slot in _puzzle_slots:
					if slot.get_meta("slot_ix") == piece_ix:
						var slot_gpos: Vector2 = _puzzle_panel.position + slot.position
						var slot_rect := Rect2(slot_gpos, slot.size)
						if slot_rect.has_point(center):
							_puzzle_dragged.position = slot.position
							_puzzle_dragged.z_index = 0
							_puzzle_dragged.set_meta("placed", true)
							_puzzle_pieces_placed += 1
							snapped = true
							if _puzzle_pieces_placed >= _puzzle_total:
								_on_puzzle_solved()
						break
				if not snapped:
					_puzzle_dragged.position = _puzzle_dragged.get_meta("orig_pos")
					_puzzle_dragged.z_index = 0
				_puzzle_dragged = null
				return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_event := event as InputEventMouseButton
			var pos := mouse_event.position
			if _area_btn_enviar.has_point(pos) and _key_intel_pendiente != "":
				_enviar_intel(_key_intel_pendiente)
			elif _area_btn_cerrar.has_point(pos):
				_cerrar_descubrimiento()
			else:
				var abs_panel := Rect2(150, 50, 700, 560) if is_instance_valid(_puzzle_panel) else Rect2(200, 80, 560, 490)
				if not abs_panel.has_point(pos):
					_cerrar_descubrimiento()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		var pos: Vector2 = mouse_event.position
		if ZONE_PC.has_point(pos): 
			if NetworkManager.is_multiplayer_active() and NetworkManager.is_detective():
				_mostrar_pop_bloqueo("🔒 ACCESO RESTRINGIDO\nEsta terminal es del Informático. Debo concentrarme en interrogar sospechosos en el campus.")
				return
			if is_inside_tree() and get_tree() != null:
				get_tree().change_scene_to_file("res://scenes/pc.tscn")
		elif ZONE_TABLERO.has_point(pos): 
			if NetworkManager.is_multiplayer_active() and NetworkManager.is_detective():
				_mostrar_pop_bloqueo("🔒 ACCESO RESTRINGIDO\nEl panel de conexiones es manipulado únicamente por el Informático en su terminal remota.")
				return
			if is_inside_tree() and get_tree() != null:
				get_tree().change_scene_to_file("res://scenes/mission_final.tscn")
		elif ZONE_ARCHIVO.has_point(pos):
			_abrir_archivo()
		elif ZONE_PUERTA.has_point(pos): 
			if is_inside_tree() and get_tree() != null:
				get_tree().change_scene_to_file("res://scenes/interrogatorio.tscn")
func _mostrar_pop_bloqueo(msg: String) -> void:
	if is_instance_valid(panel_bloqueo) and is_instance_valid(lbl_bloqueo):
		lbl_bloqueo.text = msg
		panel_bloqueo.visible = true
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(panel_bloqueo):
			panel_bloqueo.visible = false
func _process(_delta: float) -> void:
	if room_layer == null or not room_layer.visible: return
	var mouse: Vector2 = get_viewport().get_mouse_position()
	hint_pc.visible = ZONE_PC.has_point(mouse)
	hint_tablero.visible = ZONE_TABLERO.has_point(mouse)
	hint_puerta.visible = ZONE_PUERTA.has_point(mouse)
	hint_archivo.visible = ZONE_ARCHIVO.has_point(mouse)
func _ir_victoria() -> void:
	get_tree().change_scene_to_file("res://scenes/escena_victoria.tscn")
var panel_resultados: Panel
var lbl_resultado: RichTextLabel
func _build_panel_resultados() -> void:
	panel_resultados = Panel.new()
	panel_resultados.position = Vector2(16, 60)
	panel_resultados.size = Vector2(350, 130)
	panel_resultados.visible = false
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.02, 0.08, 0.02, 0.96)
	st.border_width_left = 3; st.border_width_top = 3
	st.border_width_right = 3; st.border_width_bottom = 3
	st.border_color = Color(0.2, 1.0, 0.45)
	panel_resultados.add_theme_stylebox_override("panel", st)
	room_layer.add_child(panel_resultados)
	var lbl_t := Label.new()
	lbl_t.text = "💻 ANÁLISIS EN TIEMPO REAL DEL INFORMÁTICO"
	lbl_t.position = Vector2(10, 6)
	lbl_t.add_theme_font_size_override("font_size", 12)
	lbl_t.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	panel_resultados.add_child(lbl_t)
	lbl_resultado = RichTextLabel.new()
	lbl_resultado.bbcode_enabled = true
	lbl_resultado.position = Vector2(10, 28)
	lbl_resultado.size = Vector2(330, 94)
	lbl_resultado.add_theme_font_size_override("normal_font_size", 13)
	panel_resultados.add_child(lbl_resultado)
func _texto_libreta() -> String:
	var mision: int = MisionFinal.mision_actual
	match mision:
		MisionFinal.Misiones.M1_ORIGEN:
			return (
				"[b][color=#ffcc44]CUADERNO DE CASO — F1: RASTREAR ORIGEN[/color][/b]\n\n"
				+ "[color=#55ff55]Caso:[/color] Sabotaje digital contra Alex.\n\n"
				+ "[color=#ff5555]Sospechosos:[/color]\n"
				+ " - Rafa\n - Camila\n - Yolanda\n - Santi\n - Andres\n\n"
				+ "[color=#aaddff]Plan:[/color]\n"
				+ "[✔] Salir al campus a interrogar sospechosos.\n"
				+ "[ ] Enviar las declaraciones al Informatico.\n"
				+ "[ ] El Informatico analizara la red."
			)
		MisionFinal.Misiones.M2_RUTA:
			var chk_archivo: String = "✔" if MisionFinal.intel_enviada_m2 else " "
			return (
				"[b][color=#ffcc44]CUADERNO DE CASO — F2: CORTAR PROPAGACION[/color][/b]\n\n"
				+ "[color=#55ff55]Contexto:[/color] Santi activo un script que replica el dano.\n"
				+ "Hay que encontrar la ruta mas rapida para intervenir.\n\n"
				+ "[color=#aaddff]Plan:[/color]\n"
				+ "[" + chk_archivo + "] Revisar el ARCHIVO del caso (diagrama de red).\n"
				+ "[ ] El Informatico debe trazar la ruta segura.\n"
				+ "[ ] Usar la PC forense si es necesario."
			)
		MisionFinal.Misiones.M3_RED:
			var chk_archivo: String = "✔" if MisionFinal.intel_enviada_m3 else " "
			return (
				"[b][color=#ffcc44]CUADERNO DE CASO — F3: RECONSTRUIR RED[/color][/b]\n\n"
				+ "[color=#55ff55]Contexto:[/color] El rumor digital se propago por toda la red.\n"
				+ "Hay que restablecer los lazos de confianza rotos.\n\n"
				+ "[color=#aaddff]Plan:[/color]\n"
				+ "[" + chk_archivo + "] Revisar el ARCHIVO (reporte de confianza social).\n"
				+ "[ ] Enviar los niveles de confianza al Informatico.\n"
				+ "[ ] El Informatico reconstruira la red."
			)
		MisionFinal.Misiones.M4_IMPACTO:
			var chk_archivo: String = "✔" if MisionFinal.intel_enviada_m4 else " "
			return (
				"[b][color=#ffcc44]CUADERNO DE CASO — F4: CONTENER EMBESTIDA[/color][/b]\n\n"
				+ "[color=#55ff55]Contexto:[/color] Santi desplego un ataque de denegacion de\n"
				+ "servicio. Hay que medir la capacidad del cortafuegos.\n\n"
				+ "[color=#aaddff]Plan:[/color]\n"
				+ "[" + chk_archivo + "] Revisar el ARCHIVO (especificaciones del servidor).\n"
				+ "[ ] Enviar la capacidad de red al Informatico.\n"
				+ "[ ] El Informatico calibrara los filtros."
			)
		_:
			return "[b][color=#ffcc44]CUADERNO DE CASO[/color][/b]\n\nEsperando instrucciones..."
func _on_resultado_informatico(result_text: String) -> void:
	if not is_instance_valid(panel_resultados): return
	lbl_resultado.text = result_text
	panel_resultados.visible = true
	await get_tree().create_timer(9.0).timeout
	if is_instance_valid(panel_resultados):
		panel_resultados.visible = false
