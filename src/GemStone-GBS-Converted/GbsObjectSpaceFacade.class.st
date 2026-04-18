Class {
	#name : 'GbsObjectSpaceFacade',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsObjectSpaceFacade class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'finalization' }
GbsObjectSpaceFacade class >> finalizationRegistry [
	^ Smalltalk globals
		at: #GbsObjectSpaceFinalizationRegistry
		ifAbsentPut: [ FinalizationRegistry new ]
]

{ #category : 'finalization' }
GbsObjectSpaceFacade class >> finalizationRegistry: aRegistry [
	Smalltalk globals
		at: #GbsObjectSpaceFinalizationRegistry
		put: aRegistry.
	^ aRegistry
]

{ #category : 'finalization' }
GbsObjectSpaceFacade class >> finalizerFor: anObject ifAbsent: aBlock [
	| ephemeron |
	ephemeron := self finalizationRegistry
		ephemeronAtKey: anObject
		ifAbsent: [ ^ aBlock value ].
	^ ephemeron value
]

{ #category : 'finalization' }
GbsObjectSpaceFacade class >> resetFinalizationRegistry [
	^ self finalizationRegistry: FinalizationRegistry new
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> allInstancesOf: aClassOrName [
	^ self repository allInstancesOf: aClassOrName
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> allInstancesOfNamed: aClassName [
	^ self repository allInstancesOfNamed: aClassName
]

{ #category : 'finalization' }
GbsObjectSpaceFacade >> defineFinalizerFor: anObject do: aBlock [
	| finalizer |
	finalizer := self class
		finalizerFor: anObject
		ifAbsent: [
			| newFinalizer |
			newFinalizer := GbsObjectFinalizer on: anObject.
			self class finalizationRegistry
				add: anObject
				finalizer: newFinalizer.
			newFinalizer ].
	finalizer addAction: aBlock.
	^ finalizer
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> eachObjectDo: aBlock [
	self objectsInMemory do: aBlock.
	^ self
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> eachObjectDo: aBlock batchSize: aSmallInteger [
	^ self
		eachObjectOf: nil
		do: aBlock
		batchSize: aSmallInteger
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> eachObjectOf: aClassOrName do: aBlock [
	(self objectsInMemoryOf: aClassOrName) do: aBlock.
	^ self
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> eachObjectOf: aClassOrName do: aBlock batchSize: aSmallInteger [
	| start batch batchSize |
	start := 1.
	batchSize := self normalizedBatchSize: aSmallInteger.
	[
		batch := self
			objectsInMemoryOf: aClassOrName
			from: start
			limit: batchSize.
		batch isEmpty ]
		whileFalse: [
			batch do: aBlock.
			start := start + batch size.
			batch size < batchSize ifTrue: [ ^ self ] ].
	^ self
]

{ #category : 'finalization' }
GbsObjectSpaceFacade >> finalizerFor: anObject [
	^ self class
		finalizerFor: anObject
		ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> hasFinalizerFor: anObject [
	^ (self finalizerFor: anObject) notNil
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> allSubclassesOf: aClassOrName [
	^ session
		executeScriptAndFetchObject: (self allSubclassesScriptFor: aClassOrName)
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> allSubclassesOfNamed: aClassName [
	^ self allSubclassesOf: aClassName
]

{ #category : 'private' }
GbsObjectSpaceFacade >> allSubclassesScriptFor: aClassOrName [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| cls | cls := ';
			nextPutAll: (self classExpressionFor: aClassOrName);
			nextPutAll: '. cls ifNil: [ #() ] ifNotNil: [ cls allSubclasses asArray ]' ]
]

{ #category : 'private' }
GbsObjectSpaceFacade >> classExpressionFor: aClassOrName [
	^ self repository classExpressionFor: aClassOrName
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> instancesInMemoryOf: aClassOrName [
	^ session
		executeScriptAndFetchObject: (self instancesInMemoryScriptFor: aClassOrName)
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> instancesInMemoryOf: aClassOrName from: aStartIndex limit: aLimit [
	^ session
		executeScriptAndFetchObject: (self
			instancesInMemoryScriptFor: aClassOrName
			from: aStartIndex
			limit: aLimit)
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> instancesInMemoryOfNamed: aClassName [
	^ self instancesInMemoryOf: aClassName
]

{ #category : 'private' }
GbsObjectSpaceFacade >> instancesInMemoryScriptFor: aClassOrName [
	^ self
		instancesInMemoryScriptFor: aClassOrName
		from: 1
		limit: 0
]

{ #category : 'private' }
GbsObjectSpaceFacade >> instancesInMemoryScriptFor: aClassOrName from: aStartIndex limit: aLimit [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| cls objects startIndex limitValue skip take | cls := ';
			nextPutAll: (self classExpressionFor: aClassOrName);
			nextPutAll: '. startIndex := ';
			nextPutAll: (aStartIndex max: 1) printString;
			nextPutAll: '. limitValue := ';
			nextPutAll: (aLimit max: 0) printString;
			nextPutAll: '. skip := startIndex - 1. take := limitValue. cls ifNil: [ #() ] ifNotNil: [ objects := (SystemRepository _listInstancesInMemory: { cls }) at: 1. skip > 0 ifTrue: [ skip >= objects size ifTrue: [ objects := #() ] ifFalse: [ objects := objects copyFrom: skip + 1 to: objects size ] ]. take > 0 ifTrue: [ take < objects size ifTrue: [ objects := objects copyFrom: 1 to: take ] ]. objects ]' ]
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> loadedClasses [
	^ self repository loadedClasses
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> loadedClassesIncludingModules [
	^ self loadedClassesIncludingModules: true
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> loadedClassesIncludingModules: aBoolean [
	^ session
		executeScriptAndFetchObject: (self loadedClassesIncludingModulesScript: aBoolean)
]

{ #category : 'private' }
GbsObjectSpaceFacade >> loadedClassesIncludingModulesScript: aBoolean [
	^ 'SystemRepository _loadedClasses: '
		, (aBoolean
			ifTrue: [ 'true' ]
			ifFalse: [ 'false' ])
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> namedObjectAt: aName [
	^ session namedObjectAt: aName
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> referencesTo: anObject [
	^ session
		executeScriptAndFetchObject: (self referencesToScriptFor: anObject)
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> referencesToOop: anOop [
	^ session
		executeScriptAndFetchObject: (self referencesToScriptForOop: anOop)
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> objectsInMemory [
	^ session
		executeScriptAndFetchObject: self objectsInMemoryScript
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> objectsInMemoryFrom: aStartIndex limit: aLimit [
	^ session
		executeScriptAndFetchObject: (self
			objectsInMemoryScriptFrom: aStartIndex
			limit: aLimit)
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> objectsInMemoryOf: aClassOrName [
	aClassOrName ifNil: [ ^ self objectsInMemory ].
	^ self instancesInMemoryOf: aClassOrName
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> objectsInMemoryOf: aClassOrName from: aStartIndex limit: aLimit [
	aClassOrName ifNil: [ ^ self objectsInMemoryFrom: aStartIndex limit: aLimit ].
	^ self
		instancesInMemoryOf: aClassOrName
		from: aStartIndex
		limit: aLimit
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> objectsInMemoryMatching: aBlock [
	^ self
		objectsInMemoryOf: nil
		matching: aBlock
		limit: 0
		batchSize: 200
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> objectsInMemoryMatching: aBlock limit: aLimit batchSize: aBatchSize [
	^ self
		objectsInMemoryOf: nil
		matching: aBlock
		limit: aLimit
		batchSize: aBatchSize
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> objectsInMemoryOf: aClassOrName matching: aBlock [
	^ self
		objectsInMemoryOf: aClassOrName
		matching: aBlock
		limit: 0
		batchSize: 200
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> objectsInMemoryOf: aClassOrName matching: aBlock limit: aLimit batchSize: aBatchSize [
	| matches maxMatches |
	matches := OrderedCollection new.
	maxMatches := aLimit max: 0.
	self
		eachObjectOf: aClassOrName
		do: [ :each |
			(aBlock value: each) ifTrue: [
				matches add: each.
				(maxMatches > 0 and: [ matches size >= maxMatches ]) ifTrue: [
					^ matches asArray ] ] ]
		batchSize: aBatchSize.
	^ matches asArray
]

{ #category : 'private' }
GbsObjectSpaceFacade >> objectsInMemoryScript [
	^ self objectsInMemoryScriptFrom: 1 limit: 0
]

{ #category : 'private' }
GbsObjectSpaceFacade >> objectsInMemoryScriptFrom: aStartIndex limit: aLimit [
	^ '| classes results startIndex limitValue skipCount takeCount |
classes := SystemRepository _loadedClasses: false.
classes size > 2034 ifTrue: [ classes := classes copyFrom: 1 to: 2034 ].
startIndex := ', (aStartIndex max: 1) printString, '.
limitValue := ', (aLimit max: 0) printString, '.
skipCount := startIndex - 1.
takeCount := limitValue.
classes isEmpty ifTrue: [ #() ] ifFalse: [
	results := OrderedCollection new.
	(SystemRepository _listInstancesInMemory: classes) do: [ :each |
		each do: [ :obj | results add: obj ] ].
	skipCount > 0 ifTrue: [
		skipCount >= results size
			ifTrue: [ results := #() ]
			ifFalse: [ results := results copyFrom: skipCount + 1 to: results size ] ].
	takeCount > 0 ifTrue: [
		takeCount < results size ifTrue: [
			results := results copyFrom: 1 to: takeCount ] ].
	results asArray ]'
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> objectForOop: anOop [
	^ session objectForOop: anOop
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> diagnostics [
	^ GbsObjectSpaceDiagnosticsFacade on: session
]

{ #category : 'accessing' }
GbsObjectSpaceFacade >> repository [
	^ session repository
]

{ #category : 'private' }
GbsObjectSpaceFacade >> referencesToScriptFor: anObject [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '(';
			nextPutAll: (session marshalArgumentToScript: anObject);
			nextPutAll: ') findReferencesInMemory asArray' ]
]

{ #category : 'private' }
GbsObjectSpaceFacade >> referencesToScriptForOop: anOop [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '((Object _objectForOop: ';
			nextPutAll: anOop asString;
			nextPutAll: ')) findReferencesInMemory asArray' ]
]

{ #category : 'accessing' }
GbsObjectSpaceFacade >> session [
	^ session
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> sessionStateAt: aKey [
	^ self
		sessionStateAt: aKey
		ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> sessionStateAt: aKey ifAbsent: aBlock [
	| result |
	result := session
		executeScriptAndFetchObject: (self sessionStateAtScriptFor: aKey).
	^ result ifNil: [ aBlock value ] ifNotNil: [ result ]
]

{ #category : 'actions' }
GbsObjectSpaceFacade >> sessionStateAt: aKey put: anObject [
	^ session
		executeScriptAndFetchObject: (self
			sessionStateAtPutScriptFor: aKey
			value: anObject)
]

{ #category : 'accessing' }
GbsObjectSpaceFacade >> session: aSession [
	session := aSession
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> maglevFinalizerRegistry [
	^ self sessionStateAt: 19
]

{ #category : 'private' }
GbsObjectSpaceFacade >> sessionStateAtPutScriptFor: aKey value: anObject [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| key value | key := ';
			nextPutAll: (session marshalArgumentToScript: aKey);
			nextPutAll: '. value := ';
			nextPutAll: (session marshalArgumentToScript: anObject);
			nextPutAll: '. ';
			nextPutAll: '(System respondsTo: #sessionStateAt:put:) ';
			nextPutAll: 'ifTrue: [ System sessionStateAt: key put: value ] ';
			nextPutAll: 'ifFalse: [ (System respondsTo: #_sessionStateAt:put:) ';
			nextPutAll: 'ifTrue: [ System _sessionStateAt: key put: value ] ';
			nextPutAll: 'ifFalse: [ Error signal: ''System does not support sessionStateAt:put:.'' ] ]' ]
]

{ #category : 'private' }
GbsObjectSpaceFacade >> sessionStateAtScriptFor: aKey [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| key | key := ';
			nextPutAll: (session marshalArgumentToScript: aKey);
			nextPutAll: '. ';
			nextPutAll: '(System respondsTo: #sessionStateAt:) ';
			nextPutAll: 'ifTrue: [ System sessionStateAt: key ] ';
			nextPutAll: 'ifFalse: [ (System respondsTo: #_sessionStateAt:) ';
			nextPutAll: 'ifTrue: [ System _sessionStateAt: key ] ';
			nextPutAll: 'ifFalse: [ nil ] ]' ]
]

{ #category : 'private' }
GbsObjectSpaceFacade >> normalizedBatchSize: aSmallInteger [
	^ ((aSmallInteger ifNil: [ 200 ]) asInteger) max: 1
]

{ #category : 'finalization' }
GbsObjectSpaceFacade >> undefineFinalizerFor: anObject [
	| finalizer |
	finalizer := self finalizerFor: anObject.
	finalizer ifNil: [ ^ nil ].
	self class finalizationRegistry
		remove: anObject
		ifAbsent: [ ].
	^ finalizer
]
