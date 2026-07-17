"
Typed GCI error raised by GbsSession>>gbsErrorClassForNumber: for its
GemStone error number, so embedders classify by class/number instead of
parsing messageText (bridge hardening audit 2026-07-17). Carries the full
GbsError protocol (tag, serverProcessOop, exceptionOop, gemStoneErrorNumber).
"
Class {
	#name : 'GbsOffsetError',
	#superclass : 'GbsError',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}
