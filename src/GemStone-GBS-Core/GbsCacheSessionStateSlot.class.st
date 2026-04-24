Class {
	#name : 'GbsCacheSessionStateSlot',
	#superclass : 'GbsSessionStateSlot',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'testing' }
GbsCacheSessionStateSlot >> isCacheSlot [
	^ true
]

{ #category : 'querying' }
GbsCacheSessionStateSlot >> slotKind [
	^ #cache
]
