class_name PCForense
extends Node
var ui_layer: CanvasLayer
var win_dms: Panel
var win_logs: Panel
var win_terminal: Panel
func _ready() -> void:
	if NetworkManager.is_multiplayer_active() and NetworkManager.is_detective():
		if is_inside_tree() and get_tree() != null:
			get_tree().change_scene_to_file("res://scenes/Habitacion.tscn")
		else:
			await get_tree().process_frame
			if get_tree() != null:
				get_tree().change_scene_to_file("res://scenes/Habitacion.tscn")
		return
	if NetworkManager.is_multiplayer_active():
		NetworkManager.victory_triggered.connect(func(): 
			if is_inside_tree() and get_tree() != null:
				get_tree().change_scene_to_file("res://scenes/escena_victoria.tscn")
		)
	_construir_escritorio()
	_construir_apps()
	_construir_terminal_narrativa()
func _construir_escritorio() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(bg)
	var taskbar := Panel.new()
	taskbar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	taskbar.offset_bottom = 42
	var st_tb := StyleBoxFlat.new()
	st_tb.bg_color = Color(0.02, 0.03, 0.04, 0.96)
	st_tb.border_width_bottom = 2
	st_tb.border_color = Color(0.15, 0.75, 0.35)
	taskbar.add_theme_stylebox_override("panel", st_tb)
	ui_layer.add_child(taskbar)
	var lbl_os := Label.new()
	lbl_os.text = "SISTEMA INVESTIGATIVO v2.4  //  ANÁLISIS DIGITAL  //  CASO: SABOTAJE UNINORTE"
	lbl_os.position = Vector2(20, 11)
	lbl_os.add_theme_font_size_override("font_size", 14)
	lbl_os.add_theme_color_override("font_color", Color(0.15, 0.85, 0.4))
	taskbar.add_child(lbl_os)
	_make_btn(taskbar, "🚪 Oficina",  Vector2(720, 6),  Vector2(148, 30), func() -> void: get_tree().change_scene_to_file("res://scenes/Habitacion.tscn"))
	_make_btn(taskbar, "🔴 Panel Central",  Vector2(878, 6),  Vector2(148, 30), func() -> void: get_tree().change_scene_to_file("res://scenes/mission_final.tscn"))
func _construir_apps() -> void:
	_make_app_icon("💬\nINTERCEPTOR\nDE MENSAJES",   Vector2(30, 60),  func() -> void: _abrir_ventana(win_dms))
	_make_app_icon("🌐\nRASTREADOR\nDE CONEXIONES",   Vector2(30, 185), func() -> void: _abrir_ventana(win_logs))
	_make_app_icon("📂\nARCHIVO\nDEL CASO",          Vector2(30, 310), func() -> void: _abrir_ventana(win_terminal))
	win_dms = _crear_ventana("💬 INTERCEPTOR V2.0  —  Historial de Mensajería Privada", Vector2(200, 60))
	ui_layer.add_child(win_dms)
	_agregar_evidencia(
		win_dms, Vector2(20, 50),
		"[color=#888888][Ayer 19:45] Rafa:[/color] Oye Camila, pásame las capturas de los mensajes de Alex para dejarlo mal en la comunidad.\n"
		+ "[color=#55aaff][Ayer 19:46] Camila:[/color] Ten, ahí están los archivos, pero no te metas en problemas pesados con él.\n"
		+ "[color=#888888][Ayer 19:47] Rafa:[/color] Descuida, yo sé qué hacer con esto.",
		"chat_01",
		"[MENSAJES] Rafa le pidió información privada a Camila para perjudicar a Alex."
	)
	_agregar_evidencia(
		win_dms, Vector2(20, 195),
		"[color=#ff5555][Hoy 02:15] Dispositivo Desconocido (ID: 4A:2F:11):[/color] Alex, te lo adverti. Tu historial de la universidad es mio.\n"
		+ "[color=#aaaaaa][Hoy 02:16] Alex:[/color] Quien eres? DETEN el borrado de mis archivos!\n"
		+ "[color=#ff5555][Hoy 02:16] Desconocido:[/color] Nunca debiste meterte en mis asuntos.",
		"ataque_final",
		"[ALERTAS] El sospechoso principal borró por completo el historial académico de Alex."
	)
	win_logs = _crear_ventana("🌐 RASTREADOR DE CONEXIONES  —  Historial de Actividad de la Red", Vector2(240, 100))
	ui_layer.add_child(win_logs)
	_agregar_evidencia(
		win_logs, Vector2(20, 50),
		"> 03:00:15  ALERTA DE SEGURIDAD  [CUENTA_YOLANDA]\n"
		+ "> DISPOSITIVO ORIGEN: Teléfono_Personal_Santi\n"
		+ "> ESTADO DE VALIDACIÓN: [color=#55ff55]ACCESO CONCEDIDO.[/color]\n"
		+ "> ACCIÓN: Modificación forzada de la base de datos central.",
		"log_admin",
		"[SEGURIDAD] El dispositivo de Santi vulneró de forma remota la cuenta de Yolanda."
	)
	_agregar_evidencia(
		win_logs, Vector2(20, 195),
		"> REPORTE DE ACTIVIDAD LOCAL  [Equipo_Andres]  03:00 AM – 05:00 AM\n"
		+ "> ESTADO: [color=#ffff55]Conexión masiva a plataformas de videojuegos[/color]\n"
		+ "> ANÁLISIS: Andrés no estaba estudiando con Santi. Su coartada es falsa.",
		"ip_andres",
		"[HISTORIAL] Andrés jugaba en línea a las 3:00 AM mientras Santi ejecutaba el sabotaje."
	)
func _construir_terminal_narrativa() -> void:
	win_terminal = _crear_ventana("📂 ARCHIVO DEL CASO", Vector2(280, 140))
	ui_layer.add_child(win_terminal)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.position = Vector2(20, 46)
	rt.size = Vector2(660, 390)
	rt.text = "[b][color=#ffcc44]INSTRUCCIONES DE COOPERACIÓN[/color][/b]\n\nExtrae las evidencias analizadas aquí para actualizar el Panel Central. Trabaja en equipo compartiendo estos hallazgos con tu Detective en el campus."
	win_terminal.add_child(rt)
func _make_app_icon(label: String, pos: Vector2, cb: Callable) -> void:
	var btn := Button.new(); btn.text = label; btn.position = pos; btn.size = Vector2(130, 100); btn.pressed.connect(cb); ui_layer.add_child(btn)
func _abrir_ventana(win: Panel) -> void:
	for w in [win_dms, win_logs, win_terminal]: if is_instance_valid(w): w.visible = (w == win)
func _crear_ventana(titulo: String, pos: Vector2) -> Panel:
	var win := Panel.new(); win.position = pos; win.size = Vector2(700, 460); win.visible = false
	var st := StyleBoxFlat.new(); st.bg_color = Color(0.05, 0.05, 0.08, 0.98); st.border_width_top = 30; st.border_color = Color(0.25, 0.3, 0.4); win.add_theme_stylebox_override("panel", st)
	var lbl := Label.new(); lbl.text = titulo; lbl.position = Vector2(10, 4); win.add_child(lbl)
	var btn_x := Button.new(); btn_x.text = "✕"; btn_x.position = Vector2(664, 3); btn_x.size = Vector2(30, 24); btn_x.pressed.connect(func() -> void: win.visible = false); win.add_child(btn_x)
	return win
func _agregar_evidencia(ventana: Panel, pos: Vector2, texto_largo: String, id_evidencia: String, texto_resumen: String) -> void:
	var bg := ColorRect.new(); bg.color = Color(0.09, 0.09, 0.14); bg.position = pos; bg.size = Vector2(660, 120); ventana.add_child(bg)
	var rt := RichTextLabel.new(); rt.bbcode_enabled = true; rt.text = texto_largo; rt.position = Vector2(10, 8); rt.size = Vector2(460, 104); bg.add_child(rt)
	var btn_extraer := Button.new(); btn_extraer.size = Vector2(165, 70); btn_extraer.position = Vector2(485, 25)
	if MisionFinal.pistas_descubiertas.has(id_evidencia):
		btn_extraer.text = "✓ TRANSMITIDO"; btn_extraer.disabled = true; btn_extraer.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	else: 
		btn_extraer.text = "📎 REGISTRAR\nEVIDENCIA"
	btn_extraer.pressed.connect(func ():
		MisionFinal.pistas_descubiertas[id_evidencia] = texto_resumen
		btn_extraer.text = "✓ TRANSMITIDO"; btn_extraer.disabled = true; btn_extraer.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		if NetworkManager.is_multiplayer_active():
			NetworkManager.sync_pistas_to_partner()
	)
	bg.add_child(btn_extraer)
func _make_btn(parent: Node, txt: String, pos: Vector2, sz: Vector2, cb: Callable) -> Button:
	var b := Button.new(); b.text = txt; b.position = pos; b.size = sz; b.pressed.connect(cb); parent.add_child(b); return b
