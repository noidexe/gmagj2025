extends Resource
class_name Checkpoint

@export_node_path("Beacon") var beacons : Array[NodePath] = []
@export_node_path("Marker3D") var spawn_point : NodePath
@export_node_path("Marker3D") var despawn_point : NodePath

func validate( parent_node : Node3D):
	assert(parent_node.get_node_or_null(spawn_point) is Node3D)
	assert(parent_node.get_node_or_null(despawn_point) is Node3D)
	for beacon in beacons:
		assert(parent_node.get_node_or_null(beacon) is Beacon)
