Class {
	#name : 'GbsSessionManager',
	#superclass : 'Object',
	#instVars : [
		'clientMap',
		'currentSession',
		'dependents',
		'disconnectedSessions',
		'globalConnectors',
		'isInitialized',
		'isRemote',
		'kernelConnectorConditions',
		'loginProtect',
		'memoryPolicy',
		'numSessionsInInteraction',
		'numSessionsInInteractionProtect',
		'parameters',
		'serverInterface',
		'sessionListProtect',
		'sessions',
		'stats',
		'fastConnectorRegistry'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'as yet unclassified' }
GbsSessionManager class >> globalFastConnectorsList [
    "Returns a list of pairs: #(PharoClassName GemStoneClassName).
     These classes are replicated by value instead of passed by reference (proxy)."
    
    ^ #(
        "Collections"
        #(Array Array)
        #(ByteArray ByteArray)
        #(ByteString String)
        #(WideString DoubleByteString) "Pharo uses WideString, GS uses DoubleByteString"
        #(Symbol Symbol)
        #(ByteSymbol Symbol)
        #(WideSymbol DoubleByteSymbol)
        #(Dictionary Dictionary)
        #(Association Association)
        
        "Numbers"
        #(SmallInteger SmallInteger)
        #(LargePositiveInteger LargePositiveInteger)
        #(LargeNegativeInteger LargeNegativeInteger)
        #(SmallFloat64 Float) "Pharo 64-bit immediate float"
        #(BoxedFloat64 Float) "Pharo 64-bit boxed float"
        #(Fraction Fraction)
        
        "Magnitudes"
        #(Character Character)
        #(Date Date)
        #(Time Time)
        #(DateAndTime DateTime) "Pharo uses DateAndTime, GS/VW uses DateTime/Timestamp"
        
        "Booleans & Nil"
        #(True True)
        #(False False)
        #(UndefinedObject UndefinedObject)
    )
]

{ #category : 'initialization' }
GbsSessionManager class >> initializeFastConnectors [
    "Initialize the global registry of classes that should be passed by value."
    
    | registry |
    registry := Dictionary new.
    
    self globalFastConnectorsList do: [ :pair |
        | clientClass serverClassName |
        clientClass := Smalltalk globals at: pair first ifAbsent: [ nil ].
        serverClassName := pair second.
        
        clientClass ifNotNil: [
            "Map both directions: Client -> Server, and Server -> Client"
            registry at: clientClass name put: serverClassName.
            registry at: serverClassName put: clientClass name.
        ].
    ].

    "Store this in your session manager's class instance variable"
    self fastConnectorRegistry: registry.
]

{ #category : 'actions' }
GbsSessionManager class >> generateClassConnectors [
	^ self initializeFastConnectors
]

{ #category : 'actions' }
GbsSessionManager class >> removeInvalidConnectors [
	| registry cleaned |
	registry := self fastConnectorRegistry ifNil: [ Dictionary new ].
	cleaned := Dictionary new.
	registry keysAndValuesDo: [ :clientName :serverName |
		| clientClass |
		clientClass := Smalltalk globals at: clientName asSymbol ifAbsent: [ nil ].
		clientClass ifNotNil: [
			cleaned at: clientName asString put: serverName asString.
			cleaned at: serverName asString put: clientName asString ] ].
	self fastConnectorRegistry: cleaned.
	^ cleaned
]

{ #category : 'accessing' }
GbsSessionManager class >> connectorPairs [
	| registry pairs seen |
	registry := self fastConnectorRegistry.
	(registry isNil or: [ registry isEmpty ]) ifTrue: [
		self initializeFastConnectors.
		registry := self fastConnectorRegistry ].
	pairs := OrderedCollection new.
	seen := Set new.
	registry keysAndValuesDo: [ :clientName :serverName |
		| clientClass pairKey |
		clientClass := Smalltalk globals at: clientName asSymbol ifAbsent: [ nil ].
		clientClass ifNotNil: [
			pairKey := clientName asString, '->', serverName asString.
			(seen includes: pairKey) ifFalse: [
				pairs add: { clientName asString. serverName asString }.
				seen add: pairKey ] ] ].
	^ pairs asArray
]

{ #category : 'actions' }
GbsSessionManager class >> addConnectorClient: clientClassName server: serverClassName [
	| registry c s |
	c := clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ].
	s := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	(c isEmpty or: [ s isEmpty ]) ifTrue: [ ^ self ].
	registry := self fastConnectorRegistry ifNil: [ Dictionary new ].
	registry at: c put: s.
	registry at: s put: c.
	self fastConnectorRegistry: registry.
]

{ #category : 'actions' }
GbsSessionManager class >> removeConnectorClient: clientClassName server: serverClassName [
	| registry c s |
	c := clientClassName ifNil: [ '' ] ifNotNil: [ clientClassName asString ].
	s := serverClassName ifNil: [ '' ] ifNotNil: [ serverClassName asString ].
	registry := self fastConnectorRegistry ifNil: [ Dictionary new ].
	(registry respondsTo: #removeKey:ifAbsent:) ifTrue: [
		registry removeKey: c ifAbsent: [ ].
		registry removeKey: s ifAbsent: [ ] ].
	self fastConnectorRegistry: registry.
]

{ #category : 'accessing' }
GbsSessionManager class >> fastConnectorRegistry [
	^ Smalltalk globals at: #GbsFastConnectorRegistry ifAbsent: [ Dictionary new ]
]

{ #category : 'accessing' }
GbsSessionManager class >> fastConnectorRegistry: aDictionary [
	Smalltalk globals at: #GbsFastConnectorRegistry put: aDictionary
]

{ #category : 'accessing' }
GbsSessionManager >> fastConnectorRegistry [
    ^ fastConnectorRegistry
]

{ #category : 'accessing' }
GbsSessionManager >> fastConnectorRegistry: aDictionary [
    fastConnectorRegistry := aDictionary
]

{ #category : 'accessing' }
GbsSessionManager >> globalFastConnectorsList [
    ^ #(
        #(Array Array)
        #(ByteString String)
        #(DateAndTime DateTime)
    )
]

{ #category : 'accessing' }
GbsSessionManager >> initializeFastConnectors [
    | registry |
    registry := Dictionary new.
    
    self globalFastConnectorsList do: [ :pair |
        | clientClassName serverClassName |
        clientClassName := pair first.
        serverClassName := pair second.
        
        "Map Client -> Server"
        registry at: clientClassName put: serverClassName.
        
        "Map Server -> Client"
        registry at: serverClassName put: clientClassName.
    ].

    self fastConnectorRegistry: registry.
]
