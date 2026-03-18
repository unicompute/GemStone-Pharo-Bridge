Class {
	#name : 'GbsConnector',
	#superclass : 'Object',
	#instVars : [
		'postConnectAction',
		'connectionCondition'
	],
	#classVars : [
		'ValidPostConnectActions'
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'comparing' }
GbsConnector >> = aConnection
[

	"Two connectors are equal if they resolve the same Smalltalk object"

	| stSelf stOther |
	aConnection gbxIsGSConnector
		ifTrue: [
			"| stSelf stOther |"
			stSelf := self resolveSTObjIfFail: [ ^self == aConnection].
			stOther := aConnection resolveSTObjIfFail: [ ^self == aConnection ].
			^stSelf == stOther ]
		ifFalse: [ ^false ]
]

{ #category : 'comparing' }
GbsConnector >> hash
[

	"Return the identity hash of the Smalltalk object.  If any error occurs
	 while resolving it, return the identity hash of the connector."

	^[self resolveClientObj identityHash]
		on: GbsError hostErrorSignal
		do: [:ex | ex return: self identityHash ]
]

{ #category : 'accessing' }
GbsConnector >> connectionCondition: anObject
[
	connectionCondition := anObject
]

{ #category : 'accessing' }
GbsConnector >> connectionCondition
[
	^connectionCondition
]

{ #category : 'initialization' }
GbsConnector >> beForwarderOnConnect
[

	"Make the Smalltalk object a forwarder upon connection"
	self postConnectAction: #forwarder
]

{ #category : 'initialization' }
GbsConnector >> noUpdateOnConnect
[

	self postConnectAction: nil
]

{ #category : 'initialization' }
GbsConnector >> updateSTOnConnect
[

	self postConnectAction: #updateST
]

{ #category : 'initialization' }
GbsConnector >> updateGSOnConnect
[

	self postConnectAction: #updateGS
]

{ #category : 'connecting and disconnecting' }
GbsConnector >> connectInSession: sess ifFail: oneArgBlock
[
	"Resolve my GemStone and Smalltalk objects, and set up a relationship
	 for them in aGSSession.  On failure, oneArgBlock is evaluated with
	 the error message as the argument."

	connectionCondition value
		ifTrue: 
			[self disconnectInSession: sess.
			^[self privConnectInSession: sess]
				on: Error
				do: [:ex | ex return: (oneArgBlock value: ex description)]]
]

{ #category : 'connecting and disconnecting' }
GbsConnector >> connect
[

	"Resolve my GemStone and Smalltalk objects, and set up a relationship for them in the current session.  Multi-session applications should use connectInSession:"

	^self connectInSession: GBSM currentSession
]

{ #category : 'connecting and disconnecting' }
GbsConnector >> connectInSession: aGSSession
[

	"Resolve my GemStone and Smalltalk objects, and set up a relationship for them in aGSSession"

	^self
		connectInSession: aGSSession
		ifFail: [:msg |
			self gbsMessenger
				raise: GbsConnectorError
				message: msg.
			nil
		].
]

{ #category : 'connecting and disconnecting' }
GbsConnector >> disconnectInSession: session
[
	"Resolve my GemStone and Smalltalk objects, and make sure they are unconnected in aGSSession.
	If one cannot be resolved, still disconnect based on the other. If neither can be resolved, do nothing"

	| st gs |
	(self isConnectedInSession: session) ifFalse: [^self].
	st := self resolveSTObjIfFail: [nil].
	gs := self resolveGSObjInSession: session ifFail: [nil].
	(st == nil and: [gs == nil]) ifTrue: [^self].
	gs == nil ifTrue: [gs := st asGSObjectInSession: session].
	session sessionCritical: 
			[st == nil
				ifTrue: 
					[st := session clientObjForDelegate: gs otherwise: nil.
					st == nil ifTrue: [^self]].
			gs isSpecial ifFalse: [session disconnectClient: st fromServer: gs]]
]

{ #category : 'private connecting' }
GbsConnector >> clientForwarderTo: clientObject session: session
[

	^self gbsMessenger
		error: 'Client forwarders are not supported for class %1'
		with: self class
]

{ #category : 'private connecting' }
GbsConnector >> postConnectSaveGsObjectInSession: anObject 
[
	"Private. Answer nil or an GbsObject or oop to be added to the
	 session export set to avoid GC."

	^nil
]

{ #category : 'private connecting' }
GbsConnector >> postConnectClient: clientObj server: delegate inSession: aGSSession
[
	"Private.  Events to occur after connecting. Default is none."
]

{ #category : 'private connecting' }
GbsConnector >> canForwardTo: clientObject inSession: aSession
[
	"Answer true iff the client object is something that a server ClientForwarder can be connected to."

	self subclassResponsibility
]

{ #category : 'private connecting' }
GbsConnector >> postConnectAction: action
[

	(action isNil or: [ (self validPostConnectActions includes: action) ])
		ifFalse: [ ^self gbsMessenger error: 'Invalid post-connect action - %1' with: action ].
	postConnectAction := action
]

{ #category : 'private connecting' }
GbsConnector >> postConnectAction
[
	"Private"

	postConnectAction isNil ifTrue: [ postConnectAction := #none ].
	^postConnectAction
]

{ #category : 'private connecting' }
GbsConnector >> validPostConnectActions
[
	"Private"

	| all resolvest |
	all := self class validPostConnectActions.
	resolvest := self resolveSTObjIfFail: [nil].
	^resolvest isBehavior ifTrue: [all copyWithout: #forwarder] ifFalse: [all]
]

{ #category : 'private connecting' }
GbsConnector >> connectsAssociation
[

	"Private.  Return true if the connector connects an association related to the object"

	^false
]

{ #category : 'private connecting' }
GbsConnector >> privConnectInSession: sess
[
	"Private.  Resolve my GemStone and Smalltalk objects, and set up a relationship for them in aGSSession.  This method might raise any signal."

	sess sessionCritical: 
			[| st gs pca oldGS oldST toConnect isBehavior |
			GbsConfiguration current connectVerification
				ifTrue: 
					[oldGS := sess cacheAtST: (self resolveSTObjIfFail: [nil]).
					oldST := sess clientObjForDelegate: (self resolveGSObjInSession: sess
										ifFail: [sess oopNil])
								otherwise: nil].
			pca := self postConnectAction.
			pca == #updateGS
				ifTrue: 
					[st := self resolveClientObj.
					gs := self updateGSfromST: st session: sess].
			(pca == #updateST or: [pca == #forwarder])
				ifTrue: 
					[pca == #updateST ifTrue: [sess flushDirtyToGS].
					gs := self resolveGSObjInSession: sess.
					st := self updateClientfromDelegate: gs].
			pca == #clientForwarder
				ifTrue: 
					[st := self resolveClientObj.
					(self canForwardTo: st inSession: sess)
						ifFalse: 
							[^self gbsMessenger error: 'Cannot connect a client forwarder to a special'].
					gs := self clientForwarderTo: st session: sess].
			pca == #none
				ifTrue: 
					[st := self resolveClientObj.
					gs := self resolveGSObjInSession: sess].
			"Did an error occur?  If so, it was already signaled - simply return"
			(st isNil or: [gs isNil]) ifTrue: [^nil].

			"Flush the cached instance variable mapping and replication control stuff."
			toConnect := IdentityDictionary new.
			toConnect at: st put: gs.
			isBehavior := st gbxIsProxy not and: [st isBehavior].
			isBehavior
				ifTrue: 
					[| theClass |
					st isMeta
						ifTrue: 
							[theClass := st gbxSoleInstance.
							toConnect at: theClass put: gs remoteInstance]
						ifFalse: 
							[theClass := st.
							toConnect at: st gbxBasicClass put: gs unsynchronizedRemoteClass]].
			(GbsConfiguration current connectVerification not or: 
					[self
						verifyoldST: oldST
						newST: st
						oldGS: oldGS
						newGS: gs
						session: sess])
				ifTrue: 
					[| toSave |
					toSave := OrderedCollection new.
					toConnect keysAndValuesDo: 
							[:clientObj :delegate |
							sess connectClient: clientObj toServer: delegate.
							(clientObj gbxIsProxy not and: [clientObj isBehavior not])
								ifTrue: [toSave add: delegate]].
					sess saveObjects: toSave.
					isBehavior ifTrue: [sess updateInstVarNamesAndClamps].
					"In single-trip, is in referenced set, but must be in export set once connected to a replicate."
					self postConnectClient: st server: gs inSession: sess]]
]

{ #category : 'private' }
GbsConnector >> clientObjIsUnstubbedClass
[
	"Private.  For building replication clamps, we need to be sure that unstubbing will not happen or
	we end up in an infinite loop."

	^false
]

{ #category : 'private' }
GbsConnector >> verifyoldST: oldSTOrNil newST: newST oldGS: oldGSOrNil newGS: newGS session: aGSSession
[
	"Private.  Check if we are overriding an existing connection with something different"

	| oldST oldGS |
	oldST := oldSTOrNil isNil ifTrue: [newST] ifFalse: [oldSTOrNil].
	oldGS := (oldGSOrNil isNil or: [oldGSOrNil = aGSSession oopNil])
				ifTrue: [newGS]
				ifFalse: [oldGSOrNil].
	((oldST == newST or: [oldST zzzisStub]) and: [oldGS sameOopAs: newGS])
		ifFalse: 
			["Restore old connection in case connector resolving/updating disturbed it"
			aGSSession connectClient: oldST toServer: oldGS.
			self gbsMessenger
				raise: GbsConnectorError
				message: '%1 is overriding an existing connection.'
				with: self.
			^false]
		ifTrue: [^true]
]

{ #category : 'private' }
GbsConnector >> checkDefunctness: anSTObj 
[
	"Private.  If anSTObj is a forwarder or stub, make sure its session is valid.  If not, a signal is raised."

	anSTObj gbxIsProxy ifTrue: [anSTObj gbxValidateExistence].
	^anSTObj
]

{ #category : 'private' }
GbsConnector >> typeOrdering
[
	"Private"

	^#(Fast Class Name ClassVar ClassInstVar) indexOf: self type
]

{ #category : 'private' }
GbsConnector >> nilSTObj
[
	"Private.  Default is do nothing."
]

{ #category : 'private' }
GbsConnector >> browserLessOrEqualTo: aConnector
[

	"Private.  Less-than-or-equal-to for displaying a list of connectors in a browser"
	self typeOrdering = aConnector typeOrdering
		ifTrue: [
			"Ordering is by GemStone object id"
			^self clientObjDescription <= aConnector clientObjDescription ]
		ifFalse: [
			^self typeOrdering < aConnector typeOrdering ]
]

{ #category : 'private' }
GbsConnector >> isKnownKernelOop
[

	"Private.  Return true if the connector is guaranteed to resolve to a GemStone kernel object.  Most connectors can't guarantee this."
	^false
]

{ #category : 'private' }
GbsConnector >> isClassConnector
[

	"Private.  Answer true if the connector is a class connector.  Default to false. "

	^ false
]

{ #category : 'verification' }
GbsConnector >> connectVerification
[
	"If true, connectors will verify that they are not redefining an object connection, and class connectors will verify that the class structures match."

	GbsConfiguration 
		deprecated: 'GbsConnector>>connectVerification. Deprecated March, 2006. Use GbsConfiguration>>connectVerification instead'.
	^GbsConfiguration current connectVerification
]

{ #category : 'testing' }
GbsConnector >> gbxIsGSConnector
[
	^true
]

{ #category : 'testing' }
GbsConnector >> isConnectedInSession: sess
[
	"Return true if the Smalltalk and GemStone objects defined by the receiver are currently connected in aGSSession"

	"First, check all that can be checked without a round trip"

	| client delegate |
	client := self resolveSTObjIfFail: [^false].
	(client gbxDelegate forSession: sess) == nil ifTrue: [^false].
	"Then make checks that require going to the server."
	delegate := self resolveGSObjInSession: sess ifFail: [^false].
	^sess isST: client connectedToGS: delegate
]

{ #category : 'private printing' }
GbsConnector >> stDescription
[
	"Private. Sent by aspect adaptor in connector browser"

	self subclassResponsibility
]

{ #category : 'private printing' }
GbsConnector >> gsDescription
[
	"Private - do not delete as it is sent by the gui code with a #perform:, 
	see the #windowSpec for GbsConnectorBrowser"

	self subclassResponsibility
]

{ #category : 'private printing' }
GbsConnector >> type
[
	"Private"

	^self class type
]

{ #category : 'private printing' }
GbsConnector >> clientObjDescription
[
	"Private"

	self subclassResponsibility
]

{ #category : 'gbs private testing' }
GbsConnector >> isClassConnectorTypeNone
[
	"Private to GBS"

	^false
]

{ #category : 'gbs private testing' }
GbsConnector >> isFastConnectorTypeNone
[
	"Private to GBS"

	^false
]

{ #category : 'private resolving' }
GbsConnector >> updateClientfromDelegate: delegate
[

	"Private.  Update the Smalltalk object from the given GemStone object.  Return the Smalltalk object."
	self subclassResponsibility
]

{ #category : 'private resolving' }
GbsConnector >> resolveSTObjIfFail: failBlockWithOptionalArg
[
	"Private.  Resolve and return Smalltalk object to be connected.
	 Do not trigger defunct stub or defunct forwarder errors.
	 If the fail block takes an argument, pass the exception explaining
	 the failure to it."

	^[self resolveClientObj]
		on: GbsError hostErrorSignal
		do: [:ex | ex return: (failBlockWithOptionalArg cull: ex) ].
]

{ #category : 'private resolving' }
GbsConnector >> resolveGSObjInSession: aGSSession ifFail: failBlockWithOptionalArg
[
	"Private.  Resolve and return GemStone object to be connected.
	 If the fail block takes an argument, pass the exception explaining
	 the failure to it."

	self gbxFixMe.	"Should be more selective about errors caught here. 
					This can mask serious errors like failure to generate a class, which breaks synchronization."
	^[self resolveGSObjInSession: aGSSession]
		on: GbsError hostErrorSignal
		do: [:ex | ex return: (failBlockWithOptionalArg cull: ex) ]
]

{ #category : 'private resolving' }
GbsConnector >> resolveGSObjInSession: aGSSession
[

	"Private.  Resolve and return GemStone object to be connected"

	^self subclassResponsibility
]

{ #category : 'private resolving' }
GbsConnector >> updateGSfromST: anSTObj session: aGSSession
[

	"Private.  Update the GemStone object from the given Smalltalk object.  Return the GemStone object."
	self subclassResponsibility
]

{ #category : 'private resolving' }
GbsConnector >> resolveClientObj
[

	"Private.  Resolve and return Smalltalk object to be connected"

	^self subclassResponsibility
]

{ #category : 'class constants' }
GbsConnector class >> connectVerification
[
	"If true, connectors will verify that they are not redefining an object connection, and class connectors will verify that the class structures match."

	GbsConfiguration 
		deprecated: 'GbsConnector class>>connectVerification. Deprecated March, 2006. Use GbsConfiguration>>connectVerification instead'.
	^GbsConfiguration current connectVerification
]

{ #category : 'class constants' }
GbsConnector class >> type
[

	"Private.  By default, type is derived from the class name"
	| i t |
	type isNil ifTrue: [
		t := self name.
		i := t indexOfSubCollection: 'Connector' startingAt: 1 ifAbsent: [ 0 ].
		i = 0 ifTrue: [ i := t size ] ifFalse: [ i := i - 1 ].
		type := (t copyFrom: 4 to: i) asSymbol ].
	^type
]

{ #category : 'class constants' }
GbsConnector class >> defaultPostConnectAction
[

	^#updateST
]

{ #category : 'class constants' }
GbsConnector class >> validPostConnectActions
[

	^ValidPostConnectActions	"Private"
]

{ #category : 'initialization' }
GbsConnector class >> connectVerification: aBool 
[
	"If aBool is set to true, connectors will verify that they are not redefining an object connection, and class connectors will verify that the class structures match."

	GbsConfiguration 
		deprecated: 'GbsConnector class>>connectVerification:. Deprecated March, 2006. Use GbsConfiguration>>connectVerification: instead'.
	GbsConfiguration current connectVerification: aBool
]

{ #category : 'initialization' }
GbsConnector class >> initialize
[
	ValidPostConnectActions := #(#updateST #updateGS #forwarder #clientForwarder #none)
]

{ #category : 'instance creation' }
GbsConnector class >> fromUser
[

	"Prompt the user for information to create an instance of the receiver"
	self subclassResponsibility
]

{ #category : 'instance creation' }
GbsConnector class >> new
[

	"Return a new instance with the default postconnect action"

	^self basicNew postConnectAction: self defaultPostConnectAction
]

{ #category : 'instance creation' }
GbsConnector class >> supportsFromUser
[
	"GBS Private. Answer whether the user is allowed to create connectors of this type through the GUI."

	^true	"by default."
]

