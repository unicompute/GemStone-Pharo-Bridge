Extension { #name : 'ByteArray' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
ByteArray >> gbxAsServerBytes [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
ByteArray >> indexableValueAt: index put: aValue [
	^ self basicAt: index put: aValue
]
