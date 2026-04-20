Extension { #name : 'GbsRemoteConstantMirror' }

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteConstantMirror >> autoloadFile [
	^ self metadata at: 4 ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteConstantMirror >> isAutoload [
	^ self autoloadFile notNil
]

{ #category : '*GemStone-GBS-MagLev' }
GbsRemoteConstantMirror >> printOn: aStream [
	super printOn: aStream.
	self name ifNotNil: [
		aStream
			nextPutAll: '(';
			nextPutAll: self name asString.
		self valueClassName ifNotNil: [
			aStream
				nextPutAll: ' : ';
				nextPutAll: self valueClassName asString ].
		self isAutoload ifTrue: [
			aStream
				nextPutAll: ' autoload ';
				nextPutAll: self autoloadFile asString ].
		aStream nextPut: $) ]
]
