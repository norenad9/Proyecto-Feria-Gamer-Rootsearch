extends Control
@onready var btn_jugar: TextureButton = get_node_or_null("VBoxContainer/btnJugar")
@onready var btn_salir: TextureButton = get_node_or_null("VBoxContainer/btnSalir")
@onready var bg_fondo: TextureRect = get_node_or_null("TextureRect")
@onready var vbox: VBoxContainer = get_node_or_null("VBoxContainer")
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if is_instance_valid(bg_fondo):
		bg_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_fondo.stretch_mode = TextureRect.STRETCH_SCALE
	if is_instance_valid(vbox):
		vbox.set_anchors_preset(Control.PRESET_CENTER)
		vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
		vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	if is_instance_valid(btn_jugar):
		btn_jugar.pressed.connect(_on_jugar_pressed)
	if is_instance_valid(btn_salir):
		btn_salir.pressed.connect(_on_salir_pressed)
func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
func _on_salir_pressed() -> void:
	get_tree().quit()
