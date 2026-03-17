Class {
	#name : 'GbxReplicatorManager',
	#superclass : 'Object',
	#instVars : [
		'session',
		'serverMap',
		'clientMap',
		'needServerInstVarNames',
		'replicatorsNeedingServerInstVarNames',
		'clampManager'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'finalizing' }
GbxReplicatorManager >> startingInteraction

	clampManager startingInteraction

{ #category : 'finalizing' }
GbxReplicatorManager >> endingInteraction
	"Sender must hold my session's protect"

	clampManager endingInteraction

{ #category : 'private - deferred updating' }
GbxReplicatorManager >> fetchMissingServerInstVarNames
	"Sender must hold my session's protect semaphore."

	| classDelegates allInstVarNames |
	self semaphoreCheck.
	classDelegates := replicatorsNeedingServerInstVarNames
				collect: [:repl | repl serverClass].
	allInstVarNames := session
				unsynchronizedEvaluateBlock: '[:classes | classes collect:[:each | each  _instVarNames copy]]'
				with: classDelegates.
	replicatorsNeedingServerInstVarNames with: allInstVarNames
		do: [:repl :ivars | repl initializeForServerInstVarNames: ivars]

{ #category : 'replicator creation' }
GbxReplicatorManager >> connectReplicator: aReplicator toServerBehavior: behaviorDelegate
	"Connect only to the server oop. Only for cases where the client is not mapped, for instance a skew replicator."
	"Sender must hold session protect."

	self semaphoreCheck.
	serverMap atOop: behaviorDelegate putClient: aReplicator

{ #category : 'replicator creation' }
GbxReplicatorManager >> mapReplicatorForClientBehavior: clientBehavior serverBehavior: behaviorDelegate
	"Sender must hold session protect."

	| replicatorClass replicator |
	replicatorClass := clientBehavior instancesAreForwarders
				ifTrue: [GbxForwarderReplicator]
				ifFalse: [clientBehavior gbsReplicatorClassInSession: session].
	replicator := replicatorClass
				forClientClass: clientBehavior
				serverClass: behaviorDelegate
				manager: self.
	self atClient: clientBehavior andServer: behaviorDelegate put: replicator.
	clampManager updateClassClampForReplicator: replicator
	"The behavior itself is identity clamped by #clamp:client: when it is mapped."

{ #category : 'accessing' }
GbxReplicatorManager >> session

	^session

{ #category : 'replicator access' }
GbxReplicatorManager >> replicatorForServerBehavior: oopOrDelegate ifAbsentPut: replicatorCreationBlock

	^session sessionCritical: 
			[| resultOfLookup |
			resultOfLookup := serverMap clientAtOop: oopOrDelegate.
			resultOfLookup == NotCachedToken
				ifTrue: 
					[serverMap atOop: oopOrDelegate putClient: replicatorCreationBlock value]
				ifFalse: [resultOfLookup]]

{ #category : 'replicator access' }
GbxReplicatorManager >> numberOfReplicators
	"We don't acquire protect here, so the answer should be close, but adds or removes could be in progress."

	^clientMap size

{ #category : 'replicator access' }
GbxReplicatorManager >> replicatorForServerBehavior: oopOrDelegate ifAbsent: alternativeBlock

	^session sessionCritical: 
			[| resultOfLookup |
			resultOfLookup := serverMap clientAtOop: oopOrDelegate.
			resultOfLookup == NotCachedToken
				ifTrue: [alternativeBlock value]
				ifFalse: [resultOfLookup]]

{ #category : 'replicator access' }
GbxReplicatorManager >> replicatorForClientBehavior: aClientBehavior ifAbsent: alternativeBlock
	"No semaphore needs to be held for this operation."

	^clientMap at: aClientBehavior ifAbsent: alternativeBlock

{ #category : 'replicator access' }
GbxReplicatorManager >> currentReplicators
	"Sender must hold my session's protect semaphore."

	self semaphoreCheck.
	^clientMap values

{ #category : 'replicator access' }
GbxReplicatorManager >> atClient: clientBehavior put: replicator
	"Map only from the client side, not the server side.
	Only used for special cases like delegates, which are not mapped to the server yet have a replicator,
	or for many-to-one mappings."
	"The sender must hold my session's protect semaphore."

	clientMap at: clientBehavior put: replicator

{ #category : 'private' }
GbxReplicatorManager >> semaphoreCheck
	"All access to the replicator mapping dictionaries must be done by a process holding the session's semaphore."

	session hasCriticalAccess
		ifFalse: 
			[self gbsMessenger
				error: 'ReplicatorManager map access without sessionProtect']

{ #category : 'private' }
GbxReplicatorManager >> atClient: clientBehavior andServer: behaviorDelegate put: replicator
	"Sender must hold my protect."

	self semaphoreCheck.
	clientMap at: clientBehavior put: replicator.
	serverMap atOop: behaviorDelegate putClient: replicator

{ #category : 'replicator removing' }
GbxReplicatorManager >> removeReplicatorForClientBehavior: clientBehavior andServerBehavior: behaviorDelegate
	"Sender must hold my session's sessionProtect."

	| clientReplicator serverReplicator |
	self semaphoreCheck.
	clientReplicator := clientMap removeKey: clientBehavior ifAbsent: [].
	serverReplicator := serverMap removeOop: behaviorDelegate.
	
	[clientReplicator == serverReplicator
		or: [clientReplicator == nil or: [serverReplicator == nil]]]
			gbxAssert.
	clientReplicator
		ifNotNil: [clampManager removeClampsForReplicator: clientReplicator]

{ #category : 'replicator removing' }
GbxReplicatorManager >> removeReplicatorForServerBehavior: behaviorDelegate
	"Used when only server -> client mapping exists, not client -> server mapping.
	Such as an unmapped class replicator."
	"Sender must hold my session's protect"

	self semaphoreCheck.
	serverMap removeOop: behaviorDelegate

{ #category : 'replicator interface' }
GbxReplicatorManager >> serverInstVarNamesNeededByReplicator: aReplicator
	"A replicator is telling me that it does not have the names of server instvars.
	I'll batch together all replicators that need this and get them all at once at the next synchronized round trip."
	"Sender must hold my protect semaphore."

	self semaphoreCheck.
	replicatorsNeedingServerInstVarNames add: aReplicator.
	needServerInstVarNames := true

{ #category : 'initialize-release' }
GbxReplicatorManager >> initializeForSession: sess

	session := sess.
	serverMap := GbxBehaviorOopMap newForSession: sess.
	clientMap := GbxConcurrentReadIdentityDictionary new: 300.
	needServerInstVarNames := false.
	replicatorsNeedingServerInstVarNames := OrderedCollection new.
	clampManager := session clampManagerClass forManager: self

{ #category : 'initialize-release' }
GbxReplicatorManager >> initializeFundamentalReplicators
	"Create and map the special one-of-a-kind replicators."
	"Sender must hold my session's protect"

	self semaphoreCheck.
	serverMap atOop: session oopNil
		putClient: (session unauthorizedObjectReplicatorClass newForManager: self)

	"Since oopNil is not a POM oop, and the serverMap is designed to only have POM oops as keys, 
	this storing of nil is a bit odd. Because of the bit patterns, it is stored as POM oop number 0.
	This is unfortunately non-obvious, but it works since there can never be an actual POM object with
	oop number 0, but the dictionary is fine with it. I'm going to leave it this way since putting in 
	special cases in the code would be both more complex and slower."

{ #category : 'initialize-release' }
GbxReplicatorManager >> release
	"The session is logging out. Eliminate any dependency on it being logged in."

	clampManager release

{ #category : 'clamp access' }
GbxReplicatorManager >> defaultReplicationSpecSet: aSymbol
	"Sender must hold my session's protect"

	^clampManager defaultReplicationSpecSet: aSymbol

{ #category : 'clamp access' }
GbxReplicatorManager >> replicationSchemeForSet: setSymbol
	"Sender must hold my session's protect semaphore."

	^clampManager replicationSchemeForSet: setSymbol

{ #category : 'clamp access' }
GbxReplicatorManager >> defaultReplicationSpecSet
	"Sender must hold my session's protect."

	^clampManager defaultReplicationSpecSet

{ #category : 'clamp access' }
GbxReplicatorManager >> removeIdentityClampForClient: aClientObject withDelegate: aDelegate

	^session sessionCritical: 
			[clampManager removeIdentityClampForClient: aClientObject
				withDelegate: aDelegate]

{ #category : 'clamp access' }
GbxReplicatorManager >> usingReplicationSpecSet: setSymbol do: aBlock
	"Evaluate the given nilary block using the given replication spec set name. 
	This does not affect the session's default replication spec set. The given replication spec set is used only in this Smalltalk Process
	(green thread) and only for this session. If the block interacts with any other sessions, the replication spec set
	currently in effect for that session will be used for that interaction. 
	Answers the result of evaluating aBlock."

	^clampManager usingReplicationSpecSet: setSymbol do: aBlock

{ #category : 'clamp access' }
GbxReplicatorManager >> currentReplicationScheme
	"Sender must hold my session's protect"

	^clampManager currentReplicationScheme

{ #category : 'clamp access' }
GbxReplicatorManager >> invalidateSchemeWithSelector: aSelector
	"If I have a scheme identified by aSelector, and it's valid, invalidate it and answer true.
	Otherwise, answer false."

	^clampManager invalidateSchemeWithSelector: aSelector

{ #category : 'clamp access' }
GbxReplicatorManager >> identityClamps

	^clampManager identityClamps

{ #category : 'clamp access' }
GbxReplicatorManager >> addIdentityClampForClient: aClientObject withDelegate: aDelegate

	session sessionCritical: 
			[clampManager addIdentityClampForClient: aClientObject
				withDelegate: aDelegate]

{ #category : 'updating' }
GbxReplicatorManager >> updateServerInstVarNamesForReplicators: replicators
	"The sender must hold my session's protect semaphore."

	| gsInstVarNames |
	gsInstVarNames := self fetchServerInstVarNamesForReplicators: replicators.
	replicators with: gsInstVarNames
		do: [:rep :names | rep initializeForServerInstVarNames: names].
	clampManager updateClampsForReplicators: replicators

{ #category : 'updating' }
GbxReplicatorManager >> fetchServerInstVarNamesForReplicators: replicators
	"Classes is a collection of client classes. The unsynchronizedEvaluateBlock: call allows us to 
	send the client classes as arguments to the server without first getting the gsClasses. 
	We make the classes an Array because we have explicitly 
	created Array's replicator during login."

	| classes |
	classes := replicators collect: [:replicator | replicator clientClass].
	^session
		unsynchronizedEvaluateBlock: '[:classes | classes collect:[:class | class  _instVarNames]]'
		with: classes asArray

{ #category : 'updating' }
GbxReplicatorManager >> changedSelector: aSelector inClass: aClass
	"A metaclass has had a method added, removed, or changed.
	I may need to update my offsets and clamps
	if the method is an instVarMap or a replication spec method, 
	and I have the class mapped."

	aClass withAllSubclasses do: 
			[:class |
			"The lookup is now safe to do without holding the session's protect."
			| replicator |
			replicator := self replicatorForClientBehavior: class soleInstance
						ifAbsent: [nil].
			replicator ~~ nil
				ifTrue: 
					[aSelector = #instVarMap
						ifTrue: [session sessionCritical: [replicator initializeServerOffsets]].
					clampManager changedSelector: aSelector forReplicator: replicator]]

{ #category : 'updating' }
GbxReplicatorManager >> updateClassClampForReplicator: replicator
	"Sender must hold my session's protect"

	clampManager updateClassClampForReplicator: replicator

{ #category : 'updating' }
GbxReplicatorManager >> updateInstVarNamesAndClamps
	"Do any deferred updating that is needed. The only kind of updates that are deferred 
	are those for which server instance variable names are missing, so that these fetches can be batched."

	needServerInstVarNames
		ifTrue: 
			[session sessionCritical: 
					["Check again after getting semaphore."
					needServerInstVarNames
						ifTrue: 
							[self fetchMissingServerInstVarNames.
							clampManager
								updateClampsForReplicators: replicatorsNeedingServerInstVarNames.
							replicatorsNeedingServerInstVarNames := OrderedCollection new.
							needServerInstVarNames := false]]]

{ #category : 'updating' }
GbxReplicatorManager >> changedClampByCallback
	"Sender must hold my session's protect."

	clampManager changedClampByCallback

{ #category : 'instance creation' }
GbxReplicatorManager class >> newForSession: sess

	| inst |
	inst := self new.
	inst initializeForSession: sess.
	^inst

