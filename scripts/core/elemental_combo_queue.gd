class_name _ElementalComboQueue
extends Node
## Manages a FIFO queue of elemental statuses for an entity.
## (DON-101) Oldest entries consumed first; durations tick down each turn.

# We store statuses in an Array to maintain FIFO order.
# The task mentions strict typing, so we use Array[ElementalStatus].

static func create_queue() -> Array[ElementalStatus]:
	var q: Array[ElementalStatus] = []
	return q


## Adds a new status to the end of the queue.
static func add_status(queue: Array[ElementalStatus], element: ElementalTypes.Element, duration: int, current_turn: int) -> void:
	if element == ElementalTypes.Element.NONE:
		return
	var new_status: ElementalStatus = ElementalStatus.new(element, duration, current_turn)
	queue.append(new_status)


## Processes a turn tick: decrements durations and removes expired statuses.
## Returns true if any status was removed.
static func tick(queue: Array[ElementalStatus], current_turn: int) -> bool:
	var initial_size: int = queue.size()
	var i: int = 0
	while i < queue.size():
		if queue[i].is_expired(current_turn):
			queue.remove_at(i)
		else:
			i += 1
	return queue.size() < initial_size


## Consumes the oldest status of a specific type from the queue.
## Returns the status if found and removed, otherwise null.
static func consume_oldest(queue: Array[ElementalStatus], element: ElementalTypes.Element) -> ElementalStatus:
	for i: int in range(queue.size()):
		if queue[i].element == element:
			var status: ElementalStatus = queue[i]
			queue.remove_at(i)
			return status
	return null


## Returns the oldest status in the queue without removing it.
static func peek_oldest(queue: Array[ElementalStatus]) -> ElementalStatus:
	if queue.is_empty():
		return null
	return queue[0]


## Returns true if the queue contains a specific element.
static func has_element(queue: Array[ElementalStatus], element: ElementalTypes.Element) -> bool:
	for status: ElementalStatus in queue:
		if status.element == element:
			return true
	return false
