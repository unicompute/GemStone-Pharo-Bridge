Class {
	#name : 'GbxReplicatorManagerTool',
	#superclass : 'Object',
	#instVars : [
		'session',
		'replicatorRegistry',
		'defaultReplicatorClass'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxReplicatorManagerTool class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'accessing' }
GbxReplicatorManagerTool >> defaultReplicatorClass [
	^ defaultReplicatorClass ifNil: [ GbxObjectReplicator ]
]

{ #category : 'accessing' }
GbxReplicatorManagerTool >> defaultReplicatorClass: aClass [
	defaultReplicatorClass := aClass
]

{ #category : 'initialization' }
GbxReplicatorManagerTool >> initialize [
	super initialize.
	replicatorRegistry := Dictionary new.
	defaultReplicatorClass := GbxObjectReplicator.
]

{ #category : 'registration' }
GbxReplicatorManagerTool >> registerReplicator: aClass forClass: className [
	"Register a replicator class for a class"
	replicatorRegistry at: className put: aClass.
]

{ #category : 'replication' }
GbxReplicatorManagerTool >> replicate: anObject [
	"Replicate an object using appropriate replicator"
	| replicator |
	
	replicator := self replicatorFor: anObject.
	^ replicator replicate
]

{ #category : 'replication' }
GbxReplicatorManagerTool >> replicatorFor: anObject [
	"Get appropriate replicator for an object"
	| className replicatorClass |
	
	className := anObject class name.
	replicatorClass := replicatorRegistry at: className ifAbsent: [ nil ].
	replicatorClass ifNil: [
		replicatorClass := self selectReplicatorFor: anObject.
	].
	
	^ replicatorClass new
		target: anObject;
		session: session;
		yourself
]

{ #category : 'accessing' }
GbxReplicatorManagerTool >> replicatorRegistry [
	^ replicatorRegistry
]

{ #category : 'replication' }
GbxReplicatorManagerTool >> selectReplicatorFor: anObject [
	"Select appropriate replicator class for an object based on its type"
	
	anObject class name includes: 'Dictionary' ifTrue: [ ^ GbxDictionaryReplicatorTool ].
	anObject class name includes: 'Array' ifTrue: [ ^ GbxArrayReplicatorTool ].
	anObject class name includes: 'OrderedCollection' ifTrue: [ ^ GbxOrderedCollectionReplicatorTool ].
	anObject class name includes: 'Set' ifTrue: [ ^ GbxIdentitySetReplicatorTool ].
	anObject class name includes: 'String' ifTrue: [ ^ GbxStringReplicatorTool ].
	anObject class name includes: 'Symbol' ifTrue: [ ^ GbxSymbolReplicatorTool ].
	
	^ defaultReplicatorClass
]

{ #category : 'accessing' }
GbxReplicatorManagerTool >> session [
	^ session
]

{ #category : 'accessing' }
GbxReplicatorManagerTool >> session: aSession [
	session := aSession
]
