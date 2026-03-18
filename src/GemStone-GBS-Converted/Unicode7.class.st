Class {
	#name : 'Unicode7',
	#superclass : 'ByteString',
	#instVars : [
	],
	#classVars : [
		'encoder'
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'converting' }
Unicode7 >> asTwoByteString
[
	"We don't really convert to a TwoByteString, but 
	rather use the promotion logic in VW, then create
	a Unicode16 string"

	^Unicode16 fromString: self
]

{ #category : 'converting' }
Unicode7 >> asFourByteString
[
	"We don't really convert to a TwoByteString, but 
	rather use the promotion logic in VW, then create
	a Unicode16 string"

	^Unicode32 fromString: self
]

{ #category : 'class initialization' }
Unicode7 class >> initialize
[
	"Unicode7 initialize"

	encoder := superclass encoder
]

