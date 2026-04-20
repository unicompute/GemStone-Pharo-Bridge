Class {
	#name : 'GbsCacheSessionStateSlot',
	#superclass : 'GbsSessionStateSlot',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
GbsCacheSessionStateSlot >> isCacheSlot [
	^ true
]

{ #category : 'querying' }
GbsCacheSessionStateSlot >> slotKind [
	^ #cache
]
