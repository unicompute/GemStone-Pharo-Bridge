Class {
	#name : 'GbsClassVarConnector',
	#superclass : 'GbsNameConnector',
	#instVars : [
		'cvarName',
		'gsvarName'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private accessing' }
GbsClassVarConnector >> gsvarName

	"Private.  If gsvarName is not set, use cvarName.  This is so upgraded images will work (in 3.0, gsvarName did not exist)"
	gsvarName isNil
		ifTrue: [ ^cvarName ]
		ifFalse: [ ^gsvarName ]

{ #category : 'private accessing' }
GbsClassVarConnector >> stvarName
"Private"

	^cvarName asSymbol

{ #category : 'private' }
GbsClassVarConnector >> nilSTObj
	"Private.  nil the Smalltalk object for the connector if the
	 post connect action is #updateST or #forwarder. This is done
	 during post logout to reduce defunct stub errors. Answer the
	 receiver. This must be done after the session caches are emptied, 
	so this will not attempt to mark me dirty."

	| pca |
	pca := self postConnectAction.
	(pca == #forwarder or: [pca == #updateST]) ifFalse: [^self].
	
	[binding := self resolveSTClass bindingFor: self stvarName asSymbol.
	binding isNil ifFalse: [binding value: nil]]
			on: GbsConnectorError
			do: [:ex | ex return: nil]

{ #category : 'private connecting' }
GbsClassVarConnector >> validPostConnectActions
	"Private"

	^self class validPostConnectActions.

{ #category : 'printing' }
GbsClassVarConnector >> printOn: aStream

	super printOn: aStream.

	aStream nextPutAll: ' stvarName: '.
	self stvarName printOn: aStream.
	aStream nextPutAll: ' gsvarName: '.
	self gsvarName printOn: aStream.

{ #category : 'private printing' }
GbsClassVarConnector >> gsDescription
	"Private - do not delete as it is sent by the gui code with a #perform:, 
	see the #windowSpec for GbsConnectorBrowser"

	^gsName printString, ' (', self gsvarName printString, ')'

{ #category : 'private printing' }
GbsClassVarConnector >> clientObjDescription
	"Private"

	^stName asSymbol printString, ' (', self stvarName asSymbol printString, ')'

{ #category : 'private printing' }
GbsClassVarConnector >> stDescription
	"Private. Sent by aspect adaptor in connector browser"

	^stName asSymbol printString, ' (', self stvarName asSymbol printString, ')'

{ #category : 'private resolving' }
GbsClassVarConnector >> updateGSfromST: anSTObj session: aGSSession

	| gsClass vars gsObj |
	gsClass := self resolveGSClassInSession: aGSSession
				ifAbsent: [self gemStoneClassForSession: aGSSession].
	vars := gsClass performOnGsServer: #classVarNames.
	(vars includes: self gsvarName)
		ifFalse: 
			["Private.  No such class instance variable"
			gsClass remotePerform: #addClassVarName: with: self gsvarName].
	gsObj := self resolveGSObjInSession: aGSSession.
	gsObj markStDirty: anSTObj.
	^gsObj

{ #category : 'private resolving' }
GbsClassVarConnector >> variableName
	"Private"

	^self gsvarName asSymbol

{ #category : 'private resolving' }
GbsClassVarConnector >> resolveSTClass
	"Private"

	| cls |
	binding := ('Root.' , self environment name , '.' , stName)
				asQualifiedReference bindingOrNil.
	binding isNil
		ifTrue: 
			[self gbsMessenger
				raise: GbsConnectorError
				message: 'Failed to resolve the client class named %1.'
				with: stName.
			^nil].
	cls := binding value.
	(cls isBehavior and: [cls isMeta not])
		ifFalse: 
			[self gbsMessenger
				raise: GbsConnectorError
				message: 'The client object named %1 is not a class.'
				with: stName.
			^nil].
	^cls

{ #category : 'private resolving' }
GbsClassVarConnector >> serverAssociationResolvingString

	^'[:restrictToDict :dictName :associationName :classVarName :shouldCreate |

	"Get the dictionary that it goes in if we have to create it. Fail if it''s bad."
	| dictionary association class |
	association := GsSession currentSession resolveSymbol: dictName.
	association == nil ifTrue: [^nil].

	dictionary := association value.
	"Get the binding/association for the class (purported)."
	association := restrictToDict
				ifTrue: [dictionary associationAt: associationName otherwise: nil]
				ifFalse: [System myUserProfile resolveSymbol: associationName].

	"If there is one, see if it is a class and get the class variable association."
	association ~~ nil
		ifTrue: 
			[class := association value.
			class isBehavior ifFalse: [^nil].
			association := class _classVars associationAt: classVarName otherwise: nil].

	^association]'

{ #category : 'private resolving' }
GbsClassVarConnector >> gemStoneClassForSession: aGSSession

	| clientClass |
	clientClass := self resolveSTClass.
	^self hasDictionaryName
		ifTrue: [aGSSession gemStoneClassFor: clientClass inDictionaryNamed: self dictionaryName]
		ifFalse: [aGSSession gemStoneClassFor: clientClass]

{ #category : 'private resolving' }
GbsClassVarConnector >> resolveGSObjInSession: session
	"Private.  Resolve and return GemStone object to be connected - the association containing the class variable"

	| gsClass gsAssoc |
	gsClass := self resolveGSClassInSession: session.
	gsAssoc := session
				executeBlock: '[:theClass :varName | theClass _classVars associationAt: varName otherwise: nil]'
				with: gsClass
				with: self gsvarName asSymbol
				context: session oopIllegal.

	"Do not fault the gsAssoc -- if the SymbolAssociation is cached, 
	the consistency check for a connection overriding an existing connection will fail."
	gsAssoc = session oopNil
		ifTrue: 
			[self gbsMessenger
				raise: GbsConnectorError
				message: 'No class variable named %1 in the server class %2.'
				with: self gsvarName
				with: gsName.
			^nil].
	^gsAssoc

{ #category : 'private initialization' }
GbsClassVarConnector >> stName: stNm gsName: gsNm stvarName: stvNm gsvarName: gsvNm
	"Private.  Initialize with specified values"

	stName := stNm.
	gsName := gsNm.
	cvarName := stvNm.
	gsvarName := gsvNm.
	connectionCondition := [true]

{ #category : 'private initialization' }
GbsClassVarConnector >> stName: stNm gsName: gsNm cvarName: cvNm

	"Private.  The class variable name is the same in Smalltalk and GemStone"

	^self stName: stNm gsName: gsNm dictionaryName: nil stvarName: cvNm gsvarName: cvNm

{ #category : 'private initialization' }
GbsClassVarConnector >> stName: stNm gsName: gsNm dictionaryName: dictNm stvarName: stvNm gsvarName: gsvNm
	"Private.  Initialize with specified values"

	stName := stNm.
	gsName := gsNm.
	dictionaryName := dictNm.
	cvarName := stvNm.
	gsvarName := gsvNm.
	connectionCondition := [true]

{ #category : 'private initialization' }
GbsClassVarConnector >> stName: stNm gsName: gsNm

	"Private.  Use stName:gsName:cvarName:"

	self stName: stNm gsName: gsNm cvarName: ''

{ #category : 'instance creation' }
GbsClassVarConnector class >> stName: stName gsName: gsName cvarName: cvName

	"Returns a new instance with specified values"

	^self new stName: stName gsName: gsName dictionaryName: nil stvarName: cvName gsvarName: cvName

{ #category : 'instance creation' }
GbsClassVarConnector class >> stName: stName gsName: gsName dictionaryName: dictName stvarName: stvName gsvarName: gsvName

	"Returns a new instance with specified values"

	^self new stName: stName gsName: gsName dictionaryName: dictName stvarName: stvName gsvarName: gsvName

{ #category : 'instance creation' }
GbsClassVarConnector class >> fromUser

	"Prompt the user for information to create an instance of the receiver"
	"self fromUser"
	| stName gsName stvarName gsvarName dictName |
	stName := self requestNamePrompting: 'Client class name' ifError: [ ^nil ].
	stvarName := self requestNamePrompting: 'Client class variable name' ifError: [ ^nil ].
	gsName := self requestNamePrompting: 'Server class name' initialAnswer: stName ifError: [ ^nil ].
	gsvarName := self requestNamePrompting: 'Server class variable name' initialAnswer: stvarName ifError: [ ^nil ].
	dictName := self
		requestNamePrompting: 'Server dictionary name'
		initialAnswer: 'UserGlobals'
		ifError: [ ^nil ].

	^self stName: stName gsName: gsName dictionaryName: dictName stvarName: stvarName gsvarName: gsvarName

{ #category : 'instance creation' }
GbsClassVarConnector class >> stName: stName gsName: gsName stvarName: stvName gsvarName: gsvName

	"Returns a new instance with specified values"

	^self new stName: stName gsName: gsName dictionaryName: nil stvarName: stvName gsvarName: gsvName

