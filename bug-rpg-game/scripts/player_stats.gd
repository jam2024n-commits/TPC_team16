extends Node

var max_hp := 30
var hp := 30
var attack := 6
var defense := 2


func reset() -> void:
	hp = max_hp


func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)


func is_dead() -> bool:
	return hp <= 0
