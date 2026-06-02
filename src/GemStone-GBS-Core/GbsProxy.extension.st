Extension { #name : 'GbsProxy' }

{ #category : '*GemStone-GBS-Core' }
GbsProxy >> == anObject [
	"Direct identity check using the Pharo identity primitive"

	<primitive: 110>
	((anObject respondsTo: #oop) and: [ anObject respondsTo: #session ])
		ifFalse: [ ^ false ].
	^ [ self oop = anObject oop and: [ self session == anObject session ] ]
		on: Error
		do: [ false ]
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
