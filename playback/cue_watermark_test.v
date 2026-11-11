// Checks ordered cue replay suppression, restored sequence state and the u64 boundary.
module playback

fn test_cue_watermark_bounded_replay_restore_and_exhaustion() ! {
	mut gate := cue_watermark(4)
	assert !gate.accept(1)! && !gate.accept(4)!
	assert gate.accept(5)! && !gate.accept(5)!
	assert gate.accept(8)! && !gate.accept(6)!
	assert gate.last_sequence() == 8
	if _ := gate.accept(0) {
		assert false
	}
	assert gate.last_sequence() == 8
	mut restored := cue_watermark(gate.last_sequence())
	assert !restored.accept(8)! && restored.accept(9)!
	assert restored.accept(~u64(0))! && !restored.accept(~u64(0))!
	assert restored.last_sequence() == ~u64(0)
	mut independent := cue_watermark(0)
	assert independent.accept(1)!
}
