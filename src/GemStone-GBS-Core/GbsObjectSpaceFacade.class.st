Class {
	#name : 'GbsObjectSpaceFacade',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
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

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> drainExportSetReleaseOops [
	^ self drainExportSetReleaseOopsLimit: nil
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> drainExportSetReleaseOopsLimit: anInteger [
	^ GbsSessionLifecycleManager
		drainExportSetReleaseOopsForSession: session
		limit: anInteger
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> drainGcedOops [
	^ self drainGcedOopsLimit: nil
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> drainGcedOopsLimit: anInteger [
	^ GbsSessionLifecycleManager
		drainGcedOopsForSession: session
		limit: anInteger
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> drainNoLongerReplicatedOops [
	^ self drainNoLongerReplicatedOopsLimit: nil
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> drainNoLongerReplicatedOopsLimit: anInteger [
	^ GbsSessionLifecycleManager
		drainNoLongerReplicatedOopsForSession: session
		limit: anInteger
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> flushExportSetReleaseOops [
	^ self flushExportSetReleaseOopsLimit: nil
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> flushExportSetReleaseOopsLimit: anInteger [
	^ GbsSessionLifecycleManager
		flushExportSetReleaseOopsForSession: session
		limit: anInteger
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> flushExportSetReleaseOopsReportText [
	^ self flushExportSetReleaseOopsReportTextLimit: nil
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> flushExportSetReleaseOopsReportTextLimit: anInteger [
	^ GbsSessionLifecycleManager
		exportSetReleaseFlushReportTextFor: (self flushExportSetReleaseOopsLimit: anInteger)
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> flushGcedOops [
	^ self flushGcedOopsLimit: nil
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> flushGcedOopsLimit: anInteger [
	^ GbsSessionLifecycleManager
		flushGcedOopsForSession: session
		limit: anInteger
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

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> forgetObject: anObject [
	^ GbsSessionLifecycleManager
		forgetObject: anObject
		inSession: session
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> forgetObjectForOop: anOop [
	^ GbsSessionLifecycleManager
		forgetObjectForOop: anOop
		inSession: session
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> faultObjectForOop: anOop [
	^ session faultObjectForOop: anOop
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> faultProxy: aProxy [
	^ session faultProxy: aProxy
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> stubObject: anObject [
	^ session stubMaterializedObject: anObject
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> stubObjectForOop: anOop [
	^ session stubMaterializedObjectForOop: anOop
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> allSubclassesOf: aClassOrName [
	^ self repository
		fetchClassReference: aClassOrName
		variableName: 'cls'
		body: self allSubclassesCommandBody
		literalAssignments: Dictionary new
		oopAssignments: Dictionary new
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> allSubclassesOfNamed: aClassName [
	^ self allSubclassesOf: aClassName
]

{ #category : 'private' }
GbsObjectSpaceFacade >> allSubclassesCommandBody [
	^ 'cls ifNil: [ #() ] ifNotNil: [ cls allSubclasses asArray ]'
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> instancesInMemoryOf: aClassOrName [
	^ self
		instancesInMemoryOf: aClassOrName
		from: 1
		limit: 0
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> instancesInMemoryOf: aClassOrName from: aStartIndex limit: aLimit [
	^ self repository
		fetchClassReference: aClassOrName
		variableName: 'cls'
		body: self instancesInMemoryCommandBody
		literalAssignments: (Dictionary new
			at: 'limitValue' put: (aLimit max: 0);
			at: 'startIndex' put: (aStartIndex max: 1);
			yourself)
		oopAssignments: Dictionary new
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> instancesInMemoryOfNamed: aClassName [
	^ self instancesInMemoryOf: aClassName
]

{ #category : 'private' }
GbsObjectSpaceFacade >> instancesInMemoryCommandBody [
	^ '| objects skip take |
skip := startIndex - 1.
take := limitValue.
cls ifNil: [ #() ] ifNotNil: [
	objects := (SystemRepository _listInstancesInMemory: { cls }) at: 1.
	skip > 0 ifTrue: [
		skip >= objects size
			ifTrue: [ objects := #() ]
			ifFalse: [ objects := objects copyFrom: skip + 1 to: objects size ] ].
	take > 0 ifTrue: [
		take < objects size ifTrue: [
			objects := objects copyFrom: 1 to: take ] ].
	objects ]'
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
	^ self
		fetchCommandBody: 'SystemRepository _loadedClasses: includeModules'
		literalBindings: (Dictionary new
			at: 'includeModules' put: aBoolean;
			yourself)
		oopBindings: Dictionary new
]

{ #category : 'private' }
GbsObjectSpaceFacade >> fetchCommandBody: bodyString literalBindings: literalDictionary oopBindings: oopDictionary [
	^ session fetchRemoteCommand: (GbsRemoteCommand
		blockBody: bodyString
		literalAssignments: literalDictionary
		oopAssignments: oopDictionary)
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> namedObjectAt: aName [
	^ session namedObjectAt: aName
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> referencesTo: anObject [
	^ self
		fetchCommandBody: 'object findReferencesInMemory asArray'
		literalBindings: (Dictionary new
			at: 'object' put: anObject;
			yourself)
		oopBindings: Dictionary new
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> referencesToOop: anOop [
	^ self
		fetchCommandBody: 'object findReferencesInMemory asArray'
		literalBindings: Dictionary new
		oopBindings: (Dictionary new
			at: 'object' put: anOop;
			yourself)
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> objectsInMemory [
	^ self objectsInMemoryFrom: 1 limit: 0
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> objectsInMemoryFrom: aStartIndex limit: aLimit [
	^ self
		fetchCommandBody: self objectsInMemoryCommandBody
		literalBindings: (Dictionary new
			at: 'limitValue' put: (aLimit max: 0);
			at: 'startIndex' put: (aStartIndex max: 1);
			yourself)
		oopBindings: Dictionary new
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
GbsObjectSpaceFacade >> objectsInMemoryCommandBody [
	^ '| classes results skipCount takeCount |
classes := SystemRepository _loadedClasses: false.
classes size > 2034 ifTrue: [ classes := classes copyFrom: 1 to: 2034 ].
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

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> lifecycleReport [
	^ GbsSessionLifecycleManager lifecycleReportForSession: session
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> lifecycleReportText [
	^ GbsSessionLifecycleManager lifecycleReportTextForSession: session
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> pendingGcedOopCount [
	^ GbsSessionLifecycleManager pendingGcedOopCountForSession: session
]

{ #category : 'export set' }
GbsObjectSpaceFacade >> saveObjects: aCollection [
	"VW-compatible export-set save: add the given objects/proxies/OOPs to the gem's PureExportSet."
	^ GbsSessionLifecycleManager saveObjects: aCollection forSession: session
]

{ #category : 'export set' }
GbsObjectSpaceFacade >> releaseObjects: aCollection [
	"VW-compatible export-set release: remove the given objects/proxies/OOPs from the gem's PureExportSet."
	^ GbsSessionLifecycleManager releaseObjects: aCollection forSession: session
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> pendingExportSetReleaseOopCount [
	^ GbsSessionLifecycleManager pendingExportSetReleaseOopCountForSession: session
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> pendingExportSetReleaseOops [
	^ self pendingExportSetReleaseOopsLimit: nil
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> pendingExportSetReleaseOopsLimit: anInteger [
	^ GbsSessionLifecycleManager
		pendingExportSetReleaseOopsForSession: session
		limit: anInteger
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> pendingGcedOops [
	^ self pendingGcedOopsLimit: nil
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> pendingGcedOopsLimit: anInteger [
	^ GbsSessionLifecycleManager
		pendingGcedOopsForSession: session
		limit: anInteger
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> pendingNoLongerReplicatedOopCount [
	^ GbsSessionLifecycleManager pendingNoLongerReplicatedOopCountForSession: session
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> pendingNoLongerReplicatedOops [
	^ self pendingNoLongerReplicatedOopsLimit: nil
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> pendingNoLongerReplicatedOopsLimit: anInteger [
	^ GbsSessionLifecycleManager
		pendingNoLongerReplicatedOopsForSession: session
		limit: anInteger
]

{ #category : 'querying' }
GbsObjectSpaceFacade >> diagnostics [
	^ GbsObjectSpaceDiagnosticsFacade on: session
]

{ #category : 'accessing' }
GbsObjectSpaceFacade >> repository [
	^ session repository
]

{ #category : 'accessing' }
GbsObjectSpaceFacade >> repositoryFacade [
	^ session objectSpaceRepository
]

{ #category : 'accessing' }
GbsObjectSpaceFacade >> session [
	^ session
]

{ #category : 'lifecycle' }
GbsObjectSpaceFacade >> serverMapSize [
	^ GbsSessionLifecycleManager serverMapSizeForSession: session
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
	result := self
		fetchCommandBody: self sessionStateAtCommandBody
		literalBindings: (Dictionary new
			at: 'key' put: aKey;
			yourself)
		oopBindings: Dictionary new.
	^ result ifNil: [ aBlock value ] ifNotNil: [ result ]
]

{ #category : 'actions' }
GbsObjectSpaceFacade >> sessionStateAt: aKey put: anObject [
	^ self
		fetchCommandBody: self sessionStateAtPutCommandBody
		literalBindings: (Dictionary new
			at: 'key' put: aKey;
			at: 'value' put: anObject;
			yourself)
		oopBindings: Dictionary new
]

{ #category : 'accessing' }
GbsObjectSpaceFacade >> session: aSession [
	session := aSession
]

{ #category : 'private' }
GbsObjectSpaceFacade >> sessionStateAtPutCommandBody [
	^ '(System respondsTo: #sessionStateAt:put:)
		ifTrue: [ System sessionStateAt: key put: value ]
		ifFalse: [ (System respondsTo: #_sessionStateAt:put:)
			ifTrue: [ System _sessionStateAt: key put: value ]
			ifFalse: [ Error signal: ''System does not support sessionStateAt:put:.'' ] ]'
]

{ #category : 'private' }
GbsObjectSpaceFacade >> sessionStateAtCommandBody [
	^ '(System respondsTo: #sessionStateAt:)
		ifTrue: [ System sessionStateAt: key ]
		ifFalse: [ (System respondsTo: #_sessionStateAt:)
			ifTrue: [ System _sessionStateAt: key ]
			ifFalse: [ nil ] ]'
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
