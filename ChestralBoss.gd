extends Node2D


export (int) var misalignment = 10000
export (int) var base_dissonance = 20
export (int) var interference = 0
export (int) var base_interference = 30

# Called when the node enters the scene tree for the first time.
func _ready():
    $ProgressBar.max_value = misalignment
    $ProgressBar.value = misalignment
    
func realign(align_value):
    interference = interference - align_value
    var damage_done = 0
    if interference < 0:
        misalignment = misalignment + interference
        damage_done = interference
        interference = 0
    #Should probably play some flappy animation?
    return damage_done

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    $ProgressBar.value = misalignment
