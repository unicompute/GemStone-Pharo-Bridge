Class {
	#name : 'GbsObjectSpaceDiagnosticsFacade',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#classVars : [
		'RegisteredWellKnownSessionStateSlotSpecifications'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsObjectSpaceDiagnosticsFacade class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'registry' }
GbsObjectSpaceDiagnosticsFacade class >> allWellKnownSessionStateSlotSpecifications [
	^ self registeredWellKnownSessionStateSlotSpecifications collect: [ :each |
		{
			each first.
			each second.
			each third copy.
			(each at: 4 ifAbsent: [ GbsSessionStateSlot ]).
			(each at: 5 ifAbsent: [ #() ]) asArray copy } ]
]

{ #category : 'registry' }
GbsObjectSpaceDiagnosticsFacade class >> defaultWellKnownSessionStateSlotSpecifications [
	^ #()
]

{ #category : 'registry' }
GbsObjectSpaceDiagnosticsFacade class >> registerWellKnownSessionStateSlotKey: aKey label: aLabel aliases: aCollection [
	^ self
		registerWellKnownSessionStateSlotKey: aKey
		label: aLabel
		aliases: aCollection
		slotClass: GbsSessionStateSlot
		tags: #()
]

{ #category : 'registry' }
GbsObjectSpaceDiagnosticsFacade class >> registerWellKnownCacheSessionStateSlotKey: aKey label: aLabel aliases: aCollection tags: aTagCollection [
	^ self
		registerWellKnownSessionStateSlotKey: aKey
		label: aLabel
		aliases: aCollection
		slotClass: GbsCacheSessionStateSlot
		tags: aTagCollection
]

{ #category : 'registry' }
GbsObjectSpaceDiagnosticsFacade class >> registerWellKnownRegistrySessionStateSlotKey: aKey label: aLabel aliases: aCollection tags: aTagCollection [
	^ self
		registerWellKnownSessionStateSlotKey: aKey
		label: aLabel
		aliases: aCollection
		slotClass: GbsRegistrySessionStateSlot
		tags: aTagCollection
]

{ #category : 'registry' }
GbsObjectSpaceDiagnosticsFacade class >> registerWellKnownThreadStateSessionStateSlotKey: aKey label: aLabel aliases: aCollection tags: aTagCollection [
	^ self
		registerWellKnownSessionStateSlotKey: aKey
		label: aLabel
		aliases: aCollection
		slotClass: GbsThreadStateSessionStateSlot
		tags: aTagCollection
]

{ #category : 'registry' }
GbsObjectSpaceDiagnosticsFacade class >> registerWellKnownSessionStateSlotKey: aKey label: aLabel aliases: aCollection slotClass: aClass tags: aTagCollection [
	| keyValue specs existing |
	keyValue := aKey asInteger.
	specs := self registeredWellKnownSessionStateSlotSpecifications.
	existing := specs detect: [ :each | each first = keyValue ] ifNone: [ nil ].
	existing ifNotNil: [ specs remove: existing ifAbsent: [ ] ].
	specs add: {
		keyValue.
		aLabel ifNil: [ 'Session State' ] ifNotNil: [ aLabel asString ].
		aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray copy ].
		(aClass ifNil: [ GbsSessionStateSlot ]).
		aTagCollection ifNil: [ #() ] ifNotNil: [ aTagCollection asArray copy ] }.
	^ keyValue
]

{ #category : 'registry' }
GbsObjectSpaceDiagnosticsFacade class >> registerWellKnownSessionStateSlots: aCollection [
	aCollection ifNil: [ ^ #() ].
	^ aCollection collect: [ :each |
		self
			registerWellKnownSessionStateSlotKey: each first
			label: (each at: 2 ifAbsent: [ nil ])
			aliases: (each at: 3 ifAbsent: [ #() ])
			slotClass: (each at: 4 ifAbsent: [ GbsSessionStateSlot ])
			tags: (each at: 5 ifAbsent: [ #() ]) ]
]

{ #category : 'registry' }
GbsObjectSpaceDiagnosticsFacade class >> registeredWellKnownSessionStateSlotSpecifications [
	RegisteredWellKnownSessionStateSlotSpecifications ifNil: [
		self resetRegisteredWellKnownSessionStateSlots ].
	^ RegisteredWellKnownSessionStateSlotSpecifications
]

{ #category : 'registry' }
GbsObjectSpaceDiagnosticsFacade class >> resetRegisteredWellKnownSessionStateSlots [
	RegisteredWellKnownSessionStateSlotSpecifications := (self defaultWellKnownSessionStateSlotSpecifications collect: [ :each |
		{
			each first.
			each second.
			each third copy.
			(each at: 4 ifAbsent: [ GbsSessionStateSlot ]).
			(each at: 5 ifAbsent: [ #() ]) asArray copy } ]) asOrderedCollection.
	^ RegisteredWellKnownSessionStateSlotSpecifications
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> objectSpace [
	^ session objectSpace
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> objectsInMemoryReportFrom: aStartIndex limit: aLimit [
	^ GbsObjectScanReport
		diagnostics: self
		title: 'Objects In Memory'
		objects: (self objectSpace objectsInMemoryFrom: aStartIndex limit: aLimit)
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> occupiedSlotsFrom: startKey to: endKey [
	| normalizedStart normalizedEnd |
	normalizedStart := startKey ifNil: [ 0 ] ifNotNil: [ startKey asInteger ].
	normalizedEnd := endKey ifNil: [ normalizedStart ] ifNotNil: [ endKey asInteger ].
	normalizedEnd < normalizedStart ifTrue: [
		| swap |
		swap := normalizedStart.
		normalizedStart := normalizedEnd.
		normalizedEnd := swap ].
	^ (normalizedStart to: normalizedEnd)
		collect: [ :each | self slotAtKey: each ]
		thenSelect: [ :slot | slot exists ]
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> occupiedSlotsReportFrom: startKey to: endKey [
	^ GbsObjectSpaceDiagnosticsReport
		diagnostics: self
		slots: (self occupiedSlotsFrom: startKey to: endKey)
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> occupiedSlotsReportTextFrom: startKey to: endKey [
	^ (self occupiedSlotsReportFrom: startKey to: endKey) text
]

{ #category : 'printing' }
GbsObjectSpaceDiagnosticsFacade >> reportText [
	^ self report text
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> reportSlots [
	^ self report slots
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> report [
	^ self reportForKeys: self wellKnownSessionStateKeys
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> reportForKeys: aCollection [
	^ GbsObjectSpaceDiagnosticsReport
		diagnostics: self
		slots: (self reportSlotsForKeys: aCollection)
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> reportForSlotNames: aCollection [
	^ self reportForKeys: ((aCollection collect: [ :each |
		self slotKeyNamed: each ]) reject: #isNil)
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> discoveredOrWellKnownSlotsFrom: startKey to: endKey [
	| occupiedKeys |
	occupiedKeys := (self occupiedSlotsFrom: startKey to: endKey)
		collect: [ :each | each key ].
	^ self reportSlotsForKeys: ((self wellKnownSessionStateKeys , occupiedKeys) asSet asArray asSortedCollection asArray)
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> reportSlotsForKeys: aCollection [
	^ self slotsForKeys: aCollection
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> referencersReportFor: anObject [
	^ self
		referencersReportForOop: ((anObject respondsTo: #oop)
			ifTrue: [ anObject oop ]
			ifFalse: [ nil ])
		label: anObject class name asString
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> referencersReportForOop: anOop [
	^ self
		referencersReportForOop: anOop
		label: 'Object'
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> referencersReportForOop: anOop label: aString [
	| referencers |
	referencers := (anOop isInteger and: [ anOop > 20 ])
		ifTrue: [ [ session referencesToOop: anOop ] on: Error do: [ #() ] ]
		ifFalse: [ #() ].
	^ GbsObjectReferencerReport
		diagnostics: self
		targetLabel: aString
		targetOop: anOop
		referencers: referencers
]

{ #category : 'printing' }
GbsObjectSpaceDiagnosticsFacade >> reportTextForKeys: aCollection [
	^ (self reportForKeys: aCollection) text
]

{ #category : 'printing' }
GbsObjectSpaceDiagnosticsFacade >> reportTextForSlotNames: aCollection [
	^ (self reportForSlotNames: aCollection) text
]

{ #category : 'accessing' }
GbsObjectSpaceDiagnosticsFacade >> session [
	^ session
]

{ #category : 'accessing' }
GbsObjectSpaceDiagnosticsFacade >> session: aSession [
	session := aSession
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> sessionStateAt: aKey [
	^ session sessionStateAt: aKey
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> sessionStateSummaryLineForKey: aKey [
	^ (self slotAtKey: aKey) summaryLine
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> sessionStateSummaryLineForKey: aKey label: aLabel [
	^ (self
		slotAtKey: aKey
		label: aLabel) summaryLine
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> sessionStateSummaryLines [
	^ self wellKnownSessionStateSlots collect: [ :each |
		each summaryLine ]
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> slotKeysReportFor: aCollection [
	^ self reportForKeys: aCollection
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> slotAtKey: aKey [
	^ self
		slotAtKey: aKey
		label: (self slotLabelForKey: aKey)
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> slotKeyNamed: aName [
	| text normalized |
	aName ifNil: [ ^ nil ].
	(aName isInteger or: [ aName isNumber ]) ifTrue: [ ^ aName asInteger ].
	text := aName asString trimBoth.
	text isEmpty ifTrue: [ ^ nil ].
	([ text asInteger ] on: Error do: [ nil ]) ifNotNil: [ :each |
		^ each ].
	normalized := self normalizedSlotAliasName: text.
	(#('slot' 'key' 'sessionstate') detect: [ :prefix | normalized beginsWith: prefix ] ifNone: [ nil ])
		ifNotNil: [ :prefix |
			| digits |
			digits := normalized copyFrom: prefix size + 1 to: normalized size.
			([ digits asInteger ] on: Error do: [ nil ]) ifNotNil: [ :each |
				^ each ] ].
	^ self
		wellKnownSessionStateSlotAliases
		at: normalized
		ifAbsent: [ nil ]
]

{ #category : 'private' }
GbsObjectSpaceDiagnosticsFacade >> normalizedSlotAliasName: aName [
	| normalized |
	aName ifNil: [ ^ '' ].
	normalized := aName asString.
	normalized := normalized copyReplaceAll: '_' with: ''.
	normalized := normalized copyReplaceAll: ' ' with: ''.
	normalized := normalized copyReplaceAll: '-' with: ''.
	normalized := normalized copyReplaceAll: '.' with: ''.
	^ normalized asLowercase
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> slotNamed: aName [
	| keyValue |
	keyValue := self slotKeyNamed: aName.
	keyValue ifNil: [ ^ nil ].
	^ self slotAtKey: keyValue
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> slotAtKey: aKey label: aLabel [
	| value slot labels specification slotClass tags |
	value := [ self sessionStateAt: aKey ]
		on: Error
		do: [ :ex | ex ].
	labels := self wellKnownSessionStateSlotLabels.
	specification := self wellKnownSessionStateSlotSpecificationAtKey: aKey.
	slotClass := specification
		ifNil: [ self inferredSlotClassForKey: aKey label: aLabel value: value ]
		ifNotNil: [ specification at: 4 ifAbsent: [ GbsSessionStateSlot ] ].
	tags := specification
		ifNil: [ self inferredTagsForKey: aKey label: aLabel value: value ]
		ifNotNil: [ specification at: 5 ifAbsent: [ #() ] ].
	slot := (slotClass
		key: aKey
		label: aLabel
		value: value
		diagnostics: self)
			aliasNames: (self slotAliasNamesAtKey: aKey);
			wellKnown: (labels includesKey: aKey);
			tags: tags;
			discoverySource: ((labels includesKey: aKey)
				ifTrue: [ #registered ]
				ifFalse: [ #discovered ]);
			yourself.
	^ slot
]

{ #category : 'private' }
GbsObjectSpaceDiagnosticsFacade >> inferredSlotClassForKey: aKey label: aLabel value: aValue [
	| normalized |
	(aValue isKindOf: Dictionary) ifTrue: [ ^ GbsRegistrySessionStateSlot ].
	(aValue isKindOf: IdentityDictionary) ifTrue: [ ^ GbsRegistrySessionStateSlot ].
	((aValue isKindOf: Collection)
		and: [ (aValue isKindOf: String) not
		and: [ (aValue isKindOf: Dictionary) not ] ]) ifTrue: [ ^ GbsCacheSessionStateSlot ].
	normalized := self normalizedSlotAliasName: aLabel.
	((normalized includesSubstring: 'registry')
		or: [ normalized includesSubstring: 'dictionary' ]) ifTrue: [ ^ GbsRegistrySessionStateSlot ].
	((normalized includesSubstring: 'cache')
		or: [ normalized includesSubstring: 'memo' ]) ifTrue: [ ^ GbsCacheSessionStateSlot ].
	((normalized includesSubstring: 'thread')
		or: [ normalized includesSubstring: 'fiber'
		or: [ normalized includesSubstring: 'process' ] ]) ifTrue: [ ^ GbsThreadStateSessionStateSlot ].
	^ GbsSessionStateSlot
]

{ #category : 'private' }
GbsObjectSpaceDiagnosticsFacade >> inferredTagsForKey: aKey label: aLabel value: aValue [
	| tags slotClass |
	tags := OrderedCollection new.
	slotClass := self inferredSlotClassForKey: aKey label: aLabel value: aValue.
	slotClass = GbsRegistrySessionStateSlot ifTrue: [ tags add: #registry ].
	slotClass = GbsCacheSessionStateSlot ifTrue: [ tags add: #cache ].
	slotClass = GbsThreadStateSessionStateSlot ifTrue: [ tags add: #threadState ].
	^ tags asArray
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> slotAliasNamesAtKey: aKey [
	^ (self wellKnownSessionStateSlotAliases associations
		select: [ :association | association value = aKey ]
		thenCollect: [ :association | association key ]) asArray
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> slotLabelForKey: aKey [
	^ self
		wellKnownSessionStateSlotLabels
		at: aKey
		ifAbsent: [ 'Session State' ]
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> wellKnownSessionStateSlotSpecificationAtKey: aKey [
	^ self class allWellKnownSessionStateSlotSpecifications
		detect: [ :each | each first = aKey ]
		ifNone: [ nil ]
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> slotsForKeys: aCollection [
	^ aCollection collect: [ :each |
		self slotAtKey: each ]
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> slotsForLabels: aDictionary [
	^ aDictionary associations collect: [ :association |
		self
			slotAtKey: association key
			label: association value ]
]

{ #category : 'printing' }
GbsObjectSpaceDiagnosticsFacade >> summaryLineFor: anObject label: aLabel [
	^ String streamContents: [ :stream |
		self writeSummaryFor: anObject label: aLabel on: stream ]
]

{ #category : 'printing' }
GbsObjectSpaceDiagnosticsFacade >> writeSummaryFor: anObject label: aLabel on: aStream [
	| sizeValue |
	(anObject isKindOf: Error) ifTrue: [
		aStream
			nextPutAll: aLabel;
			nextPutAll: ': ERROR - ';
			nextPutAll: anObject messageText.
		^ self ].
	anObject ifNil: [
		aStream
			nextPutAll: aLabel;
			nextPutAll: ': (absent)'.
		^ self ].
	aStream
		nextPutAll: aLabel;
		nextPutAll: ': ';
		nextPutAll: anObject class name asString.
	(anObject respondsTo: #oop) ifTrue: [
		aStream
			nextPutAll: ' oop=';
			nextPutAll: anObject oop printString ].
	sizeValue := [
		((anObject respondsTo: #size) and: [ anObject class ~~ GbsProxy ])
			ifTrue: [ anObject size ]
			ifFalse: [ nil ] ]
		on: Error
		do: [ nil ].
	(sizeValue isInteger) ifTrue: [
		aStream
			nextPutAll: ' size=';
			nextPutAll: sizeValue printString ]
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> wellKnownSessionStateKeys [
	^ self wellKnownSessionStateSlotLabels keys asArray asSortedCollection asArray
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> wellKnownSessionStateSlotAliases [
	| aliases |
	aliases := Dictionary new.
	self class allWellKnownSessionStateSlotSpecifications do: [ :each |
		| keyValue label aliasesForSlot |
		keyValue := each first.
		label := each second.
		aliasesForSlot := each third copyWith: label.
		aliasesForSlot do: [ :aliasName |
			aliases
				at: (self normalizedSlotAliasName: aliasName)
				put: keyValue ] ].
	^ aliases
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> wellKnownSessionStateSlotLabels [
	| labels |
	labels := Dictionary new.
	self class allWellKnownSessionStateSlotSpecifications do: [ :each |
		labels at: each first put: each second ].
	^ labels
]

{ #category : 'querying' }
GbsObjectSpaceDiagnosticsFacade >> wellKnownSessionStateSlots [
	^ self slotsForLabels: self wellKnownSessionStateSlotLabels
]
