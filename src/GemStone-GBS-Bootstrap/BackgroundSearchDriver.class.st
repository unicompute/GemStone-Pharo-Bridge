Class {
	#name : 'BackgroundSearchDriver',
	#superclass : 'Object',
	#instVars : [
		'searchProcess'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'accessing' }
BackgroundSearchDriver >> killSearchProcess
[
	searchProcess := nil
]

{ #category : 'accessing' }
BackgroundSearchDriver >> session
[
	"VisualWorks compatibility stub"
	^nil
]

{ #category : 'accessing' }
BackgroundSearchDriver >> session: anObject
[
	"VisualWorks compatibility stub"
]
