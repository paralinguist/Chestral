extends Sprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    $Bubble.position = Vector2.ZERO
    $Bubble.rotation = -rotation * scale.x/abs(scale.x)
    $Bubble.global_position.y += sin(rotation)*397*global_scale.y*sqrt(2)
    $Bubble/Words.rect_scale.x = scale.x/abs(scale.x) * 0.8
    position.x = 47 * scale.x
