Class {
	#name : 'GbxAbstractProxy',
	#superclass : '',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
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
	"Private.  Answer nil or a GbxDelegate, found cached for any
	 session, representing a remote object that is the logical
	 equivalent to the receiver. An instance of any subclass of
	 GbxRemoteObject or GbxDelegate is a valid response."

	^GBSM delegateForClientObject: self
]

{ #category : 'Object GBS methods' }
GbxAbstractProxy >> asGSObject
[

	^self gbxValidateDelegateAndSession forAnySingleSession
]

{ #category : 'validation' }
GbxAbstractProxy >> gbxSession
[
	"Private. Answer the session for the receiver. Error if the proxy
	 has any obvious problems."

	| delegate |
	(delegate := self gbxDelegate) isNil
		ifTrue: [^nil].
	^delegate validateSessionForProxy: self.
]

{ #category : 'validation' }
GbxAbstractProxy >> gbxValidateExistence
[
	"Private. Not only validate the client proxy, but also validate
	 that an object exists on the server for the proxy. This will
	 raise errors if invalid."

	| proxy |
	proxy := self gbxValidateDelegateAndSession.
	proxy isNil ifFalse: [
		proxy exists ifFalse: [
			self
				gbxProxyError: '%1 - %2 does not exist'
				with: self gbxBasicClass
				with: proxy.
		].
	].
]

{ #category : 'debugging' }
GbxAbstractProxy >> gbxDebugPrintOn: aStream
[

	| delegate |
	aStream
		nextPutAll: self gbxBasicClass name;
		nextPutAll: ' (id '.
	self identityHash printOn: aStream.
	aStream nextPutAll: ') for '.
	delegate := self gbxDelegate.
	delegate gbxDebugPrintOn: aStream
]

{ #category : 'debugging' }
GbxAbstractProxy >> gbxDebugPrintString
[
	"Answer a String whose characters are a description of the receiver.
	This description may be obtained in a safer manner or may be more detailed
	than the normal printString"

	| aStream |
	aStream := GemStone.Gbs.GbxLimitingStream on: (WriteStream on: (String new: 16)).
	
	[[self gbxDebugPrintOn: aStream]
		on: GemStone.Gbs.GbsMaxStreamSizeNotification
		do: [:notification | aStream nextPutAll: ' << etc. >>']]
			on: Error
			do: [:err | aStream nextPutAll: '||| Printing error: ' , err description].
	^aStream contents
]

{ #category : 'proxy support' }
GbxAbstractProxy >> gbxProxyError: errorString with: arg1
[
	"Private"


	self gbxBasicClass debugWhile: [
		self gbsMessenger
			error: errorString
			with: arg1.
	]
]

{ #category : 'proxy support' }
GbxAbstractProxy >> gbxProxyError: errorString 
[
	"Private"

	self gbxBasicClass debugWhile: [self gbsMessenger error: errorString]
]

{ #category : 'proxy support' }
GbxAbstractProxy >> gbxPerform: selector withArguments: anArray
[
	"Send the receiver the keyword message indicated by the arguments. The argument
	selector is the selector of the message. The arguments of the message are the
	elements of anArray. Invoke messageNotUnderstood: if the number of
	arguments expected by the selector is not the same as the length of
	anArray."

	self gbxProxyError: 'Subclass responsibility.'
]

{ #category : 'proxy support' }
GbxAbstractProxy >> gbxProxyError: errorString with: arg1 with: arg2 with: arg3
[
	"Private"


	self gbxBasicClass debugWhile: [
		self gbsMessenger
			error: errorString
			with: arg1
			with: arg2
			with: arg3.
	]
]

{ #category : 'proxy support' }
GbxAbstractProxy >> gbxProxyError: errorString with: arg1 with: arg2
[
	"Private"


	self gbxBasicClass debugWhile: [
		self gbsMessenger
			error: errorString
			with: arg1
			with: arg2.
	]
]

{ #category : 'proxy support' }
GbxAbstractProxy >> gbxBecomeReplicate
[

	nil subclassResponsibility
]

{ #category : 'dirty management' }
GbxAbstractProxy >> gbxIgnoreFutureChanges
[

	"Ignore - proxies must remain immutable."
]

{ #category : 'dirty management' }
GbxAbstractProxy >> gbxTrapFutureChanges
[
	"Private.  GBS."
	"Proxies are immutable as long as they're in the cache."

	self gbxIsImmutable: true
]

{ #category : 'dirty management' }
GbxAbstractProxy >> markDirty
[

	"The sender probably doesn't realize it couldn't have really modified this object in Smalltalk"
	^self
]

{ #category : 'dirty management' }
GbxAbstractProxy >> markNotDirty
[

	"I'm already not dirty"
	^self
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> isMemberOf: aClass
[

	"Answer a Boolean which is true if aClass, is the class of
	 the receiver, and false otherwise."

	^self gbxBasicClass == aClass or: [self class == aClass]
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> isNil
[
	"Note: Stub and forwarders will never be a placeholder for nil."

	^false
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> finalize
[

	"If a stub or forwarder should ever be sent #finalize, the message should
	 be ignored to avoid a defunct stub/forwarder error."

	^self
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> ~~ anObject
[

	"Answer a Boolean which is false when the receiver and anObject
	 represent the identical object, and true otherwise."

	^(self == anObject) not
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> notNil
[

	^self isNil not
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> isBehavior
[

	"Returns false - does a bad job pretending to be a genuine client behavior"
	^false
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> ifNil: aBlock
[
	"Note: Stub and forwarders will never be a placeholder for nil."

	^self
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> printOn: aStream
[
	"Any errors while printing will have the error message
	 printed on aStream."

	^self gbxPrintOn: aStream
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> printString
[

	| aStream |
	aStream := WriteStream on: (String new: 16).
	self printOn: aStream.
	^aStream contents
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> ~= anObject
[

	"Answer a Boolean which is false when the receiver and anObject
	 are equivalent, and true otherwise."

	^(self = anObject) not
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> doesNotUnderstand: aMessage
[


	^self
		gbxPerform: aMessage selector
		withArguments: aMessage arguments
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> ifNil: nilBlock ifNotNil: notNilBlock
[
	"If the receiver is not nil, answer the evaluation of aBlock (with the receiver as
	 its argument if it takes one), otherwise answer nil.
	 UndefinedObject redefines this to answer the evaluation of nilBlock, and hence
	 since here the receiver is not nil answer the evaluation of notNilBlock."

	^notNilBlock cull: self
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> yourself
[
	"Answer self."
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> maxPrint
[
	"Answer the maximum number of characters to print with printOn:."

	^100000
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> isImmediate
[
	"A forwarder will never take the place of an immediate object"

	^false
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> gbxPrintOn: aStream
[

	aStream
		nextPutAll: 'a ';
		nextPutAll: self gbxBasicClass name.
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> = anObject
[


	^self == anObject
]

{ #category : 'Object kernel methods' }
GbxAbstractProxy >> isKindOf: aClass
[

	"Answer a Boolean which is true if aClass, is the class or
	 a superclass of the receiver, and false otherwise."

	^(self isMemberOf: aClass) or: [self class inheritsFrom: aClass]
]

{ #category : 'testing carefully' }
GbxAbstractProxy >> isPoint
[

	^self carefullyTest: #isPoint
]

{ #category : 'testing carefully' }
GbxAbstractProxy >> isSymbol
[

	^self carefullyTest: #isSymbol
]

{ #category : 'testing carefully' }
GbxAbstractProxy >> isNumber
[

	^self carefullyTest: #isNumber
]

{ #category : 'testing carefully' }
GbxAbstractProxy >> gbxCanBeArgForUnsynchronizedOperationInSession: session
[

	^true
]

{ #category : 'testing carefully' }
GbxAbstractProxy >> isAssociation
[

	^self carefullyTest: #isAssociation
]

{ #category : 'testing carefully' }
GbxAbstractProxy >> carefullyTest: selector
[
	"Checks that stub is valid to prevent development tools from
	 getting stub errors if methods hold unconnected stubs."

	self gbxIsGSDefunct ifTrue: [^false].
	^self gbxPerform: selector withArguments: #()
]

{ #category : 'GBS private' }
GbxAbstractProxy class >> gbsReplicatorClass
[
	"In general, these proxy classes should not be replicated."

	^self shouldNotImplement
]

{ #category : 'debugging' }
GbxAbstractProxy class >> debugWhile: aBlock
[

	"Subclasses will override."

	^aBlock value
]

