Class {
	#name : 'GbsObjectFinalizer',
	#superclass : 'Object',
	#instVars : [
		'target',
		'actions'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsObjectFinalizer class >> on: anObject [
	^ self new
		target: anObject;
		yourself
]

{ #category : 'accessing' }
GbsObjectFinalizer >> actions [
	^ actions ifNil: [ actions := OrderedCollection new ]
]

{ #category : 'accessing' }
GbsObjectFinalizer >> addAction: anObject [
	((anObject respondsTo: #cull:)
		or: [ anObject respondsTo: #value ])
		ifFalse: [ self error: 'Finalizer action must be callable.' ].
	self actions add: anObject.
	^ anObject
]

{ #category : 'finalization' }
GbsObjectFinalizer >> finalize [
	| capturedTarget capturedActions |
	capturedTarget := target.
	capturedActions := self actions asArray.
	target := nil.
	actions := OrderedCollection new.
	capturedActions do: [ :each |
		self invokeAction: each with: capturedTarget ]
]

{ #category : 'private' }
GbsObjectFinalizer >> invokeAction: anObject with: aTarget [
	(anObject respondsTo: #cull:)
		ifTrue: [ ^ anObject cull: aTarget ].
	^ anObject value: aTarget
]

{ #category : 'printing' }
GbsObjectFinalizer >> printOn: aStream [
	aStream
		nextPutAll: 'GbsObjectFinalizer(';
		print: self size;
		nextPutAll: ' actions)'
]

{ #category : 'querying' }
GbsObjectFinalizer >> size [
	^ self actions size
]

{ #category : 'accessing' }
GbsObjectFinalizer >> target [
	^ target
]

{ #category : 'accessing' }
GbsObjectFinalizer >> target: anObject [
	target := anObject
]
