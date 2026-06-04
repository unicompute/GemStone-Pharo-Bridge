Extension { #name : 'GbsNameConnector' }

{ #category : '*GemStone-GBS-Core' }
GbsNameConnector class >> stName: aClientName gsName: aServerName dictionaryName: aDictionaryName [
	^ (self stName: aClientName gsName: aServerName)
		dictionaryName: aDictionaryName;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbsNameConnector class >> stName: aClientName gsName: aServerName dictionaryName: aDictionaryName postConnectAction: anAction [
	^ self new
		stName: aClientName
		gsName: aServerName
		dictionaryName: aDictionaryName
		postConnectAction: anAction;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbsNameConnector >> connectorClientName [
	^ self stName
]

{ #category : '*GemStone-GBS-Core' }
GbsNameConnector >> connectorClientName: aString [
	^ self stName: aString
]

{ #category : '*GemStone-GBS-Core' }
GbsNameConnector >> connectorServerName [
	^ self gsName
]

{ #category : '*GemStone-GBS-Core' }
GbsNameConnector >> connectorServerName: aString [
	^ self gsName: aString
]

{ #category : '*GemStone-GBS-Core' }
GbsNameConnector >> dictionaryName [
	^ self hasDictionaryName
		ifTrue: [ dictionaryName asString ]
		ifFalse: [ 'UserGlobals' ]
]

{ #category : '*GemStone-GBS-Core' }
GbsNameConnector >> dictionaryName: aString [
	dictionaryName := aString
		ifNil: [ nil ]
		ifNotNil: [ aString asString ].
	^ dictionaryName
]

{ #category : '*GemStone-GBS-Core' }
GbsNameConnector >> hasDictionaryName [
	^ dictionaryName notNil
		and: [ dictionaryName asString trimBoth isEmpty not ]
]

{ #category : '*GemStone-GBS-Core' }
GbsNameConnector >> resolveGSObjInSession: aSession ifFail: failBlock [
	| serverSymbol |
	aSession ifNil: [ ^ failBlock value ].
	serverSymbol := self gsName asString asSymbol.
	(self hasDictionaryName and: [ self dictionaryName ~= 'UserGlobals' ]) ifTrue: [
		^ [ (aSession symbolDictionaryNamed: self dictionaryName) at: serverSymbol ifAbsent: failBlock ]
			on: Error
			do: [ failBlock value ] ].
	^ [ aSession namedObjectAt: serverSymbol ifAbsent: failBlock ]
		on: Error
		do: [ failBlock value ]
]

{ #category : '*GemStone-GBS-Core' }
GbsNameConnector >> stName: aClientName gsName: aServerName dictionaryName: aDictionaryName [
	self
		stName: aClientName;
		gsName: aServerName;
		dictionaryName: aDictionaryName.
	^ self
]

{ #category : '*GemStone-GBS-Core' }
GbsNameConnector >> stName: aClientName gsName: aServerName dictionaryName: aDictionaryName postConnectAction: anAction [
	self postConnectAction: anAction.
	^ self stName: aClientName gsName: aServerName dictionaryName: aDictionaryName
]
