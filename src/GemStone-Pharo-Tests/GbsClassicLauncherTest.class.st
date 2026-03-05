Class {
	#name : 'GbsClassicLauncherTest',
	#superclass : 'TestCase',
	#instVars : [
		'launcher',
		'previousCurrentSession'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsClassicLauncherTest >> setUp [
	super setUp.
	previousCurrentSession := GbsSessionParameters currentSession.
	launcher := GbsTestableClassicLauncher new
]

{ #category : 'running' }
GbsClassicLauncherTest >> tearDown [
	GbsSessionParameters currentSession: previousCurrentSession.
	super tearDown
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testOpenSystemBrowserUsesSessionForBrowsing [
	| fakeSession |
	fakeSession := Object new.
	launcher forcedSession: fakeSession.

	self assert: launcher openSystemBrowser.
	self assert: launcher openBrowserCalls equals: 1.
	self assert: launcher lastOpenedSession == fakeSession.
	self assert: launcher lastOpenedDictionary isNil.
	self assert: GbsSessionParameters currentSession == fakeSession
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testOpenSystemBrowserWithoutSessionShowsMessage [
	launcher forcedSession: nil.

	self deny: launcher openSystemBrowser.
	self assert: launcher openBrowserCalls equals: 0.
	self assert: launcher infoMessages size equals: 1.
	self assert: launcher infoMessages first equals: 'Select or log into a GemStone session first.'
]

{ #category : 'tests' }
GbsClassicLauncherTest >> testOpenSymbolDictionaryBrowserPassesDictionaryName [
	| fakeSession |
	fakeSession := Object new.
	launcher forcedSession: fakeSession.
	launcher requestedDictionaryName: 'UserGlobals'.

	self assert: launcher openSymbolDictionaryBrowser.
	self assert: launcher openBrowserCalls equals: 1.
	self assert: launcher lastOpenedSession == fakeSession.
	self assert: launcher lastOpenedDictionary equals: 'UserGlobals'
]
