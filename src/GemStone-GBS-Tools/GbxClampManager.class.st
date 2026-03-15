Class {
	#name : 'GbxClampManager',
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
GbxClampManager class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'clamping' }
GbxClampManager >> clampSpecFor: anObject [
	"Get clamp specification for an object"
	| className spec |
	
	className := anObject class name.
	spec := clampSpecifications at: className ifAbsent: [ nil ].
	^ spec ifNil: [ defaultClampLevel ]
]

{ #category : 'accessing' }
GbxClampManager >> clampSpecifications [
	^ clampSpecifications ifNil: [ clampSpecifications := Dictionary new ]
]

{ #category : 'accessing' }
GbxClampManager >> defaultClampLevel [
	^ defaultClampLevel ifNil: [ 3 ]
]

{ #category : 'accessing' }
GbxClampManager >> defaultClampLevel: anInteger [
	defaultClampLevel := anInteger
]

{ #category : 'initialization' }
GbxClampManager >> initialize [
	super initialize.
	clampSpecifications := Dictionary new.
	defaultClampLevel := 3.
]

{ #category : 'clamping' }
GbxClampManager >> registerClampSpec: aSpec forClass: className [
	"Register a clamp specification for a class"
	clampSpecifications at: className put: aSpec.
]

{ #category : 'accessing' }
GbxClampManager >> session [
	^ session
]

{ #category : 'accessing' }
GbxClampManager >> session: aSession [
	session := aSession
]
