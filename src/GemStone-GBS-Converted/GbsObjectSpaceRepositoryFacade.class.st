Class {
	#name : 'GbsObjectSpaceRepositoryFacade',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsObjectSpaceRepositoryFacade class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'querying' }
GbsObjectSpaceRepositoryFacade >> allInstancesOf: aClassOrName [
	^ session repository allInstancesOf: aClassOrName
]

{ #category : 'querying' }
GbsObjectSpaceRepositoryFacade >> allInstancesOfNamed: aClassName [
	^ self allInstancesOf: aClassName
]

{ #category : 'private' }
GbsObjectSpaceRepositoryFacade >> classExpressionFor: aClassOrName [
	^ session repository classExpressionFor: aClassOrName
]

{ #category : 'querying' }
GbsObjectSpaceRepositoryFacade >> countInstancesOf: aClassOrName [
	^ session executeScriptAndFetchObject: (self countInstancesScriptFor: aClassOrName)
]

{ #category : 'querying' }
GbsObjectSpaceRepositoryFacade >> countInstancesOfNamed: aClassName [
	^ self countInstancesOf: aClassName
]

{ #category : 'private' }
GbsObjectSpaceRepositoryFacade >> countInstancesScriptFor: aClassOrName [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| cls instances | cls := ';
			nextPutAll: (self classExpressionFor: aClassOrName);
			nextPutAll: '. cls ifNil: [ 0 ] ifNotNil: [ instances := (SystemRepository listInstances: { cls }) at: 1. instances size ]' ]
]

{ #category : 'querying' }
GbsObjectSpaceRepositoryFacade >> eachInstanceOf: aClassOrName do: aBlock batchSize: aBatchSize [
	^ session objectSpace
		eachObjectOf: aClassOrName
		do: aBlock
		batchSize: aBatchSize
]

{ #category : 'querying' }
GbsObjectSpaceRepositoryFacade >> instanceOopsOf: aClassOrName [
	^ session executeScriptAndFetchObject: (self instanceOopsScriptFor: aClassOrName)
]

{ #category : 'querying' }
GbsObjectSpaceRepositoryFacade >> instanceOopsOfNamed: aClassName [
	^ self instanceOopsOf: aClassName
]

{ #category : 'private' }
GbsObjectSpaceRepositoryFacade >> instanceOopsScriptFor: aClassOrName [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| cls instances | cls := ';
			nextPutAll: (self classExpressionFor: aClassOrName);
			nextPutAll: '. cls ifNil: [ #() ] ifNotNil: [ instances := (SystemRepository listInstances: { cls }) at: 1. instances collect: [ :each | each asOop ] ]' ]
]

{ #category : 'querying' }
GbsObjectSpaceRepositoryFacade >> listInstancesOf: aClassOrName [
	^ session repository listInstancesOf: aClassOrName
]

{ #category : 'querying' }
GbsObjectSpaceRepositoryFacade >> listInstancesOf: aClassOrName limit: aLimit [
	^ session repository listInstancesOf: aClassOrName limit: aLimit
]

{ #category : 'querying' }
GbsObjectSpaceRepositoryFacade >> listInstancesOf: aClassOrName limit: aLimit allowAbort: aBoolean [
	^ session repository
		listInstancesOf: aClassOrName
		limit: aLimit
		allowAbort: aBoolean
]

{ #category : 'querying' }
GbsObjectSpaceRepositoryFacade >> listInstancesOfNamed: aClassName [
	^ self listInstancesOf: aClassName
]

{ #category : 'printing' }
GbsObjectSpaceRepositoryFacade >> reportTextFor: aClassOrName [
	| count oops label |
	label := aClassOrName asString.
	count := self countInstancesOf: aClassOrName.
	oops := self instanceOopsOf: aClassOrName.
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'ObjectSpace::Repository';
			cr; cr;
			nextPutAll: 'Class: ';
			nextPutAll: label;
			cr;
			nextPutAll: 'Count: ';
			nextPutAll: count printString;
			cr;
			nextPutAll: 'Oops: ';
			nextPutAll: oops printString ]
]

{ #category : 'accessing' }
GbsObjectSpaceRepositoryFacade >> session [
	^ session
]

{ #category : 'accessing' }
GbsObjectSpaceRepositoryFacade >> session: aSession [
	session := aSession
]
