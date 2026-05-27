class_name ChatOverlay
extends CanvasLayer
var panel_chat: Panel
var log_chat: RichTextLabel
var txt_input: LineEdit
var btn_toggle: Button
var lbl_role: Label
var is_open: bool = false
var unread: bool = false
const CHAT_W := 360
const CHAT_H := 280
func _ready() -> void:
	layer = 20
	if not NetworkManager.is_multiplayer_active():
		return
	_build_toggle_button()
	_build_chat_panel()
	_build_role_indicator()
	NetworkManager.chat_received.connect(_on_chat_received)
	NetworkManager.algorithm_result_received.connect(_on_algorithm_result)
	NetworkManager.pistas_synced.connect(_on_pistas_synced)
	NetworkManager.partner_left.connect(_on_partner_left)
func _build_toggle_button() -> void:
	btn_toggle = Button.new()
	btn_toggle.text = "💬"
	btn_toggle.tooltip_text = "Abrir / cerrar canal seguro"
	btn_toggle.position = Vector2(14, 620)
	btn_toggle.size = Vector2(54, 44)
	btn_toggle.pressed.connect(_toggle_chat)
	add_child(btn_toggle)
func _build_role_indicator() -> void:
	lbl_role = Label.new()
	lbl_role.position = Vector2(74, 630)
	var role_name := "🕵️ Detective" if NetworkManager.is_detective() else "💻 Informático"
	lbl_role.text = role_name
	lbl_role.add_theme_font_size_override("font_size", 13)
	var col := Color(0.55, 0.75, 1.0) if NetworkManager.is_detective() else Color(0.4, 1.0, 0.6)
	lbl_role.add_theme_color_override("font_color", col)
	add_child(lbl_role)
func _build_chat_panel() -> void:
	panel_chat = Panel.new()
	panel_chat.position = Vector2(14, 720 - CHAT_H - 80)
	panel_chat.size = Vector2(CHAT_W, CHAT_H)
	panel_chat.visible = false
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.04, 0.08, 0.96)
	st.border_width_left = 2; st.border_width_top = 2
	st.border_width_right = 2; st.border_width_bottom = 2
	st.border_color = Color(0.25, 0.55, 1.0)
	st.corner_radius_top_left = 6; st.corner_radius_top_right = 6
	panel_chat.add_theme_stylebox_override("panel", st)
	add_child(panel_chat)
	var lbl_title := Label.new()
	lbl_title.text = "📡 Canal Forense Seguro"
	lbl_title.position = Vector2(10, 8)
	lbl_title.add_theme_font_size_override("font_size", 13)
	lbl_title.add_theme_color_override("font_color", Color(0.4, 0.75, 1.0))
	panel_chat.add_child(lbl_title)
	var btn_x := Button.new()
	btn_x.text = "✕"
	btn_x.position = Vector2(CHAT_W - 34, 4)
	btn_x.size = Vector2(28, 24)
	btn_x.pressed.connect(func(): _toggle_chat())
	panel_chat.add_child(btn_x)
	log_chat = RichTextLabel.new()
	log_chat.bbcode_enabled = true
	log_chat.position = Vector2(8, 34)
	log_chat.size = Vector2(CHAT_W - 16, CHAT_H - 86)
	log_chat.add_theme_font_size_override("normal_font_size", 13)
	log_chat.add_theme_color_override("default_color", Color(0.85, 0.88, 0.9))
	panel_chat.add_child(log_chat)
	var hbox := HBoxContainer.new()
	hbox.position = Vector2(8, CHAT_H - 48)
	hbox.size = Vector2(CHAT_W - 16, 40)
	panel_chat.add_child(hbox)
	txt_input = LineEdit.new()
	txt_input.placeholder_text = "Escribe y presiona Enter..."
	txt_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt_input.custom_minimum_size = Vector2(270, 36)
	txt_input.add_theme_font_size_override("font_size", 13)
	txt_input.text_submitted.connect(_on_send)
	hbox.add_child(txt_input)
	var btn_send := Button.new()
	btn_send.text = "▶"
	btn_send.custom_minimum_size = Vector2(38, 36)
	btn_send.pressed.connect(func(): _on_send(txt_input.text))
	hbox.add_child(btn_send)
	_append_system("Canal listo. Comunícate con tu compañero.")
func _toggle_chat() -> void:
	is_open = !is_open
	panel_chat.visible = is_open
	if is_open:
		unread = false
		btn_toggle.text = "💬"
func _on_send(text: String) -> void:
	text = text.strip_edges()
	if text.is_empty(): return
	NetworkManager.send_chat(text)
	txt_input.text = ""
	txt_input.grab_focus()
func _on_chat_received(sender: String, text: String) -> void:
	var col := "#55aaff" if sender.contains("Detective") else "#55ff88"
	log_chat.append_text("[color=" + col + "][b]" + sender + ":[/b][/color] " + text + "\n")
	log_chat.scroll_to_line(log_chat.get_line_count())
	_notify_unread()
func _on_algorithm_result(result_text: String) -> void:
	log_chat.append_text("[color=#ffff55][b]📊 ANÁLISIS:[/b] " + result_text + "[/color]\n")
	log_chat.scroll_to_line(log_chat.get_line_count())
	if not is_open:
		_toggle_chat()
func _on_pistas_synced(_pistas: Dictionary) -> void:
	_append_system("🔍 Evidencias sincronizadas.")
	_notify_unread()
func _on_partner_left() -> void:
	_append_system("⚠ Compañero desconectado.")
func _append_system(msg: String) -> void:
	if is_instance_valid(log_chat):
		log_chat.append_text("[color=#777777][i]" + msg + "[/i][/color]\n")
func _notify_unread() -> void:
	if not is_open and is_instance_valid(btn_toggle):
		unread = true
		btn_toggle.text = "💬❗"
