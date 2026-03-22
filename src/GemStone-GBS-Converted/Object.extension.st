Extension { #name : 'Object' }

{ #category : '*GemStone-GBS-Converted-messenger' }
Object >> cstMessenger [
	^ CstMessageDispatcher singleton
]

{ #category : '*GemStone-GBS-Converted-messenger' }
Object >> cstArgumentPrintOn: aStream [
	self printOn: aStream
]

{ #category : '*GemStone-GBS-Converted-messenger' }
Object >> gbsMessenger [
	^ GbxMessageDispatcher singleton
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> changeRequest: anAspect [
	| dependents |
	dependents := (self respondsTo: #myDependents)
		ifTrue: [ self myDependents ]
		ifFalse: [
			(self respondsTo: #dependents)
				ifTrue: [ self dependents ]
				ifFalse: [ nil ] ].
	dependents ifNil: [ ^ true ].
	dependents do: [ :each |
		(each respondsTo: #updateRequest:)
			ifTrue: [
				([ each updateRequest: anAspect ] on: Error do: [ true ])
					ifFalse: [ ^ false ] ] ].
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> changed: anAspect [
	^ self changed: anAspect with: nil
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> changed: anAspect with: anObject [
	| dependents |
	dependents := (self respondsTo: #myDependents)
		ifTrue: [ self myDependents ]
		ifFalse: [
			(self respondsTo: #dependents)
				ifTrue: [ self dependents ]
				ifFalse: [ nil ] ].
	dependents ifNil: [ ^ self ].
	dependents do: [ :each |
		(each respondsTo: #update:with:from:)
			ifTrue: [
				[ each update: anAspect with: anObject from: self ]
					on: Error
					do: [ ] ]
			ifFalse: [
				(each respondsTo: #update:from:)
					ifTrue: [
						[ each update: anAspect from: self ]
							on: Error
							do: [ ] ]
					ifFalse: [
						(each respondsTo: #update:)
							ifTrue: [
								[ each update: anAspect ]
									on: Error
									do: [ ] ] ] ] ].
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> asGSObject [
	| remoteObject |
	remoteObject := self gbxDelegate.
	^ remoteObject isNil
		ifTrue: [ self asGSObjectInSession: GbsSessionManager current currentSession ]
		ifFalse: [ remoteObject forAnySingleSession ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> asGSObjectInSession: aGbsSession [
	| delegate |
	delegate := aGbsSession cacheAtST: self.
	delegate isNil
		ifTrue: [
			aGbsSession sessionCritical: [
				delegate := aGbsSession cacheAtST: self.
				delegate isNil
					ifTrue: [ delegate := self newGSObjectMappingInSession: aGbsSession ] ] ].
	^ delegate forSession: aGbsSession
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxResolve: varNameSymbol [
	^ self class gbxResolve: varNameSymbol
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxResolve: varNameSymbol in: namespaceName [
	^ self class gbxResolve: varNameSymbol in: namespaceName
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxBindingFor: varNameSymbol [
	^ self class gbxBindingFor: varNameSymbol
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxBindingFor: varNameSymbol in: namespaceName [
	^ self class gbxBindingFor: varNameSymbol in: namespaceName
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxDelegate [
	^ GbsSessionManager current delegateForClientObject: self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxBasicClass [
	"Private. Use this instead of #class when proxies may be involved."

	^ self class
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxUnmappedClassReplicatorClass [
	"Subclasses can override this for GBS-specific replication behavior."

	^ GbxUnmappedClassReplicator
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxFixMe [
	"A send of gbxFixMe indicates code that still needs work."
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsThisLastReport: report [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxAssertImmutable [
	self gbsMessenger assertImmutable: self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsImmutable [
	(self respondsTo: #isReadOnlyObject)
		ifTrue: [ ^ self isReadOnlyObject ].
	(self respondsTo: #isImmediateObject)
		ifTrue: [ ^ self isImmediateObject ].
	(self respondsTo: #isImmutable)
		ifTrue: [ ^ self isImmutable ].
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsImmutable: aBoolean [
	| wasImmutable |
	wasImmutable := self gbxIsImmutable.
	((self respondsTo: #isImmediateObject) and: [ self isImmediateObject ])
		ifTrue: [ ^ wasImmutable ].
	(self respondsTo: #isReadOnlyObject:)
		ifTrue: [
			self isReadOnlyObject: aBoolean.
			^ wasImmutable ].
	aBoolean
		ifTrue: [
			(self respondsTo: #beReadOnlyObject)
				ifTrue: [
					self beReadOnlyObject.
					^ wasImmutable ] ]
		ifFalse: [
			(self respondsTo: #beWritableObject)
				ifTrue: [
					self beWritableObject.
					^ wasImmutable ] ].
	(self respondsTo: #isImmutable:)
		ifTrue: [
			self isImmutable: aBoolean.
			^ wasImmutable ].
	^ wasImmutable
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsimmutable [
	^ self gbxIsImmutable
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsimmutable: aBoolean [
	^ self gbxIsImmutable: aBoolean
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsGSError [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxAsCString [
	(self isKindOf: Symbol) ifTrue: [ ^ self asString ].
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxByteSizeForReplace [
	^ self basicSize
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxByteAtForReplace: index [
	^ self basicAt: index
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxByteAtForReplace: index put: value [
	^ self basicAt: index put: value
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxReplaceBytesFrom: start to: stop with: replacement startingAt: repStart [
	"GemStone compatibility for byte-indexed objects."

	| offset replacementSize |
	replacementSize := replacement gbxByteSizeForReplace.
	(replacementSize notNil and: [ stop - start + repStart > replacementSize ])
		ifTrue: [ self error: 'There are not enough elements to perform the replacement' ].
	offset := repStart - start.
	(self == replacement and: [ repStart < start ])
		ifTrue: [
			stop to: start by: -1 do: [ :index |
				self
					gbxByteAtForReplace: index
					put: (replacement gbxByteAtForReplace: offset + index) ] ]
		ifFalse: [
			start to: stop do: [ :index |
				self
					gbxByteAtForReplace: index
					put: (replacement gbxByteAtForReplace: offset + index) ] ].
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxBecome: anObject [
	^ self becomeForward: anObject
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxBecomeForwarder [
	| fwd |
	self gbxIsImmutable: true.
	fwd := GbsForwarder new.
	^ self gbxBecome: fwd
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxCanBeArgForUnsynchronizedOperationInSession: session [
	| delegate |
	delegate := self gbxDelegate.
	delegate isNil ifTrue: [ ^ false ].
	(delegate respondsTo: #forSession:)
		ifTrue: [ delegate := delegate forSession: session ].
	^ delegate notNil and: [ delegate isStDirty not ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxCanBeStubbed [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxCanTraversalSplit [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxConnectingToMultipleSessions [
	self gbxIsModifiable
		ifTrue: [
			self gbsMessenger
				error: 'Attempt to associate a %1 with more than one GemStone session'
				with: self class ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxCouldBeForwarder [
	| delegate |
	delegate := self gbxDelegate.
	^ delegate isNil
		ifTrue: [ self gbxIsImmutable not ]
		ifFalse: [ delegate gbxCouldBeForwarder ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxDebugPrintOn: aStream [
	^ self printOn: aStream
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxDebugPrintString [
	| stream |
	stream := WriteStream on: String new.
	[ self gbxDebugPrintOn: stream ]
		on: Error
		do: [ :err | stream nextPutAll: '||| Printing error: ' , err description ].
	^ stream contents
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxDeepCopy [
	^ self gbxDeepCopyCycles: (GbxLargeIdentityDictionary new: 23)
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxDeepCopyCycles: cycles [
	^ cycles
		at: self
		ifAbsent: [
			| copy |
			copy := self shallowCopy.
			cycles at: self put: copy.
			self class isBits
				ifFalse: [
					1 to: self class instSize do: [ :i |
						copy instVarAt: i put: ((self instVarAt: i) gbxDeepCopyCycles: cycles) ].
					1 to: self basicSize do: [ :i |
						copy basicAt: i put: ((self basicAt: i) gbxDeepCopyCycles: cycles) ] ].
			copy ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxExistingOrSpecialDelegateInSession: aSession [
	^ aSession cacheAtST: self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxFaultNowForDelegate: delegate [
	| session serverTraversal result |
	session := delegate session.
	session addToNoLongerReplicated: delegate.
	serverTraversal := session newServerTraversal.
	result := serverTraversal
		rootDelegate: delegate;
		replicationLevel: 1;
		execute.
	[ result == self ] gbxAssert
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> newGSObjectMappingInSession: aGbsSession [
	| aDelegate |
	aDelegate := aGbsSession getFreeOop.
	aGbsSession connectClient: self toServer: aDelegate.
	aDelegate markStDirty: self.
	^ aDelegate
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> fault [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> faultPolicy [
	^ GbsConfiguration current defaultFaultPolicy
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> isImmediate [
	(self respondsTo: #isImmediateObject)
		ifTrue: [ ^ self isImmediateObject ].
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> islmmediate [
	^ self isImmediate
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> faultToLevel: level [
	| remoteObject session |
	self isImmediate ifTrue: [ ^ self ].
	remoteObject := self gbxDelegate ifNotNil: [ :delegate | delegate forAnySingleSession ].
	remoteObject isNil ifTrue: [ ^ self ].
	session := remoteObject session.
	session isNil ifTrue: [ ^ self ].
	remoteObject
		traverseToLevel: level
		replicationScheme: session currentReplicationScheme
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> asForwarder [
	| delegate session |
	self gbxCouldBeForwarder ifFalse: [ ^ self ].
	delegate := self asGSObject.
	session := delegate session.
	session sessionCritical: [
		self gbxIsProxy
			ifTrue: [ ^ self asForwarder ].
		delegate isStDirty ifTrue: [ delegate session flushDirtyToGS ].
		session addClampedObject: self withDelegate: delegate.
		self gbxBecomeForwarder.
		session addToNoLongerReplicated: delegate ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> asGSObjectCopy [
	^ self asGSObjectCopyInSession: GbsSessionManager current currentSession
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> asGSObjectCopyInSession: aGbsSession [
	| result |
	GbsConfiguration
		deprecated: 'Copy replication deprecated March, 2006. Use normal replication instead'.
	result := self gbxDeepCopy asGSObjectInSession: aGbsSession.
	aGbsSession flushDirtyToGS.
	^ result
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> beForwarder [
	^ self asForwarder
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> beReplicate [
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbsAsUncachedForwarder [
	| delegate sess |
	delegate := self gbxDelegate.
	sess := delegate
		ifNil: [ GbsSessionManager current currentSession ]
		ifNotNil: [ :del | del forAnySingleSession session ].
	sess isNil ifTrue: [ ^ self ].
	^ self gbsAsUncachedForwarderInSession: sess
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbsAsUncachedForwarderInSession: sess [
	| fwdr |
	self gbxCouldBeForwarder ifFalse: [ ^ self ].
	fwdr := GbsForwarder new.
	sess sessionCritical: [
		sess cacheCritical: [
			GBSM atST: fwdr putGS: (self asGSObjectInSession: sess) ] ].
	^ fwdr
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gsIsDirty [
	| remoteObject |
	remoteObject := self gbxDelegate.
	^ remoteObject notNil and: [ remoteObject isStDirty ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gsIsPersistent [
	^ self gbxDelegate notNil
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> indexableSize [
	^ self basicSize
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> indexableValueAt: index [
	^ self basicAt: index
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> indexableValueAt: index put: aValue [
	^ self basicAt: index put: aValue
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> indexableValues [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> indexableValues: anArray [
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> indexableValuesBuffer [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> isGSObject [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> markDirty [
	| remoteObject |
	remoteObject := self gbxDelegate.
	remoteObject notNil ifTrue: [ remoteObject markStDirty: self ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> markNotDirty [
	| remoteObject |
	remoteObject := self gbxDelegate.
	remoteObject notNil ifTrue: [ remoteObject markStNotDirty: self ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> namedSize [
	^ self class instSize
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> namedValueAt: index [
	^ self instVarAt: index
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> namedValueAt: index put: aValue [
	self instVarAt: index put: aValue
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> namedValues [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> namedValues: anArray [
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> namedValues: namedValues indexableValues: indexableValues [
	self namedValues: namedValues.
	self indexableValues: indexableValues
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> namedValuesBuffer [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> performOnGsServer: selector withArguments: argArray [
	| delegate |
	delegate := self gbxDelegate ifNotNil: [ :del | del forAnySingleSession ].
	delegate isNil
		ifTrue: [ ^ self gbsMessenger error: 'Cannot perform on server, no server mapping' ].
	^ delegate performOnGsServer: selector withArguments: argArray
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> performOnGsServer: selector [
	^ self performOnGsServer: selector withArguments: #()
]

{ #category : '*GemStone-GBS-Converted-debugging' }
Object >> gbxGsDebuggerSession [
	| delegate |
	delegate := self gbxDelegate.
	delegate isNil ifTrue: [ ^ nil ].
	^ [ delegate forAnySingleSession session ] on: Error do: [ nil ]
]

{ #category : '*GemStone-GBS-Converted-debugging' }
Object >> gbxIsGsBottomGlue: aSelector [
	^ false
]

{ #category : '*GemStone-GBS-Converted-debugging' }
Object >> gbxIsGsTopGlue: aSelector [
	^ false
]

{ #category : '*GemStone-GBS-Converted-debugging' }
Object >> gbxStepsIntoGemStone: aSelector showGlue: showGlue [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> postFault [
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> postFlush [
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> postFaultInSession: aSession [
	self postFault
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> preFault [
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> preFaultWithReport: report inSession: aSession [
	self preFault
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> updateFromGS [
	| delegate session |
	delegate := self asGSObject.
	session := delegate session.
	session sessionCritical: [ self gbxUpdateFromDelegate: delegate ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxUpdateFromDelegate: delegate [
	delegate isReadOnlyObject
		ifTrue: [
			self gbsMessenger
				error: 'Attempt to update an object that shouldn''t be modified in the client.' ].
	self faultPolicy == #lazy
		ifTrue: [
			| replicator |
			replicator := delegate session
				replicatorForClientBehavior: self gbxBasicClass
				ifAbsent: [ nil ].
			replicator isNil
				ifTrue: [
					GbxObjectStub
						stubObject: self
						forDelegate: delegate
						freeSlots: self class freeSlotsOnStubbing ]
				ifFalse: [
					replicator
						stubObject: self
						forDelegate: delegate
						freeSlots: self class freeSlotsOnStubbing ] ]
		ifFalse: [ self gbxFaultNowForDelegate: delegate ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsDelegate [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsGSConnector [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsGSDefunct [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsProxy [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> zzzisStub [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> zzzisForwarder [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxShouldBeWrapped [
	"Answer true for ordinary replicates so inspection wrappers can opt in."

	^ self gbxDelegate notNil
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsWrapped [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsServerSpecialInSession: aSession [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsModifiable [
	| delegate |
	(GbsConfiguration current autoMarkDirty and: [ self gbxIsImmutable ])
		ifFalse: [ ^ true ].
	delegate := self gbxDelegate.
	delegate isNil ifTrue: [ ^ false ].
	^ delegate isReadOnlyObject not
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxValidateDelegateAndSession [
	| delegate |
	self gbxFixMe.
	delegate := self gbxDelegate.
	delegate isNil
		ifTrue: [
			self gbsMessenger error: 'Defunct %1 - unconnected' with: self gbxBasicClass.
			^ nil ].
	(delegate validateSessionForProxy: self) isNil ifTrue: [ ^ nil ].
	^ delegate
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxAsServerBytes [
	^ self gbsMessenger error: 'Invalid argument'
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxBasicSize [
	^ self basicSize
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxChangeClassTo: aClass [
	aClass adoptInstance: self.
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxCopyBytesFromReport: report [
	| firstOffset lastOffset |
	firstOffset := report firstOffset.
	lastOffset := firstOffset + report valueBuffSize - 1.
	lastOffset >= firstOffset ifTrue: [
		report
			copyBytesBufferInto: self
			from: firstOffset
			to: lastOffset ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIdentityHash [
	^ self identityHash
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIgnoreFutureChanges [
	GbsConfiguration current autoMarkDirty
		ifTrue: [ self gbxIsImmutable: false ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxTrapFutureChanges [
	GbsConfiguration current autoMarkDirty
		ifTrue: [ self gbxIsImmutable: true ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxWhileMutableDoUnpreemptively: aBlock [
	^ [ self gbxIsImmutable
			ifTrue: [
				self gbxIsImmutable: false.
				aBlock ensure: [ self gbxIsImmutable: true ] ]
			ifFalse: [ aBlock value ] ]
		valueUnpreemptively
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> whileMutableDo: aBlock [
	"Compatibility wrapper used by internal replicated collections."

	^ self gbxWhileMutableDoUnpreemptively: aBlock
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> fixRefsTo: old with: new [
	self class isBits ifTrue: [ ^ self ].
	1 to: self class instSize do: [ :index |
		(self instVarAt: index) == old ifTrue: [
			self instVarAt: index put: new ] ].
	1 to: self basicSize do: [ :index |
		(self basicAt: index) == old ifTrue: [
			self basicAt: index put: new ] ].
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> shouldCollapseGemStoneWindow [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> shouldRaiseGemStoneWindow [
	^ false
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Object >> stType [
	^ #Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Object >> osType [
	^ Smalltalk os isWindows
		ifTrue: [ #win ]
		ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Object >> isRunningUnderAssertingVM [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> putInGS [
	^ self putInGSSession: GbsSessionManager current currentSession
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> putInGSSession: aGbsSession [
	| proxy |
	proxy := self asGSObjectInSession: aGbsSession.
	proxy isStDirty ifTrue: [ aGbsSession flushDirtyToGS ].
	^ proxy
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> putInGSSession: aSession toLevel: level [
	GbsConfiguration
		deprecated: 'Object>>putInGSSession:toLevel: deprecated January, 2008. Use #putInGSSession instead, or even better, use normal replication mechanisms and avoid forcing objects to the server in separate network round trips.'.
	^ self putInGSSession: aSession
]

{ #category : '*GemStone-GBS-Converted-messenger' }
Object class >> gbsMessenger [
	^ GbxMessageDispatcher singleton
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Object class >> stType [
	^ #Pharo
]

{ #category : '*GemStone-GBS-Converted-accessing' }
Object class >> osType [
	^ Smalltalk os isWindows
		ifTrue: [ #win ]
		ifFalse: [ #unix ]
]

{ #category : '*GemStone-GBS-Converted-testing' }
Object class >> isRunningUnderAssertingVM [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object class >> gbsReplicatorClass [
	^ self isBits
		ifTrue: [ GbxByteObjectReplicator ]
		ifFalse: [ GbxPointerObjectReplicator ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object class >> gbsSkewedReplicatorClass [
	^ GbxSkewedFaultingReplicator
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object class >> gbxResolve: varNameSymbol [
	| varAssoc |
	varAssoc := self gbxBindingFor: varNameSymbol.
	^ varAssoc
		ifNil: [ nil ]
		ifNotNil: [ varAssoc value ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object class >> gbxResolve: varNameSymbol in: namespaceName [
	| varAssoc |
	varAssoc := self gbxBindingFor: varNameSymbol in: namespaceName.
	^ varAssoc
		ifNil: [ nil ]
		ifNotNil: [ varAssoc value ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object class >> gbxBindingFor: varNameSymbol [
	^ Smalltalk globals
		associationAt: (varNameSymbol isString ifTrue: [ varNameSymbol asSymbol ] ifFalse: [ varNameSymbol ])
		ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object class >> gbxBindingFor: varNameSymbol in: namespaceName [
	| namespace normalizedKey resolvedNamespaceName |
	normalizedKey := varNameSymbol isString
		ifTrue: [ varNameSymbol asSymbol ]
		ifFalse: [ varNameSymbol ].
	resolvedNamespaceName := namespaceName isString
		ifTrue: [ namespaceName asSymbol ]
		ifFalse: [ namespaceName ].
	namespace := resolvedNamespaceName isSymbol
		ifTrue: [ Smalltalk globals at: resolvedNamespaceName ifAbsent: [ Smalltalk globals ] ]
		ifFalse: [
			resolvedNamespaceName inject: Smalltalk globals into: [ :current :each |
				| key |
				key := each isString ifTrue: [ each asSymbol ] ifFalse: [ each ].
				(current respondsTo: #at:ifAbsent:)
					ifTrue: [ current at: key ifAbsent: [ current ] ]
					ifFalse: [ current ] ] ].
	^ (namespace respondsTo: #associationAt:ifAbsent:)
		ifTrue: [ namespace associationAt: normalizedKey ifAbsent: [ nil ] ]
		ifFalse: [ nil ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object class >> replicationSpec [
	^ #()
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object class >> transitiveClosureSpec [
	| repspec closurespec type |
	repspec := self replicationSpec.
	repspec == #callback ifTrue: [ ^ #() ].
	closurespec := OrderedCollection new.
	repspec do: [ :spec |
		type := spec at: 2.
		(type == #min or: [ type == #max or: [ type == #stub ] ])
			ifFalse: [ closurespec add: spec ] ].
	^ closurespec
]
