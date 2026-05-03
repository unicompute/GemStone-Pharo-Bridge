Extension { #name : 'GbsProxy' }

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> == anObject [
	"Direct identity check using the Pharo identity primitive"

	<primitive: 110>
	^ (anObject isKindOf: GbsProxy) and: [
		self oop = anObject oop and: [ self session == anObject session ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> class [
	^ super class
]

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> isKindOf: aClass [
	"Shield this from doesNotUnderstand:"
	(aClass respondsTo: #inheritsFrom:) ifFalse: [ ^ false ].
	^ (self class == aClass) or: [ self class inheritsFrom: aClass ]
]

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> isMemberOf: aClass [
	^ self class == aClass
]

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> respondsTo: aSymbol [
	^ self class canUnderstand: aSymbol
]
