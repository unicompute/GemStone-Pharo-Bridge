Class {
	#name : #'GbxReplicationScheme',
	#superclass : #'GbxAbstractReplicationScheme',
	#instVars : [ #'clamp' #'indexedInstvarsShouldBeForwardersDict' #'selector' #'forwarderOffsetsDict' #'isValid' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'updating' }
GbxReplicationScheme >> updateForClampingByCallback: aBoolean inSession: aSession
	"Update my Clamp Specification to reflect aBoolean, the current Clamp by Callback setting."

	clamp instVarLevelsSelector: (self
				determineInstVarLevelsSelectorForClampByCallback: aBoolean
				inSession: aSession)

{ #category : #'updating' }
GbxReplicationScheme >> replaceInstVarLevelsForClass: clientClass with: instVarLevels

	clamp replaceInstVarLevelsForClass: clientClass with: instVarLevels

{ #category : #'updating' }
GbxReplicationScheme >> replaceIndexedInstvarsShoudBeForwardersForClass: clientClass with: aBooleanOrNil

	aBooleanOrNil == nil
		ifTrue: 
			[indexedInstvarsShouldBeForwardersDict removeKey: clientClass ifAbsent: []]
		ifFalse: 
			[indexedInstvarsShouldBeForwardersDict at: clientClass put: aBooleanOrNil]

{ #category : #'updating' }
GbxReplicationScheme >> removeInstVarLevelsForClass: clientClass

	clamp removeInstVarLevelsForClass: clientClass.
	forwarderOffsetsDict removeKey: clientClass ifAbsent: [].
	indexedInstvarsShouldBeForwardersDict removeKey: clientClass ifAbsent: []

{ #category : #'updating' }
GbxReplicationScheme >> replaceForwarderOffsetsForClass: clientClass with: forwarderOffsets

	forwarderOffsets == nil
		ifTrue: [forwarderOffsetsDict removeKey: clientClass ifAbsent: []]
		ifFalse: [forwarderOffsetsDict at: clientClass put: forwarderOffsets]

{ #category : #'updating' }
GbxReplicationScheme >> removeArtefactsForClass: aClass

	self
		updateInstVarLevels: nil
		forwarderOffsets: nil
		forwardIndexedPart: nil
		forClass: aClass

{ #category : #'updating' }
GbxReplicationScheme >> updateInstVarLevels: instVarLevels forwarderOffsets: forwarderOffsets forwardIndexedPart: indexedShouldBeForwarders forClass: clientClass

	self
		replaceInstVarLevelsForClass: clientClass with: instVarLevels;
		replaceForwarderOffsetsForClass: clientClass with: forwarderOffsets;
		replaceIndexedInstvarsShoudBeForwardersForClass: clientClass
			with: indexedShouldBeForwarders

{ #category : #'accessing' }
GbxReplicationScheme >> determineInstVarLevelsSelectorForClampByCallback: aBoolean inSession: aSession
	"Answer the appropriate selector for the server's Clamp by Callback.
	 There is no callback selector if Clamp by Callback is off,
	 nor for the special case of a Transitive Closure replication spec."

	| clampByCallbackSelector |
	aBoolean ifFalse: [^nil].
	selector == #transitiveClosureSpec ifTrue: [^nil].
	clampByCallbackSelector := (self selector , 'GbsClampCallback') asSymbol.
	self validateClampByCallbackSelector: clampByCallbackSelector
		inSession: aSession.
	^clampByCallbackSelector

{ #category : #'accessing' }
GbxReplicationScheme >> clamp: aClampSpec

	clamp := aClampSpec

{ #category : #'accessing' }
GbxReplicationScheme >> clamp

	isValid
		ifFalse: 
			[self gbsMessenger
				error: 'Attempt to use a replication spec set that is no longer valid, possibly because its definition method in Object class has been removed.'].
	^clamp

{ #category : #'accessing' }
GbxReplicationScheme >> indexedInstvarsShouldBeForwardersInClass: clientClass

	^indexedInstvarsShouldBeForwardersDict at: clientClass

{ #category : #'accessing' }
GbxReplicationScheme >> selector: aSymbol

	selector := aSymbol

{ #category : #'accessing' }
GbxReplicationScheme >> forwarderOffsetsForClass: clientClass

	^forwarderOffsetsDict at: clientClass ifAbsent: [#()]

{ #category : #'accessing' }
GbxReplicationScheme >> selector

	^selector

{ #category : #'accessing' }
GbxReplicationScheme >> validateClampByCallbackSelector: clampByCallbackSelector inSession: aSession
	"This is a simplistic test. If Object instances can understand the selector,
	 we assume/hope that the developer has done a good job of implementing
	 everywhere on the server that it is needed and that it correctly provides the
	 appropriate instVarLevels results when called."

	((SpecialGemStoneObjects.OObject asGSObjectInSession: aSession)
		unsynchronizedPerformOnGsServer: #canUnderstand:
		withArgs: (Array with: clampByCallbackSelector)) ifTrue: [^self].
	self gbsMessenger
		raise: Error
		message: 'The configuration option #clampByCallback for the replication scheme "%2" requires the default server method Object>>#%1 to exist.'
		with: clampByCallbackSelector
		with: self selector

{ #category : #'testing' }
GbxReplicationScheme >> isValid
	^ isValid

{ #category : #'testing' }
GbxReplicationScheme >> invalidate
	"If valid, invalidate and answer true.
	If invalid, answer false."

	| result |
	result := isValid.
	isValid := false.
	^result

{ #category : #'testing' }
GbxReplicationScheme >> usesClamps

	^true

{ #category : #'printing' }
GbxReplicationScheme >> printOn: aStream

	aStream
		nextPutAll: 'Replication Scheme ';
		nextPutAll: selector

{ #category : #'initialize-release' }
GbxReplicationScheme >> initializeForIdentityClamps: identityClamps classClamps: classClamps

	clamp := GbxClampSpecification newWithIdentityClampsHolder: identityClamps
				classClamps: classClamps.
	forwarderOffsetsDict := IdentityDictionary new.
	indexedInstvarsShouldBeForwardersDict := IdentityDictionary new.
	isValid := true

{ #category : #'instance creation' }
GbxReplicationScheme class >> newForSelector: replicationSet identityClamps: identityClamps classClamps: classClamps clampByCallback: aBoolean inSession: aSession

	^(self new)
		selector: replicationSet;
		initializeForIdentityClamps: identityClamps classClamps: classClamps;
		updateForClampingByCallback: aBoolean inSession: aSession;
		yourself

