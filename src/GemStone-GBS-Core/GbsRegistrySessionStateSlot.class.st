Class {
	#name : 'GbsRegistrySessionStateSlot',
	#superclass : 'GbsSessionStateSlot',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'testing' }
GbsRegistrySessionStateSlot >> isRegistrySlot [
	^ true
]

{ #category : 'querying' }
GbsRegistrySessionStateSlot >> slotKind [
	^ #registry
]
