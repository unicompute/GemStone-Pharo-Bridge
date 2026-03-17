Class {
	#name : 'GbxClampManager',
	#superclass : 'Object',
	#instVars : [
		'classClamps',
		'defaultReplicationScheme',
		'identityClamps',
		'manager',
		'replicationSchemes',
		'threadSpecificSchemes'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'finalizing' }
GbxClampManager >> endingInteraction
	"Sender must hold my session's protect"

	identityClamps beWeak

{ #category : 'finalizing' }
GbxClampManager >> startingInteraction

	identityClamps beStrongAndFinalized

{ #category : 'accessing' }
GbxClampManager >> changedSelector: aSelector forReplicator: replicator
	"A method with the given selector has been added, removed, or changed in the client metaclass for the given replicator.
	If the selector is the selector of a replication scheme, we need to update the instVarLevels for that scheme."

	| scheme |
	aSelector = #instancesAreForwarders
		ifTrue: 
			[self session
				sessionCritical: [self updateClassClampForReplicator: replicator]]
		ifFalse: 
			["It is now safe to look up a scheme without holding the session protect semaphore.
			This allows the saving of unrelated class methods while debugging inside of a session's critical section."
			scheme := replicationSchemes at: aSelector ifAbsent: [^self].
			self session
				sessionCritical: [replicator updateInstVarLevelsOfScheme: scheme]]

{ #category : 'accessing' }
GbxClampManager >> updateClassClampForReplicators: replicators
	"Sender must hold my session's protect"

	replicators
		do: [:replicator | self updateClassClampForReplicator: replicator]

{ #category : 'accessing' }
GbxClampManager >> usingReplicationSpecSet: setSymbol do: aBlock
	"Evaluate the given nilary block using the given replication spec set name. 
	This does not affect the session's default replication spec set. The given replication spec set is used only in this Smalltalk Process
	(green thread) and only for this session. If the block interacts with any other sessions, the replication spec set
	currently in effect for that session will be used for that interaction. 
	Answers the result of evaluating aBlock."

	| scheme previousScheme result |
	self session sessionCritical: 
			[scheme := self replicationSchemeForSet: setSymbol.
			previousScheme := threadSpecificSchemes value].
	"previousScheme will be nil at this point if no thread-specific spec set is currently in effect for this thread."
	
	[self session sessionCritical: [threadSpecificSchemes value: scheme].
	"We do *not* want to be holding sessionProtect during the entire block. That would defeat the purpose.
	But we do need to hold it whenever accessing threadSpecificSchemes."
	result := aBlock value]
			ensure: 
				[self session sessionCriticalNoSessionCheck: 
						[threadSpecificSchemes value: previousScheme
						"Don't check the session when restoring previous scheme, in case the session 
						has logged out during evaluating the block."]].
	^result

{ #category : 'accessing' }
GbxClampManager >> currentReplicationScheme
	"Answer the replication scheme currently in use by the current thread.
	If the thread doesn't have a special one, then the default one for the session.
	If the session hasn't set one, create one for selector #replicationSpec."
	"Sender must hold my session's protect"

	| scheme |
	scheme := threadSpecificSchemes value.
	^scheme ifNil: [self defaultReplicationScheme]

{ #category : 'accessing' }
GbxClampManager >> defaultReplicationSpecSet
	"Answer the session-wide default replication spec set, which may be overridden on a thread-specific basis."
	"Sender must hold my session's protect."

	^self defaultReplicationScheme selector

{ #category : 'accessing' }
GbxClampManager >> defaultReplicationSpecSet: aSymbol
	"Set the session-wide default replication spec set, which may be overridden on a thread-specific basis."
	"Sender must hold my session's protect."

	defaultReplicationScheme := self replicationSchemeForSet: aSymbol

{ #category : 'accessing' }
GbxClampManager >> identityClamps

	^identityClamps

{ #category : 'accessing' }
GbxClampManager >> invalidateSchemeWithSelector: aSelector
	"If I have a scheme identified by aSelector, and it's valid, invalidate it and answer true.
	Otherwise, answer false."

	| scheme |
	scheme := replicationSchemes at: aSelector ifAbsent: [^false].
	replicationSchemes removeKey: aSelector
		ifAbsent: [self gbsMessenger error: 'It was just here!'].
	defaultReplicationScheme == scheme
		ifTrue: 
			[defaultReplicationScheme := replicationSchemes at: #replicationSpec
						ifAbsent: 
							[self gbsMessenger
								error: 'GBS fatal error. Has someone removed Object class >> replicationSpec?']].
	^scheme invalidate

{ #category : 'accessing' }
GbxClampManager >> removeClampsForReplicator: replicator
	"Do a full update of the clamps for the given replicators, as if they're new (which they probably are)."
	"Sender must hold my session's protect semaphore."

	| clientClass |
	clientClass := replicator clientClass.
	identityClamps removeIfPresent: clientClass.
	classClamps removeIfPresent: clientClass.
	replicationSchemes
		do: [:scheme | scheme removeInstVarLevelsForClass: clientClass]

{ #category : 'accessing' }
GbxClampManager >> removeIdentityClampForClient: aClientObject withDelegate: aDelegate
	"Private.  Remove <anObject> from the list of 'id' clamps in the clamp specification.
	If not present, ignore."

	aDelegate clearIdentityClampedBit.
	identityClamps removeIfPresent: aClientObject.
	^aClientObject

{ #category : 'accessing' }
GbxClampManager >> replicationSchemeForSet: setSelector
	"Sender must hold my session's protect semaphore."

	^setSelector == nil
		ifTrue: [GbxNullReplicationScheme new]
		ifFalse: 
			[replicationSchemes at: setSelector
				ifAbsent: [self createAndInstallReplicationSchemeFor: setSelector]]

{ #category : 'accessing' }
GbxClampManager >> manager: aReplicatorManager

	manager := aReplicatorManager

{ #category : 'accessing' }
GbxClampManager >> addIdentityClampForClient: aClientObject withDelegate: aDelegate
	"Private.  Add the object to the list of 'id' clamps in all of my clamp specifications."

	identityClamps add: aClientObject.
	aDelegate setIdentityClampedBit

{ #category : 'accessing' }
GbxClampManager >> changedClampByCallback
	"The session's Clamp by Callback configuration has changed.
	 Update all Clamp Specifications to reflect this."
	"Sender must hold my session's protect."

	| clampByCallback |
	clampByCallback := self shouldClampByCallback.
	replicationSchemes do: 
			[:scheme |
			scheme updateForClampingByCallback: clampByCallback inSession: self session]

{ #category : 'accessing' }
GbxClampManager >> updateClampsForReplicators: replicators
	"Do a full update of the clamps for the given replicators, as if they're new (which they probably are)."
	"Sender must hold my session's protect semaphore."

	self updateClassClampForReplicators: replicators.
	replicationSchemes do: 
			[:scheme |
			replicators
				do: [:replicator | replicator updateInstVarLevelsOfScheme: scheme]]

{ #category : 'accessing' }
GbxClampManager >> updateClassClampForReplicator: replicator
	"Sender must hold my session's protect"

	| clientClass |
	clientClass := replicator clientClass.
	clientClass ~~ #NoClientClass
		ifTrue: 
			[replicator shouldBeClassClamped
				ifTrue: [classClamps add: clientClass]
				ifFalse: [classClamps removeIfPresent: clientClass]]

{ #category : 'initialize-release' }
GbxClampManager >> initialize

	classClamps := GbxClassSet new: 500.
	identityClamps := GbxIdentityClampSet new: 500.
	replicationSchemes := GbxConcurrentReadIdentityDictionary new: 1.
	threadSpecificSchemes := GbxThreadStateDictionary new

{ #category : 'initialize-release' }
GbxClampManager >> release
	"The session is logging out. Eliminate any dependency on it being logged in."

	identityClamps release

{ #category : 'private' }
GbxClampManager >> createReplicationSchemeFor: replicationSet
	"Private"
	"Sender must hold session's protect"

	^GbxReplicationScheme
		newForSelector: replicationSet
		identityClamps: identityClamps
		classClamps: classClamps
		clampByCallback: self shouldClampByCallback
		inSession: self session

{ #category : 'private' }
GbxClampManager >> createAndInstallReplicationSchemeFor: setSelector
	"Sender must hold my session's protect"

	| scheme |
	self validateSpecSet: setSelector.
	self gbsMessenger
		statusTag: ('createReplicationSchemeFor:' , setSelector) asSymbol
		message: '(s%1) GbxClampManager>>createAndInstallReplicationSchemeFor: #%2'
		with: self session sessionId
		with: setSelector.
	scheme := self createReplicationSchemeFor: setSelector.
	replicationSchemes at: setSelector put: scheme.
	manager currentReplicators
		do: [:replicator | replicator updateInstVarLevelsOfScheme: scheme].
	self gbsMessenger
		statusTag: nil
		message: '(s%1) completed GbxClampManager>>createAndInstallReplicationSchemeFor:; result = %2'
		with: self session sessionId
		with: scheme.
	^scheme

{ #category : 'private' }
GbxClampManager >> session

	^manager session

{ #category : 'private' }
GbxClampManager >> validateSpecSet: aSymbol
	"Signal an error if aSymbol is not suitable as a replicationSpecSet selector."

	aSymbol isSymbol
		ifFalse: 
			[^self gbsMessenger
				error: 'A replication spec set selector must be symbol, not %1'
				with: aSymbol].
	(Object class canUnderstand: aSymbol)
		ifFalse: 
			[^self gbsMessenger
				error: 'In order to use #%1 as a replicationSpecSet, you must provide a default implementation in Object class'
				with: aSymbol]

{ #category : 'private' }
GbxClampManager >> shouldClampByCallback

	^self session clampByCallback

{ #category : 'private' }
GbxClampManager >> defaultReplicationScheme
	"Answer the session-wide default replication scheme, which may be overridden on a thread-specific basis."
	"Sender must hold my session's protect."

	^defaultReplicationScheme
		ifNil: 
			[self defaultReplicationSpecSet: #replicationSpec.
			defaultReplicationScheme]

{ #category : 'instance creation' }
GbxClampManager class >> forManager: aReplicatorManager

	^self new initialize manager: aReplicatorManager

