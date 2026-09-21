class_name PoolTypes
extends RefCounted

const CUE := 0
const EIGHT := 8

enum Group { OPEN, SOLIDS, STRIPES }
enum Phase { BREAK, OPEN, ASSIGNED, ON_EIGHT, OVER }
enum Mode { EIGHT_BALL, PRACTICE, NINE_BALL }

const SOLIDS: Array[int] = [1, 2, 3, 4, 5, 6, 7]
const STRIPES: Array[int] = [9, 10, 11, 12, 13, 14, 15]
const NINE_BALL_SET: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]


static func is_solid(id: int) -> bool:
	return id >= 1 and id <= 7


static func is_stripe(id: int) -> bool:
	return id >= 9 and id <= 15


static func is_object(id: int) -> bool:
	return id >= 1 and id <= 15


static func group_of(id: int) -> Group:
	if is_solid(id):
		return Group.SOLIDS
	if is_stripe(id):
		return Group.STRIPES
	return Group.OPEN


static func group_balls(g: Group) -> Array[int]:
	if g == Group.SOLIDS:
		return SOLIDS.duplicate()
	if g == Group.STRIPES:
		return STRIPES.duplicate()
	return []


static func group_name(g: Group) -> String:
	match g:
		Group.SOLIDS:
			return "solids"
		Group.STRIPES:
			return "stripes"
		_:
			return "open"


static func opposite(g: Group) -> Group:
	if g == Group.SOLIDS:
		return Group.STRIPES
	if g == Group.STRIPES:
		return Group.SOLIDS
	return Group.OPEN
