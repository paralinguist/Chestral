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
var saved_angle = 0.0

var entrance = ['sending my roadie away now', 'tuned up and good to go', 'ready to rock and/or roll',
                "you've probably never heard of me", 'serving up the freshest beats', 'your new favourite band',
                "I'm big in Japan", 'packing the heavy accompaniment!', 'hang on, broke a string', 
                'the hills are alive with the sound of me, baby', "plink plink, let's do this",
                "99 problems but a pitch ain't one", 'this harp goes to eleven', 'be careful in the mosh pit']

#Music vectors created by ddraw - www.freepik.com

# Called when the node enters the scene tree for the first time.
func _ready():
    randomize()
    $Sprite.scale = Vector2(0.5,0.5)

func reposition(new_x,new_y, angle):
    saved_angle = angle
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
func set_interference(inter_value, additive=true, timer=true):
    if additive:
        interference = interference + inter_value
    else:
        interference = inter_value
    if timer:
        $IntTimer.start()
    if interference <= 0:
            interference = 0
            $IntTimer.stop()
            $UI/Interference.value = 0
    $UI/Interference/InterferenceLabel.text = str(interference)

#directly changes harmonics + label bar
func set_harmonics(harmonics_value, additive=true, timer=true):
    if additive:
        harmonics = harmonics + harmonics_value
    else:
        harmonics = harmonics_value
    if timer:
        $HarmonicsTimer.start()
    if harmonics <= 0:
            harmonics = 0
            $HarmonicsTimer.stop()
            $UI/HBox/Harmonics.value = 0
    $UI/HBox/Harmonics/HarmonicsLabel.text = str(harmonics)

#directly changes resonance + label bar
func set_resonance(resonance_value, additive=true, timer=true):
    if additive:
        resonance = resonance + resonance_value
    else:
        resonance = resonance_value
    if timer:
        $ResonanceTimer.start()
    if resonance <= 0:
        resonance = 0
        $ResonanceTimer.stop()
        $UI/HBox/Resonance.value = 0
    $UI/HBox/Resonance/ResonanceLabel.text = str(resonance)

#directly changes soothe + label bar
func set_soothe(soothe_value, additive=true, timer=true, instant=false):
    if instant:
        current_irritation = current_irritation - soothe_value
        if current_irritation < 0:
            current_irritation = 0
    else:
        if additive:
            soothe = soothe + soothe_value        
        else:
            soothe = soothe_value
        if timer:
            $SootheTimer.start()
        if soothe <= 0:
                soothe = 0
                $SootheTimer.stop()
                $UI/Soothe.value = 0
        $UI/Soothe/SootheLabel.text = str(soothe)
    
func train(new_name, instrument, id):
    name = new_name
    playername = new_name
    $UI/Label.text = new_name
    connection_id = id
    image = load("res://Sprites/Instruments/sax.png")
    if instrument == 'Violin':
        max_irritation = 200
        base_align = 10
        image = load("res://Sprites/Instruments/violin.png")  
    $Sprite.texture = image
    talk("This is " + playername + ' - ' + entrance[randi() % entrance.size()])

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

func rename(new_name: String):
    playername = new_name
    $UI/Label.text = new_name
    talk("Hi I am " + playername + " now")
    name = new_name

func send_attack(pos):
    $Note/Tween.interpolate_property($Note, "position", Vector2.ZERO, to_local(pos), 2, Tween.TRANS_LINEAR)
    $Note/Tween.interpolate_property($Note, "scale", Vector2(0.6, 0.6), Vector2(1.4, 1.4), 1, Tween.TRANS_SINE, Tween.EASE_IN)
    $Note/Tween.interpolate_property($Note, "scale", Vector2(1.4, 1.4), Vector2(0.6, 0.6), 1, Tween.TRANS_SINE, Tween.EASE_OUT, 1)
    $Note/Tween.interpolate_property($Note, "modulate", Color.transparent, Color.white, 0.6, Tween.TRANS_EXPO, Tween.EASE_OUT)
    $Note/Tween.interpolate_property($Note, "modulate", Color.white, Color.transparent, 1.4, Tween.TRANS_EXPO, Tween.EASE_IN, 0.6)
    $Note/Tween.start()
