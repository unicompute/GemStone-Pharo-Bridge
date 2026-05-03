Class {
	#name : 'GbsThreadStateSessionStateSlot',
	#superclass : 'GbsSessionStateSlot',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'testing' }
GbsThreadStateSessionStateSlot >> isThreadStateSlot [
	^ true
]

{ #category : 'querying' }
GbsThreadStateSessionStateSlot >> slotKind [
	^ #threadState
]
