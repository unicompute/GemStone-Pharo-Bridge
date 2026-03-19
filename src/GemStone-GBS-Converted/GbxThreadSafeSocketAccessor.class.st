Class {
	#name : 'GbxThreadSafeSocketAccessor',
	#superclass : 'Object',
	#instVars : [
		'sequencer',
		'handle'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxThreadSafeSocketAccessor class >> openOn: aHandle sequencer: aSequencer
[
	| inst |
	inst := self new.
	inst handle: aHandle.
	inst sequencer: aSequencer.
	^inst
]

{ #category : 'accessing' }
GbxThreadSafeSocketAccessor >> release
[
	handle := nil.
	sequencer := nil
]

{ #category : 'accessing' }
GbxThreadSafeSocketAccessor >> sequencer: anObject
[
	sequencer := anObject
]

{ #category : 'accessing' }
GbxThreadSafeSocketAccessor >> sequencer
[
	^sequencer
]

{ #category : 'accessing' }
GbxThreadSafeSocketAccessor >> handle
[
	^handle
]

{ #category : 'accessing' }
GbxThreadSafeSocketAccessor >> handle: anObject
[
	handle := anObject
]

{ #category : 'waiting' }
GbxThreadSafeSocketAccessor >> readWaitWithTimeoutMs: delay
[
	^sequencer primInterface gciPollSocket: handle forRead: delay
]
