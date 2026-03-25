Class {
	#name : 'GbsTools',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'lifecycle' }
GbsTools class >> initializeClasses [
	| runtime |
	runtime := Smalltalk globals at: #GbsRuntime ifAbsent: [ nil ].
	(runtime isNil or: [ (runtime respondsTo: #initializeClasses) not ]) ifTrue: [ ^ #() ].
	^ runtime initializeClasses
]

{ #category : 'lifecycle' }
GbsTools class >> loaded [
	(Smalltalk globals at: #GbsRuntime ifAbsent: [ nil ])
		ifNotNil: [ :runtime | (runtime respondsTo: #loaded) ifTrue: [ runtime loaded ] ].
]

{ #category : 'lifecycle' }
GbsTools class >> removing [
	(Smalltalk globals at: #GbsRuntime ifAbsent: [ nil ])
		ifNotNil: [ :runtime | (runtime respondsTo: #removing) ifTrue: [ runtime removing ] ].
]
