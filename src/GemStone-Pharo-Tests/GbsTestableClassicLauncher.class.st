Class {
	#name : 'GbsTestableClassicLauncher',
	#superclass : 'GbsClassicLauncher',
	#instVars : [
		'forcedSession',
		'requestedDictionaryName',
		'infoMessages',
		'lastOpenedSession',
		'lastOpenedDictionary',
		'openBrowserCalls'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'private' }
GbsTestableClassicLauncher >> sessionForBrowsing [
	^ forcedSession
]

{ #category : 'accessing' }
GbsTestableClassicLauncher >> forcedSession: anObject [
	forcedSession := anObject
]

{ #category : 'private' }
GbsTestableClassicLauncher >> requestSymbolDictionaryName [
	^ requestedDictionaryName ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsTestableClassicLauncher >> requestedDictionaryName: aString [
	requestedDictionaryName := aString
]

{ #category : 'private' }
GbsTestableClassicLauncher >> openBrowserOn: aSession dictionary: aDictionaryName [
	openBrowserCalls := self openBrowserCalls + 1.
	lastOpenedSession := aSession.
	lastOpenedDictionary := aDictionaryName.
	^ self
]

{ #category : 'accessing' }
GbsTestableClassicLauncher >> openBrowserCalls [
	^ openBrowserCalls ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbsTestableClassicLauncher >> lastOpenedSession [
	^ lastOpenedSession
]

{ #category : 'accessing' }
GbsTestableClassicLauncher >> lastOpenedDictionary [
	^ lastOpenedDictionary
]

{ #category : 'ui' }
GbsTestableClassicLauncher >> inform: aString [
	self infoMessages add: aString.
	^ aString
]

{ #category : 'accessing' }
GbsTestableClassicLauncher >> infoMessages [
	^ infoMessages ifNil: [ infoMessages := OrderedCollection new ]
]
