Class {
	#name : 'GbxBehaviorOopMapNode',
	#superclass : 'Object',
	#instVars : [
		'oop',
		'behavior',
		'session',
		'isClass',
		'isMetaclass'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxBehaviorOopMapNode class >> oop: anOop behavior: aBehavior [
	^ self new
		oop: anOop;
		behavior: aBehavior;
		yourself
]

{ #category : 'accessing' }
GbxBehaviorOopMapNode >> behavior [
	^ behavior
]

{ #category : 'accessing' }
GbxBehaviorOopMapNode >> behavior: aBehavior [
	behavior := aBehavior
]

{ #category : 'accessing' }
GbxBehaviorOopMapNode >> isClass [
	^ isClass ifNil: [ false ]
]

{ #category : 'accessing' }
GbxBehaviorOopMapNode >> isClass: aBoolean [
	isClass := aBoolean
]

{ #category : 'accessing' }
GbxBehaviorOopMapNode >> isMetaclass [
	^ isMetaclass ifNil: [ false ]
]

{ #category : 'accessing' }
GbxBehaviorOopMapNode >> isMetaclass: aBoolean [
	isMetaclass := aBoolean
]

{ #category : 'accessing' }
GbxBehaviorOopMapNode >> oop [
	^ oop
]

{ #category : 'accessing' }
GbxBehaviorOopMapNode >> oop: anOop [
	oop := anOop
]

{ #category : 'accessing' }
GbxBehaviorOopMapNode >> printString [
	^ 'BehaviorNode (oop: ', (oop ifNil: [ 'nil' ] ifNotNil: [ oop asString ]),
	  ', class: ', isClass asString, ', meta: ', isMetaclass asString, ')'
]

{ #category : 'accessing' }
GbxBehaviorOopMapNode >> session [
	^ session
]

{ #category : 'accessing' }
GbxBehaviorOopMapNode >> session: aSession [
	session := aSession
]
