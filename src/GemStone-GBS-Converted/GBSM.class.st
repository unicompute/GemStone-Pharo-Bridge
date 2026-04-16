Class {
	#name : 'GBSM',
	#superclass : 'Object',
	#classInstVars : [
		'CurrentSession',
		'MainStatsEnabled',
		'CacheStatsEnabled',
		'ManagerStatResource',
		'ClientMap',
		'MemoryPolicy',
		'SessionsInInteractionCount'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'statistics' }
GBSM class >> cacheSampleIntervalMultiplier [
	^ GbxStatMonitor instance cacheSampleIntervalMultiplier
]

{ #category : 'statistics' }
GBSM class >> cacheSampleIntervalMultiplier: anInteger [
	GbxStatMonitor instance cacheSampleIntervalMultiplier: anInteger
]

{ #category : 'statistics' }
GBSM class >> cacheStatsEnabled [
	^ CacheStatsEnabled ifNil: [ CacheStatsEnabled := false ]
]

{ #category : 'statistics' }
GBSM class >> cacheStatsEnabled: aBoolean [
	CacheStatsEnabled := aBoolean
]

{ #category : 'accessing' }
GBSM class >> clientMap [
	^ ClientMap
]

{ #category : 'accessing' }
GBSM class >> clientMap: anObject [
	ClientMap := anObject
]

{ #category : 'accessing' }
GBSM class >> currentSession [
    ^ GbsSessionParameters currentSession
		ifNil: [ CurrentSession ]
]

{ #category : 'accessing' }
GBSM class >> currentSession: aSession [
    CurrentSession := aSession.
	GbsSessionParameters currentSession: aSession.
	^ aSession
]

{ #category : 'named-objects' }
GBSM class >> globals [
	^ self requireCurrentSession globals
]

{ #category : 'named-objects' }
GBSM class >> published [
	^ self requireCurrentSession published
]

{ #category : 'named-objects' }
GBSM class >> requireCurrentSession [
	^ self currentSession
		ifNil: [ self error: 'No current GemStone session' ]
]

{ #category : 'interactions' }
GBSM class >> beginInteraction [
	self sessionsInInteractionCount: self sessionsInInteractionCount + 1
]

{ #category : 'interactions' }
GBSM class >> endInteraction [
	self sessionsInInteractionCount: (self sessionsInInteractionCount - 1 max: 0)
]

{ #category : 'interactions' }
GBSM class >> hasSessionsInInteractions [
	^ self sessionsInInteractionCount > 0
]

{ #category : 'accessing' }
GBSM class >> loggedInSessions [
	^ GbsSessionManager loggedInSessions
]

{ #category : 'statistics' }
GBSM class >> mainStatsEnabled [
	^ MainStatsEnabled ifNil: [ MainStatsEnabled := false ]
]

{ #category : 'statistics' }
GBSM class >> mainStatsEnabled: aBoolean [
	MainStatsEnabled := aBoolean
]

{ #category : 'accessing' }
GBSM class >> memoryPolicy [
	^ MemoryPolicy
]

{ #category : 'accessing' }
GBSM class >> memoryPolicy: anObject [
	MemoryPolicy := anObject
]

{ #category : 'cleanup' }
GBSM class >> reset [
    CurrentSession := nil.
	GbsSessionParameters currentSession: nil.
	MainStatsEnabled := false.
	CacheStatsEnabled := false.
	ManagerStatResource := nil.
	ClientMap := nil.
	MemoryPolicy := nil.
	SessionsInInteractionCount := 0
]

{ #category : 'ui' }
GBSM class >> showBusyWhile: aBlock [
	^ aBlock value
]

{ #category : 'statistics' }
GBSM class >> statMonitorRunning [
	^ GbxStatMonitor instance isProcessRunning
]

{ #category : 'statistics' }
GBSM class >> statMonitorRunning: aBoolean [
	aBoolean
		ifTrue: [ GbxStatMonitor instance startProcess ]
		ifFalse: [ GbxStatMonitor instance stopProcess ]
]

{ #category : 'statistics' }
GBSM class >> statResource [
	^ ManagerStatResource ifNil: [ ManagerStatResource := GbxSessionManagerStatResource new ]
]

{ #category : 'statistics' }
GBSM class >> statSampleInterval [
	^ GbxStatMonitor instance sampleInterval
]

{ #category : 'statistics' }
GBSM class >> statSampleInterval: milliseconds [
	GbxStatMonitor instance sampleInterval: milliseconds
]

{ #category : 'statistics' }
GBSM class >> statsEnabled [
	^ self mainStatsEnabled or: [ self cacheStatsEnabled ]
]

{ #category : 'statistics' }
GBSM class >> statsEnabled: aBoolean [
	self
		mainStatsEnabled: aBoolean;
		cacheStatsEnabled: aBoolean;
		statMonitorRunning: aBoolean
]

{ #category : 'named-objects' }
GBSM class >> sessionForwarderFor: aSymbol [
	^ self requireCurrentSession sessionForwarderFor: aSymbol
]

{ #category : 'interactions' }
GBSM class >> sessionsInInteractionCount [
	^ SessionsInInteractionCount ifNil: [ SessionsInInteractionCount := 0 ]
]

{ #category : 'interactions' }
GBSM class >> sessionsInInteractionCount: anInteger [
	SessionsInInteractionCount := anInteger max: 0
]

{ #category : 'named-objects' }
GBSM class >> userClasses [
	^ self requireCurrentSession userClasses
]

{ #category : 'named-objects' }
GBSM class >> userGlobals [
	^ self requireCurrentSession userGlobals
]
