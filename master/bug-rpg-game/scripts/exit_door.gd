extends Node2D

# 次の層へ進む白い扉。最初は隠れていて、appear() で現れる。
# 近づくと「E: 入る」と表示され、E を押すと entered を出す

signal entered

const APPEAR_TIME := 0.5

@onready var _area = $InteractArea  # interact_area.gd


func _ready() -> void:
	visible = false
	# 隠れている間は調べられないようにする（当たり判定ごと外す）
	_area.process_mode = Node.PROCESS_MODE_DISABLED
	_area.interacted.connect(entered.emit)


func appear() -> void:
	visible = true
	modulate.a = 0.0
	_area.process_mode = Node.PROCESS_MODE_INHERIT
	create_tween().tween_property(self, "modulate:a", 1.0, APPEAR_TIME)
