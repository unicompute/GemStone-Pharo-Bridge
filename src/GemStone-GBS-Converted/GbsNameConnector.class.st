Class {
	#name : 'GbsNameConnector',
	#superclass : 'GbsConnector',
	#instVars : [
		'stName',
		'gsName',
		'dictionaryName',
		'binding',
		'environment'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'comparing' }
GbsNameConnector >> hash
[

	^self clientObjDescription hash
]

{ #category : 'comparing' }
GbsNameConnector >> = aConnector
[

	"Two connectors are equal if they describe the same Smalltalk object"
	^aConnector gbxIsGSConnector
		ifTrue: [ self clientObjDescription = aConnector clientObjDescription ]
		ifFalse: [ super = aConnector ]
]

{ #category : 'accessing' }
GbsNameConnector >> stName
[
	^stName
]

{ #category : 'accessing' }
GbsNameConnector >> environment
[

	^environment ifNil: [environment := Smalltalk]
]

{ #category : 'accessing' }
GbsNameConnector >> environment: anObject
[
	environment := anObject
]

{ #category : 'private' }
GbsNameConnector >> gsName
[
	"Private"

	^gsName
]

{ #category : 'private' }
GbsNameConnector >> verifyNameAssoc: anAssoc
[
	"Private.  Need to use special Smalltalk class for name associations, to assure that assignments
	 in Smalltalk are propagated to GemStone, and to prevent the name itself from being propagated
	 between ST and GS"

	anAssoc class == GbxNameAssociation ifTrue: [^self].
	anAssoc gbxBecome: (GbxNameAssociation newWithValuesFrom: anAssoc andGsName: gsName)
]

{ #category : 'private' }
GbsNameConnector >> nilSTObj
[
	"Private.  nil the Smalltalk object for the connector if the
	post connect action is #updateST or #forwarder.
	This is done during post logout to reduce defunct stub errors."

	| pca |
	pca := self postConnectAction.
	(pca == #forwarder or: [pca == #updateST]) ifTrue: [binding ifNotNil: [binding value: nil]]
]

{ #category : 'private' }
GbsNameConnector >> connectsAssociation
[
	"Private"

	^true
]

{ #category : 'private connecting' }
GbsNameConnector >> clientForwarderTo: clientAssoc session: sess
[
	"Answer a delegate for the association of the client forwarder for my variable.
	 If necessary, the server variable will be assigned to be a client forwarder in postConnect."
	"Sender must hold session's sessionProtect"

	| assocDelegate valueDelegate clientValue mappedClientDelegate |
	clientValue := clientAssoc value.
	assocDelegate := self resolveOrCreateServerAssociationInSession: sess.
	valueDelegate := assocDelegate remotePerform: #value.
	valueDelegate remoteClassIsClientForwarder
		ifFalse: 
			["Must create a new CF on server and assign it to the server variable.
			  So this is assignment is not replicated to the client, we must make sure that the 
			  association is not mapped before doing this. The association will be mapped or 
			  remapped in #privConnect..."
			| mappedClientAssoc |
			mappedClientAssoc := sess clientObjForDelegate: assocDelegate otherwise: nil.
			mappedClientAssoc ~~ nil
				ifTrue: [sess disconnectClient: mappedClientAssoc fromServer: assocDelegate].
			valueDelegate := sess
						execute: '| cf | cf := ClientForwarder new. self value: cf. ^cf'
						context: assocDelegate].

	"Whether or not the server value was a client forwarder, 
	 must disconnect any old connection and make a new one."
	[clientValue == clientAssoc value] gbxAssert.	"replication should not have changed this."
	mappedClientDelegate := clientValue gbxDelegate
				ifNotNil: [:del | del forSession: sess].
	mappedClientDelegate ~~ nil
		ifTrue: [sess disconnectClient: clientValue fromServer: mappedClientDelegate].
	sess
		addClampedObject: clientValue withDelegate: valueDelegate;
		connectClient: clientValue toServer: valueDelegate;
		saveObjects: (Array with: valueDelegate).
	^assocDelegate
]

{ #category : 'private connecting' }
GbsNameConnector >> postConnectClient: clientAssoc server: assocDelegate inSession: sess
[
	"Private.
	Sender must hold sessionProtect"

	| pca valueDelegate |
	pca := self postConnectAction.
	pca == #none
		ifTrue: 
			["Don't update either side after connection.  In this case,  the
		 	values of the associations must also be connected at this time, unless special."
			| clientValue |
			clientValue := clientAssoc value.
			((clientValue gbxIsServerSpecialInSession: sess) not and: 
					[valueDelegate := assocDelegate remotePerform: #value.
					valueDelegate isSpecial not])
				ifTrue: 
					[sess
						connectClient: clientValue toServer: valueDelegate;
						saveObjects: (Array with: valueDelegate)].
			^self].
	pca == #clientForwarder
		ifTrue: [^self	"All the work was done in #clientForwarderTo:session:"].
	pca == #updateGS
		ifTrue: 
			[assocDelegate markStDirty: clientAssoc.
			^assocDelegate].

	"If control is here, the Smalltalk object will be updated.  Update by changing the
	 value of the association"
	valueDelegate := sess unsynchronizedExecute: 'self value'
				context: assocDelegate.
	^clientAssoc noDirtyValue: (pca == #forwarder
				ifTrue: [valueDelegate asForwarder]
				ifFalse: [valueDelegate asLocalObject])
]

{ #category : 'private connecting' }
GbsNameConnector >> canForwardTo: clientBinding inSession: aSession
[
	"Answer true iff the client object is something that a server ClientForwarder can be connected to.
	The client object is the value of the passed-in binding.
	Sender must hold sessionProtect."

	^(clientBinding value gbxIsServerSpecialInSession: aSession) not
]

{ #category : 'connecting' }
GbsNameConnector >> disconnectInSession: session
[
	"Resolve my GemStone and Smalltalk objects, and make sure they are unconnected in session"

	| clientAssoc assocDelegate clientValue valueDelegate |
	session sessionCritical: 
			[(self isConnectedInSession: session) ifFalse: [^self].
			clientAssoc := self resolveSTObjIfFail: [nil].
			"Resolve what can be resolved"
			assocDelegate := self resolveGSObjInSession: session ifFail: [nil].
			(clientAssoc == nil and: [assocDelegate == nil]) ifTrue: [^self].
			clientValue := clientAssoc isNil ifTrue: [nil] ifFalse: [clientAssoc value].
			valueDelegate := assocDelegate isNil ifTrue: [nil] ifFalse: [assocDelegate remotePerform: #value].
			"Disconnect the association/binding"
			assocDelegate == nil ifTrue: [assocDelegate := clientAssoc asGSObjectInSession: session].
			clientAssoc == nil ifTrue: [clientAssoc := session clientObjForDelegate: assocDelegate otherwise: nil].
			(clientAssoc ~~ nil and: [assocDelegate ~~ nil])
				ifTrue: [session disconnectClient: clientAssoc fromServer: assocDelegate].
			"Disconnect the bound objects"
			(clientValue == nil and: [valueDelegate == nil]) ifTrue: [^self].
			valueDelegate == nil ifTrue: [valueDelegate := clientValue asGSObjectInSession: session].
			clientValue == nil ifTrue: [clientValue := session clientObjForDelegate: valueDelegate otherwise: nil].
			(clientValue ~~ nil and: [valueDelegate ~~ nil])
				ifTrue: [valueDelegate isSpecial ifFalse: [session disconnectClient: clientValue fromServer: valueDelegate]]]
]

{ #category : 'private printing' }
GbsNameConnector >> clientObjDescription
[
	" Private - Answer a string describing my Client binding. "

	^ '#' , stName
]

{ #category : 'private printing' }
GbsNameConnector >> hasDictionaryName
[
	" Private - Answer true if I know about my dictionary name. "

	^ dictionaryName notNil and: [ dictionaryName isEmpty not ]
]

{ #category : 'private printing' }
GbsNameConnector >> stDescription
[
	" Private - Answer a string describing my Client binding. 
	Sent by aspect adaptor in connector browser"

	^'#' , stName
]

{ #category : 'private printing' }
GbsNameConnector >> gsDescription
[
	" Private - Answer a string describing my GemStone binding.
	  NOTE:  We used to append the dictionary name, but we couldn't be sure it was right (bug #13942). "

	"do not delete as it is sent by the gui code with a #perform:, 
	see the #windowSpec for GbsConnectorBrowser"

	^ gsName printString
]

{ #category : 'printing' }
GbsNameConnector >> storeOn: aStream
[
	"Write an executable expression to the stream such that evaluating
	 the expression would reconstruct the receiver.

	 If the connection condition is not the default [true] and not a simple
	 block, we cannot regenerate the block in a file in, so this can signal
	 a GbsBlockReplicationError in such cases.
	 Note that, typically, Fast Connectors have non-default conditions.
	 However, customer defined blocks could have them, too."

	aStream nextPutAll: '('.
	self connectionCondition = [true]
		ifTrue: [self printOn: aStream]
		ifFalse: [
			aStream nextPutAll: '('.
			self printOn: aStream.
			aStream nextPutAll: ') connectionCondition: ';
				nextPutAll: self connectionCondition gbxDecompiledSource;
				nextPutAll: '; yourself)'
			].
	aStream nextPutAll: ')'.
]

{ #category : 'printing' }
GbsNameConnector >> printOn: aStream
[

	aStream nextPutAll: self class name;
		nextPutAll: ' stName: '.
	stName printOn: aStream.
	aStream nextPutAll: ' gsName: '.
	gsName printOn: aStream.
	self hasDictionaryName ifTrue:
		[aStream nextPutAll: ' dictionaryName: '.
		dictionaryName printOn: aStream]
]

{ #category : 'private resolving' }
GbsNameConnector >> serverAssociationResolvingString
[

	^'[:restrictToDict :dictName :associationName :variableName :shouldCreate |

	"Get the dictionary that it goes in if we have to create it. Fail if it''s bad."
	| dictionary association |
	association := GsSession currentSession resolveSymbol: dictName.
	association == nil ifTrue: [^nil].

	dictionary := association value.
	"Get the binding/association for the connection."
	association := restrictToDict
				ifTrue: [dictionary associationAt: associationName otherwise: nil]
				ifFalse: [System myUserProfile resolveSymbol: associationName].

	"If there isn''t one, create it if we can."
	(association == nil and: [shouldCreate])
		ifTrue: 
			[dictionary at: associationName put: nil.
			association := dictionary associationAt: associationName].

	^association]'
]

{ #category : 'private resolving' }
GbsNameConnector >> dictionaryName
[
	"Private"

	^ self hasDictionaryName
		ifTrue: [ dictionaryName ]
		ifFalse: [ #UserGlobals ].
]

{ #category : 'private resolving' }
GbsNameConnector >> resolveGSObjInSession: aGSSession
[
	"Private.  Resolve and return GemStone object to be connected - the symbol list association holding the object named gsName."

	^self resolveRequiredServerAssociationInSession: aGSSession
]

{ #category : 'private resolving' }
GbsNameConnector >> resolveServerAssociationInSession: session createMissing: createBoolean
[

	| assocDelegate errorMessage |
	assocDelegate := session
				executeBlock: self serverAssociationResolvingString
				with: self hasDictionaryName
				with: self dictionaryName asSymbol
				with: self gsName asSymbol
				with: self variableName
				with: createBoolean
				context: nil.
	assocDelegate = session oopNil
		ifTrue: 
			[errorMessage := self hasDictionaryName
						ifTrue: ['Failed to resolve the server object named %1 in %2.']
						ifFalse: ['Failed to resolve the server object named %1.'].
			self gbsMessenger
				raise: GbsConnectorError
				message: errorMessage
				with: gsName
				with: self dictionaryName.
			^nil].
	^assocDelegate
]

{ #category : 'private resolving' }
GbsNameConnector >> resolveRequiredServerAssociationInSession: session
[

	^self resolveServerAssociationInSession: session createMissing: false
]

{ #category : 'private resolving' }
GbsNameConnector >> resolveClientObj
[
	"Private.  Resolve and return Smalltalk object to be connected.
		Do not trigger any defunct stub or defunct forwarder errors."

	| stAssoc |
	stAssoc := (BindingReference
				pathString: 'Root.' , self environment name , '.' , stName) bindingOrNil.
	stAssoc isNil
		ifTrue: 
			[self gbsMessenger
				raise: GbsConnectorError
				message: 'Failed to resolve the client object named %1.'
				with: stName.
			^nil].
	self verifyNameAssoc: stAssoc.
	(stAssoc key gbxIsGSDefunct or: [stAssoc value gbxIsGSDefunct])
		ifTrue: 
			[self gbsMessenger raise: GbsConnectorError
				message: 'Defunct stub or forwarder'.
			^nil].
	stAssoc isImmutable ifFalse: [stAssoc gsName: gsName].
	^stAssoc
]

{ #category : 'private resolving' }
GbsNameConnector >> updateGSfromST: anSTObj session: aGSSession
[
	"Private.  Update the GemStone object from specification in the
	 receiver.  Return the GemStone name association."

	^self resolveOrCreateServerAssociationInSession: aGSSession
]

{ #category : 'private resolving' }
GbsNameConnector >> resolveOrCreateServerAssociationInSession: session
[

	^self resolveServerAssociationInSession: session createMissing: true
]

{ #category : 'private resolving' }
GbsNameConnector >> updateClientfromDelegate: delegate
[
	"Private.  Update the Smalltalk object as specified in the receiver.  Return the Smalltalk name association."

	| ref val |
	ref := ('Root.' , self environment name , '.' , stName asString) asQualifiedReference.
	val := ref valueOrDo: [ref environment at: ref simpleName put: nil].
	(val isBehavior and: [self postConnectAction = #forwarder])
		ifTrue: [^self gbsMessenger error: 'A class should never become a forwarder.'].
	binding := ref bindingOrNil.
	binding value: nil.
	self verifyNameAssoc: binding.
	binding markNotDirty.
	^binding
]

{ #category : 'private resolving' }
GbsNameConnector >> variableName
[
	"Private. An ordinary name connector does not have a variable name."

	^nil
]

{ #category : 'private resolving' }
GbsNameConnector >> resolveGSClassInSession: aGSSession ifAbsent: absentBlock
[
	"Private"

	| delegate serverSource |
	serverSource := '[:restrictToDict :dictName :associationName |

	| dictionary association class |
	"Get the binding/association for the connection."
	association := restrictToDict
				ifTrue:
					[association := GsSession currentSession resolveSymbol: dictName.
					association == nil ifTrue: [^nil].
					dictionary := association value.
					dictionary associationAt: associationName otherwise: nil]
				ifFalse:
					[System myUserProfile resolveSymbol: associationName].

	"Answer the class from the association, if there is one. Otherwise answer nil."
	association == nil ifTrue: [^nil].
	class := association value.
	(class isBehavior and: [class isMeta not])
		ifTrue: [class]
		ifFalse: [nil]]'.
	delegate := aGSSession
				unsynchronizedExecuteBlock: serverSource
				with: self hasDictionaryName
				with: self dictionaryName asSymbol
				with: self gsName asSymbol
				context: nil.
	delegate = aGSSession oopNil ifTrue: [^absentBlock value].
	^delegate
]

{ #category : 'private resolving' }
GbsNameConnector >> resolveGSClassInSession: aGSSession
[
	"Private.  Resolve and return GemStone class to be connected"

	| errorMessage |
	^self resolveGSClassInSession: aGSSession
		ifAbsent: 
			[errorMessage := self hasDictionaryName
				ifTrue: ['Failed to resolve the server class named %1 in %2.']
				ifFalse: ['Failed to resolve the server class named %1.'].
			self gbsMessenger
				raise: GbsConnectorError
				message: errorMessage
				with: gsName
				with: self dictionaryName.
			nil]
]

{ #category : 'private initialization' }
GbsNameConnector >> stName: stNm gsName: gsNm dictionaryName: dictNm postConnectAction: pca
[
	"Private.  Initialize with specified values"

	postConnectAction := pca.
	self stName: stNm gsName: gsNm dictionaryName: dictNm
]

{ #category : 'private initialization' }
GbsNameConnector >> stName: stNm gsName: gsNm
[

	"Private.  Initialize with specified values"

	stName := stNm.
	gsName := gsNm
]

{ #category : 'private initialization' }
GbsNameConnector >> stName: stNm gsName: gsNm dictionaryName: dictNm
[
	"Private.  Initialize with specified values"

	stName := stNm.
	gsName := gsNm.
	dictionaryName := dictNm.
	connectionCondition := [true]	"most connectors just connect"
]

{ #category : 'private' }
GbsNameConnector class >> requestNamePrompting: aPrompt ifError: errorBlock
[

	"Prompt the user for a name"

	^self requestNamePrompting: aPrompt initialAnswer: '' ifError: errorBlock
]

{ #category : 'instance creation' }
GbsNameConnector class >> stName: stName gsName: gsName
[

	"Returns a new instance with specified values"

	^self stName: stName gsName: gsName dictionaryName: nil
]

{ #category : 'instance creation' }
GbsNameConnector class >> stName: stName gsName: gsName dictionaryName: dictName
[

	"Returns a new instance with specified values"

	^self basicNew
		stName: stName
		gsName: gsName
		dictionaryName: dictName
		postConnectAction: self defaultPostConnectAction
]

{ #category : 'instance creation' }
GbsNameConnector class >> fromUser
[

	"Prompt the user for information to create an instance of the receiver"
	"self fromUser"
	| stName gsName dictName |
	stName := self requestNamePrompting: 'Client object name' ifError: [ ^nil ].
	gsName := self requestNamePrompting: 'Server object name' initialAnswer: stName ifError: [ ^nil ].
	dictName := self
		requestNamePrompting: 'Server dictionary name'
		initialAnswer: 'UserGlobals'
		ifError: [ ^nil ].

	^self stName: stName gsName: gsName dictionaryName: dictName
]

