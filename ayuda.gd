extends Button

@export var algorithm_explanation: String = "Explicación del algoritmo..."
@export var how_to_play: String = "Instrucciones de juego..."

var panel: Panel
var label: RichTextLabel

func _ready() -> void:
	# Crear el panel de ayuda dinámicamente
	panel = Panel.new()
	panel.set_anchors_preset(PRESET_CENTER)
	panel.custom_minimum_size = Vector2(400, 300)
	panel.visible = false
	
	label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.set_anchors_preset(PRESET_FULL_RECT)
	label.text = "[center][b]MANUAL DEL DETECTIVE[/b][/center]\n\n" + "[color=#aaddff]Explicacion:[/color]\n" + algorithm_explanation + "\n\n[color=#aaddff]Como investigar:[/color]\n" + how_to_play
	
	var close_btn = Button.new()
	close_btn.text = "Cerrar"
	close_btn.position = Vector2(150, 260)
	close_btn.pressed.connect(func(): panel.visible = false)
	
	panel.add_child(label)
	panel.add_child(close_btn)
	get_parent().add_child.call_deferred(panel)
	
	self.pressed.connect(_on_help_pressed)

func _on_help_pressed() -> void:
	panel.visible = not panel.visible
