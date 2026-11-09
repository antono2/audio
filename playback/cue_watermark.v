module playback

// At-most-once presentation attempts for one caller-owned, ordered event stream.
// Construct one watermark per stable source identity; restore from an authority's
// committed sequence to avoid replaying historical cues. No audio device or
// gameplay authority is owned here. Accepted failures are not retried implicitly.
pub struct CueWatermark {
mut:
	sequence u64
}

pub fn cue_watermark(committed_sequence u64) CueWatermark {
	return CueWatermark{ sequence: committed_sequence }
}

pub fn (gate CueWatermark) last_sequence() u64 {
	return gate.sequence
}

pub fn (mut gate CueWatermark) accept(sequence u64) !bool {
	if sequence == 0 {
		return error('cue sequence must be nonzero')
	}
	if sequence <= gate.sequence {
		return false
	}
	gate.sequence = sequence
	return true
}
