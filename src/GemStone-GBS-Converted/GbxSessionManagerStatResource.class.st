Class {
	#name : 'GbxSessionManagerStatResource',
	#superclass : 'GbxStatResource',
	#instVars : [
		'sessionListProtectInvocations',
		'gciCallProtectInvocations',
		'numSessions',
		'stObjectCacheSize',
		'mainStatSampleTime',
		'cacheStatSampleTime'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'class initialization' }
GbxSessionManagerStatResource class >> initialize [
	statDescriptors := OrderedCollection new.
	#(
		('numSessions' 'The number of logged in GbsSessions' 4 false false 'sessions')
		('sessionListProtectInvocations' 'The number of accesses to the sessionListProtect semaphore' 5 true false 'accesses')
		('gciCallProtectInvocations' 'The number of accesses to the GciCallProtect semaphore' 5 true false 'accesses')
		('clientMapSize' 'The number of client objects in the client map.' 5 false false 'entries')
		('mainStatSampleTime' 'The amount of time spent sampling manager and session statistics' 5 true false 'microseconds')
		('cacheStatSampleTime' 'The amount of time spent sampling cache statistics' 5 true false 'microseconds')
	) do: [ :spec |
		self addStatDescriptor: (GbxStatDescriptor
			name: spec first
			description: spec second
			type: spec third
			isCounter: spec fourth
			isLargerBetter: spec fifth
			unit: spec sixth) ]
]

{ #category : 'archiving' }
GbxSessionManagerStatResource class >> resourceTypeId [
	^ 0
]

{ #category : 'archiving' }
GbxSessionManagerStatResource class >> resourceTypeName [
	^ 'GbsSessionManager'
]

{ #category : 'stat accessing' }
GbxSessionManagerStatResource >> clientMapSize [
	| clientMap size |

	clientMap := GBSM clientMap.
	size := (clientMap respondsTo: #size)
		ifTrue: [ clientMap size ]
		ifFalse: [ 0 ].
	self setStatNamed: 'clientMapSize' value: size.
	^ size
]

{ #category : 'archiving' }
GbxSessionManagerStatResource >> instanceDescription [
	^ 'GbsSessionManagerStats'
]

{ #category : 'initialize-release' }
GbxSessionManagerStatResource >> initializeStatistics [
	super initializeStatistics.
	self initializeZeroStatisticsFromDescriptors.
	self setStatNamed: 'numSessions' value: GBSM loggedInSessions size
]

{ #category : 'archiving' }
GbxSessionManagerStatResource >> writeSampleTo: statArchive [
	self setStatNamed: 'numSessions' value: GBSM loggedInSessions size.
	self clientMapSize.
	^ super writeSampleTo: statArchive
]
