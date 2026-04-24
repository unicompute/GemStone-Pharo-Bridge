Class {
	#name : 'GbxStatsPortTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousMainStatsEnabled',
		'previousCacheStatsEnabled',
		'previousCurrentSession',
		'previousClientMap'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbxStatsPortTest >> setUp [
	super setUp.
	previousMainStatsEnabled := GBSM mainStatsEnabled.
	previousCacheStatsEnabled := GBSM cacheStatsEnabled.
	previousCurrentSession := GBSM currentSession.
	previousClientMap := GBSM clientMap.
	GbxStatMonitor instance stopProcess.
	GBSM reset
]

{ #category : 'running' }
GbxStatsPortTest >> tearDown [
	GbxStatMonitor instance stopProcess.
	GBSM reset.
	GBSM mainStatsEnabled: previousMainStatsEnabled.
	GBSM cacheStatsEnabled: previousCacheStatsEnabled.
	GBSM currentSession: previousCurrentSession.
	GBSM clientMap: previousClientMap.
	super tearDown
]

{ #category : 'tests' }
GbxStatsPortTest >> testBasicCacheInventoryCacheTracksClassesAndResetsStaleStats [
	| cache firstArray secondArray stringValue arrayStats stringStats |
	cache := GbxBasicCache new.
	firstArray := #(1 2).
	secondArray := #(3).
	stringValue := 'abc'.

	cache
		atOop: 101 put: firstArray;
		atOop: 102 put: secondArray;
		atOop: 103 put: stringValue.
	cache inventoryCache.

	arrayStats := cache cachedClassStats at: Array.
	stringStats := cache cachedClassStats at: stringValue class.
	self assert: arrayStats numInstances equals: 2.
	self assert: arrayStats gbsBytesCached equals: firstArray basicSize + secondArray basicSize.
	self assert: stringStats numInstances equals: 1.
	self assert: stringStats gbsBytesCached equals: stringValue basicSize.

	cache oopToProxy removeKey: 102.
	cache proxyToOop removeKey: secondArray ifAbsent: [ ].
	cache oopToProxy removeKey: 103.
	cache proxyToOop removeKey: stringValue ifAbsent: [ ].
	cache inventoryCache.

	self assert: arrayStats numInstances equals: 1.
	self assert: arrayStats gbsBytesCached equals: firstArray basicSize.
	self assert: stringStats numInstances equals: 0.
	self assert: stringStats gbsBytesCached equals: 0
]

{ #category : 'tests' }
GbxStatsPortTest >> testGbsSessionNewUsesStatsSubclassWhenEnabled [
	| withoutStats withStats |
	GBSM mainStatsEnabled: false.
	withoutStats := GbsSession new.
	self assert: withoutStats class equals: GbsSession.

	GBSM mainStatsEnabled: true.
	withStats := GbsSession new.
	self assert: withStats class equals: GbsSessionWithStats.
	self assert: withStats statResource class equals: GbxSessionStatResource
]

{ #category : 'tests' }
GbxStatsPortTest >> testGbsSessionWithStatsMeasureGemCallUpdatesCounters [
	| session stats result |
	session := GbsSessionWithStats new.
	stats := session statResource.

	result := session measureGemCall: [ 42 ].

	self assert: result equals: 42.
	self assert: stats gciCallsToGem equals: 1.
	self assert: stats gciCallsToGemTime >= 0
]

{ #category : 'tests' }
GbxStatsPortTest >> testLargeIdentityDictionaryUsesIdentityKeys [
	| dictionary keyOne keyTwo |
	dictionary := GbxLargeIdentityDictionary new.
	keyOne := 'same' copy.
	keyTwo := 'same' copy.

	self deny: keyOne == keyTwo.
	dictionary at: keyOne put: 1.

	self assert: (dictionary at: keyOne ifAbsent: [ #missing ]) equals: 1.
	self assert: (dictionary at: keyTwo ifAbsent: [ #missing ]) equals: #missing.

	dictionary at: keyTwo put: 2.
	self assert: (dictionary statistics at: #size) equals: 2.
	self assert: (dictionary removeKey: keyOne) equals: 1
]
