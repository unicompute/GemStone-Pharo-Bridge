"
Exception raised when a thread-safe GCI call fails. Built from a GbsGciErrSType
out-parameter rather than from a GciErr buffer with hand-computed offsets.
Subclasses GbsError so it carries through the bridge's existing debugger
metadata and UI error handling. Ported in spirit from PharoGemStoneFFI (GciError).
"
Class {
	#name : 'GbsGciTsError',
	#superclass : 'GbsError',
	#instVars : [
		'number',
		'reason'
	],
	#category : 'GemStone-GBS-ThreadSafe',
	#package : 'GemStone-GBS-ThreadSafe'
}

{ #category : 'instance creation' }
GbsGciTsError class >> newForError: aGbsGciErrSType [
	"Build (but do not signal) an exception from a populated error struct. Read
	every field here, while the struct's C memory is still valid."
	^ self new
		number: aGbsGciErrSType number;
		reason: aGbsGciErrSType reason;
		exceptionOop: aGbsGciErrSType context;
		messageText: aGbsGciErrSType message;
		yourself
]

{ #category : 'instance creation' }
GbsGciTsError class >> signalForError: aGbsGciErrSType tracker: aMemoryTracker [
	"Build a coherent exception from the struct, free the tracked C memory, then
	signal. The struct must be read before freeAll, never after."
	| ex |
	ex := self newForError: aGbsGciErrSType.
	aMemoryTracker freeAll.
	^ ex signal: ex messageText
]

{ #category : 'accessing' }
GbsGciTsError >> number [
	^ number
]

{ #category : 'accessing' }
GbsGciTsError >> number: anObject [
	number := anObject
]

{ #category : 'accessing' }
GbsGciTsError >> reason [
	^ reason
]

{ #category : 'accessing' }
GbsGciTsError >> reason: anObject [
	reason := anObject
]
