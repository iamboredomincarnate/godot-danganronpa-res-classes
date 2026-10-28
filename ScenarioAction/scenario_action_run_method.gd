## Calls a method on the host 
extends ScenarioAction
class_name ScenarioActionRunMethod

@export var method_name: String = ""


func _run(host: Node) -> void:
	if method_name != "" and host.has_method(method_name):
		await host.call(method_name)
	elif method_name != "":
		push_warning("[ScenarioAction] RunMethod: host has no method '%s'." % method_name)
