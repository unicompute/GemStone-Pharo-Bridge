Class {
	#name : 'GbsLauncherTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousCurrentSession',
		'previousSessions'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsLauncherTest >> setUp [
	super setUp.
	previousCurrentSession := GbsSessionParameters currentSession.
	previousSessions := GbsSessionParameters allSessions copy.
	GbsSessionParameters allSessions removeAll.
	GbsSessionParameters currentSession: nil
]

{ #category : 'running' }
GbsLauncherTest >> tearDown [
	GbsSessionParameters currentSession: previousCurrentSession.
	GbsSessionParameters allSessions removeAll.
	GbsSessionParameters allSessions addAll: previousSessions.
	super tearDown
]

{ #category : 'tests' }
GbsLauncherTest >> testActiveSessionParametersFallsBackToConnectedRegistryEntry [
	| connectedParam disconnectedParam launcher |
	launcher := GbsLauncher basicNew.
	connectedParam := GbsSessionParameters new.
	connectedParam gemStoneName: 'gs64stone'.
	connectedParam instVarNamed: 'sessionId' put: 123.
	disconnectedParam := GbsSessionParameters new.
	disconnectedParam gemStoneName: 'otherStone'.
	GbsSessionParameters allSessions
		add: disconnectedParam;
		add: connectedParam.
	self assert: launcher activeSessionParameters == connectedParam
]

{ #category : 'tests' }
GbsLauncherTest >> testActiveSessionParametersUsesCurrentSessionIdMatch [
	| connectedParam current launcher otherParam |
	launcher := GbsLauncher basicNew.
	otherParam := GbsSessionParameters new.
	otherParam gemStoneName: 'otherStone'.
	otherParam instVarNamed: 'sessionId' put: 7.
	connectedParam := GbsSessionParameters new.
	connectedParam gemStoneName: 'gs64stone'.
	connectedParam instVarNamed: 'sessionId' put: 123.
	GbsSessionParameters allSessions
		add: otherParam;
		add: connectedParam.
	current := MockGbsSession new.
	current sessionId: 123.
	current isLoggedIn: true.
	GbsSessionParameters currentSession: current.
	self assert: launcher activeSessionParameters == connectedParam
]

{ #category : 'tests' }
GbsLauncherTest >> testAllSessionsRemovesClosureCandidate [
	GbsSessionParameters allSessions add: [ :ignored | ignored ].
	self assert: GbsSessionParameters allSessions isEmpty
]

{ #category : 'tests' }
GbsLauncherTest >> testAdminSessionSupportResolvesLiveSessionFromParameterRecord [
	| params liveSession resolved |
	[
		GBSM reset.
		params := GbsSessionParameters new.
		params sessionId: 7.
		liveSession := MockGbsSession new.
		liveSession
			sessionId: 7;
			isLoggedIn: true.
		GBSM manager privAddSession: liveSession.
		GbsSessionParameters currentSession: params.

		resolved := GbsAdminSessionSupport currentUsableSession.

		self assert: resolved == liveSession.
		self assert: GbsSessionParameters currentSession == liveSession
	] ensure: [ GBSM reset ]
]

{ #category : 'tests' }
GbsLauncherTest >> testAdminSessionSupportFallsBackToConnectedRegistryEntryWhenCurrentMissing [
	| params liveSession resolved |
	[
		GBSM reset.
		params := GbsSessionParameters new.
		params sessionId: 8.
		GbsSessionParameters registerSession: params.
		liveSession := MockGbsSession new.
		liveSession
			sessionId: 8;
			isLoggedIn: true.
		GBSM manager privAddSession: liveSession.
		GbsSessionParameters currentSession: nil.

		resolved := GbsAdminSessionSupport currentUsableSession.

		self assert: resolved == liveSession.
		self assert: GbsSessionParameters currentSession == liveSession
	] ensure: [ GBSM reset ]
]

{ #category : 'tests' }
GbsLauncherTest >> testReplicatorManagerKeepsRuntimeApiAndShape [
	self assert: (GbxReplicatorManager respondsTo: #newForSession:).
	self
		assert: GbxReplicatorManager instVarNames
		equals: #(session serverMap clientMap needServerInstVarNames replicatorsNeedingServerInstVarNames clampManager).
	self assert: (Smalltalk at: #GbxReplicatorManagerTool ifAbsent: [ nil ]) notNil
]

{ #category : 'tests' }
GbsLauncherTest >> testStatsClassesKeepRuntimeApiAndToolVariants [
	self
		assert: (GbxStatDescriptor respondsTo: #name:description:type:isCounter:isLargerBetter:unit:).
	self
		assert: GbxStatDescriptor instVarNames
		equals: #(type id name description isCounter isLargerBetter unit category statClass).
	self
		assert: GbxStatResource instVarNames
		equals: #(instanceId stats).
	self assert: GbxStatMonitor superclass equals: Object.
	self
		assert: GbxStatMonitor instVarNames
		equals: #(process state stateChangeProtect nextResumption delay archiver sampleInterval cacheSampleIntervalMultiplier).
	self assert: (GbxStatMonitor respondsTo: #instance).
	self assert: (Smalltalk at: #GbxToolStat ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxToolStatDescriptor ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxToolStatResource ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxToolStatMonitor ifAbsent: [ nil ]) notNil.
	self assert: (Smalltalk at: #GbxToolSessionStatResource ifAbsent: [ nil ]) notNil
]
