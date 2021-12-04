extends Sprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func send_attack(pos):
    $Tween.interpolate_property(self, "position", to_local(pos), Vector2.ZERO, 2, Tween.TRANS_LINEAR)
    $Tween.interpolate_property(self, "scale", Vector2(0.6, 0.6), Vector2(1.4, 1.4), 1, Tween.TRANS_SINE, Tween.EASE_IN)
    $Tween.interpolate_property(self, "scale", Vector2(1.4, 1.4), Vector2(0.6, 0.6), 1, Tween.TRANS_SINE, Tween.EASE_OUT, 1)
    $Tween.interpolate_property(self, "modulate", Color.transparent, Color.white, 0.6, Tween.TRANS_EXPO, Tween.EASE_OUT)
    $Tween.interpolate_property(self, "modulate", Color.white, Color.transparent, 1.4, Tween.TRANS_EXPO, Tween.EASE_IN, 0.6)
    $Tween.start()


func _on_Tween_tween_all_completed():
    queue_free()
