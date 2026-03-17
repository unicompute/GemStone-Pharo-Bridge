Class {
	#name : #'GbsClassInstVarConnector',
	#superclass : #'GbsClassVarConnector',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'private resolving' }
GbsClassInstVarConnector >> updateClientfromDelegate: delegate

	| stMeta stClass offset pca |
	stClass := self resolveSTClass.
	stMeta := stClass class.
	pca := self postConnectAction.

	"Private.  Ensure the specified Smalltalk class instance variable exists"
	offset := stMeta allInstVarNames indexOf: self stvarName asString ifAbsent: [ 0 ].
	offset == 0 ifTrue: [
		stMeta := stMeta addInstVarName: self stvarName.
		stClass := self resolveSTClass.
		offset := stMeta allInstVarNames indexOf: self stvarName asString.
	].

	"Prepare the class instvar for updating.  Update by doing an instVarAt:put:"
	self resolveSTObjCheckingIfDefunct: false.
	^stClass instVarAt: offset put: (pca == #forwarder
		ifTrue: [ delegate asForwarder ]
		ifFalse: [ delegate asLocalObject ])

{ #category : #'private resolving' }
GbsClassInstVarConnector >> updateGSfromST: anSTObj session: aGSSession
	"Private.  Make sure the GemStone variable exists.  Updating its value will happen during postConnect"

	| gsClass gsObj |
	gsClass := self resolveGSClassInSession: aGSSession
				ifAbsent: [self gemStoneClassForSession: aGSSession].
	[gsClass remotePerform: #atClassInstVar: with: self gsvarName]
		on: (GbsError signalFor: #classErrNotAVar)
		do: 
			[:ex |
			"No such class instance variable"
			gsClass remotePerform: #addClassInstanceVariable: with: self gsvarName].
	gsObj := self resolveGSObjInSession: aGSSession.
	(aGSSession smalltalkClassFor: gsObj unsynchronizedRemoteClass)
		= anSTObj class
			ifTrue: 
				["To preserve GemStone object identity"
				gsObj markStDirty: anSTObj]
			ifFalse: 
				["Have to reassign the class instance variable"
				gsObj := anSTObj putInGSSession: aGSSession.
				(self resolveGSClassInSession: aGSSession)
					remotePerform: #atClassInstVar:put:
					with: self gsvarName
					with: gsObj].
	^gsObj

{ #category : #'private resolving' }
GbsClassInstVarConnector >> resolveClientObj
	"Private.  Resolve and return Smalltalk object to be connected.
	Trigger any defunct stub or defunct forwarder errors."

	^self resolveSTObjCheckingIfDefunct: true

{ #category : #'private resolving' }
GbsClassInstVarConnector >> resolveGSObjInSession: aGSSession
	"Private.  Resolve and return GemStone object to be connected - the value of the inst var of the class"

	| gsClass value |
	gsClass := self resolveGSClassInSession: aGSSession.
	[value := gsClass remotePerform: #atClassInstVar: with: self gsvarName]
		on: GbsError errorSignal
		do: 
			[:ex |
			self gbsMessenger raise: GbsConnectorError message: ex description.
			ex return: nil].
	^value

{ #category : #'private resolving' }
GbsClassInstVarConnector >> resolveSTObjCheckingIfDefunct: check
	"Private.  Resolve and return Smalltalk object to be connected.  If <check> is true, check for defunctness."

	| stClass stMeta offset civar |
	stClass := self resolveSTClass.
	stMeta := stClass class.
	offset := stMeta allInstVarNames indexOf: self stvarName asString ifAbsent: [ 0 ].
	offset == 0 ifTrue: [
		self gbsMessenger
			raise: GbsConnectorError
			message: 'No class instance variable named %1 in the client class %2.'
			with: self stvarName
			with: stClass name.
		^nil
	].
	civar := stClass instVarAt: offset.
	(check and: [civar gbxIsGSDefunct]) ifTrue: [
		self gbsMessenger
			raise: GbsConnectorError
			message: 'Defunct stub or forwarder'.
		^nil
	].
	^civar

{ #category : #'connecting' }
GbsClassInstVarConnector >> disconnectInSession: session
	"Resolve my GemStone and Smalltalk objects, and make sure they are both unconnected in aGSSession, even if they are no longer connected to each other. The latter condition will be true if one of the client or server variables has been assigned to, since class instance variable connectors cannot track assignments as other name connectors can.
	If one cannot be resolved, still disconnect the other. If neither can be resolved, do nothing"

	| client server |
	client := self resolveSTObjIfFail: [nil].
	session sessionCritical: 
			[server := self resolveGSObjInSession: session ifFail: [nil].
			client ~~ nil
				ifTrue: 
					[| serverForClient |
					serverForClient := session cacheAtST: client.
					serverForClient ~~ nil ifTrue: [session disconnectClient: client fromServer: serverForClient]].
			(server ~~ nil and: [server isSpecial not])
				ifTrue: 
					[| clientForServer |
					clientForServer := session clientObjForDelegate: server otherwise: nil.
					clientForServer ~~ nil ifTrue: [session disconnectClient: clientForServer fromServer: server]]]

{ #category : #'private connecting' }
GbsClassInstVarConnector >> clientForwarderTo: clientObject session: sess
	"Return a delegate for the client forwarder I specify. If the server variable holds anything other than a
	 ClientForwarder, assign a new ClientForwarder to the server variable."

	| cfDelegate |
	cfDelegate := self resolveGSObjInSession: sess.
	cfDelegate remoteClassIsClientForwarder
		ifFalse: 
			["Do an in-context class instvar assignment, which gets around class invariance."
			cfDelegate := cfDelegate session
						execute: '| cf | cf := ClientForwarder new. ', self gsvarName, ' := cf. ^cf'
						context: (self resolveGSClassInSession: sess)].
	^cfDelegate

{ #category : #'private connecting' }
GbsClassInstVarConnector >> postConnectClient: clientObj server: cfDelegate inSession: sess
	"Private"
	"Must identity clamp client forwarders once connected to avoid propagating client changing to the server,
	and to avoid getting reports for the ClientForwarder"

	self postConnectAction == #clientForwarder
		ifTrue: [sess addClampedObject: clientObj withDelegate: cfDelegate]

{ #category : #'private connecting' }
GbsClassInstVarConnector >> canForwardTo: clientObject inSession: aSession
	"Answer true iff the client object is something that a server ClientForwarder can be connected to.
	Sender must hold sessionProtect."

	^(clientObject gbxIsServerSpecialInSession: aSession) not

{ #category : #'private' }
GbsClassInstVarConnector >> nilSTObj
	"Private.  nil the Smalltalk object for the connector if the
	 post connect action is #updateST or #forwarder. This is done
	 during post logout to reduce defunct stub errors. Answer
	 the receiver."

	| pca |
	pca := self postConnectAction.
	( pca == #forwarder or: [ pca == #updateST ] )
		ifFalse: [ ^self ].
	[
		|stClass stMeta offset |
		stClass := self resolveSTClass.
		stMeta := stClass class.
		offset := stMeta allInstVarNames
			indexOf: self stvarName asString
			ifAbsent: [ 0 ].
		offset == 0
			ifFalse: [stClass instVarAt: offset put: nil]
	]
		on: GbsConnectorError
		do: [ :ex | ex return: nil ]

{ #category : #'private' }
GbsClassInstVarConnector >> connectsAssociation
	"Private"

	^false

{ #category : #'instance creation' }
GbsClassInstVarConnector class >> fromUser

	"Prompt the user for information to create an instance of the receiver"
	"self fromUser"
	| stName gsName stvarName gsvarName dictName |
	stName := self requestNamePrompting: 'Client class name' ifError: [ ^nil ].
	stvarName := self requestNamePrompting: 'Client class instance variable name' ifError: [ ^nil ].
	gsName := self requestNamePrompting: 'Server class name' initialAnswer: stName ifError: [ ^nil ].
	gsvarName := self requestNamePrompting: 'Server class instance variable name' initialAnswer: stvarName ifError: [ ^nil ].
	dictName := self
		requestNamePrompting: 'Server dictionary name'
		initialAnswer: 'UserGlobals' 
		ifError: [ ^nil ].

	^self stName: stName gsName: gsName dictionaryName: dictName stvarName: stvarName gsvarName: gsvarName

