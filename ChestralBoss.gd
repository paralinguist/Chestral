#Bird art from: https://opengameart.org/content/colorful-bird-flying-animation
extends Node2D

export (int) var misalignment = 10000
export (int) var base_dissonance = 20
export (int) var interference = 0
export (int) var base_interference = 30

var telegraphed = false
var tele_target = null
var tele_irritation = 200

var targetting: bool = false

const NOTE = preload("res://Note.tscn")

var bard_scale = 1.0
# Called when the node enters the scene tree for the first time.
func _ready():
    randomize()
    $ProgressBar.max_value = misalignment
    $ProgressBar.value = misalignment
    talk("SCRAWWKKKK")
    
func realign(align_value):
    interference = interference - align_value
    var damage_done = 0
    if interference < 0:
        misalignment = misalignment + interference * bard_scale
        damage_done = interference * bard_scale
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
    if get_parent().state == 1 or get_parent().state == 2:    
        #change this to scale required damage
        bard_scale = 1.0
        if not targetting:
            position = lerp(position, get_position(), 0.02)
        $Sprite.animation == "Flap"
    elif get_parent().state == 0:
        $Sprite.animation == "Idle"
    if interference > 0:
        $Sprite/ShieldSprite.visible = true
        $Sprite/ShieldSprite.modulate = Color(1,1,1,float(interference)/150.0)
    else:
        $Sprite/ShieldSprite.visible = false

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


#Really inefficient but idc
func get_angle_position(angl):
    var radius = 240
    var center = Vector2(800, 500)
    var new_position = center + radius * Vector2(cos(angl), sin(angl)*0.65)
    return new_position

func talk(words: String):
    $Speech/Bubble/Words.text = words
    $AnimationPlayer.play("Speech")

func _on_InterferenceTimer_timeout():
    interference = 0
    print('clearing boss int')


#These timers should really belong to the boss OR should be informed by code from the boss
func _on_AttackTimer_timeout():
    if get_parent().state == get_parent().IN_PROGRESS:
        var players = get_parent().players
        var victim = get_parent().clients[players[randi() % players.size()]]
        if get_parent().dead_players.has(victim):
            _on_AttackTimer_timeout()
            return
        if not $Buffer.is_stopped():
            yield($Buffer, "timeout")
        move_to_position(get_angle_position(victim.saved_angle))
        $Buffer.start()
        yield($Buffer, "timeout")
        var dissonance = get_parent().rng.randi_range(10,50)
        send_attack(victim.global_position)
        talk(victim.playername + ' CAW CAW!')
        $AudioStreamPlayer.play(0.0)
        print('Squarked at ' + victim.playername + ' for: ' + str(victim.irritate(dissonance))) 
        $AttackTimer.start()

#Badly named, but itll do
func _on_ShieldTimer_timeout():
    if get_parent().state == get_parent().IN_PROGRESS:
        interference += get_parent().rng.randi_range(30,100)
        print('providing intereference...' + str(interference))
        $InterferenceTimer.start()


func _on_TelegraphedTimer_timeout():
    var players = get_parent().players
    if tele_target != null and get_parent().dead_players.has(tele_target):
        telegraphed = false
    if get_parent().state != get_parent().IN_PROGRESS:
        return
    if telegraphed and tele_target != null and tele_target.is_inside_tree():
        if not $Buffer.is_stopped():
            yield($Buffer, "timeout")
        move_to_position(get_angle_position(tele_target.saved_angle))
        $Buffer.start()
        yield($Buffer, "timeout")
        telegraphed = false
        $AudioStreamPlayer.play(0.0)
        tele_target.irritate(tele_irritation)
        $TelegraphedTimer.wait_time = 26
        $TelegraphedTimer.start()
    else:
        if not $Buffer.is_stopped():
            yield($Buffer, "timeout")
        tele_target = get_parent().clients[players[randi() % players.size()]]
        if get_parent().dead_players.has(tele_target):
            _on_TelegraphedTimer_timeout()
            return
        talk(tele_target.playername + " YOU'RE NEXT!")
        $TelegraphedTimer.wait_time = 4
        $TelegraphedTimer.start()
        telegraphed = true

func start_attack_cycle():
    $AttackTimer.start()
    $ShieldTimer.start()
    $TelegraphedTimer.start()


func move_to_position(pos: Vector2):
    $Tween.interpolate_property(self, "position", position, pos, 3.5, Tween.TRANS_QUAD, Tween.EASE_OUT)
    $Tween.start()
    targetting = true

func _on_Tween_tween_all_completed():
    if get_parent().state == get_parent().IN_PROGRESS:
        targetting = false


func send_attack(pos):
    $Note/Tween.interpolate_property($Note, "global_position", $Sprite/Beak.global_position, pos, 2, Tween.TRANS_LINEAR)
    $Note/Tween.interpolate_property($Note, "scale", Vector2(0.6, 0.6), Vector2(1.4, 1.4), 1, Tween.TRANS_SINE, Tween.EASE_IN)
    $Note/Tween.interpolate_property($Note, "scale", Vector2(1.4, 1.4), Vector2(0.6, 0.6), 1, Tween.TRANS_SINE, Tween.EASE_OUT, 1)
    $Note/Tween.interpolate_property($Note, "modulate", Color.transparent, Color.white, 0.6, Tween.TRANS_EXPO, Tween.EASE_OUT)
    $Note/Tween.interpolate_property($Note, "modulate", Color.white, Color.transparent, 1.4, Tween.TRANS_EXPO, Tween.EASE_IN, 0.6)
    $Note/Tween.start()

func get_attacked(pos):
    var new_note = NOTE.instance()
    add_child(new_note)
    new_note.send_attack(pos)
