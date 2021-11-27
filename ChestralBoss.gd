#Bird art from: https://opengameart.org/content/colorful-bird-flying-animation
extends Node2D

export (int) var misalignment = 10000
export (int) var base_dissonance = 20
export (int) var interference = 0
export (int) var base_interference = 30

# Called when the node enters the scene tree for the first time.
func _ready():
    $ProgressBar.max_value = misalignment
    $ProgressBar.value = misalignment
    talk("SCRAWWKKKK")
    
func realign(align_value):
    interference = interference - align_value
    var damage_done = 0
    if interference < 0:
        misalignment = misalignment + interference
        damage_done = interference
        interference = 0
    $AnimationPlayer2.play("Alignment")
    if misalignment <= 0:
        get_parent().state = get_parent().ENDED_WIN
        $Tween.interpolate_property(self, "position", position, Vector2(2400, -400), 5, Tween.TRANS_CIRC, Tween.EASE_IN)
        $Tween.start()
        scale.x = 1
    return damage_done

func _process(delta):
    $ProgressBar.value = misalignment
    if get_parent().state == 1:    
        position = lerp(position, get_position(), 0.02)
        $Sprite.animation == "Flap"
    elif get_parent().state == 0:
        $Sprite.animation == "Idle"

func get_position():
    var radius = 240
    var center = Vector2(800, 500)
    var angle = TAU * ($CircleTimer.time_left/$CircleTimer.wait_time)
    var new_position = center + radius * Vector2(cos(angle), sin(angle)*0.65)
    if sin(angle) < 0:
        $Sprite.scale.x = 1
        $Speech.scale.x = -0.2
        $Speech.position.x = -136
    else:
        $Sprite.scale.x = -1
        $Speech.scale.x = 0.2
        $Speech.position.x = 136
    $Speech/Bubble/Words.rect_scale.x = -$Sprite.scale.x
    return new_position


func _on_Timer_timeout():
    pass
#    if $Sprite.animation == "Idle":
#        $Sprite.animation = "Flap"
#    else:
#        $Sprite.animation = "Idle"

func talk(words: String):
    $Speech/Bubble/Words.text = words
    $AnimationPlayer.play("Speech")
