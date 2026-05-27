extends Control
var lbl_status: Label
var txt_ip: LineEdit
var btn_host: Button
var btn_join: Button
func _ready() -> void:
	_build_ui()
	NetworkManager.partner_joined.connect(_on_partner_joined)
	NetworkManager.connection_failed.connect(_on_connection_failed)
func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists("res://images/fondo_menu.png"):
		bg.texture = load("res://images/fondo_menu.png")
	add_child(bg)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.45)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var barra := ColorRect.new()
	barra.color = Color(0.9, 0.72, 0.15, 0.15)
	barra.position = Vector2(0, 0); barra.size = Vector2(1280, 4)
	add_child(barra)
	var lbl_logo := Label.new()
	lbl_logo.text = "ROOTSEARCH"
	lbl_logo.position = Vector2(64, 36)
	lbl_logo.add_theme_font_size_override("font_size", 14)
	lbl_logo.add_theme_color_override("font_color", Color(0.4, 0.6, 0.4))
	add_child(lbl_logo)
	var title := Label.new()
	title.text = "CASO: HILO ROJO"
	title.position = Vector2(340, 60)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.2))
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Sistema de Cooperacion Forense  —  2 Jugadores"
	subtitle.position = Vector2(330, 112)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	add_child(subtitle)
	var sep := ColorRect.new()
	sep.color = Color(0.8, 0.52, 0.18)
	sep.position = Vector2(320, 150); sep.size = Vector2(640, 2)
	add_child(sep)
	var panel_roles := Panel.new()
	panel_roles.position = Vector2(320, 170)
	panel_roles.size = Vector2(640, 70)
	var st_roles := StyleBoxFlat.new()
	st_roles.bg_color = Color(0.04, 0.05, 0.08, 0.8)
	st_roles.border_width_left = 1; st_roles.border_width_top = 1
	st_roles.border_width_right = 1; st_roles.border_width_bottom = 1
	st_roles.border_color = Color(0.3, 0.3, 0.4)
	st_roles.corner_radius_top_left = 4; st_roles.corner_radius_top_right = 4
	st_roles.corner_radius_bottom_left = 4; st_roles.corner_radius_bottom_right = 4
	panel_roles.add_theme_stylebox_override("panel", st_roles)
	add_child(panel_roles)
	var roles_lbl := RichTextLabel.new()
	roles_lbl.bbcode_enabled = true
	roles_lbl.position = Vector2(16, 8)
	roles_lbl.size = Vector2(608, 54)
	roles_lbl.add_theme_font_size_override("normal_font_size", 14)
	roles_lbl.text = (
		"[color=#55aaff]HOST = Detective[/color]  —  Interroga sospechosos, revisa el archivo del caso, descubre pistas.\n"
		+ "[color=#55ff88]JOIN = Informatico[/color]  —  Analiza la red, vincula evidencias, ejecuta algoritmos forenses."
	)
	panel_roles.add_child(roles_lbl)
	btn_host = Button.new()
	btn_host.text = "CREAR PARTIDA  (Sere el Detective)"
	btn_host.position = Vector2(320, 264)
	btn_host.size = Vector2(640, 60)
	btn_host.add_theme_font_size_override("font_size", 18)
	var st_btn_h := StyleBoxFlat.new()
	st_btn_h.bg_color = Color(0.08, 0.12, 0.2)
	st_btn_h.border_width_left = 2; st_btn_h.border_width_top = 2
	st_btn_h.border_width_right = 2; st_btn_h.border_width_bottom = 2
	st_btn_h.border_color = Color(0.3, 0.5, 0.8)
	st_btn_h.corner_radius_top_left = 6; st_btn_h.corner_radius_top_right = 6
	st_btn_h.corner_radius_bottom_left = 6; st_btn_h.corner_radius_bottom_right = 6
	btn_host.add_theme_stylebox_override("normal", st_btn_h)
	var st_btn_hh := st_btn_h.duplicate(); st_btn_hh.bg_color = Color(0.12, 0.18, 0.3); st_btn_hh.border_color = Color(0.5, 0.7, 1.0)
	btn_host.add_theme_stylebox_override("hover", st_btn_hh)
	btn_host.pressed.connect(_on_host_pressed)
	add_child(btn_host)
	var lbl_ip := Label.new()
	lbl_ip.text = "IP del Detective (host):"
	lbl_ip.position = Vector2(320, 348)
	lbl_ip.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(lbl_ip)
	txt_ip = LineEdit.new()
	txt_ip.placeholder_text = "192.168.x.x"
	txt_ip.text = "127.0.0.1"
	txt_ip.position = Vector2(320, 374)
	txt_ip.size = Vector2(400, 44)
	txt_ip.add_theme_font_size_override("font_size", 16)
	add_child(txt_ip)
	btn_join = Button.new()
	btn_join.text = "UNIRSE  (Sere el Informatico)"
	btn_join.position = Vector2(320, 432)
	btn_join.size = Vector2(640, 60)
	btn_join.add_theme_font_size_override("font_size", 18)
	var st_btn_j := StyleBoxFlat.new()
	st_btn_j.bg_color = Color(0.08, 0.15, 0.08)
	st_btn_j.border_width_left = 2; st_btn_j.border_width_top = 2
	st_btn_j.border_width_right = 2; st_btn_j.border_width_bottom = 2
	st_btn_j.border_color = Color(0.3, 0.7, 0.3)
	st_btn_j.corner_radius_top_left = 6; st_btn_j.corner_radius_top_right = 6
	st_btn_j.corner_radius_bottom_left = 6; st_btn_j.corner_radius_bottom_right = 6
	btn_join.add_theme_stylebox_override("normal", st_btn_j)
	var st_btn_jh := st_btn_j.duplicate(); st_btn_jh.bg_color = Color(0.12, 0.22, 0.12); st_btn_jh.border_color = Color(0.5, 1.0, 0.5)
	btn_join.add_theme_stylebox_override("hover", st_btn_jh)
	btn_join.pressed.connect(_on_join_pressed)
	add_child(btn_join)
	var sep2 := ColorRect.new()
	sep2.color = Color(0.3, 0.3, 0.3)
	sep2.position = Vector2(320, 516); sep2.size = Vector2(640, 1)
	add_child(sep2)
	var btn_solo := Button.new()
	btn_solo.text = "Jugar en Solitario"
	btn_solo.position = Vector2(320, 530)
	btn_solo.size = Vector2(640, 46)
	btn_solo.add_theme_font_size_override("font_size", 16)
	var st_solo := StyleBoxFlat.new()
	st_solo.bg_color = Color(0.06, 0.06, 0.08)
	st_solo.border_width_left = 1; st_solo.border_width_top = 1
	st_solo.border_width_right = 1; st_solo.border_width_bottom = 1
	st_solo.border_color = Color(0.4, 0.4, 0.5)
	st_solo.corner_radius_top_left = 4; st_solo.corner_radius_top_right = 4
	st_solo.corner_radius_bottom_left = 4; st_solo.corner_radius_bottom_right = 4
	btn_solo.add_theme_stylebox_override("normal", st_solo)
	btn_solo.pressed.connect(_on_solo_pressed)
	add_child(btn_solo)
	var btn_volver := Button.new()
	btn_volver.text = "Volver al Menu Principal"
	btn_volver.position = Vector2(320, 588)
	btn_volver.size = Vector2(640, 36)
	btn_volver.add_theme_font_size_override("font_size", 13)
	btn_volver.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	btn_volver.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn"))
	add_child(btn_volver)
	lbl_status = Label.new()
	lbl_status.position = Vector2(320, 632)
	lbl_status.size = Vector2(640, 60)
	lbl_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_status.add_theme_font_size_override("font_size", 14)
	lbl_status.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	add_child(lbl_status)
func _on_host_pressed() -> void:
	btn_host.disabled = true
	btn_join.disabled = true
	var err := NetworkManager.host_game()
	if err != OK:
		_set_error("No se pudo crear el servidor. Puerto " + str(NetworkManager.PORT) + " puede estar en uso.")
		btn_host.disabled = false
		btn_join.disabled = false
		return
	var local_ip := NetworkManager.get_local_ip()
	lbl_status.text = (
		"⏳ Servidor activo. Esperando al Informático...\n"
		+ "📡 Tu IP para compartir: [b]" + local_ip + "[/b]"
	)
func _on_join_pressed() -> void:
	var ip := txt_ip.text.strip_edges()
	if ip.is_empty():
		_set_error("Escribe la IP del Detective antes de unirte.")
		return
	btn_host.disabled = true
	btn_join.disabled = true
	lbl_status.text = "⏳ Conectando a " + ip + "..."
	lbl_status.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	var err := NetworkManager.join_game(ip)
	if err != OK:
		_set_error("Error al intentar conectar. Verifica la IP.")
		btn_host.disabled = false
		btn_join.disabled = false
func _on_solo_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Habitacion.tscn")
func _on_partner_joined() -> void:
	var rol := "Detective" if NetworkManager.is_detective() else "Informático"
	lbl_status.text = "✅ ¡Conectado! Entrando como " + rol + "..."
	lbl_status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(self) and is_inside_tree():
		if NetworkManager.is_detective():
			get_tree().change_scene_to_file("res://scenes/Habitacion.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/mission_final.tscn")
func _on_connection_failed() -> void:
	_set_error("❌ Conexión fallida. Verifica IP y que el Detective ya haya creado la partida.")
	btn_host.disabled = false
	btn_join.disabled = false
func _set_error(msg: String) -> void:
	lbl_status.text = msg
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
