Class {
	#name : 'GbxBackgroundSearchDriver',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'searching' }
GbxBackgroundSearchDriver >> killSearchProcess
[
	"don't terminate the search if our process is in gemstone"

	searchProcess isNil ifTrue: [^self].
	session sessionCritical: [super killSearchProcess]
]

{ #category : 'accessing' }
GbxBackgroundSearchDriver >> session: anObject
[

	session := anObject
]

{ #category : 'accessing' }
GbxBackgroundSearchDriver >> session
[

	^session
]

