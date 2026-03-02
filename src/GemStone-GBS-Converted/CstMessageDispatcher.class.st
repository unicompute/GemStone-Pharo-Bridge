Class {
	#name : 'CstMessageDispatcher',
	#superclass : 'Object',
	#instVars : [
		'handler'
	],
	#classInstVars : [
		'singleton'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'class initialization' }
CstMessageDispatcher class >> new [
	^super new initialize
]
