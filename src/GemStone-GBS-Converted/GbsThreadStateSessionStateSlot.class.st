Class {
	#name : 'GbsThreadStateSessionStateSlot',
	#superclass : 'GbsSessionStateSlot',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
GbsThreadStateSessionStateSlot >> isThreadStateSlot [
	^ true
]

{ #category : 'querying' }
GbsThreadStateSessionStateSlot >> slotKind [
	^ #threadState
]
