Class {
	#name : 'GbsFinalizerRegistrySessionStateSlot',
	#superclass : 'GbsSessionStateSlot',
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'testing' }
GbsFinalizerRegistrySessionStateSlot >> isFinalizerRegistry [
	^ true
]

{ #category : 'testing' }
GbsFinalizerRegistrySessionStateSlot >> isRegistrySlot [
	^ true
]

{ #category : 'querying' }
GbsFinalizerRegistrySessionStateSlot >> slotKind [
	^ #finalizerRegistry
]
