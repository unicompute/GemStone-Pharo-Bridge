Class {
	#name : #'GbsClassConnector',
	#superclass : #'GbsNameConnector',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'gbs private testing' }
GbsClassConnector >> isClassConnectorTypeNone
	"Private to GBS"

	^self postConnectAction == #none

{ #category : #'private resolving' }
GbsClassConnector >> updateClientfromDelegate: delegate
	"Private.  Update the Smalltalk object from the given GemStone object.  Return the Smalltalk object."

	| cat oldClass |
	self postConnectAction = #forwarder
		ifTrue: 
			[^self gbsMessenger error: 'Class connectors should not create a forwarder'].	"the only invalid value dispatched here"
	"postConnectAction is #updateST"
	oldClass := self resolveSTObjMustBeDefined: false.
	(oldClass isNil or: [GbsConfiguration isVisualWorksImage not])
		ifTrue: [cat := 'UserClasses']
		ifFalse: [cat := oldClass category asString].
	^delegate session
		createClientClassFor: delegate
		usingName: stName
		classified: cat
		generateConnector: false

{ #category : #'private resolving' }
GbsClassConnector >> updateGSfromST: stClass session: aGSSession
	"Private"

	| oldClass newClass |
	oldClass := self resolveGSObjInSession: aGSSession ifFail: [nil].
	newClass := aGSSession
				createServerClassFor: stClass
				inDictionaryNamed: self dictionaryName
				usingName: gsName
				generateConnector: false.
	oldClass isNil
		ifFalse: 
			["An old version of the class exists.  Recompile subclasses & behavior"
			aGSSession versionedOldClass: oldClass withNewClass: newClass].
	^newClass

{ #category : #'private resolving' }
GbsClassConnector >> resolveClientObj
		"Private.  Resolve and return Smalltalk class to be connected.
		Raise exception if stName does not resolve to a client class."

	^ self resolveSTObjMustBeDefined: true.

{ #category : #'private resolving' }
GbsClassConnector >> resolveGSObjInSession: aGSSession
	"Private.  Resolve and return GemStone class to be connected"

	^self resolveGSClassInSession: aGSSession

{ #category : #'private resolving' }
GbsClassConnector >> resolveSTObjMustBeDefined: enforceBool 
	"Private.  Resolve and return Smalltalk class to be connected.
		Raise exception if stName resolves to an object that is not a client class.
		If stName is not defined, return nil if enforceBool is false, otherwise raise
		exception."

	| stObj |
	stObj := (BindingReference pathString: stName) bindingOrNil value.
	stObj isNil 
		ifTrue: 
			[enforceBool 
				ifTrue: 
					[self gbsMessenger 
						raise: GbsConnectorError
						message: 'Failed to resolve the client class named %1.'
						with: stName].
			^nil].
	(stObj isBehavior and: [stObj gbxIsMeta not]) 
		ifFalse: 
			[self gbsMessenger 
				raise: GbsConnectorError
				message: 'The client object named %1 is not a class.'
				with: stName.
			^nil].
	stObj gbxIsGSDefunct 
		ifTrue: 
			[self gbsMessenger
				raise: GbsConnectorError
				message: 'Defunct stub or forwarder'.
			^nil].
	^stObj

{ #category : #'connecting' }
GbsClassConnector >> disconnectInSession: session
	"Resolve my server and client objects, and make sure both are unconnected in session, whether or not
	they are connected to each other.
	If neither can be resolved, do nothing. Client metaclasses are also disconnected."

	| client serverClass serverMetaclass |
	client := self resolveSTObjIfFail: [nil].
	session sessionCritical: 
			[serverClass := self resolveGSObjInSession: session ifFail: [nil].
			serverClass ~~ nil
				ifTrue: 
					[serverMetaclass := session unsynchronizedExecute: 'self class'
								context: serverClass].
			client ~~ nil
				ifTrue: 
					[| toDisconnect |
					(client isBehavior and: [client isMeta not])
						ifFalse: 
							[self gbsMessenger
								error: 'Class connector is connecting a non-class object'].
					toDisconnect := Array with: client with: client gbxBasicClass.
					toDisconnect do: 
							[:obj |
							| del |
							del := session cacheAtST: obj.
							del ~~ nil ifTrue: [session disconnectClient: obj fromServer: del]]].
			"If we didn't resolve a server class, it could be nil or it could be oopNil"
			(serverClass ~~ nil and: [serverClass isSpecial not])
				ifTrue: 
					[| toDisconnect |
					toDisconnect := Array with: serverClass with: serverMetaclass.
					toDisconnect do: 
							[:del |
							| clientForServer |
							clientForServer := session clientObjForDelegate: del otherwise: nil.
							clientForServer ~~ nil
								ifTrue: [session disconnectClient: clientForServer fromServer: del]]]]

{ #category : #'private connecting' }
GbsClassConnector >> postConnectClient: clientObj server: delegate inSession: session
	"Class connectors don't need to do anything here, but must override the NameConnector behavior."

{ #category : #'private connecting' }
GbsClassConnector >> validPostConnectActions
	"Private"

	| valid |
	valid := self class validPostConnectActions asSet.
	valid remove: #forwarder; remove: #clientForwarder.
	^valid asArray

{ #category : #'private' }
GbsClassConnector >> clientObjIsUnstubbedClass
	"Private.  For building replication clamps, we need to be sure that unstubbing will not happen or
	we end up in an infinite loop."

	binding := stName asQualifiedReference bindingOrNil.
	^binding notNil
		and: [binding value zzzisStub not and: [binding value isBehavior]]

{ #category : #'private' }
GbsClassConnector >> verifyoldST: oldST newST: newST oldGS: oldGS newGS: newGS session: aGSSession

	"Private.  If verification is turned on, verify that class structures match"

	| ok |
	ok := super verifyoldST: oldST newST: newST oldGS: oldGS newGS: newGS session: aGSSession.
	ok ifFalse: [ ^false ].
	(aGSSession doesClientClass: newST matchServerClass: newGS)
		ifTrue: [ ^true ]
		ifFalse: [
			aGSSession disconnectClient: newST fromServer: newGS.
			self gbsMessenger
				raise: GbsConnectorError
				message: 'Smalltalk %1 and GemStone %2 are not compatible.'
				with: stName
				with: gsName.
			^false
		]

{ #category : #'private' }
GbsClassConnector >> nilSTObj
	"Private.  Don't nil out class connectors."

{ #category : #'private' }
GbsClassConnector >> isClassConnector

	"Private.  Answer true if the connector is a class connector. "

	^ true

{ #category : #'private' }
GbsClassConnector >> connectsAssociation
	"Private"

	^false

{ #category : #'class constants' }
GbsClassConnector class >> defaultPostConnectAction

	^#none

{ #category : #'instance creation' }
GbsClassConnector class >> fromUser

	"Prompt the user for information to create an instance of the receiver"
	"self fromUser"
	| stName gsName dictName |
	stName := self requestNamePrompting: 'Client class name' ifError: [ ^nil ].
	gsName := self requestNamePrompting: 'GemStone class name' initialAnswer: stName ifError: [ ^nil ].
	dictName := self
		requestNamePrompting: 'Server dictionary name'
		initialAnswer: 'UserGlobals'
		ifError: [ ^nil ].

	^self stName: stName gsName: gsName dictionaryName: dictName

{ #category : #'instance creation' }
GbsClassConnector class >> new

	"Class connectors do not update either the GemStone or Smalltalk object by default"

	^self basicNew

