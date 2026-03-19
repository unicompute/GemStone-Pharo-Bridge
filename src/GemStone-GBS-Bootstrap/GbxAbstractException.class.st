Class {
	#name : 'GbxAbstractException',
	#superclass : 'Exception',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'testing' }
GbxAbstractException class >> accepts: anExceptionCreator
[
	"VisualWorks compatibility: answer whether the receiver handles exceptions
	created by the given exception class or signalled exception."

	| creator |
	anExceptionCreator ifNil: [^false].
	creator := (anExceptionCreator isKindOf: Behavior)
		ifTrue: [anExceptionCreator]
		ifFalse: [
			(anExceptionCreator respondsTo: #creator)
				ifTrue: [anExceptionCreator creator]
				ifFalse: [anExceptionCreator class] ].
	^creator == self or: [creator inheritsFrom: self]
]

{ #category : 'testing' }
GbxAbstractException class >> handles: aSignalledException
[
	"VisualWorks compatibility for code that still treats exception classes as handlers."

	^self accepts: aSignalledException
]

{ #category : 'constants' }
GbxAbstractException class >> mayResume
[
	"To signify resumability in VW"

	^true
]
