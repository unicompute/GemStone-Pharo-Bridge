Class {
	#name : 'GbxFakeContextForPolicy',
	#superclass : 'Object',
	#instVars : [
		'sender',
		'receiver',
		'isGlue',
		'isServer',
		'processOop',
		'methodClass',
		'selector'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeContextForPolicy >> sender [
	^ sender
]

{ #category : 'accessing' }
GbxFakeContextForPolicy >> sender: aContext [
	sender := aContext
]

{ #category : 'accessing' }
GbxFakeContextForPolicy >> receiver [
	^ receiver
]

{ #category : 'accessing' }
GbxFakeContextForPolicy >> receiver: anObject [
	receiver := anObject
]

{ #category : 'testing' }
GbxFakeContextForPolicy >> isGlue [
	^ isGlue ifNil: [ false ]
]

{ #category : 'accessing' }
GbxFakeContextForPolicy >> isGlue: aBoolean [
	isGlue := aBoolean
]

{ #category : 'testing' }
GbxFakeContextForPolicy >> gbxIsServerContext [
	^ isServer ifNil: [ false ]
]

{ #category : 'accessing' }
GbxFakeContextForPolicy >> gbxIsServerContext: aBoolean [
	isServer := aBoolean
]

{ #category : 'accessing' }
GbxFakeContextForPolicy >> processOop [
	^ processOop
]

{ #category : 'accessing' }
GbxFakeContextForPolicy >> processOop: anInteger [
	processOop := anInteger
]

{ #category : 'accessing' }
GbxFakeContextForPolicy >> process [
	^ processOop
]

{ #category : 'accessing' }
GbxFakeContextForPolicy >> methodClass [
	^ methodClass ifNil: [ 'Object' ]
]

{ #category : 'accessing' }
GbxFakeContextForPolicy >> methodClass: aString [
	methodClass := aString
]

{ #category : 'accessing' }
GbxFakeContextForPolicy >> selector [
	^ selector ifNil: [ #fakeSelector ]
]

{ #category : 'accessing' }
GbxFakeContextForPolicy >> selector: aSymbol [
	selector := aSymbol
]
