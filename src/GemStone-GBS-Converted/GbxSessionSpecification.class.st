Class {
	#name : 'GbxSessionSpecification',
	#superclass : 'Object',
	#instVars : [
		'connectors',
		'username',
		'password',
		'sessionClass'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxSessionSpecification >> connectors: anObject

	connectors := anObject

{ #category : 'accessing' }
GbxSessionSpecification >> username: aUsername

	username := aUsername

{ #category : 'accessing' }
GbxSessionSpecification >> username

	^username

{ #category : 'accessing' }
GbxSessionSpecification >> sessionClass: aClass

	sessionClass := aClass

{ #category : 'accessing' }
GbxSessionSpecification >> sessionClass

	^sessionClass

{ #category : 'accessing' }
GbxSessionSpecification >> password

	^password

{ #category : 'accessing' }
GbxSessionSpecification >> password: aPassword

	password := aPassword

{ #category : 'private-initialization' }
GbxSessionSpecification >> isX509

	^false

{ #category : 'private-initialization' }
GbxSessionSpecification >> initialize
	"Private"

	connectors := Set new.
	sessionClass := GbsSession.

{ #category : 'private-initialization' }
GbxSessionSpecification >> rehashConnectors

	"Private.  If the value of any connector's Smalltalk object has changed, this will fix the resulting hash table corruption"
	connectors rehash

{ #category : 'connectors' }
GbxSessionSpecification >> removeConnector: aGSConnector 
	"We're aggressive about rehashing because the hash value of connectors changes if the Smalltalk object it resolves to changes"

	connectors
		rehash;
		remove: aGSConnector ifAbsent: [nil]

{ #category : 'connectors' }
GbxSessionSpecification >> addConnector: aConnector

	"Add aConnector to our collection of GbsConnectors.  These
	 are definitions of relationships between Smalltalk and GemStone
	 objects which survive across sessions.  At login time, connections
	 are created (object/proxy relationships added to the session's
	 caches) by asking each GbsConnector to connect within the
	 session.  Upon executing this method, aConnector will be
	 connected in all sessions currently logged in with these parameters."

	^self addConnectors: (Array with: aConnector)

{ #category : 'connectors' }
GbxSessionSpecification >> addNoConnectConnector: aConnector

	"Add aConnector to our collection of GbsConnectors.  These are
	 definitions of relationships between Smalltalk and GemStone
	 objects which survive across sessions.  At login time, connections
	 are created (object/proxy relationships added to the session's
	 caches) by asking each GbsConnector to connect within the
	 session."

	^self addNoConnectConnectors: (Array with: aConnector)

{ #category : 'connectors' }
GbxSessionSpecification >> addNoConnectConnectors: collectionOfConnectors
	"Add each connector in the collection collectionOfConnectors to
	 the receiver's collection of GbsConnectors.  These are definitions
	 of relationships between Smalltalk and GemStone objects which
	 survive across sessions.  At login time, connections are created
	 (object/proxy relationships added to the session's caches) by asking
	 each GbsConnector to connect within the session."

	"We're aggressive about this because the hash value of connectors
	 changes if the Smalltalk object it resolves to changes"

	| stobj |
	connectors rehash.

	"First, remove any pre-existing connector that resolves to the same stObj"
	collectionOfConnectors do: 
			[:aConnector |
			connectors remove: aConnector ifAbsent: [nil].
			connectors add: aConnector.
			stobj := aConnector resolveSTObjIfFail: [nil]]

{ #category : 'connectors' }
GbxSessionSpecification >> addConnectors: collectionOfConnectors

	"Add each connector in collectionOfConnectors to our collection
	 of GbsConnectors.  These are definitions of relationships between
	 Smalltalk and GemStone objects which survive across sessions.
	 At login time, connections are created (object/proxy relationships
	 added to the session's caches) by asking each GbsConnector to
	 connect within the session.  Upon executing this method,
	 collectionOfConnectors will be connected in all sessions
	 currently logged in with these parameters."

	self addNoConnectConnectors: collectionOfConnectors.
	(GBSM sessionsWithParameters: self) do: [ :sess |
		collectionOfConnectors do: [ :connector |
			connector connectInSession: sess ]]

{ #category : 'printing' }
GbxSessionSpecification >> storeOn: aStream
	"Produce a store string which survives instance variable reordering"

	aStream
		nextPutAll: '("';
		print: self;
		nextPutAll: '" ';
		store: self class;
		nextPutAll: ' new'.
	self class allInstVarNames doWithIndex: 
			[:eachInstVar :index |
			aStream
				space;
				nextPutAll: eachInstVar;
				nextPutAll: ': ';
				store: (self instVarAt: index);
				nextPutAll: ';'].
	aStream nextPutAll: ' yourself)'

{ #category : 'private - connectors' }
GbxSessionSpecification >> nilAllConnectors
	"Private.  nil the Smalltalk object for all session-based connectors that are either
	name, class var, or class inst var connectors and have a post connect action
	of #updateST or #forwarder."

	GBSM nilAllConnectors: self connectorList

{ #category : 'private - connectors' }
GbxSessionSpecification >> connectors

	^connectors

{ #category : 'private - connectors' }
GbxSessionSpecification >> connectorList

	"Private.  A Set of GbsConnectors to be connected whenever this session logs in"
	^connectors

{ #category : 'private - connectors' }
GbxSessionSpecification >> connectorExistsFor: anObject

	"Private.  If a global or session-parameters-based connector exists for anObject,
	 return true, otherwise return false"

	(self connectorList
		detect: [ :conn | (conn resolveSTObjIfFail: [ nil ]) == anObject ]
		ifNone: [ nil ]) isNil ifFalse: [ ^true ].
	(GBSM connectorList
		detect: [ :conn | (conn resolveSTObjIfFail: [ nil ]) == anObject ]
		ifNone: [ nil ]) isNil ifFalse: [ ^true ].
	^false

{ #category : 'private - connectors' }
GbxSessionSpecification >> allClassConnectorsDo: aBlock

	"Private.  Iterate over session and global connectors, in merged sorted order.  Class connectors come first, in superclass order."

	GBSM allClassConnectors: connectors do: aBlock

{ #category : 'private - connectors' }
GbxSessionSpecification >> removeClassConnectorsFor: aStClass
	" Private.  Remove the class connector for aStClass, if one exists.
	NOTE:  This works only on session connectors.  It does not affect any global connectors. "

	| list |
	list := OrderedCollection new.
	connectors do: 
			[:aConnector |
			(aConnector isClassConnector
				and: [aConnector gsName asString = aStClass name asString])
					ifTrue: [list add: aConnector]].
	list do: [:aClassConnector | self removeConnector: aClassConnector]

