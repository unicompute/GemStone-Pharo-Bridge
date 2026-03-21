Class {
	#name : 'GbxClampManagerTool',
	#superclass : 'Object',
	#instVars : [
		'session',
		'clampSpecifications',
		'defaultClampLevel'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxClampManagerTool class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'clamping' }
GbxClampManagerTool >> clampSpecFor: anObject [
	"Get clamp specification for an object"
	| className spec |
	
	className := anObject class name.
	spec := clampSpecifications at: className ifAbsent: [ nil ].
	^ spec ifNil: [ defaultClampLevel ]
]

{ #category : 'accessing' }
GbxClampManagerTool >> clampSpecifications [
	^ clampSpecifications ifNil: [ clampSpecifications := Dictionary new ]
]

{ #category : 'accessing' }
GbxClampManagerTool >> defaultClampLevel [
	^ defaultClampLevel ifNil: [ 3 ]
]

{ #category : 'accessing' }
GbxClampManagerTool >> defaultClampLevel: anInteger [
	defaultClampLevel := anInteger
]

{ #category : 'initialization' }
GbxClampManagerTool >> initialize [
	super initialize.
	clampSpecifications := Dictionary new.
	defaultClampLevel := 3.
]

{ #category : 'clamping' }
GbxClampManagerTool >> registerClampSpec: aSpec forClass: className [
	"Register a clamp specification for a class"
	clampSpecifications at: className put: aSpec.
]

{ #category : 'accessing' }
GbxClampManagerTool >> session [
	^ session
]

{ #category : 'accessing' }
GbxClampManagerTool >> session: aSession [
	session := aSession
]
