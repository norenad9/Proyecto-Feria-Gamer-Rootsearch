extends Node
var ui_layer: CanvasLayer
var bg_rect: TextureRect
var sprite_alex: TextureRect
var dialog_box: Panel
var name_label: Label
var dialog_text: RichTextLabel
var btn_continuar: Button
var panel_final: Panel
var lbl_titulo_final: Label
var btn_reiniciar: Button
var btn_salir: Button
enum Fase { AGRADECIMIENTO, MENU_FIN }
var fase_actual: int = Fase.AGRADECIMIENTO
var lista_dialogos: Array[String] = []
var indice_dialogo: int = 0
var is_typing: bool = false
func _ready() -> void:
	_construir_interfaz_base()
	_cargar_guion_clausura()
	_mostrar_siguiente_texto()
	if NetworkManager.is_multiplayer_active():
		NetworkManager.disconnect_game()
func _construir_interfaz_base() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	bg_rect = TextureRect.new()
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists("res://backgrounds/bg_campus.png"):
		bg_rect.texture = load("res://backgrounds/bg_campus.png")
	bg_rect.modulate = Color(0.6, 0.7, 0.6)
	ui_layer.add_child(bg_rect)
	sprite_alex = TextureRect.new()
	sprite_alex.position = Vector2(470, 90)
	sprite_alex.size = Vector2(340, 400)
	sprite_alex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite_alex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists("res://avatars/alex_avatar.png"):
		sprite_alex.texture = load("res://avatars/alex_avatar.png")
	ui_layer.add_child(sprite_alex)
	dialog_box = Panel.new()
	dialog_box.position = Vector2(90, 500)
	dialog_box.size = Vector2(1100, 180)
	var style_db = StyleBoxFlat.new()
	style_db.bg_color = Color(0.04, 0.05, 0.06, 0.96)
	style_db.border_width_top = 4
	style_db.border_color = Color(0.15, 0.75, 0.35)
	style_db.corner_radius_top_left = 6
	style_db.corner_radius_top_right = 6
	dialog_box.add_theme_stylebox_override("panel", style_db)
	ui_layer.add_child(dialog_box)
	name_label = Label.new()
	name_label.text = "ALEX"
	name_label.position = Vector2(25, 12)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	dialog_box.add_child(name_label)
	dialog_text = RichTextLabel.new()
	dialog_text.bbcode_enabled = true
	dialog_text.position = Vector2(25, 48)
	dialog_text.size = Vector2(880, 110)
	dialog_text.add_theme_font_size_override("normal_font_size", 18)
	dialog_box.add_child(dialog_text)
	btn_continuar = Button.new()
	btn_continuar.text = "SIGUIENTE ▶"
	btn_continuar.position = Vector2(930, 110)
	btn_continuar.size = Vector2(145, 45)
	btn_continuar.pressed.connect(_on_btn_continuar_pressed)
	dialog_box.add_child(btn_continuar)
	panel_final = Panel.new()
	panel_final.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_final.visible = false
	var style_pf = StyleBoxFlat.new()
	style_pf.bg_color = Color(0.02, 0.02, 0.03, 1.0)
	panel_final.add_theme_stylebox_override("panel", style_pf)
	ui_layer.add_child(panel_final)
	lbl_titulo_final = Label.new()
	lbl_titulo_final.text = "¡CASO CLAUSURADO CON EXITO!\n\nSISTEMA FORENSE ROOTSEARCH v2.4\nUNIVERSIDAD DEL NORTE"
	lbl_titulo_final.position = Vector2(0, 180)
	lbl_titulo_final.size = Vector2(1280, 120)
	lbl_titulo_final.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo_final.add_theme_font_size_override("font_size", 26)
	lbl_titulo_final.add_theme_color_override("font_color", Color(0.9, 0.75, 0.25))
	panel_final.add_child(lbl_titulo_final)
	btn_reiniciar = Button.new()
	btn_reiniciar.text = "VOLVER A JUGAR"
	btn_reiniciar.position = Vector2(390, 380)
	btn_reiniciar.size = Vector2(220, 50)
	btn_reiniciar.pressed.connect(_on_btn_reiniciar_pressed)
	panel_final.add_child(btn_reiniciar)
	var btn_menu := Button.new()
	btn_menu.text = "VOLVER AL MENU"
	btn_menu.position = Vector2(630, 380)
	btn_menu.size = Vector2(220, 50)
	btn_menu.pressed.connect(_on_btn_menu_pressed)
	panel_final.add_child(btn_menu)
	btn_salir = Button.new()
	btn_salir.text = "SALIR AL ESCRITORIO"
	btn_salir.position = Vector2(490, 460)
	btn_salir.size = Vector2(220, 50)
	btn_salir.pressed.connect(_on_btn_salir_pressed)
	panel_final.add_child(btn_salir)
func _cargar_guion_clausura() -> void:
	lista_dialogos = [
		"Detective... No se como agradecerle. El decano de Ingenieria me llamo hace unos minutos... Mis notas y registros de laboratorio fueron completamente restaurados.",
		"Santi se quebro ante el consejo disciplinario cuando le presentaron el reporte de conexiones y los registros de su telefono. No tuvo escapatoria.",
		"Rafa y Camila recibieron una amonestacion, pero quedo claro quien fue la mente maestra detras de todo este sabotaje.",
		"Gracias a su trabajo en equipo con el Informatico, la red de Ingenieria vuelve a ser un lugar seguro. ¡Resolvimos el caso, detective!"
	]
func _mostrar_siguiente_texto() -> void:
	if indice_dialogo >= lista_dialogos.size():
		_activar_pantalla_final()
		return
	is_typing = true
	dialog_text.text = lista_dialogos[indice_dialogo]
	dialog_text.visible_characters = 0
	for i in range(lista_dialogos[indice_dialogo].length() + 1):
		if not is_typing: break
		dialog_text.visible_characters = i
		await get_tree().create_timer(0.015).timeout
	is_typing = false
	dialog_text.visible_characters = -1
func _on_btn_continuar_pressed() -> void:
	if is_typing:
		is_typing = false
		dialog_text.visible_characters = -1
	else:
		indice_dialogo += 1
		_mostrar_siguiente_texto()
func _activar_pantalla_final() -> void:
	fase_actual = Fase.MENU_FIN
	dialog_box.visible = false
	sprite_alex.visible = false
	panel_final.visible = true
func _limpiar_estado_global() -> void:
	MisionFinal.pistas_descubiertas.clear()
	MisionFinal.memoria_grafo.clear()
	MisionFinal.memoria_verificados.clear()
	MisionFinal.mision_actual = MisionFinal.Misiones.M1_ORIGEN
	MisionFinal.yolanda_delato_a_rafa = false
	MisionFinal.historia_completada = false
	MisionFinal.intel_enviada_m2 = false
	MisionFinal.intel_enviada_m3 = false
	MisionFinal.intel_enviada_m4 = false
func _on_btn_reiniciar_pressed() -> void:
	_limpiar_estado_global()
	get_tree().change_scene_to_file("res://scenes/Habitacion.tscn")
func _on_btn_menu_pressed() -> void:
	_limpiar_estado_global()
	get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn")
func _on_btn_salir_pressed() -> void:
	get_tree().quit()
func _input(event: InputEvent) -> void:
	if fase_actual == Fase.AGRADECIMIENTO and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_typing:
			is_typing = false
			dialog_text.visible_characters = -1
