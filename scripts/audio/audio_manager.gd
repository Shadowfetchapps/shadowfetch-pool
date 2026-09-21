extends Node

var _players: Dictionary = {}


func _ready() -> void:
	for key in ["ui", "cue", "hit", "pocket", "foul", "win", "lose"]:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players[key] = p
	_players["ui"].stream = _tone(820, 0.04, 0.14)
	_players["cue"].stream = _tone(180, 0.09, 0.28)
	_players["hit"].stream = _tone(320, 0.07, 0.24)
	_players["pocket"].stream = _tone(140, 0.16, 0.22)
	_players["foul"].stream = _tone(110, 0.2, 0.2)
	_players["win"].stream = _chord([523, 659], 0.45)
	_players["lose"].stream = _tone(150, 0.3, 0.2)
	var music := AudioStreamPlayer.new()
	music.bus = "Music"
	music.stream = _pad()
	add_child(music)
	SettingsStore.settings_changed.connect(func(): SettingsStore.apply_audio())
	SettingsStore.apply_audio()
	if SettingsStore.music_volume > 0.02:
		music.play()


func play(kind: String) -> void:
	if SettingsStore.sfx_volume <= 0.001:
		return
	if _players.has(kind):
		_players[kind].play()


func _tone(freq: float, seconds: float, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var env := exp(-t * 8.0) * (1.0 - t / seconds)
		var s := clampi(int(sin(t * TAU * freq) * 32767.0 * vol * env), -32767, 32767)
		data[i * 2] = s & 255
		data[i * 2 + 1] = (s >> 8) & 255
	return _wav(data, rate)


func _chord(freqs: Array, seconds: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var sample := 0.0
		for f in freqs:
			sample += sin(t * TAU * float(f))
		sample /= float(freqs.size())
		var env := exp(-t * 3.5)
		var s := clampi(int(sample * 20000.0 * env), -32767, 32767)
		data[i * 2] = s & 255
		data[i * 2 + 1] = (s >> 8) & 255
	return _wav(data, rate)


func _pad() -> AudioStreamWAV:
	var rate := 22050
	var n := rate * 8
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var sample := 0.08 * sin(t * TAU * 55.0) + 0.05 * sin(t * TAU * 82.0)
		var s := clampi(int(sample * 32767.0), -32767, 32767)
		data[i * 2] = s & 255
		data[i * 2 + 1] = (s >> 8) & 255
	var w := _wav(data, rate)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w


func _wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = false
	s.data = data
	return s
