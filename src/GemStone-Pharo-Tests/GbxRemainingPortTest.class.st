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

{ #category : 'private' }
GbxRemainingPortTest >> ensureRuntimeOverridesInstalled [
	(GbxOverrideUtility allOverridesInPackage: GbxRuntimeOverrideSpec overridesPackageName) size
		= GbxRuntimeOverrideSpec spec methodOverrides size
		ifTrue: [ ^ self ].
	GbxOverrideUtility removeAllOverridesFromPackage: GbxRuntimeOverrideSpec overridesPackageName.
	GbxRuntimeOverrideSpec apply
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

{ #category : 'tests - replication' }
GbxRemainingPortTest >> testConsiderModifiedMarksMutableReplicatedObjectsDirty [
	| previousConfiguration configuration delegate fixture |
	previousConfiguration := Smalltalk globals at: #GbsCurrentConfiguration ifAbsent: [ nil ].
	[
		configuration := GbsConfiguration new initializeDefaults; yourself.
		configuration autoMarkDirty: true.
		GbsConfiguration current: configuration.
		delegate := GbxDirtyMarkingDelegate new.
		fixture := GbxDirtyMarkingFixture new
			delegate: delegate;
			immutable: false;
			yourself.

		fixture gbxConsiderModified.
		self assert: delegate markedObjects asArray equals: { fixture }.

		fixture immutable: true.
		fixture gbxConsiderModified.
		self assert: delegate markedObjects size equals: 1
	] ensure: [
		previousConfiguration
			ifNil: [ Smalltalk globals removeKey: #GbsCurrentConfiguration ifAbsent: [ ] ]
			ifNotNil: [ Smalltalk globals at: #GbsCurrentConfiguration put: previousConfiguration ] ]
]

{ #category : 'tests - replication' }
GbxRemainingPortTest >> testSessionDirtyPoolTracksActiveStoreTraversals [
	| session traversal |
	session := GbsSession new.
	traversal := Object new.

	session addStoreTraversal: traversal.
	self assert: (session activeStoreTraversals includes: traversal).

	session removeStoreTraversal: traversal.
	self deny: (session activeStoreTraversals includes: traversal)
]

{ #category : 'tests - replication' }
GbxRemainingPortTest >> testStoreTraversalFlushExportsPackedObjectsAfterServerAccepts [
	| session buffer traversal delegate object remaining |
	session := GbxFakeStoreTraversalSession new.
	buffer := GbxFakeTraversalBuffer new.
	traversal := GbxStoreTraversal for: (GbxFakeTraversalInteraction
		serverInterface: (GbxFakeTraversalServerInterface
			session: session
			buffer: buffer)).
	delegate := GbxFakeReplicationDelegate new.
	object := GbxFakeReplicatedObject new
		delegate: delegate;
		yourself.

	traversal packed: object.
	traversal flushBufferToServer.
	remaining := OrderedCollection new.
	traversal emptyPackedNotYetAcceptedInto: remaining.

	self assert: session storedBuffers asArray equals: { buffer }.
	self assert: delegate exportedCount equals: 1.
	self assert: buffer emptyCount equals: 1.
	self assert: remaining isEmpty
]

{ #category : 'tests - replication' }
GbxRemainingPortTest >> testStoreTraversalPackCreatesUnmappedReplicatorInsideSetAside [
	| session buffer traversal delegate object |
	session := GbxFakeStoreTraversalSession new.
	buffer := GbxFakeTraversalBuffer new.
	traversal := GbxStoreTraversal for: (GbxFakeTraversalInteraction
		serverInterface: (GbxFakeTraversalServerInterface
			session: session
			buffer: buffer)).
	delegate := GbxFakeReplicationDelegate new dirty: true; yourself.
	object := GbxFakeReplicatedObject new
		delegate: delegate;
		basicClass: GbxFakeReplicatedObject;
		replicatorClass: GbxFakeUnmappedReplicator;
		yourself.

	traversal pack: object.

	self assert: session setAsideCount equals: 1.
	self assert: session lastCreatedReplicator storeCount equals: 1.
	self assert: session lastCreatedReplicator storedObjects asArray equals: { object }
]

{ #category : 'tests - replication' }
GbxRemainingPortTest >> testStoreTraversalPackSkipsCleanObjects [
	| session buffer traversal delegate object replicator |
	session := GbxFakeStoreTraversalSession new.
	buffer := GbxFakeTraversalBuffer new.
	traversal := GbxStoreTraversal for: (GbxFakeTraversalInteraction
		serverInterface: (GbxFakeTraversalServerInterface
			session: session
			buffer: buffer)).
	replicator := GbxFakeStoreReplicator new.
	session addReplicator: replicator forClient: GbxFakeReplicatedObject.
	delegate := GbxFakeReplicationDelegate new dirty: false; yourself.
	object := GbxFakeReplicatedObject new
		delegate: delegate;
		basicClass: GbxFakeReplicatedObject;
		yourself.

	traversal pack: object.

	self assert: replicator storeCount equals: 0.
	self assert: session setAsideCount equals: 0
]

{ #category : 'tests - replication' }
GbxRemainingPortTest >> testStoreTraversalPackUsesRegisteredReplicatorForDirtyObjects [
	| session buffer traversal delegate object replicator |
	session := GbxFakeStoreTraversalSession new.
	buffer := GbxFakeTraversalBuffer new.
	traversal := GbxStoreTraversal for: (GbxFakeTraversalInteraction
		serverInterface: (GbxFakeTraversalServerInterface
			session: session
			buffer: buffer)).
	replicator := GbxFakeStoreReplicator new.
	session addReplicator: replicator forClient: GbxFakeReplicatedObject.
	delegate := GbxFakeReplicationDelegate new dirty: true; yourself.
	object := GbxFakeReplicatedObject new
		delegate: delegate;
		basicClass: GbxFakeReplicatedObject;
		yourself.

	traversal pack: object.

	self assert: replicator storeCount equals: 1.
	self assert: replicator storedObjects asArray equals: { object }.
	self assert: session setAsideCount equals: 0
]

{ #category : 'tests - replication' }
GbxRemainingPortTest >> testStoreTraversalRegistersAndReleasesWithSession [
	| session buffer traversal |
	session := GbxFakeStoreTraversalSession new.
	buffer := GbxFakeTraversalBuffer new.
	traversal := GbxStoreTraversal for: (GbxFakeTraversalInteraction
		serverInterface: (GbxFakeTraversalServerInterface
			session: session
			buffer: buffer)).

	self assert: session addedTraversals asArray equals: { traversal }.

	traversal release.

	self assert: session removedTraversals asArray equals: { traversal }.
	self assert: buffer unlockCount equals: 1
]

{ #category : 'tests - replication' }
GbxRemainingPortTest >> testRuntimeCollectionMutationsMarkReplicatedCollectionsDirty [
	| previousConfiguration configuration delegate ordered dictionary set |
	self ensureRuntimeOverridesInstalled.
	previousConfiguration := Smalltalk globals at: #GbsCurrentConfiguration ifAbsent: [ nil ].
	[
		configuration := GbsConfiguration new initializeDefaults; yourself.
		configuration autoMarkDirty: true.
		GbsConfiguration current: configuration.
		delegate := GbxDirtyMarkingDelegate new.
		ordered := GbxDirtyOrderedCollectionFixture new
			delegate: delegate;
			immutable: false;
			yourself.
		dictionary := GbxDirtyDictionaryFixture new
			delegate: delegate;
			immutable: false;
			yourself.
		set := GbxDirtySetFixture new
			delegate: delegate;
			immutable: false;
			yourself.

		ordered add: #alpha.
		ordered remove: #alpha ifAbsent: [ self fail ].
		dictionary at: #alpha put: #beta.
		dictionary at: #alpha put: #gamma.
		set add: #alpha.
		set add: #alpha.
		set remove: #alpha ifAbsent: [ self fail ].

		self assert: ((delegate markedObjects select: [ :each | each == ordered ]) size) equals: 2.
		self assert: ((delegate markedObjects select: [ :each | each == dictionary ]) size) equals: 2.
		self assert: ((delegate markedObjects select: [ :each | each == set ]) size) equals: 2
	] ensure: [
		previousConfiguration
			ifNil: [ Smalltalk globals removeKey: #GbsCurrentConfiguration ifAbsent: [ ] ]
			ifNotNil: [ Smalltalk globals at: #GbsCurrentConfiguration put: previousConfiguration ] ]
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

{ #category : 'tests - dirty pool' }
GbxRemainingPortTest >> testSetAsideDirtyWhileIsolatesNestedDirtyMarks [
	"Inside the set-aside block the top dirty pool must be empty, even though an object was dirty before."
	| session pool outer innerTopWasEmpty |
	session := GbxFakeSetAsideDirtySession new.
	pool := session dirtyPool.
	outer := Object new.
	pool markDirty: outer.

	pool setAsideDirtyWhile: [ innerTopWasEmpty := pool dirtyAwaitingPacking isEmpty ].

	self assert: innerTopWasEmpty.
	self assert: (pool dirtyAwaitingPacking includes: outer)
]

{ #category : 'tests - dirty pool' }
GbxRemainingPortTest >> testSetAsideDirtyWhileRestoresPreviousPool [
	"After the block, the previous dirty pool (and its objects) must be restored and the stack emptied."
	| session pool outer |
	session := GbxFakeSetAsideDirtySession new.
	pool := session dirtyPool.
	outer := Object new.
	pool markDirty: outer.

	pool setAsideDirtyWhile: [ pool markDirty: Object new ].

	self assert: (pool dirtyAwaitingPacking includes: outer).
	self deny: session flushedObjects isEmpty.
	self assert: session flushCount equals: 1
]

{ #category : 'tests - dirty pool' }
GbxRemainingPortTest >> testSetAsideDirtyWhileFlushesNestedDirtyObjects [
	"Objects dirtied inside the set-aside block are flushed in their own pass and do not pollute the
	restored outer pool."
	| session pool outer nested |
	session := GbxFakeSetAsideDirtySession new.
	pool := session dirtyPool.
	outer := Object new.
	nested := Object new.
	pool markDirty: outer.

	pool setAsideDirtyWhile: [ pool markDirty: nested ].

	self assert: (session flushedObjects includes: nested).
	self deny: (session flushedObjects includes: outer).
	self assert: (pool dirtyAwaitingPacking includes: outer).
	self deny: (pool dirtyAwaitingPacking includes: nested)
]

{ #category : 'tests - dirty pool' }
GbxRemainingPortTest >> testSetAsideDirtyWhileSkipsFlushWhenNoNestedDirty [
	"A set-aside block that dirties nothing must not trigger a flush."
	| session pool |
	session := GbxFakeSetAsideDirtySession new.
	pool := session dirtyPool.

	pool setAsideDirtyWhile: [ 42 ].

	self assert: session flushCount equals: 0
]
