Extension { #name : 'Exception' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Exception >> originator
[
	^ self
		propertyAt: #gbsOriginator
		ifAbsent: [ self ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Exception >> originator: anObject
[
	self propertyAt: #gbsOriginator put: anObject.
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Exception >> raiseSignal
[
	^ self signal
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Exception >> raiseSignal: aString
[
	self messageText: aString.
	^ self signal
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Exception class >> accepts: anExceptionCreator
[
	| creator |
	anExceptionCreator ifNil: [ ^ false ].
	creator := (anExceptionCreator isKindOf: Behavior)
		ifTrue: [ anExceptionCreator ]
		ifFalse: [
			(anExceptionCreator respondsTo: #creator)
				ifTrue: [ anExceptionCreator creator ]
				ifFalse: [ anExceptionCreator class ] ].
	^ creator == self or: [ creator inheritsFrom: self ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Exception class >> handles: aSignalledException
[
	^ self accepts: aSignalledException
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Exception class >> raiseSignal
[
	^ self signal
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Exception class >> raiseSignal: aString
[
	^ self signal: aString
]
