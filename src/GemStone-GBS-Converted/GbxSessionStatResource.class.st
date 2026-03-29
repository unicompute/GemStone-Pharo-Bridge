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
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'class initialization' }
GbxSessionStatResource class >> initialize [
	statDescriptors := OrderedCollection new.
	#(
		('bytesSentByStoreTraversal' 'The number of bytes sent cumulatively by store traversal calls' 5 true false 'bytes')
		('bytesTraversed' 'The cumulative number of bytes returned by traversal calls' 5 true false 'bytes')
		('changedObjNotifications' 'The number of changed object notifications received' 5 true false 'notifications')
		('freeOopsFetched' 'The number of free oops fetched' 5 true false 'oops')
		('gciCallsToGem' 'The number of gci calls made that communicate with the gem' 5 true false 'calls to gem')
		('gciCallsToGemTime' 'The amount of time spent in gci calls that communicate with the gem' 6 true false 'microseconds')
		('gciErrors' 'The number of errors reported by GciErr()' 5 true false 'errors')
		('lostOtRoots' 'The number of lost ot roots signals received' 5 true false 'lost ot roots')
		('nbEndResultNoProgress' 'The number of times GciNbEnd() was called when the result was not ready and no progress was made' 5 true false 'calls')
		('nbEndResultProgressed' 'The number of times GciNbEnd() was called and progress was made' 5 true false 'calls')
		('nbEndResultReady' 'The number of times GciNbEnd() was called and a result was ready' 5 true false 'calls')
		('objectsStoredByTraversal' 'The total number of objects stored by store traversal calls' 5 true false 'objects')
		('objectsTraversed' 'The total number of objects received by traversal calls' 5 true false 'objects')
		('serverMapSize' 'The number of server objects mapped by this session' 5 false false 'entries')
		('sessionProtectInvocations' 'The number of times the sessionProtect semaphore has been invoked' 5 true false 'invocations')
		('sessionSignals' 'The number of gem-to-gem signals received' 5 true false 'signals')
		('sigAborts' 'The number of signaled aborts received' 5 true false 'signaled aborts')
		('storeTraversals' 'The number of store traversal calls made' 5 true false 'storeTraversals')
		('traversalUnpackingTime' 'The total time spent unpacking traversal buffers' 6 true false 'microseconds')
		('traverseCallTime' 'The amount of time spent in traversal calls' 6 true false 'microseconds')
		('traverseCalls' 'The number of traversal calls, including moreTraversal' 5 true false 'traversals')
	) do: [ :spec |
		self addStatDescriptor: (GbxStatDescriptor
			name: spec first
			description: spec second
			type: spec third
			isCounter: spec fourth
			isLargerBetter: spec fifth
			unit: spec sixth) ]
]

{ #category : 'initialize-release' }
GbxSessionStatResource >> initializeStatistics [
	super initializeStatistics.
	self initializeZeroStatisticsFromDescriptors
]

{ #category : 'archiving' }
GbxSessionStatResource >> instanceDescription [
	| serial |

	serial := (session respondsTo: #sessionId)
		ifTrue: [ session sessionId ]
		ifFalse: [ nil ].
	^ session ifNil: [ 'DetachedSessionStats' ] ifNotNil: [
		serial
			ifNil: [ session printString ]
			ifNotNil: [ session printString, '-ssn:', serial printString ] ]
]

{ #category : 'archiving' }
GbxSessionStatResource class >> resourceTypeId [
	^ 1
]

{ #category : 'archiving' }
GbxSessionStatResource class >> resourceTypeName [
	^ 'GbsSession'
]

{ #category : 'accessing' }
GbxSessionStatResource >> serverMapSize [
	| size |

	size := (session notNil and: [ session respondsTo: #serverMapSize ])
		ifTrue: [ session serverMapSize ]
		ifFalse: [ self valueOfStatNamed: 'serverMapSize' ].
	self setStatNamed: 'serverMapSize' value: size.
	^ size
]

{ #category : 'accessing' }
GbxSessionStatResource >> session [
	^ session
]

{ #category : 'accessing' }
GbxSessionStatResource >> session: aSession [
	session := aSession
]

{ #category : 'archiving' }
GbxSessionStatResource >> writeSampleTo: statArchive [
	self serverMapSize.
	^ super writeSampleTo: statArchive
]
