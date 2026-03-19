Extension { #name : 'Collection' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Collection >> gbxDebugPrintOn: aStream [
	| tooMany maxPrint |
	self class isBits ifTrue: [ ^ self printOn: aStream ].
	maxPrint := (self respondsTo: #maxPrint)
		ifTrue: [ self maxPrint ]
		ifFalse: [ 100 ].
	tooMany := aStream position + maxPrint.
	aStream
		print: self class;
		nextPutAll: ' ('.
	self do: [ :element |
		aStream position > tooMany ifTrue: [
			aStream nextPutAll: '...etc...)'.
			^ self ].
		GbxReflection debugPrint: element on: aStream ]
		separatedBy: [ aStream space ].
	aStream nextPut: $)
]
