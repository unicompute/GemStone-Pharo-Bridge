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
	^ serverInstVarNames
]

{ #category : '*GemStone-GBS-Core' }
GbxPointerObjectReplicator >> isComplete [
	^ serverInstVarNames notNil
]

{ #category : '*GemStone-GBS-Core' }
GbxPointerObjectReplicator >> serverInstVarNames [
	^ serverInstVarNames ifNil: [ #() ]
]

{ #category : '*GemStone-GBS-Core' }
GbxPointerObjectReplicator >> serverInstVarNames: aCollection [
	serverInstVarNames := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : '*GemStone-GBS-Core-private' }
GbxPointerObjectReplicator >> serverInstVarNamesScript [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:className | | association cls | association := GsSession currentSession resolveSymbol: className asSymbol. cls := association ifNil: [ nil ] ifNotNil: [ association value ]. cls ifNil: [ #() ] ifNotNil: [ cls _instVarNames copy ]] value: ';
			nextPutAll: serverClass asString printString ]
]
