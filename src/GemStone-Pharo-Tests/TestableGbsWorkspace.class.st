Class {
	#name : 'TestableGbsWorkspace',
	#superclass : 'GbsWorkspace',
	#instVars : [
		'debuggerOpened',
		'lastOpenedProcessOop',
		'lastInspectedOop',
		'lastInspectedSession',
		'requestAnswers',
		'lastInfoMessage'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'initialization' }
TestableGbsWorkspace >> debuggerOpened [

  ^ debuggerOpened ifNil: [ false ]
]

{ #category : 'initialization' }
TestableGbsWorkspace >> initialize [
	super initialize.
	requestAnswers := OrderedCollection new
]

{ #category : 'testing' }
TestableGbsWorkspace >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'initialization' }
TestableGbsWorkspace >> openRemoteDebuggerOn: anException processOop: processOop session: aSession [
  "Instead of opening the physical window, just flip our test flag to true!"

  debuggerOpened := true.
  lastOpenedProcessOop := processOop
]

{ #category : 'initialization' }
TestableGbsWorkspace >> lastOpenedProcessOop [

  ^ lastOpenedProcessOop
]

{ #category : 'private' }
TestableGbsWorkspace >> inspectOop: anOop session: aSession [
	lastInspectedOop := anOop.
	lastInspectedSession := aSession
]

{ #category : 'accessing' }
TestableGbsWorkspace >> lastInspectedOop [
	^ lastInspectedOop
]

{ #category : 'accessing' }
TestableGbsWorkspace >> lastInspectedSession [
	^ lastInspectedSession
]

{ #category : 'private' }
TestableGbsWorkspace >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'accessing' }
TestableGbsWorkspace >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'private' }
TestableGbsWorkspace >> requestInput: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]
