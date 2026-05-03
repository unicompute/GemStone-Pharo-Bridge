Class {
	#name : 'CoreTestableGbsWorkspace',
	#superclass : 'GbsWorkspace',
	#instVars : [
		'debuggerOpened',
		'lastOpenedProcessOop',
		'lastInspectedOop',
		'lastInspectedSession',
		'requestAnswers',
		'lastInfoMessage'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'initialization' }
CoreTestableGbsWorkspace >> debuggerOpened [

  ^ debuggerOpened ifNil: [ false ]
]

{ #category : 'initialization' }
CoreTestableGbsWorkspace >> initialize [
	super initialize.
	requestAnswers := OrderedCollection new
]

{ #category : 'testing' }
CoreTestableGbsWorkspace >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'initialization' }
CoreTestableGbsWorkspace >> openRemoteDebuggerOn: anException processOop: processOop session: aSession [
  debuggerOpened := true.
  lastOpenedProcessOop := processOop
]

{ #category : 'initialization' }
CoreTestableGbsWorkspace >> lastOpenedProcessOop [

  ^ lastOpenedProcessOop
]

{ #category : 'private' }
CoreTestableGbsWorkspace >> inspectOop: anOop session: aSession [
	lastInspectedOop := anOop.
	lastInspectedSession := aSession
]

{ #category : 'accessing' }
CoreTestableGbsWorkspace >> lastInspectedOop [
	^ lastInspectedOop
]

{ #category : 'accessing' }
CoreTestableGbsWorkspace >> lastInspectedSession [
	^ lastInspectedSession
]

{ #category : 'private' }
CoreTestableGbsWorkspace >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'accessing' }
CoreTestableGbsWorkspace >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'private' }
CoreTestableGbsWorkspace >> requestInput: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]
