Extension { #name : 'GbxReplicationScheme' }

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme class >> none [
	^ self selector: #none
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme class >> replicate [
	^ self selector: #replicate
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme class >> selector: aSelector [
	^ self new
		selector: aSelector;
		yourself
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme class >> stub [
	^ self selector: #stub
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> clamp [
	^ clamp ifNil: [ clamp := GbxClampSpecification new ]
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> clamp: aClamp [
	clamp := aClamp
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> dictionaryFormOfReplicationSpec: replicationSpec [
	| specs |
	(replicationSpec isSymbol) ifTrue: [ ^ Dictionary new ].
	specs := Dictionary new.
	replicationSpec do: [ :specArray |
		(specArray size between: 2 and: 3)
			ifFalse: [ self error: 'Each element of a replication spec should be a two- or three-element array.' ].
		specs at: specArray first asString put: specArray ].
	^ specs
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> forwarderOffsetsFor: aClass [
	^ forwarderOffsetsDict at: aClass ifAbsent: [ #() ]
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> forwarderOffsetsFor: aClass put: offsets [
	forwarderOffsetsDict at: aClass put: offsets asArray.
	^ offsets
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> forwarderOffsetsForClass: aClass [
	^ self forwarderOffsetsFor: aClass
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> forwarderOffsetsForClass: aClass put: offsets [
	^ self forwarderOffsetsFor: aClass put: offsets
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> hasServerClampMetadata [
	^ self serverClampInstVarLevelEntries isEmpty not
		or: [ self clamp instVarLevelsSelector notNil ]
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> clampByCallbackSelector [
	^ (self selector asString, 'GbsClampCallback') asSymbol
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> determineInstVarLevelsSelectorForClampByCallback: aBoolean inSession: aSession [
	^ self
		determineInstVarLevelsSelectorForClampByCallback: aBoolean
		inSession: aSession
		serverBehavior: nil
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> determineInstVarLevelsSelectorForClampByCallback: aBoolean inSession: aSession serverBehavior: serverBehavior [
	| clampByCallbackSelector |
	aBoolean ifFalse: [ ^ nil ].
	self selector = #transitiveClosureSpec ifTrue: [ ^ nil ].
	clampByCallbackSelector := self clampByCallbackSelector.
	self
		validateClampByCallbackSelector: clampByCallbackSelector
		inSession: aSession
		serverBehavior: serverBehavior.
	^ clampByCallbackSelector
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> initialize [
	super initialize.
	indexedInstvarsShouldBeForwardersDict := IdentityDictionary new.
	forwarderOffsetsDict := IdentityDictionary new.
	selector := #replicate.
	isValid := true
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> invalidate [
	isValid := false
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> indexedInstvarsShouldBeForwardersInClass: aClass [
	^ indexedInstvarsShouldBeForwardersDict
		at: aClass
		ifAbsent: [ false ]
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> indexedInstvarsShouldBeForwardersInClass: aClass put: aBoolean [
	indexedInstvarsShouldBeForwardersDict at: aClass put: aBoolean.
	^ aBoolean
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> instVarLevelForReplicationSpec: rawInstVarLevelsSpec [
	| operator level |
	operator := (rawInstVarLevelsSpec at: 2) asSymbol.
	operator = #forwarder ifTrue: [ ^ false ].
	operator = #stub ifTrue: [ ^ 0 ].
	operator = #replicate ifTrue: [ ^ nil ].
	operator = #max ifTrue: [
		level := rawInstVarLevelsSpec at: 3.
		^ level < 0 ifTrue: [ 0 ] ifFalse: [ level ] ].
	operator = #min ifTrue: [
		level := rawInstVarLevelsSpec at: 3.
		^ level <= 0 ifTrue: [ nil ] ifFalse: [ level negated ] ].
	self error: 'Illegal operator "', operator asString, '" in a replicationSpec.'
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> instVarLevelsForClass: aClass [
	^ self clamp instVarLevelsForClass: aClass
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> isValid [
	^ isValid ~~ false
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> isNone [
	^ selector = #none
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> isReplicate [
	^ selector = #replicate
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> isStub [
	^ selector = #stub
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> removeArtefactsForClass: aClass [
	^ self
		updateInstVarLevels: nil
		forwarderOffsets: nil
		forwardIndexedPart: nil
		forClass: aClass
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> replaceForwarderOffsetsForClass: aClass with: offsets [
	offsets
		ifNil: [ forwarderOffsetsDict removeKey: aClass ifAbsent: [ ] ]
		ifNotNil: [ forwarderOffsetsDict at: aClass put: offsets asArray ].
	^ offsets
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> replaceIndexedInstvarsShoudBeForwardersForClass: aClass with: aBooleanOrNil [
	aBooleanOrNil
		ifNil: [ indexedInstvarsShouldBeForwardersDict removeKey: aClass ifAbsent: [ ] ]
		ifNotNil: [ indexedInstvarsShouldBeForwardersDict at: aClass put: aBooleanOrNil ].
	^ aBooleanOrNil
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> replaceInstVarLevelsForClass: aClass with: levelsArray [
	^ self clamp replaceInstVarLevelsForClass: aClass with: levelsArray
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> selector [
	^ selector
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> selector: aSelector [
	selector := aSelector asSymbol
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> serverClampInstVarLevelEntries [
	| entries |
	entries := OrderedCollection new.
	self clamp instVarLevels associationsDo: [ :association |
		association value ifNotNil: [
			entries add: {
				association key name asString.
				association value asArray } ] ].
	^ (entries asArray sorted: [ :left :right | left first < right first ])
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> serverClampSpecificationFingerprint [
	^ {
		self selector.
		self serverClampInstVarLevelEntries.
		self clamp addSubleafHeaders.
		self clamp environmentId.
		self clamp instVarLevelsSelector.
		self clamp traversalCallBackSelector }
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> shouldAutoMarkDirty [
	^ self shouldReplicate
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> shouldBeForwarderForReplicationSpec: rawInstVarLevelsSpec [
	^ (rawInstVarLevelsSpec at: 2) asSymbol = #forwarder
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> shouldProxyIndexedInstvarsOfClass: aClass [
	^ self indexedInstvarsShouldBeForwardersInClass: aClass
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> shouldProxyNamedSlot: slotIndex ofClass: aClass [
	| offsets |
	offsets := self forwarderOffsetsForClass: aClass.
	(slotIndex between: 1 and: offsets size) ifFalse: [ ^ false ].
	^ offsets at: slotIndex
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> shouldReplicate [
	^ self isValid and: [
		self isNone not and: [ self isStub not ] ]
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> shouldStub [
	^ self isValid and: [ self isStub ]
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> updateForClampingByCallback: aBoolean inSession: aSession [
	^ self
		updateForClampingByCallback: aBoolean
		inSession: aSession
		serverBehavior: nil
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> updateForClampingByCallback: aBoolean inSession: aSession serverBehavior: serverBehavior [
	self clamp instVarLevelsSelector: (self
		determineInstVarLevelsSelectorForClampByCallback: aBoolean
		inSession: aSession
		serverBehavior: serverBehavior)
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> updateInstVarLevels: instVarLevels forwarderOffsets: forwarderOffsets forwardIndexedPart: indexedShouldBeForwarders forClass: aClass [
	self
		replaceInstVarLevelsForClass: aClass with: instVarLevels;
		replaceForwarderOffsetsForClass: aClass with: forwarderOffsets;
		replaceIndexedInstvarsShoudBeForwardersForClass: aClass
			with: indexedShouldBeForwarders.
	^ instVarLevels
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> updateInstVarLevelsForClass: aClass serverInstVarNames: serverInstVarNames replicationSpec: replicationSpec [
	| specs namedLevels indexedSpec forwarderOffsets forwardIndexed |
	replicationSpec ifNil: [ ^ self removeArtefactsForClass: aClass ].
	(replicationSpec isSymbol and: [ replicationSpec ~= #callback ]) ifTrue: [
		^ self removeArtefactsForClass: aClass ].
	replicationSpec = #callback ifTrue: [
		^ self
			updateInstVarLevels: nil
			forwarderOffsets: (Array new: serverInstVarNames size withAll: false)
			forwardIndexedPart: false
			forClass: aClass ].
	specs := self dictionaryFormOfReplicationSpec: replicationSpec.
	namedLevels := serverInstVarNames collect: [ :name |
		| spec |
		spec := specs at: name asString ifAbsent: [ nil ].
		spec ifNil: [ nil ] ifNotNil: [ self instVarLevelForReplicationSpec: spec ] ].
	indexedSpec := specs at: 'indexable_part' ifAbsent: [ nil ].
	forwarderOffsets := serverInstVarNames collect: [ :name |
		| spec |
		spec := specs at: name asString ifAbsent: [ nil ].
		spec notNil and: [ self shouldBeForwarderForReplicationSpec: spec ] ].
	forwardIndexed := indexedSpec notNil and: [
		self shouldBeForwarderForReplicationSpec: indexedSpec ].
	^ self
		updateInstVarLevels: (namedLevels copyWith:
			(indexedSpec ifNil: [ nil ] ifNotNil: [
				self instVarLevelForReplicationSpec: indexedSpec ]))
		forwarderOffsets: forwarderOffsets
		forwardIndexedPart: forwardIndexed
		forClass: aClass
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> updateInstVarLevelsForClass: aClass serverInstVarNames: serverInstVarNames serverToClientOffsets: serverToClientOffsets replicationSpec: replicationSpec [
	| clientInstVarNames specs namedLevels indexedSpec forwarderOffsets forwardIndexed |
	replicationSpec ifNil: [ ^ self removeArtefactsForClass: aClass ].
	(replicationSpec isSymbol and: [ replicationSpec ~= #callback ]) ifTrue: [
		^ self removeArtefactsForClass: aClass ].
	serverToClientOffsets ifNil: [
		^ self
			updateInstVarLevelsForClass: aClass
			serverInstVarNames: serverInstVarNames
			replicationSpec: replicationSpec ].
	replicationSpec = #callback ifTrue: [
		^ self
			updateInstVarLevels: nil
			forwarderOffsets: (Array new: serverInstVarNames size withAll: false)
			forwardIndexedPart: false
			forClass: aClass ].
	clientInstVarNames := (aClass respondsTo: #allInstVarNames)
		ifTrue: [ aClass allInstVarNames collect: [ :each | each asString ] ]
		ifFalse: [ #() ].
	specs := self dictionaryFormOfReplicationSpec: replicationSpec.
	namedLevels := serverToClientOffsets collect: [ :clientIndex |
		| spec |
		clientIndex
			ifNil: [ false ]
			ifNotNil: [
				spec := specs
					at: (clientInstVarNames at: clientIndex ifAbsent: [ '' ])
					ifAbsent: [ nil ].
				spec ifNil: [ nil ] ifNotNil: [ self instVarLevelForReplicationSpec: spec ] ] ].
	indexedSpec := specs at: 'indexable_part' ifAbsent: [ nil ].
	forwarderOffsets := serverToClientOffsets collect: [ :clientIndex |
		| spec |
		clientIndex
			ifNil: [ false ]
			ifNotNil: [
				spec := specs
					at: (clientInstVarNames at: clientIndex ifAbsent: [ '' ])
					ifAbsent: [ nil ].
				spec notNil and: [ self shouldBeForwarderForReplicationSpec: spec ] ] ].
	forwardIndexed := indexedSpec notNil and: [
		self shouldBeForwarderForReplicationSpec: indexedSpec ].
	^ self
		updateInstVarLevels: (namedLevels copyWith:
			(indexedSpec ifNil: [ nil ] ifNotNil: [
				self instVarLevelForReplicationSpec: indexedSpec ]))
		forwarderOffsets: forwarderOffsets
		forwardIndexedPart: forwardIndexed
		forClass: aClass
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> traversalCallbackSelectorForSession: aSession [
	| policy |
	policy := [ GbsReplicationPolicy forSession: aSession ] on: Error do: [ nil ].
	(policy notNil and: [ policy respondsTo: #traversalCallBackSelector ]) ifTrue: [
		^ policy traversalCallBackSelector ].
	^ self clamp traversalCallBackSelector
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> validateClampByCallbackSelector: clampByCallbackSelector inSession: aSession [
	^ self
		validateClampByCallbackSelector: clampByCallbackSelector
		inSession: aSession
		serverBehavior: nil
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> validateClampByCallbackSelector: clampByCallbackSelector inSession: aSession serverBehavior: serverBehavior [
	aSession ifNil: [ ^ self ].
	((serverBehavior notNil
		and: [ aSession respondsTo: #serverBehavior:canUnderstand: ])
		and: [
			[ aSession
				serverBehavior: serverBehavior
				canUnderstand: clampByCallbackSelector ]
				on: Error
				do: [ :ex | ex pass ] ]) ifTrue: [ ^ self ].
	(aSession respondsTo: #serverObjectCanUnderstand:) ifFalse: [ ^ self ].
	([ aSession serverObjectCanUnderstand: clampByCallbackSelector ]
		on: Error
		do: [ :ex | ex pass ]) ifTrue: [ ^ self ].
	self error: 'The configuration option #clampByCallback for the replication scheme "', self selector asString, '" requires the default server method Object>>#', clampByCallbackSelector asString, ' to exist.'
]

{ #category : '*GemStone-GBS-Core' }
GbxReplicationScheme >> transitiveClosureSpecForReplicationSpec: replicationSpec [
	replicationSpec ifNil: [ ^ #() ].
	replicationSpec isSymbol ifTrue: [ ^ #() ].
	replicationSpec = #callback ifTrue: [ ^ #() ].
	^ replicationSpec select: [ :specArray |
		| operator |
		specArray size < 2 ifTrue: [
			self error: 'Each element of a replication spec should include an instvar name and operator.' ].
		operator := (specArray at: 2) asSymbol.
		(#(#min #max #stub) includes: operator) not ]
]
