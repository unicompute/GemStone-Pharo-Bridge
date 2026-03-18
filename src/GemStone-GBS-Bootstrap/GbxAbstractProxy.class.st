Class {
	#name : 'GbxAbstractProxy',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'remote execution' }
GbxAbstractProxy >> performOnGsServer: selector withArguments: argArray
[
	"GBS public. Send the receiver's server counterpart a message with the given selector and
	 arguments. Replicate the result with the session's current replication spec. Answer a replicate 
	of the server result.
	If the receiver is defunct, an error is signaled."

	| del |
	del := self gbxDelegate.
	del == nil ifTrue: [^nil gbsMessenger error: 'Proxy is not mapped'].
	^del performOnGsServer: selector withArguments: argArray
]

{ #category : 'remote execution' }
GbxAbstractProxy >> performOnGsServer: selector
[
	"GBS public. Send the receiver's server counterpart a message with the given unary selector.
	Replicate the result with the session's current replication spec. Answer a replicate 
	of the server result.
	If the receiver is defunct, an error is signaled."

	^self performOnGsServer: selector withArguments: #()
]

{ #category : 'messenging' }
GbxAbstractProxy >> cstArgumentPrintOn: aStream
[
	"The receiver was passed as an argument to be printed
	 into a string handled by a messenger. This method
	 determines how that argument will print itself."

	^self printOn: aStream
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxIsDelegate
[
	"Private"

	^false
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> asUncachedForwarder
[

	GbsConfiguration
		deprecated: 'GbxAbstractProxy>>asUncachedForwarder deprecated March, 2011. Use GbxAbstractProxy>>gbsAsUncachedForwarder instead.
	(Preferably GbxDelegate>>gbsAsUncachedForwarderInSession:)
'.
	^self gbsAsUncachedForwarder
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> beForwarder
[
	"Private.  GBS.  This is obsolete protocol. You should send #asForwarder if
	 you want the receiver to become a forwarder, or #asUncachedForwarder if
	 you want another reference to the oop that will forward messages."

	^self asForwarder
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxIsGSDefunct
[
	"Private.  Answer true if defunct."

	| gsObject |
	gsObject := self gbxDelegate forAnySingleSession.
	gsObject isGSObject ifFalse: [ ^true ].
	^gsObject gbxIsGSDefunct
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxIsGSError
[

	^false
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxIsProxy
[
	"Private. Answer boolean whether the receiver represents a remote
	 object that attempts to behave like a local object. This method takes
	 the place of the older ^(obj zzzisForwarder or: [obj zzzisStub])."

	^true
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> beReplicate
[

	"GBS.  Stubs answer themselves, forwarders override this message."
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxStoreInTraversal: storeTraversal 
[
	"Private.  The receiver is already stored in GemStone.  Therefore,
	there is nothing to do. "
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxValidProxy
[

	"Private.  Similar to #gbxValidateDelegate but answers nil if there
	 is an obvious problem instead of passing an exception."

	^[ self gbxValidateDelegateAndSession ]
		on: GbsError hostErrorSignal
		do: [:ex | ex return: nil ].
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> cachedProxy
[
	"Private-Old.  This was a private method, used until GBS 5.1.4,
	 that now has the name shown below. Though private, this method
	 exists so any customers that directly used it can easily transition to
	 the new protocol. This old protocol will be deleted in a future release."

	GbsConfiguration 
		deprecated: ' AbstractProxy>>cachedProxy deprecated June, 2007. Use #gbxDelegate instead'.
	^self gbxDelegate
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> fault
[
	"Non-stub proxies ignore this, they're already as faulted as they can get."

	^self
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxValidateDelegateAndSession
[
	"Private.  Raise an error if there are any obvious problems with
	 the client proxy itself. Answer the delegate, or nil if allowed to proceed
	 after an error is reported."

	| delegate |
	delegate := self gbxDelegate.
	delegate isNil 
		ifTrue: 
			[self gbsMessenger error: 'Defunct %1 - unconnected'
				with: self gbxBasicClass.
			^nil].
	(delegate validateSessionForProxy: self) isNil ifTrue: [^nil].
	^delegate
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbsAsUncachedForwarder
[
	"GBS. Answers a new uncached forwarder."
	"Normally, the session's sessionProtect semaphore must be acquired before 
	grabbing the ClientMap's writeProtect. Here, we can get away with not doing that
	because we do not need the sessionProtect at all, so we are not subject to deadlock."

	| fwdr |
	fwdr := GbsForwarder new.
	GBSM clientMap
		writeCritical: [GBSM atST: fwdr putGS: self gbxValidateDelegateAndSession].
	^fwdr
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbsMessenger
[
	"Answer something that knows how to handle GBS messages. This
	 eliminates many method references to a global, and allows for
	 easy substitution in the future."

	^Object gbsMessenger
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxWhileMutableDoUnpreemptively: aBlock
[
	"Sender must hold sessionProtect of the appropriate session."

	^
	[self gbxIsImmutable
		ifTrue: 
			[self gbxIsImmutable: false.
			aBlock ensure: [self gbxIsImmutable: true]]
		ifFalse: [aBlock value]]
			valueUnpreemptively
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> stubYourself
[
	"This is behavior intended for client objects only, so don't forward or
	 attempt to stub a stub; just answer the receiver."
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> isGSObject
[
	"Private"

	^false
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxAssertImmutable
[
	nil gbsMessenger assertImmutable: self
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> zzzisForwarder
[
	"Private"

	^false
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> zzzisStub
[
	"Private"

	^false
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> asForwarder
[
	"GBS. Forwarder returns self. Stub converts to forwarder."
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxCouldBeForwarder
[
	"Private GBS.  Answer boolean whether the receiver can become a forwarder."

	nil error: 'GBS internal error: No one should send this message to a proxy'
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxDelegate
[
	self subclassResponsibility
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxBecomeReplicate
[
	self subclassResponsibility
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxBasicClass
[
	^self class
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxDebugPrintOn: aStream
[
	^self printOn: aStream
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxDebugPrintString
[
	^String streamContents: [ :stream | self gbxDebugPrintOn: stream ]
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxIgnoreFutureChanges
[
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxPerform: selector withArguments: argArray
[
	^self perform: selector withArguments: argArray
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxPrintOn: aStream
[
	^self printOn: aStream
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxProxyError: aString
[
	^self error: aString
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxProxyError: aString with: anObject
[
	^self error: (aString format: { anObject })
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxProxyError: aString with: object1 with: object2
[
	^self error: (aString format: { object1. object2 })
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxProxyError: aString with: object1 with: object2 with: object3
[
	^self error: (aString format: { object1. object2. object3 })
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxSession
[
	^self gbxDelegate session
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxTrapFutureChanges
[
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> gbxValidateExistence
[
	^self gbxValidateDelegateAndSession
]

{ #category : 'testing' }
GbxAbstractProxy >> ifNil: aBlock
[
	^self
]

{ #category : 'testing' }
GbxAbstractProxy >> ifNil: nilBlock ifNotNil: notNilBlock
[
	^notNilBlock value: self
]

{ #category : 'testing' }
GbxAbstractProxy >> isAssociation
[
	^false
]

{ #category : 'testing' }
GbxAbstractProxy >> isBehavior
[
	^false
]

{ #category : 'testing' }
GbxAbstractProxy >> isImmediate
[
	^false
]

{ #category : 'testing' }
GbxAbstractProxy >> isKindOf: aClass
[
	^super isKindOf: aClass
]

{ #category : 'testing' }
GbxAbstractProxy >> isMemberOf: aClass
[
	^super isMemberOf: aClass
]

{ #category : 'testing' }
GbxAbstractProxy >> isNil
[
	^false
]

{ #category : 'testing' }
GbxAbstractProxy >> isNumber
[
	^false
]

{ #category : 'testing' }
GbxAbstractProxy >> isPoint
[
	^false
]

{ #category : 'testing' }
GbxAbstractProxy >> isSymbol
[
	^false
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> markDirty
[
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> markNotDirty
[
]

{ #category : 'printing' }
GbxAbstractProxy >> maxPrint
[
	^500
]

{ #category : 'testing' }
GbxAbstractProxy >> notNil
[
	^true
]

{ #category : 'printing' }
GbxAbstractProxy >> printString
[
	^super printString
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> yourself
[
	^self
]

{ #category : 'comparing' }
GbxAbstractProxy >> = anObject
[
	self subclassResponsibility
]

{ #category : 'comparing' }
GbxAbstractProxy >> ~= anObject
[
	^super ~= anObject
]

{ #category : 'comparing' }
GbxAbstractProxy >> ~~ anObject
[
	^super ~~ anObject
]
