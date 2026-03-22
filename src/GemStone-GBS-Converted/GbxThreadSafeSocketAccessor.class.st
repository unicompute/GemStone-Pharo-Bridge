Class {
	#name : 'GbxThreadSafeSocketAccessor',
	#superclass : 'Object',
	#instVars : [
		'sequencer',
		'handle',
		'worker'
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
	inst worker: (TFWorker named: 'GBS Signal Socket ' , aHandle asString).
	^inst
]

{ #category : 'accessing' }
GbxThreadSafeSocketAccessor >> release
[
	worker ifNotNil: [worker release].
	worker := nil.
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

{ #category : 'accessing' }
GbxThreadSafeSocketAccessor >> worker
[
	^worker
]

{ #category : 'accessing' }
GbxThreadSafeSocketAccessor >> worker: anObject
[
	worker := anObject
]

{ #category : 'waiting' }
GbxThreadSafeSocketAccessor >> readWaitWithTimeoutMs: delay
[
	^TFProcessLocalWorker
		use: worker
		during: [sequencer primInterface gciPollSocket: handle forRead: delay]
]
