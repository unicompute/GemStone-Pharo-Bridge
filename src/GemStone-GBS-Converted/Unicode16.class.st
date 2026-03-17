Class {
	#name : 'Unicode16',
	#superclass : 'TwoByteString',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
Unicode16 >> at: index put: aCharacter
[

	self isImmutable ifTrue:
			[^self noModificationErrorFor: #at:put: index: index value: aCharacter].
	^super at: index put: aCharacter
]

{ #category : 'converting' }
Unicode16 >> asFourByteString
[
	"We don't really convert to a TwoByteString, but 
	rather use the promotion logic in VW, then create
	a Unicode32 string"

	^Unicode32 fromString: self
]

