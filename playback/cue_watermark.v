module playback

// At-most-once presentation attempts for one caller-owned, ordered event stream.
// Construct one watermark per stable source identity; restore from an authority's
// committed sequence to avoid replaying historical cues. No audio device or
// gameplay authority is owned here. Accepted failures are not retried implicitly.
pub struct CueWatermark {
mut:
	sequence u64
}

// cue_watermark restores the last accepted/committed sequence; zero starts a new stream.
pub fn cue_watermark(committed_sequence u64) CueWatermark {
	return CueWatermark{ sequence: committed_sequence }
}

// last_sequence returns the highest admitted sequence, including failed playback attempts.
pub fn (gate CueWatermark) last_sequence() u64 {
	return gate.sequence
}

// accept rejects zero with an error and returns false for duplicate or older sequences.
// A true result advances the watermark immediately, before any caller playback attempt.
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
