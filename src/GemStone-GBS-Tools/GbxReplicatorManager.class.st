Class {
	#name : 'GbxReplicatorManager',
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
GbxReplicatorManager class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'replication' }
GbxReplicatorManager >> replicatorFor: anObject [
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
GbxReplicatorManager >> defaultReplicatorClass [
	^ defaultReplicatorClass ifNil: [ GbxObjectReplicator ]
]

{ #category : 'accessing' }
GbxReplicatorManager >> defaultReplicatorClass: aClass [
	defaultReplicatorClass := aClass
]

{ #category : 'initialization' }
GbxReplicatorManager >> initialize [
	super initialize.
	replicatorRegistry := Dictionary new.
	defaultReplicatorClass := GbxObjectReplicator.
]

{ #category : 'registration' }
GbxReplicatorManager >> registerReplicator: aClass forClass: className [
	"Register a replicator class for a class"
	replicatorRegistry at: className put: aClass.
]

{ #category : 'accessing' }
GbxReplicatorManager >> replicatorRegistry [
	^ replicatorRegistry
]

{ #category : 'replication' }
GbxReplicatorManager >> replicate: anObject [
	"Replicate an object using appropriate replicator"
	| replicator |
	
	replicator := self replicatorFor: anObject.
	^ replicator replicate
]

{ #category : 'replication' }
GbxReplicatorManager >> selectReplicatorFor: anObject [
	"Select appropriate replicator class for an object based on its type"
	
	anObject class name includes: 'Dictionary' ifTrue: [ ^ GbxDictionaryReplicator ].
	anObject class name includes: 'Array' ifTrue: [ ^ GbxArrayReplicator ].
	anObject class name includes: 'OrderedCollection' ifTrue: [ ^ GbxOrderedCollectionReplicator ].
	anObject class name includes: 'Set' ifTrue: [ ^ GbxIdentitySetReplicator ].
	anObject class name includes: 'String' ifTrue: [ ^ GbxStringReplicator ].
	anObject class name includes: 'Symbol' ifTrue: [ ^ GbxSymbolReplicator ].
	
	^ defaultReplicatorClass
]

{ #category : 'accessing' }
GbxReplicatorManager >> session [
	^ session
]

{ #category : 'accessing' }
GbxReplicatorManager >> session: aSession [
	session := aSession
]
