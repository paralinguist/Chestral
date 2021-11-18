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
    $Sprite.position.y = $Sprite.position.y + 200

func reposition(new_x,new_y):
    self.position.x = new_x
    self.position.y = new_y

#directly changes interference + label bar
func set_interference(inter_value, additive):
    if additive:
        interference = interference + inter_value
        if interference <= 0:
            interference = 0
        else:
            $InterferenceLabel.visible = true
            $Interference.visible = true
    else:
        interference = inter_value
    $InterferenceLabel.text = str(interference)

#Applies interference with a timer
func apply_int(inter_value):
    set_interference(inter_value, true)
    $IntTimer.start()

#directly changes soothe + label bar
func set_soothe(soothe_value, additive):
    if additive:
        soothe = soothe + soothe_value
        if soothe <= 0:
            soothe = 0
        else:
            $SootheLabel.visible = true
            $Soothe.visible = true
    else:
        soothe = soothe_value
    $SootheLabel.text = str(soothe)

func apply_soothe(soothe_value):
    set_soothe(soothe_value, true)
    
func train(name, instrument, id):
    playername = name
    $Label.text = name
    connection_id = id
    image = load("res://Sprites/Instruments/sax.png")
    if instrument == 'Violin':
        max_irritation = 200
        base_align = 10
        image = load("res://Sprites/Instruments/violin.png")  
    $Sprite.texture = image
    

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    $Interference.value = $IntTimer.time_left
    if soothe <= 0:
        $SootheLabel.visible = false
        $Soothe.visible = false
    if interference <= 0:
        $InterferenceLabel.visible = false
        $Interference.visible = false


func _on_IntTimer_timeout():
    set_interference(0, false)


func _on_SootheTimer_timeout():
    set_soothe(0, false)
    #Need to actually heal here
