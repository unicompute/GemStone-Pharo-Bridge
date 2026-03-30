Class {
	#name : 'GbxRemainingPortTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousClientMap',
		'previousMemoryPolicy',
		'previousInteractionCount'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbxRemainingPortTest >> setUp [
	super setUp.
	previousClientMap := GBSM clientMap.
	previousMemoryPolicy := GBSM memoryPolicy.
	previousInteractionCount := GBSM sessionsInInteractionCount.
]

{ #category : 'running' }
GbxRemainingPortTest >> tearDown [
	GBSM clientMap: previousClientMap.
	GBSM memoryPolicy: previousMemoryPolicy.
	GBSM sessionsInInteractionCount: previousInteractionCount.
	super tearDown
]

{ #category : 'tests - behavior cache' }
GbxRemainingPortTest >> testBehaviorServerCacheBuildsProtocolMaps [
	| inspector cache instanceProtocols classProtocols |
	inspector := GbxFakeBehaviorCacheInspector new.
	inspector
		theClass: GbxBehaviorCacheFixture;
		theClassName: #GbxBehaviorCacheFixture;
		isAtInstanceSide: true.
	cache := GbxBehaviorServerCache
		on: { #GbxBehaviorCacheFixture }
		inspector: inspector.

	instanceProtocols := cache currentProtocolsFor: #GbxBehaviorCacheFixture.
	self assert: (instanceProtocols includes: 'accessing').
	self assert: ((cache currentSelectorsFor: #GbxBehaviorCacheFixture protocol: 'accessing') includes: #alpha).

	inspector isAtInstanceSide: false.
	classProtocols := cache currentProtocolsFor: #GbxBehaviorCacheFixture.
	self assert: (classProtocols includes: 'examples').
	self assert: ((cache currentSelectorsFor: #GbxBehaviorCacheFixture protocol: 'examples') includes: #gamma)
]

{ #category : 'tests - compatibility' }
GbxRemainingPortTest >> testCompatibilityLayerProvidesFilenameReflectionTimeZoneAndMemoryPolicy [
	| filePath fileName policy zone |
	filePath := '/tmp/gbs-filename-port-test.txt'.
	(FileSystem disk referenceTo: filePath) ensureDelete.
	fileName := GbxFilename named: filePath.
	[
		fileName writeStreamDo: [ :stream | stream nextPutAll: 'ok' ].
		self assert: fileName exists.
		self assert: fileName tail equals: 'gbs-filename-port-test.txt'.
		self assert: (GbxReflection classOf: 1) equals: SmallInteger.
		self assert: ((GbxReflection identityHashOf: Object new) isInteger).

		zone := GbxTimeZone default.
		self assert: (zone offsetAtUTC: DateAndTime now) equals: DateAndTime now offset asSeconds.

		policy := GbsMemoryPolicy new.
		policy noticeOfInstall.
		self assert: GBSM memoryPolicy identicalTo: policy.
		GBSM sessionsInInteractionCount: 1.
		policy incrementalReclamation.
		GBSM sessionsInInteractionCount: 0.
		policy postReplicationAction
	] ensure: [ fileName ensureDelete ]
]

{ #category : 'tests - cache' }
GbxRemainingPortTest >> testConcurrentIdentityDictionaryAndReplicatorManager [
	| dictionary manager replicator |
	dictionary := GbxConcurrentReadIdentityDictionary new: 4.
	dictionary at: Object new put: #value.
	self assert: dictionary size equals: 1.

	manager := GbxReplicatorManager newForSession: nil.
	replicator := Object new.
	manager
		atClient: GbxBehaviorCacheFixture
		andServer: #ServerBehavior
		put: replicator.

	self assert: (manager replicatorForClientBehavior: GbxBehaviorCacheFixture ifAbsent: [ nil ]) identicalTo: replicator.
	self assert: (manager replicatorForServerBehavior: #ServerBehavior ifAbsent: [ nil ]) identicalTo: replicator.
	self assert: manager numberOfReplicators equals: 1.
	manager removeReplicatorForClientBehavior: GbxBehaviorCacheFixture andServerBehavior: #ServerBehavior.
	self assert: manager numberOfReplicators equals: 0
]

{ #category : 'tests - debugger' }
GbxRemainingPortTest >> testContextDumpPolicyAndDebuggerClient [
	| context service client dump stackString |
	context := GbxFakeContextForPolicy new.
	context
		gbxIsServerContext: true;
		methodClass: 'DemoClass';
		selector: #demoSelector;
		processOop: 42.
	service := GbxFakeContextService new.
	service context: context.

	client := GbxDebuggerClient new.
	client service: service.
	self deny: client hasValidClientContext.

	context gbxIsServerContext: false.
	self assert: client hasValidClientContext.

	dump := GbxContextDumpPolicy new.
	dump
		stack: { context };
		errorMessage: 'Boom'.
	stackString := dump copyStackString.
	self assert: (stackString includesSubstring: 'Boom').
	self assert: (stackString includesSubstring: 'DemoClass>>demoSelector')
]

{ #category : 'tests - trippy' }
GbxRemainingPortTest >> testTrippySupportObjectsWorkHeadlessly [
	| page driver segments textObject textInspector element dictionaryInspector keySelection |
	page := GbxFakePageForRemainingPorts new.
	page
		partCount: 25;
		gbxCachedRanges: { 1 to: 10 }.
	driver := GbxSegmentedPageDriver new.
	driver
		page: page;
		segmentSize: 10.
	segments := driver computeSegmentList.

	self deny: segments first isUncached.
	self assert: (segments second isUncached).

	page selectedSegments: { segments second }.
	driver segmentSelectionChanged.
	self assert: page cachedIntervals size equals: 1.
	self assert: page cachedIntervals first equals: (11 to: 20).
	self deny: segments second isUncached.

	textObject := GbxFakeTextObjectForRemainingPorts new.
	textObject text: 'before'.
	textInspector := GbxTextEditorInspector new initialize: textObject.
	self assert: textInspector documentHolder value equals: 'before'.
	textInspector textAccepted: 'after'.
	self assert: textObject text equals: 'after'.
	self assert: textInspector documentHolder value equals: 'after'.

	element := GbxKeyedElement
		of: nil
		key: 'alpha'
		keyName: 'alpha'
		value: 1
		valueName: 'one'.
	dictionaryInspector := GbxTrippyDictionaryInspector new initialize: nil.
	dictionaryInspector
		fieldList: { element };
		selectionIndexes: #(1);
		valueOrKey: #key.
	keySelection := dictionaryInspector selection.
	self assert: keySelection value equals: 'alpha'
]
