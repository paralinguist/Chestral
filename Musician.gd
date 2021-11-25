extends Node2D

export var playername = 'Muso'
export var instrument = 'Voice'
export var max_irritation = 200
export var current_irritation = 0
export var interference = 0
export var soothe = 0
export var resonance = 0
export var harmonics = 0
export var base_align = 10
export var connection_id = 0
var image

#Music vectors created by ddraw - www.freepik.com

# Called when the node enters the scene tree for the first time.
func _ready():
    $Sprite.scale = Vector2(0.5,0.5)
    $Sprite.position.y -= 80

func reposition(new_x,new_y, angle):
    self.position.x = new_x
    self.position.y = new_y
    if new_y < 300:
        $Speech.rotation = TAU/4
    else:
        $Speech.rotation = 0
#    $Speech.rotation = min(abs(angle), PI-abs(angle))/2
    if angle > TAU/4:
        $Speech.scale.x = -0.2
        $Speech.rotation *= -1
    else:
        $Speech.scale.x = 0.2

#directly changes interference + label bar
func set_interference(inter_value, additive):
    if additive:
        interference = interference + inter_value
        if interference <= 0:
            interference = 0
        else:
            $UI/Interference/InterferenceLabel.visible = true
            $UI/Interference.visible = true
    else:
        interference = inter_value
    $UI/Interference/InterferenceLabel.text = str(interference)

#directly changes harmonics + label bar
func set_harmonics(harmonics_value, additive):
    if additive:
        harmonics = harmonics + harmonics_value
        if harmonics <= 0:
            harmonics = 0
        else:
            $UI/HBox/Harmonics/HarmonicsLabel.visible = true
            $UI/HBox/Harmonics.visible = true
    else:
        harmonics = harmonics_value
    $UI/HBox/Harmonics/HarmonicsLabel.text = str(harmonics)

#directly changes resonance + label bar
func set_resonance(resonance_value, additive):
    if additive:
        resonance = resonance + resonance_value
        if resonance <= 0:
            resonance = 0
        else:
            $UI/HBox/Resonance/ResonanceLabel.visible = true
            $UI/HBox/Resonance.visible = true
    else:
        resonance = resonance_value
    $UI/HBox/Resonance/ResonanceLabel.text = str(resonance)

#Applies interference with a timer
func apply_int(inter_value):
    set_interference(inter_value, true)
    $IntTimer.start()

#Applies harmonics with a timer
func apply_harmonics(harmonics_value):
    set_harmonics(harmonics_value, true)
    $HarmonicsTimer.start()
    
#Applies resonance with a timer
func apply_resonance(resonance_value):
    set_resonance(resonance_value, true)
    $ResonanceTimer.start()

#directly changes soothe + label bar
func set_soothe(soothe_value, additive):
    if additive:
        soothe = soothe + soothe_value
        if soothe <= 0:
            soothe = 0
        else:
            $UI/Soothe/SootheLabel.visible = true
            $UI/Soothe.visible = true
    else:
        soothe = soothe_value
    $UI/Soothe/SootheLabel.text = str(soothe)

#Apply an int of soothe to muso - instant is a bool, is this instant or applied on timer?
func apply_soothe(soothe_value, instant):
    if instant:
        current_irritation = current_irritation - soothe_value
        if current_irritation < 0:
            current_irritation = 0
    else:
        set_soothe(soothe_value, true)
        $SootheTimer.start()
    
func train(name, instrument, id):
    playername = name
    $UI/Label.text = name
    connection_id = id
    image = load("res://Sprites/Instruments/sax.png")
    if instrument == 'Violin':
        max_irritation = 200
        base_align = 10
        image = load("res://Sprites/Instruments/violin.png")  
    $Sprite.texture = image
    talk("Hi I am " + playername + " and I play the " + instrument)

func set_avatar(filename):
    var avatar_file = 'res://Sprites/Orcs/' + filename
    if ResourceLoader.exists(avatar_file):
        image = load(avatar_file)
        $Sprite.texture = image

#TODO: check for death
func _process(delta):
    $UI/HBox/Irritation.value = current_irritation
    $UI/Soothe.value = $SootheTimer.time_left
    $UI/Interference.value = $IntTimer.time_left
    $UI/HBox/Harmonics.value = $HarmonicsTimer.time_left
    $UI/HBox/Resonance.value = $ResonanceTimer.time_left
#    Commented this out so the UI is aligned correctly
#    if soothe <= 0:
#        $UI/Soothe/SootheLabel.visible = false
#        $UI/Soothe.visible = false
#    if interference <= 0:
#        $UI/Interference/InterferenceLabel.visible = false
#        $UI/Interference.visible = false
#    if harmonics <= 0:
#        $UI/HBox/Harmonics/HarmonicsLabel.visible = false
#        $UI/HBox/Harmonics.visible = false
#    if resonance <= 0:
#        $UI/HBox/Resonance/ResonanceLabel.visible = false
#        $UI/HBox/Resonance.visible = false
        
    $UI/HBox/Irritation.value = current_irritation
    #Need to check for "dead" player here and handle

func _on_IntTimer_timeout():
    set_interference(0, false)

func _on_SootheTimer_timeout():
    current_irritation = current_irritation - soothe
    if current_irritation < 0:
        current_irritation = 0
    set_soothe(0, false)

func _on_HarmonicsTimer_timeout():
    set_harmonics(0, false)

func _on_ResonanceTimer_timeout():
    set_resonance(0, false)

#Send image filename too?
func get_state():
    var state = {}
    state['id'] = connection_id
    state['name'] = playername
    state['instrument'] = instrument
    state['max_irritation'] = max_irritation
    state['irritation'] = current_irritation
    state['interference'] = interference
    state['soothe'] = soothe
    state['resonance'] = resonance
    state['harmonics'] = harmonics
    state['interference_time'] = $UI/Interference.value
    state['soothe_time'] = $UI/Soothe.value
    state['resonance_time'] = $UI/HBox/Resonance.value
    state['harmonics_time'] = $UI/HBox/Harmonics.value
    return state

func irritate(dissonance):
    interference = interference - dissonance
    var damage_done = 0
    if interference < 0:
        current_irritation = current_irritation - interference
        damage_done = interference
        interference = 0
        $Sprite.modulate = Color(1,0.5,0.5)
        start_hurt_shake()
        $HurtTimer.start()
    #Should animate over this muso to show they got annoyed
    return damage_done


func _on_HurtTimer_timeout():
    $Sprite.modulate = Color(1,1,1)
    $HurtShake.stop_all()

func start_hurt_shake():
    var shake_distance = Vector2()
    var shake_amplitude = 2
    shake_distance.x = rand_range(-shake_amplitude, shake_amplitude)
    shake_distance.y = rand_range(-shake_amplitude, shake_amplitude)

    $HurtShake.interpolate_property($Sprite, "offset", $Sprite.offset, shake_distance, 0.05, Tween.TRANS_SINE)
    $HurtShake.start()


func _on_HurtShake_tween_completed(object, key):
    start_hurt_shake()


func talk(words: String):
    $Speech/Bubble/Words.text = words
    $AnimationPlayer.play("Speech")
