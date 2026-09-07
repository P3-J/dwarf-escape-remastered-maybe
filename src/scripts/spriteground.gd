extends Node
class_name GroundImpactSprite

var dec: Texture = preload("res://src/assets/sprites/spriteimpact.png")


func _create_sprite(point: Vector3, normal: Vector3) -> void:
	var decal := Decal.new()
	decal.texture_albedo = dec
	decal.texture_emission = dec
	decal.modulate = Color.hex(790008)
	decal.size = Vector3(1, 1, 1)

	get_tree().current_scene.add_child(decal)

	decal.global_position = point
	if !Vector3.UP.is_equal_approx(normal):
		decal.rotation = normal + (Vector3.UP * 90)


	#decal.global_basis = Basis(x, y, z)
