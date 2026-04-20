Class {
	#name : 'GbsRegistrySessionStateSlot',
	#superclass : 'GbsSessionStateSlot',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
GbsRegistrySessionStateSlot >> isRegistrySlot [
	^ true
]

{ #category : 'querying' }
GbsRegistrySessionStateSlot >> slotKind [
	^ #registry
]
