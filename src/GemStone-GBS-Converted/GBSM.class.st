Class {
	#name : 'GBSM',
	#superclass : 'Object',
	#classInstVars : [
		'CurrentSession',
		'MainStatsEnabled',
		'CacheStatsEnabled',
		'ManagerStatResource',
		'ClientMap'
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
    ^ CurrentSession
]

{ #category : 'accessing' }
GBSM class >> currentSession: aSession [
    CurrentSession := aSession
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

{ #category : 'cleanup' }
GBSM class >> reset [
    CurrentSession := nil.
	MainStatsEnabled := false.
	CacheStatsEnabled := false.
	ManagerStatResource := nil.
	ClientMap := nil
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
