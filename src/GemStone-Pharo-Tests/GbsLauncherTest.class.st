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
	| launcher connectedParam disconnectedParam |
	launcher := GbsLauncher new.
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
	| launcher connectedParam otherParam current |
	launcher := GbsLauncher new.
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
