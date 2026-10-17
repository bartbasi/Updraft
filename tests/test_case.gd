# Updraft. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name TestCase
extends RefCounted
## Base class for test suites run by run_tests.gd. Test methods start with "test_".

var tree: SceneTree
var failures := PackedStringArray()
var _nodes: Array[Node] = []


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_between(value: float, low: float, high: float, what: String) -> void:
	check(value >= low and value <= high, "%s = %.3f, expected %.3f .. %.3f" % [what, value, low, high])


## Adds a node to the scene tree for this test; it is freed afterwards.
func add_node(node: Node) -> Node:
	tree.root.add_child(node)
	_nodes.append(node)
	return node


func physics_frames(count: int) -> void:
	for i in count:
		await tree.physics_frame


func cleanup() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.queue_free()
	_nodes.clear()
	await tree.process_frame
