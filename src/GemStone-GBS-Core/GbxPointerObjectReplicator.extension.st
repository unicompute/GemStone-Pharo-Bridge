Extension { #name : 'GbxPointerObjectReplicator' }

{ #category : '*GemStone-GBS-Core' }
GbxPointerObjectReplicator >> fetchMissingServerInstVarNames [
	| names |
	names := (session notNil and: [ session respondsTo: #executeScriptAndFetchObject: ])
		ifTrue: [
			[ session executeScriptAndFetchObject: self serverInstVarNamesScript ]
				on: Error
				do: [ #() ] ]
		ifFalse: [ #() ].
	^ self initializeForServerInstVarNames: (names ifNil: [ #() ])
]

{ #category : '*GemStone-GBS-Core' }
GbxPointerObjectReplicator >> initializeForServerInstVarNames: aCollection [
	serverInstVarNames := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ].
	serverToClientOffsets := nil.
	^ serverInstVarNames
]

{ #category : '*GemStone-GBS-Core' }
GbxPointerObjectReplicator >> initializeServerOffsets [
	| clientNames explicitMappings clientNamesMappedToNil offsets |
	clientNames := self normalizedClientInstVarNames.
	explicitMappings := Dictionary new.
	clientNamesMappedToNil := Set new.
	self normalizedInstVarMap do: [ :mapping |
		| clientName serverName |
		mapping size >= 2 ifTrue: [
			clientName := self normalizedInstVarName: mapping first.
			serverName := self normalizedInstVarName: mapping second.
			serverName
				ifNil: [
					clientName ifNotNil: [
						clientNamesMappedToNil add: clientName ] ]
				ifNotNil: [
					explicitMappings at: serverName put: clientName ] ] ].
	offsets := self serverInstVarNames collect: [ :serverName |
		| mappedClientName |
		mappedClientName := explicitMappings
			at: (self normalizedInstVarName: serverName)
			ifAbsent: [ self normalizedInstVarName: serverName ].
		(mappedClientName isNil or: [ clientNamesMappedToNil includes: mappedClientName ])
			ifTrue: [ nil ]
			ifFalse: [ clientNames indexOf: mappedClientName ifAbsent: [ nil ] ] ].
	serverToClientOffsets := offsets asArray.
	^ serverToClientOffsets
]

{ #category : '*GemStone-GBS-Core' }
GbxPointerObjectReplicator >> isComplete [
	^ serverInstVarNames notNil
]

{ #category : '*GemStone-GBS-Core-private' }
GbxPointerObjectReplicator >> namedInstVarValuesInServerOrderFor: anObject unmappedValue: unmappedValue [
	^ self serverToClientOffsets collect: [ :clientIndex |
		clientIndex
			ifNil: [ unmappedValue ]
			ifNotNil: [ anObject instVarAt: clientIndex ] ]
]

{ #category : '*GemStone-GBS-Core-private' }
GbxPointerObjectReplicator >> normalizedClientInstVarNames [
	clientClass ifNil: [ ^ #() ].
	(clientClass respondsTo: #allInstVarNames) ifFalse: [ ^ #() ].
	^ clientClass allInstVarNames collect: [ :each |
		self normalizedInstVarName: each ]
]

{ #category : '*GemStone-GBS-Core-private' }
GbxPointerObjectReplicator >> normalizedInstVarMap [
	clientClass ifNil: [ ^ #() ].
	(clientClass respondsTo: #instVarMap) ifFalse: [ ^ #() ].
	^ [ clientClass instVarMap ] on: Error do: [ #() ]
]

{ #category : '*GemStone-GBS-Core-private' }
GbxPointerObjectReplicator >> normalizedInstVarName: aName [
	(aName isNil or: [ aName = #nil ]) ifTrue: [ ^ nil ].
	^ aName asString
]

{ #category : '*GemStone-GBS-Core' }
GbxPointerObjectReplicator >> serverInstVarNames [
	^ serverInstVarNames ifNil: [ #() ]
]

{ #category : '*GemStone-GBS-Core' }
GbxPointerObjectReplicator >> serverInstVarNames: aCollection [
	serverInstVarNames := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ].
	serverToClientOffsets := nil
]

{ #category : '*GemStone-GBS-Core' }
GbxPointerObjectReplicator >> serverNamedSize [
	^ self serverToClientOffsets size
]

{ #category : '*GemStone-GBS-Core' }
GbxPointerObjectReplicator >> serverToClientOffsets [
	serverToClientOffsets ifNil: [ self initializeServerOffsets ].
	^ serverToClientOffsets ifNil: [ #() ]
]

{ #category : '*GemStone-GBS-Core' }
GbxPointerObjectReplicator >> usesInstVarMap [
	clientClass ifNil: [ ^ false ].
	^ clientClass respondsTo: #instVarMap
]

{ #category : '*GemStone-GBS-Core-private' }
GbxPointerObjectReplicator >> serverInstVarNamesScript [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:className | | association cls | association := GsSession currentSession resolveSymbol: className asSymbol. cls := association ifNil: [ nil ] ifNotNil: [ association value ]. cls ifNil: [ #() ] ifNotNil: [ cls _instVarNames copy ]] value: ';
			nextPutAll: serverClass asString printString ]
]

{ #category : '*GemStone-GBS-Core' }
GbxPointerObjectReplicator >> updateInstVarLevelsOfScheme: aReplicationScheme [
	| replicationSpec |
	clientClass ifNil: [ ^ aReplicationScheme ].
	self usesInstVarMap ifFalse: [
		^ super updateInstVarLevelsOfScheme: aReplicationScheme ].
	replicationSpec := self replicationSpecForScheme: aReplicationScheme.
	replicationSpec = #callback ifTrue: [
		aReplicationScheme removeArtefactsForClass: clientClass.
		aReplicationScheme
			updateForClampingByCallback: true
			inSession: self session
			serverBehavior: self serverClass.
		^ aReplicationScheme ].
	^ aReplicationScheme
		updateInstVarLevelsForClass: clientClass
		serverInstVarNames: self serverInstVarNames
		serverToClientOffsets: self serverToClientOffsets
		replicationSpec: replicationSpec
]
