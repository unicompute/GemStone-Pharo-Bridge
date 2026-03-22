Extension { #name : 'String' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
String class >> gbxHostLineDelimiter [
	^ self with: Character cr
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
String class >> hostLineDelimiter [
	^ self gbxHostLineDelimiter
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
String class >> newFromGSObjectReport: report [
	^ self new: report idxSize
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
String >> asGSPattern [
	| pattern stream aString |
	pattern := OrderedCollection new.
	self isEmpty ifTrue: [ ^ pattern ].
	stream := WriteStream on: (String new: 100).
	self do: [ :each |
		('*?' includes: each)
			ifTrue: [
				aString := stream contents.
				aString isEmpty ifFalse: [ pattern addLast: aString ].
				stream reset.
				pattern addLast: each ]
			ifFalse: [ stream nextPut: each ] ].
	aString := stream contents.
	aString isEmpty ifFalse: [ pattern addLast: aString ].
	^ pattern asArray
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
String >> faultPolicy [
	^ #immediate
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
String >> gbxAsArrayOfLines [
	^ self lines
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
String >> gbxAsServerBytes [
	^ self asByteArray
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
String >> gbxAsCString [
	^ ExternalAddress fromString: self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
String >> gbxCanBeArgForUnsynchronizedOperationInSession: session [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
String >> gbxCopyWrappedTo: rightMargin [
	^ self gbxCopyWrappedTo: rightMargin indent: 0
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
String >> gbxCopyWrappedTo: rightMargin indent: indent [
	| result column character cr lf |
	self size < rightMargin ifTrue: [ ^ self ].
	cr := Character cr.
	lf := Character lf.
	result := WriteStream on: (String new: (self size + ((self size // (rightMargin max: 1)) max: 1))).
	column := 0.
	1 to: self size do: [ :index |
		(column = 1 and: [ index > rightMargin ]) ifTrue: [
			indent timesRepeat: [ result nextPut: Character space ] ].
		character := self at: index.
		result nextPut: character.
		(character = cr or: [ character = lf ])
			ifTrue: [ column := 1 ]
			ifFalse: [ column := column + 1 ].
		(column > rightMargin and: [ character isSeparator ]) ifTrue: [
			(character = cr or: [ character = lf ])
				ifFalse: [ result nextPut: lf ].
			column := 1 ] ].
	^ result contents
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
String >> gbxConvertToHostLineDelimiter [
	| cr lf rs ws char newline |
	cr := Character cr.
	lf := Character lf.
	newline := String gbxHostLineDelimiter.
	rs := ReadStream on: self.
	ws := WriteStream on: (String new: self size).
	[ rs atEnd ] whileFalse: [
		char := rs next.
		char = cr ifTrue: [ rs atEnd ifFalse: [ rs peek = lf ifTrue: [ rs next ] ] ].
		(char = lf or: [ char = cr ])
			ifTrue: [ ws nextPutAll: newline ]
			ifFalse: [ char asciiValue > 0 ifTrue: [ ws nextPut: char ] ] ].
	^ ws contents
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
String >> gbxIsSameSequenceAs: otherCollection [
	| size |
	size := self size.
	size = otherCollection size ifFalse: [ ^ false ].
	1 to: size do: [ :index |
		(self at: index) = (otherCollection at: index) ifFalse: [ ^ false ] ].
	^ true
]
