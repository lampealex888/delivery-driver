extends GridMap

@onready var straight_lanes = preload("res://stages/road-kit/roads/road_straight/road_straight.tscn")
@onready var intersection_lanes = preload("res://stages/road-kit/roads/road_intersection/road_intersection.tscn")
@onready var crossroad_lanes = preload("res://stages/road-kit/roads/road_crossroad/road_crossroad.tscn")
@onready var bend_sidewalk_lanes = preload("res://stages/road-kit/roads/road_bend_sidewalk/road_bend_sidewalk.tscn")

const STRAIGHT = 7
const INTERSECTION = 6
const CROSSROAD = 3
const BEND_SIDEWALK = 1

const NORTH = 10
const EAST = 16
const SOUTH = 0
const WEST = 22

func _ready() -> void:
	for cell in get_used_cells():
		if get_cell_item(Vector3i(cell.x, cell.y, cell.z)) == STRAIGHT:
			add_traffic_nodes(cell, straight_lanes)
		if get_cell_item(Vector3i(cell.x, cell.y, cell.z)) == INTERSECTION:
			add_traffic_nodes(cell, intersection_lanes)
		if get_cell_item(Vector3i(cell.x, cell.y, cell.z)) == CROSSROAD:
			add_traffic_nodes(cell, crossroad_lanes)
		if get_cell_item(Vector3i(cell.x, cell.y, cell.z)) == BEND_SIDEWALK:
			add_traffic_nodes(cell, bend_sidewalk_lanes)

func add_traffic_nodes(cell, traffic_node):
	var traffic_node_instance = traffic_node.instantiate()
	traffic_node_instance.position = map_to_local(Vector3i(cell.x, cell.y, cell.z))
	if get_cell_item_orientation(Vector3i(cell.x, cell.y, cell.z)) == NORTH:
		traffic_node_instance.rotation_degrees.y += 180
	if get_cell_item_orientation(Vector3i(cell.x, cell.y, cell.z)) == EAST:
		traffic_node_instance.rotation_degrees.y += 90
	if get_cell_item_orientation(Vector3i(cell.x, cell.y, cell.z)) == SOUTH:
		traffic_node_instance.rotation_degrees.y += 0
	if get_cell_item_orientation(Vector3i(cell.x, cell.y, cell.z)) == WEST:
		traffic_node_instance.rotation_degrees.y += 270
	add_child(traffic_node_instance)
