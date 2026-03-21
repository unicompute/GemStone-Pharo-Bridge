Class {
	#name : 'GbxBehaviorOopMapNodeTool',
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
GbxBehaviorOopMapNodeTool class >> oop: anOop behavior: aBehavior [
	^ self new
		oop: anOop;
		behavior: aBehavior;
		yourself
]

{ #category : 'accessing' }
GbxBehaviorOopMapNodeTool >> behavior [
	^ behavior
]

{ #category : 'accessing' }
GbxBehaviorOopMapNodeTool >> behavior: aBehavior [
	behavior := aBehavior
]

{ #category : 'accessing' }
GbxBehaviorOopMapNodeTool >> isClass [
	^ isClass ifNil: [ false ]
]

{ #category : 'accessing' }
GbxBehaviorOopMapNodeTool >> isClass: aBoolean [
	isClass := aBoolean
]

{ #category : 'accessing' }
GbxBehaviorOopMapNodeTool >> isMetaclass [
	^ isMetaclass ifNil: [ false ]
]

{ #category : 'accessing' }
GbxBehaviorOopMapNodeTool >> isMetaclass: aBoolean [
	isMetaclass := aBoolean
]

{ #category : 'accessing' }
GbxBehaviorOopMapNodeTool >> oop [
	^ oop
]

{ #category : 'accessing' }
GbxBehaviorOopMapNodeTool >> oop: anOop [
	oop := anOop
]

{ #category : 'accessing' }
GbxBehaviorOopMapNodeTool >> printString [
	^ 'BehaviorNode (oop: ', (oop ifNil: [ 'nil' ] ifNotNil: [ oop asString ]),
	  ', class: ', isClass asString, ', meta: ', isMetaclass asString, ')'
]

{ #category : 'accessing' }
GbxBehaviorOopMapNodeTool >> session [
	^ session
]

{ #category : 'accessing' }
GbxBehaviorOopMapNodeTool >> session: aSession [
	session := aSession
]
