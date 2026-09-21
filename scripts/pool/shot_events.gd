class_name ShotEvents
extends RefCounted

var first_contact: int = -1
var pocketed: Array[int] = []
var cue_pocketed: bool = false
var rail_after_first_contact: bool = false
var rail_count_on_break: int = 0
var off_table: Array[int] = []
var contacted_any: bool = false


func to_dict() -> Dictionary:
	return {
		"first_contact": first_contact,
		"pocketed": pocketed.duplicate(),
		"cue_pocketed": cue_pocketed,
		"rail_after_first_contact": rail_after_first_contact,
		"rail_count_on_break": rail_count_on_break,
		"off_table": off_table.duplicate(),
		"contacted_any": contacted_any,
	}


static func from_dict(d: Dictionary) -> ShotEvents:
	var e := ShotEvents.new()
	e.first_contact = int(d.get("first_contact", -1))
	for n in d.get("pocketed", []):
		e.pocketed.append(int(n))
	e.cue_pocketed = bool(d.get("cue_pocketed", false))
	e.rail_after_first_contact = bool(d.get("rail_after_first_contact", false))
	e.rail_count_on_break = int(d.get("rail_count_on_break", 0))
	for n in d.get("off_table", []):
		e.off_table.append(int(n))
	e.contacted_any = bool(d.get("contacted_any", e.first_contact >= 0))
	return e
