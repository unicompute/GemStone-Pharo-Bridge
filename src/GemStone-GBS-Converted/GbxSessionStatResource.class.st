Class {
	#name : 'GbxSessionStatResource',
	#superclass : 'GbxStatResource',
	#instVars : [
		'bytesSentByStoreTraversal',
		'bytesTraversed',
		'changedObjNotifications',
		'freeOopsFetched',
		'gciCallsToGem',
		'gciCallsToGemTime',
		'gciErrors',
		'lostOtRoots',
		'nbEndResultNoProgress',
		'nbEndResultProgressed',
		'nbEndResultReady',
		'objectsStoredByTraversal',
		'objectsTraversed',
		'serverMapSize',
		'session',
		'sessionProtectInvocations',
		'sessionSignals',
		'sigAborts',
		'storeTraversals',
		'traversalUnpackingTime',
		'traverseCallTime',
		'traverseCalls'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'stat updating' }
GbxSessionStatResource >> incSessionProtectInvocations
[
	sessionProtectInvocations incValue: 1
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incChangedObjNotifications: delta
[
	changedObjNotifications incValue: delta
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incFreeOopsFetched: delta
[
	freeOopsFetched incValue: delta
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incSessionSignals
[
	sessionSignals incValue: 1
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incSigAborts
[
	sigAborts incValue: 1
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incGciCallsToGem
[
	gciCallsToGem incValue: 1
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incStoreTraversals
[
	storeTraversals incValue: 1
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incTraversalUnpackingTime: delta
[
	traversalUnpackingTime incValue: delta
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incGciCallsToGemTime: delta
[
	gciCallsToGemTime incValue: delta
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incLostOtRoots
[
	lostOtRoots incValue: 1
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incTraverseCallTime: delta
[
	traverseCallTime incValue: delta
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incNbEndResultNoProgress
[
	nbEndResultNoProgress incValue: 1
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incNbEndResultProgressed
[
	nbEndResultProgressed incValue: 1
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incTraverseCalls
[

	traverseCalls incValue: 1
]

{ #category : 'stat updating' }
GbxSessionStatResource >> gbxIncGciErrors
[
	gciErrors incValue: 1
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incNbEndResultReady
[
	nbEndResultReady incValue: 1
]

{ #category : 'stat updating' }
GbxSessionStatResource >> gbxIncProgress: primResult
[
	primResult == GbxNonBlockingGciCallSequencer resultReady 
		ifTrue: [self incNbEndResultReady]
		ifFalse: 
			[primResult == GbxNonBlockingGciCallSequencer resultProgressed 
				ifTrue: [self incNbEndResultProgressed]
				ifFalse: [self incNbEndResultNoProgress]]
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incObjectsStoredByTraversal
[

	objectsStoredByTraversal incValue: 1
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incObjectsTraversed
[
	objectsTraversed incValue: 1
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incBytesSentByStoreTraversal: delta
[
	bytesSentByStoreTraversal incValue: delta
]

{ #category : 'stat updating' }
GbxSessionStatResource >> incBytesTraversed: delta
[
	bytesTraversed incValue: delta
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> freeOopsFetched
[
	^freeOopsFetched value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> gciCallsToGem
[
	^gciCallsToGem value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> sessionProtectInvocations
[
	^sessionProtectInvocations value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> sessionSignals
[
	^sessionSignals value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> gciCallsToGemTime
[
	^gciCallsToGemTime value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> sigAborts
[
	^sigAborts value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> storeTraversals
[
	^storeTraversals value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> gciErrors
[
	^gciErrors value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> lostOtRoots
[
	^lostOtRoots value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> traversalUnpackingTime
[
	^traversalUnpackingTime value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> nbEndResultNoProgress
[
	^nbEndResultNoProgress value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> nbEndResultProgressed
[
	^nbEndResultProgressed value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> traverseCallTime
[
	^traverseCallTime value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> traverseCalls
[
	^traverseCalls value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> bytesSentByStoreTraversal
[

	^bytesSentByStoreTraversal value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> nbEndResultReady
[
	^nbEndResultReady value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> dirtyPoolSize
[
	^session dirtyPoolSize
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> bytesTraversed
[

	^bytesTraversed value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> objectsStoredByTraversal
[
	^objectsStoredByTraversal value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> objectsTraversed
[
	^objectsTraversed value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> changedObjNotifications
[
	^changedObjNotifications value
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> classesMapped
[
	"check for stubs because classes can't be stubs on the client
	and it saves a server trip"

	| count gsObjectCache |
	count := 0.
	gsObjectCache := session serverMap.
	gsObjectCache isNil ifTrue: [^0].
	session sessionCritical: 
			[gsObjectCache delegatesAndClientObjsDo: 
					[:del :clientObj |
					(clientObj zzzisStub not and: [clientObj isBehavior])
						ifTrue: [count := count + 1]]]
		unlessBlocked: [Error signal: 'session blocked'].
	^count
]

{ #category : 'stat accessing' }
GbxSessionStatResource >> serverMapSize
[

	serverMapSize setValue: session serverMap size.
	^serverMapSize value
]

{ #category : 'archiving' }
GbxSessionStatResource >> instanceDescription
[
	^session printString , '-ssn:' 
		, (session 
				unsynchronizedEvaluate: 'GsCurrentSession currentSession sessionSerialNum') 
					printString
]

{ #category : 'archiving' }
GbxSessionStatResource >> writeSampleTo: statArchive
[
	"Poll the serverMapSize before archiving"

	self serverMapSize.
	^super writeSampleTo: statArchive
]

{ #category : 'initialize-release' }
GbxSessionStatResource >> initializeStatistics
[
	super initializeStatistics.
	bytesSentByStoreTraversal := self 
				newGbxStatFor: 'bytesSentByStoreTraversal'
				value: 0.
	bytesTraversed := self newGbxStatFor: 'bytesTraversed' value: 0.
	changedObjNotifications := self newGbxStatFor: 'changedObjNotifications'
				value: 0.
	freeOopsFetched := self newGbxStatFor: 'freeOopsFetched' value: 0.
	gciCallsToGem := self newGbxStatFor: 'gciCallsToGem' value: 0.
	gciCallsToGemTime := self newGbxStatFor: 'gciCallsToGemTime' value: 0.
	gciErrors := self newGbxStatFor: 'gciErrors' value: 0.
	lostOtRoots := self newGbxStatFor: 'lostOtRoots' value: 0.
	nbEndResultNoProgress := self newGbxStatFor: 'nbEndResultNoProgress'
				value: 0.
	nbEndResultProgressed := self newGbxStatFor: 'nbEndResultProgressed'
				value: 0.
	nbEndResultReady := self newGbxStatFor: 'nbEndResultReady' value: 0.
	objectsStoredByTraversal := self newGbxStatFor: 'objectsStoredByTraversal'
				value: 0.
	objectsTraversed := self newGbxStatFor: 'objectsTraversed' value: 0.
	serverMapSize := self newGbxStatFor: 'serverMapSize' value: 0.
	sessionProtectInvocations := self 
				newGbxStatFor: 'sessionProtectInvocations'
				value: 0.
	sessionSignals := self newGbxStatFor: 'sessionSignals' value: 0.
	sigAborts := self newGbxStatFor: 'sigAborts' value: 0.
	storeTraversals := self newGbxStatFor: 'storeTraversals' value: 0.
	traversalUnpackingTime := self newGbxStatFor: 'traversalUnpackingTime'
				value: 0.
	traverseCallTime := self newGbxStatFor: 'traverseCallTime' value: 0.
	traverseCalls := self newGbxStatFor: 'traverseCalls' value: 0
]

{ #category : 'initialize-release' }
GbxSessionStatResource >> session: aGbsSession
[
	session := aGbsSession
]

{ #category : 'class initialization' }
GbxSessionStatResource class >> initialize
[
	"Create GbxStatDescriptors for this stat resource"

	"self initialize"

	statDescriptors := OrderedCollection new.
	self
		addStatDescriptor: (GbxStatDescriptor 
					name: 'bytesSentByStoreTraversal'
					description: 'The number of bytes sent cumulatively by store traversal calls'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'bytesTraversed'
					description: 'The cumulative number of bytes returned by traversal calls'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'changedObjNotifications'
					description: 'The number of changed object notifications received'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'notifications');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'freeOopsFetched'
					description: 'The number of free oops fetched'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'oops');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'gciCallsToGem'
					description: 'The number of gci calls made that communicate with the gem'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'calls to gem');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'gciCallsToGemTime'
					description: 'The amount of time spent in gci calls that communicate with the gem'
					type: GemStone.Gbs.GbxStatArchiver.TypeLong64
					isCounter: true
					isLargerBetter: false
					unit: 'microseconds');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'gciErrors'
					description: 'The number of errors reported by GciErr()'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'errors');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'lostOtRoots'
					description: 'The number of lost ot roots signals received'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'lost ot roots');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'nbEndResultNoProgress'
					description: 'The number of times GciNbEnd() was called when the result wasn''t ready and no progress was made'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'calls');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'nbEndResultProgressed'
					description: 'The number of times GciNbEnd() was called and progress was made'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'calls');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'nbEndResultReady'
					description: 'The number of times GciNbEnd() was called and a result was ready'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'calls');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'objectsStoredByTraversal'
					description: 'The total number of objects stored by store traversal calls'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'objects');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'objectsTraversed'
					description: 'The total number of objects (with or without a value buffer) received by traversal call'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'objects');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'serverMapSize'
					description: 'The number of server objects mapped to client objects and/or delegates by this session''s serverMap'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'entries');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'sessionProtectInvocations'
					description: 'The number of times the sessionProtect semaphore has been invoked'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'invocations');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'sessionSignals'
					description: 'The number of gem-to-gem signals received'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'signals');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'sigAborts'
					description: 'The number of signaled aborts received'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'signaled aborts');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'storeTraversals'
					description: 'The number of store traversal calls made'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'storeTraversals');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'traversalUnpackingTime'
					description: 'The total number of milliseconds spent unpacking traversal buffers'
					type: GemStone.Gbs.GbxStatArchiver.TypeLong64
					isCounter: true
					isLargerBetter: false
					unit: 'microseconds');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'traverseCallTime'
					description: 'The amount of time spent in traversal calls. The first traversal processing in single round trip will not be counted as this is heavily intertwined with execution.'
					type: GemStone.Gbs.GbxStatArchiver.TypeLong64
					isCounter: true
					isLargerBetter: false
					unit: 'microseconds');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'traverseCalls'
					description: 'The number of traversal calls (all types, including more traversal)'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'traversals')
]

{ #category : 'archiving' }
GbxSessionStatResource class >> resourceTypeName
[
	^'GbsSession'
]

{ #category : 'archiving' }
GbxSessionStatResource class >> resourceTypeDescription
[
	^'Statistics associated with a logged in GbsSession'
]

{ #category : 'archiving' }
GbxSessionStatResource class >> resourceTypeId
[
	^1
]

