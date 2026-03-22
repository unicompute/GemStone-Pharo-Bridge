Class {
	#name : 'ProcessHandle',
	#superclass : 'Object',
	#instVars : [
		'process',
		'context',
		'interrupted'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'instance creation' }
ProcessHandle class >> on: aProcess at: aContext interrupted: aBoolean [
	^ self new
		process: aProcess;
		context: aContext;
		interrupted: aBoolean;
		yourself
]

{ #category : 'accessing' }
ProcessHandle >> process: anObject [
	process := anObject
]

{ #category : 'accessing' }
ProcessHandle >> context: anObject [
	context := anObject
]

{ #category : 'accessing' }
ProcessHandle >> interrupted: aBoolean [
	interrupted := aBoolean
]
