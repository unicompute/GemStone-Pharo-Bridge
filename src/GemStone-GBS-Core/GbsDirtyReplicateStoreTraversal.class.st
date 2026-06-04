Class {
	#name : 'GbsDirtyReplicateStoreTraversal',
	#superclass : 'Object',
	#instVars : [
		'session',
		'recursiveDirtyReferentEntryCount',
		'nativeEntryExpansionCache'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsDirtyReplicateStoreTraversal class >> forSession: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'flushing' }
GbsDirtyReplicateStoreTraversal class >> flushSession: aSession [
	^ (self forSession: aSession) flush
]

{ #category : 'reporting' }
GbsDirtyReplicateStoreTraversal class >> dirtyStoreTraversalReportForSession: aSession [
	aSession ifNil: [ ^ self newDirtyStoreTraversalReport ].
	^ (self dirtyStoreTraversalReportStorageForSession: aSession) copy
]

{ #category : 'private - reporting' }
GbsDirtyReplicateStoreTraversal class >> dirtyStoreTraversalReportStorageForSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionDirtyStoreTraversalReports)
		at: aSession
		ifAbsentPut: [ self newDirtyStoreTraversalReport ]
]

{ #category : 'private - reporting' }
GbsDirtyReplicateStoreTraversal class >> newDirtyStoreTraversalReport [
	^ Dictionary new
		at: #totalEntries put: 0;
		at: #nativeEntryCount put: 0;
		at: #semanticEntryCount put: 0;
		at: #semanticDictionaryEntryCount put: 0;
		at: #semanticSetEntryCount put: 0;
		at: #semanticBagEntryCount put: 0;
		at: #semanticCustomEntryCount put: 0;
		at: #recursiveDirtyReferentEntryCount put: 0;
		at: #remoteCommandEntryCount put: 0;
		at: #nativeFlushCount put: 0;
		at: #remoteCommandCount put: 0;
		at: #semanticCommandCount put: 0;
		at: #nativeFallbackCount put: 0;
		at: #nativeFallbackReason put: nil;
		at: #nativeFallbackDetails put: nil;
		at: #nativeCapabilityReport put: nil;
		at: #perReplicatorStoreEntryCount put: 0;
		at: #newObjectEntryCount put: 0;
		at: #freeOopAllocationCount put: 0;
		yourself
]

{ #category : 'reporting' }
GbsDirtyReplicateStoreTraversal class >> resetDirtyStoreTraversalReportForSession: aSession [
	aSession ifNil: [ ^ self newDirtyStoreTraversalReport ].
	^ self
		setDirtyStoreTraversalReport: self newDirtyStoreTraversalReport
		forSession: aSession
]

{ #category : 'private - reporting' }
GbsDirtyReplicateStoreTraversal class >> setDirtyStoreTraversalReport: aDictionary forSession: aSession [
	aSession ifNil: [ ^ aDictionary ].
	(aSession class weakRegistryNamed: #GbsSessionDirtyStoreTraversalReports)
		at: aSession
		put: aDictionary.
	^ aDictionary
]

{ #category : 'private - arguments' }
GbsDirtyReplicateStoreTraversal >> addArgumentNamed: name value: value toNames: argumentNames scripts: argumentScripts [
	argumentNames add: name.
	argumentScripts add: (self argumentScriptFor: value visited: IdentitySet new).
	^ name
]

{ #category : 'private - reporting' }
GbsDirtyReplicateStoreTraversal >> beginDirtyStoreReportForEntries: entries [
	| report semanticEntries |
	report := self class newDirtyStoreTraversalReport.
	semanticEntries := self semanticStoreEntriesFor: entries.
	report
		at: #totalEntries put: entries size;
		at: #semanticEntryCount put: semanticEntries size;
		at: #semanticDictionaryEntryCount put: (semanticEntries count: [ :entry |
			#(#dictionary #identityDictionary) includes: (entry at: 3) ]);
		at: #semanticSetEntryCount put: (semanticEntries count: [ :entry |
			(entry at: 3) = #set ]);
		at: #semanticBagEntryCount put: (semanticEntries count: [ :entry |
			(entry at: 3) = #bag ]);
		at: #semanticCustomEntryCount put: (semanticEntries count: [ :entry |
			self semanticDirtyStoreRequestedBy: entry second ]);
		at: #recursiveDirtyReferentEntryCount put: (recursiveDirtyReferentEntryCount ifNil: [ 0 ]);
		at: #perReplicatorStoreEntryCount put: (entries count: [ :entry | self entryHasReplicator: entry ]);
		at: #newObjectEntryCount put: (entries count: [ :entry | self entryIsNewObject: entry ]);
		at: #freeOopAllocationCount put: (entries count: [ :entry | self entryIsNewObject: entry ]).
	^ self class
		setDirtyStoreTraversalReport: report
		forSession: session
]

{ #category : 'private - appending' }
GbsDirtyReplicateStoreTraversal >> appendArrayFlushFor: anArray entryIndex: entryIndex to: stream names: argumentNames scripts: argumentScripts [
	stream
		nextPutAll: 'object size = ';
		nextPutAll: anArray size printString;
		nextPutAll: ' ifFalse: [ Error signal: ''Dirty Array size changed before flush.'' ].';
		cr.
	1 to: anArray size do: [ :index | | valueName |
		valueName := self
			addArgumentNamed: (self valueArgumentNameForEntry: entryIndex element: index)
			value: (anArray at: index)
			toNames: argumentNames
			scripts: argumentScripts.
		stream
			nextPutAll: 'object at: ';
			nextPutAll: index printString;
			nextPutAll: ' put: ';
			nextPutAll: valueName;
			nextPutAll: '.';
			cr ]
]

{ #category : 'private - appending' }
GbsDirtyReplicateStoreTraversal >> appendAssociationFlushFor: anAssociation entryIndex: entryIndex to: stream names: argumentNames scripts: argumentScripts [
	| keyName valueName |
	keyName := self
		addArgumentNamed: 'key' , entryIndex asString
		value: anAssociation key
		toNames: argumentNames
		scripts: argumentScripts.
	valueName := self
		addArgumentNamed: 'value' , entryIndex asString
		value: anAssociation value
		toNames: argumentNames
		scripts: argumentScripts.
	stream
		nextPutAll: 'object key: ';
		nextPutAll: keyName;
		nextPutAll: ' value: ';
		nextPutAll: valueName;
		nextPutAll: '.';
		cr
]

{ #category : 'private - appending' }
GbsDirtyReplicateStoreTraversal >> appendCollectionFlushFor: aCollection entryIndex: entryIndex to: stream names: argumentNames scripts: argumentScripts [
	stream
		nextPutAll: 'object asArray do: [ :each | object remove: each ifAbsent: [ ] ].';
		cr.
	aCollection asArray doWithIndex: [ :each :index | | valueName |
		valueName := self
			addArgumentNamed: (self valueArgumentNameForEntry: entryIndex element: index)
			value: each
			toNames: argumentNames
			scripts: argumentScripts.
		stream
			nextPutAll: 'object add: ';
			nextPutAll: valueName;
			nextPutAll: '.';
				cr ]
]

{ #category : 'private - appending' }
GbsDirtyReplicateStoreTraversal >> appendBagFlushFor: aBag entryIndex: entryIndex to: stream names: argumentNames scripts: argumentScripts [
	| elements |
	stream
		nextPutAll: 'object asSet do: [ :each | 1 to: (object occurrencesOf: each) do: [ :ignored | object remove: each ifAbsent: [ ] ] ].';
		cr.
	elements := aBag asSet asArray.
	elements doWithIndex: [ :each :index | | valueName |
		valueName := self
			addArgumentNamed: (self valueArgumentNameForEntry: entryIndex element: index)
			value: each
			toNames: argumentNames
			scripts: argumentScripts.
		stream
			nextPutAll: 'object add: ';
			nextPutAll: valueName;
			nextPutAll: ' withOccurrences: ';
			nextPutAll: (aBag occurrencesOf: each) printString;
			nextPutAll: '.';
			cr ]
]

{ #category : 'private - appending' }
GbsDirtyReplicateStoreTraversal >> appendDictionaryFlushFor: aDictionary entryIndex: entryIndex to: stream names: argumentNames scripts: argumentScripts [
	| associationIndex |
	associationIndex := 0.
	stream
		nextPutAll: 'object removeAll.';
		cr.
	aDictionary associationsDo: [ :association | | keyName valueName |
		associationIndex := associationIndex + 1.
		keyName := self
			addArgumentNamed: (self keyArgumentNameForEntry: entryIndex element: associationIndex)
			value: association key
			toNames: argumentNames
			scripts: argumentScripts.
		valueName := self
			addArgumentNamed: (self valueArgumentNameForEntry: entryIndex element: associationIndex)
			value: association value
			toNames: argumentNames
			scripts: argumentScripts.
		stream
			nextPutAll: 'object at: ';
			nextPutAll: keyName;
			nextPutAll: ' put: ';
			nextPutAll: valueName;
			nextPutAll: '.';
			cr ]
]

{ #category : 'private - appending' }
GbsDirtyReplicateStoreTraversal >> appendNamedObjectFlushFor: anObject entryIndex: entryIndex to: stream names: argumentNames scripts: argumentScripts [
	| namedValues indexableValues namedSize |
	namedValues := self namedSlotFlushValuesForObject: anObject.
	(self namedSlotFlushMappingsForObject: anObject) do: [ :mapping | | serverIndex clientIndex valueName |
		serverIndex := mapping first.
		clientIndex := mapping second.
		valueName := self
			addArgumentNamed: (self valueArgumentNameForEntry: entryIndex element: serverIndex)
			value: (namedValues
				ifNil: [ anObject instVarAt: clientIndex ]
				ifNotNil: [ namedValues at: serverIndex ifAbsent: [ anObject instVarAt: clientIndex ] ])
			toNames: argumentNames
			scripts: argumentScripts.
		stream
			nextPutAll: 'object instVarAt: ';
			nextPutAll: serverIndex printString;
			nextPutAll: ' put: ';
			nextPutAll: valueName;
			nextPutAll: '.';
			cr ].
	indexableValues := self indexableFlushValuesForObject: anObject.
	namedSize := self namedSlotCountForObject: anObject.
	indexableValues doWithIndex: [ :value :index | | valueName |
		valueName := self
			addArgumentNamed: (self valueArgumentNameForEntry: entryIndex element: namedSize + index)
			value: value
			toNames: argumentNames
			scripts: argumentScripts.
		stream
			nextPutAll: 'object at: ';
			nextPutAll: index printString;
			nextPutAll: ' put: ';
			nextPutAll: valueName;
			nextPutAll: '.';
			cr ]
]

{ #category : 'private - appending' }
GbsDirtyReplicateStoreTraversal >> appendFlushForEntry: entry index: entryIndex to: stream names: argumentNames scripts: argumentScripts [
	| objectName |
	objectName := 'object' , entryIndex asString.
	argumentNames add: objectName.
	argumentScripts add: (self remoteObjectExpressionForOop: entry first).
	stream
		nextPutAll: 'object := ';
		nextPutAll: objectName;
		nextPutAll: '.';
		cr.
	(entry at: 3) = #array ifTrue: [
		^ self
			appendArrayFlushFor: entry second
			entryIndex: entryIndex
			to: stream
			names: argumentNames
			scripts: argumentScripts ].
	(entry at: 3) = #association ifTrue: [
		^ self
			appendAssociationFlushFor: entry second
			entryIndex: entryIndex
			to: stream
			names: argumentNames
			scripts: argumentScripts ].
	(((entry at: 3) = #dictionary) or: [ (entry at: 3) = #identityDictionary ]) ifTrue: [
		^ self
			appendDictionaryFlushFor: entry second
			entryIndex: entryIndex
			to: stream
			names: argumentNames
			scripts: argumentScripts ].
		(entry at: 3) = #namedObject ifTrue: [
			^ self
				appendNamedObjectFlushFor: entry second
				entryIndex: entryIndex
				to: stream
				names: argumentNames
				scripts: argumentScripts ].
		(entry at: 3) = #bag ifTrue: [
			^ self
				appendBagFlushFor: entry second
				entryIndex: entryIndex
				to: stream
				names: argumentNames
				scripts: argumentScripts ].
		^ self
			appendCollectionFlushFor: entry second
			entryIndex: entryIndex
		to: stream
		names: argumentNames
		scripts: argumentScripts
]

{ #category : 'private - arguments' }
GbsDirtyReplicateStoreTraversal >> argumentScriptFor: anObject visited: visited [
	| oop |
	oop := self oopForObject: anObject.
	oop ifNotNil: [ ^ self remoteObjectExpressionForOop: oop ].
	(self shouldMarshalConstructedObject: anObject) ifTrue: [
		^ self marshalConstructedArgumentToScript: anObject visited: visited ].
	^ session marshalArgumentToScript: anObject visited: visited
]

{ #category : 'private - commands' }
GbsDirtyReplicateStoreTraversal >> bodyForEntries: entries argumentNames: argumentNames argumentScripts: argumentScripts [
	^ String streamContents: [ :stream |
		entries doWithIndex: [ :entry :entryIndex |
			self
				appendFlushForEntry: entry
				index: entryIndex
				to: stream
				names: argumentNames
				scripts: argumentScripts ].
		stream nextPutAll: 'true' ]
]

{ #category : 'private - tracking' }
GbsDirtyReplicateStoreTraversal >> dirtyObjects [
	^ GbsMaterializedObjectDirtyTracker dirtyObjectsForSession: session
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> dirtyReferentsOf: anObject [
	| replicator |
	replicator := self replicatorForObject: anObject.
	(replicator notNil and: [ replicator respondsTo: #packDirtyReferentsOf:inTraversal: ]) ifTrue: [
		^ replicator packDirtyReferentsOf: anObject inTraversal: self ].
	^ self defaultDirtyReferentsOf: anObject
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> defaultDirtyReferentsOf: anObject [
	| referents |
	referents := OrderedCollection new.
	anObject ifNil: [ ^ #() ].
	(anObject isKindOf: Association) ifTrue: [
		referents
			add: anObject key;
			add: anObject value.
		^ referents asArray ].
	(anObject isKindOf: Dictionary) ifTrue: [
		anObject associationsDo: [ :association |
			referents
				add: association;
				add: association key;
				add: association value ].
		^ referents asArray ].
	((anObject isKindOf: Set)
		or: [ (anObject isKindOf: Bag)
		or: [ (anObject isKindOf: OrderedCollection)
		or: [ anObject isKindOf: Array ] ] ]) ifTrue: [
			anObject do: [ :each | referents add: each ].
			^ referents asArray ].
	(self hasNamedSlotsForObject: anObject) ifTrue: [
		(self namedSlotFlushMappingsForObject: anObject) do: [ :mapping |
			referents add: (anObject instVarAt: mapping second) ] ].
	^ referents asArray
]

{ #category : 'private - flushing' }
GbsDirtyReplicateStoreTraversal >> dirtyStoreTraversalBufferForEntries: entries [
	^ GbsDirtyStoreTraversalBuffer entries: entries session: session
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> entriesForDirtyObjects [
	| entriesByOop dirtySet visited |
	entriesByOop := Dictionary new.
	recursiveDirtyReferentEntryCount := 0.
	dirtySet := IdentitySet new.
	self dirtyObjects do: [ :object | dirtySet add: object ].
	visited := IdentitySet new.
	dirtySet do: [ :object |
		self
			addDirtyEntryFor: object
			dirtySet: dirtySet
			entriesByOop: entriesByOop
			visited: visited ].
	^ (entriesByOop values asSortedCollection: [ :left :right | left first < right first ]) asArray
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> addDirtyEntryFor: anObject dirtySet: dirtySet entriesByOop: entriesByOop visited: visited [
	| entry oop |
	(visited includes: anObject) ifTrue: [ ^ self ].
	visited add: anObject.
	entry := self dirtyStoreEntryFor: anObject.
	entry ifNotNil: [
		oop := entry first ].
	(entry notNil and: [ GbsMaterializedObjectDirtyTracker canTrackObject: anObject ])
		ifTrue: [
			entriesByOop
				at: oop
				ifAbsentPut: [ entry ] ].
	(self dirtyReferentsOf: anObject) do: [ :referent |
		(dirtySet includes: referent) ifTrue: [
			(entriesByOop includesKey: (self oopForObject: referent)) ifFalse: [
				recursiveDirtyReferentEntryCount := recursiveDirtyReferentEntryCount + 1 ].
			self
				addDirtyEntryFor: referent
				dirtySet: dirtySet
				entriesByOop: entriesByOop
				visited: visited ] ].
	^ self
]

{ #category : 'flushing' }
GbsDirtyReplicateStoreTraversal >> flush [
	| entries objects |
	entries := self entriesForDirtyObjects.
	self beginDirtyStoreReportForEntries: entries.
	entries isEmpty ifTrue: [ ^ #() ].
	objects := entries collect: [ :entry | entry second ].
	GbsMaterializedObjectDirtyTracker
		clearDirtyObjects: objects
		forSession: session.
	[ self flushEntries: entries ]
		on: Error
		do: [ :ex |
			objects do: [ :object |
				session dirtyPool markDirty: object ].
			ex pass ].
	^ (entries collect: [ :entry | entry first ]) asArray
]

{ #category : 'private - flushing' }
GbsDirtyReplicateStoreTraversal >> flushEntries: entries [
	(self entriesRequireBinaryStoreTraversal: entries) ifTrue: [
		self ensureBinaryStoreTraversalAvailableForEntries: entries.
		^ self flushEntriesWithBinaryStoreTraversalBuffer: entries ].
	self transportRequiresBinary ifTrue: [
		self ensureBinaryStoreTraversalAvailableForEntries: entries.
		^ self flushEntriesWithBinaryStoreTraversalBuffer: entries ].
	(self shouldUseBinaryStoreTraversalBufferForEntries: entries) ifTrue: [
		^ self flushEntriesWithBinaryStoreTraversalBuffer: entries ].
	(self semanticStoreEntriesFor: entries) size = entries size ifTrue: [
		^ self flushEntriesWithRemoteCommand: entries ].
	^ self flushEntriesWithRemoteCommand: entries
]

{ #category : 'private - flushing' }
GbsDirtyReplicateStoreTraversal >> flushEntriesWithBinaryStoreTraversalBuffer: entries [
	| nativeEntries semanticEntries result |
	nativeEntries := self nativeStoreTraversalEntriesFor: entries.
	semanticEntries := self semanticStoreEntriesFor: entries.
	nativeEntries isEmpty ifTrue: [
		^ self flushEntriesWithRemoteCommand: semanticEntries ].
	result := self flushNativeEntriesWithBinaryStoreTraversalBuffer: nativeEntries.
	semanticEntries isEmpty ifFalse: [
		self flushEntriesWithRemoteCommand: semanticEntries ].
	^ result
]

{ #category : 'private - flushing' }
GbsDirtyReplicateStoreTraversal >> flushEntriesWithRemoteCommand: entries [
	| result |
	session addStoreTraversal: self.
	^ [
		result := session returnRemoteCommandOop: (self remoteCommandForEntries: entries).
		self recordRemoteCommandForEntries: entries.
		result ]
		ensure: [ session removeStoreTraversal: self ]
]

{ #category : 'private - flushing' }
GbsDirtyReplicateStoreTraversal >> flushNativeEntriesWithBinaryStoreTraversalBuffer: entries [
	^ GbsSessionLifecycleManager
		withStrongServerMapForSession: session
		do: [
			| buffer server exportSetReleaseOops |
			buffer := self dirtyStoreTraversalBufferForEntries: entries.
			server := session serverInterface.
			exportSetReleaseOops := self exportSetReleaseOopsForStoreTraversalUsing: server.
			(server respondsTo: #ensureDirtyObjectsInitialized) ifTrue: [
				server ensureDirtyObjectsInitialized ].
			session addStoreTraversal: self.
			GbsSessionLifecycleManager
				notePackedDirtyStoreEntries: entries
				forSession: session.
			[
				| result |
				result := self
					storeTraversalBuffer: buffer
					on: server
					releasingExportSetReleaseOops: exportSetReleaseOops.
				self recordNativeFlushForEntries: entries.
				GbsSessionLifecycleManager
					acknowledgePackedDirtyStoreEntries: entries
					forSession: session.
				result
			]
				ensure: [ session removeStoreTraversal: self ] ]
]

{ #category : 'private - names' }
GbsDirtyReplicateStoreTraversal >> keyArgumentNameForEntry: entryIndex element: elementIndex [
	^ 'key' , entryIndex asString , '_' , elementIndex asString
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> kindForObject: anObject [
	^ self kindForObject: anObject replicator: (self replicatorForObject: anObject)
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> kindForObject: anObject replicator: aReplicator [
	(aReplicator notNil and: [ aReplicator respondsTo: #dirtyStoreKindFor:inTraversal: ]) ifTrue: [
		^ aReplicator dirtyStoreKindFor: anObject inTraversal: self ].
	^ self defaultKindForObject: anObject
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> defaultKindForObject: anObject [
	(anObject isKindOf: Association) ifTrue: [ ^ #association ].
	(anObject isKindOf: IdentityDictionary) ifTrue: [ ^ #identityDictionary ].
	(anObject isKindOf: Dictionary) ifTrue: [ ^ #dictionary ].
	(anObject isKindOf: Array) ifTrue: [ ^ #array ].
	anObject class == OrderedCollection ifTrue: [ ^ #orderedCollection ].
	(anObject isKindOf: Bag) ifTrue: [ ^ #bag ].
	(anObject isKindOf: Set) ifTrue: [ ^ #set ].
	(anObject isKindOf: OrderedCollection) ifTrue: [ ^ #collection ].
	(self hasNamedSlotsForObject: anObject) ifTrue: [ ^ #namedObject ].
	self error: 'Unsupported dirty materialized object class: ', anObject class name
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> hasNamedSlotsForObject: anObject [
	^ (self namedSlotCountForObject: anObject) > 0
]

{ #category : 'private - lifecycle' }
GbsDirtyReplicateStoreTraversal >> exportSetReleaseOopsForStoreTraversalUsing: serverInterface [
	| releaseOops |
	(self supportsNoLongerReplicatedStoreTraversalOn: serverInterface) ifFalse: [ ^ #() ].
	releaseOops := GbsSessionLifecycleManager
		pendingExportSetReleaseOopsForSession: session
		limit: nil.
	(serverInterface respondsTo: #storeTraversalBuffer:releasingNoLongerReplicatedOops:gcedOops:) ifTrue: [
		^ releaseOops ].
	^ Dictionary new
		at: #noLongerReplicated put: (releaseOops at: #noLongerReplicated ifAbsent: [ #() ]);
		at: #gced put: #();
		yourself
]

{ #category : 'private - marshaling' }
GbsDirtyReplicateStoreTraversal >> marshalArrayArgumentToScript: anArray visited: visited [
	| statements |
	statements := OrderedCollection new: anArray size.
	1 to: anArray size do: [ :index |
		statements add:
			'at: ', index printString, ' put: ',
				(self argumentScriptFor: (anArray at: index) visited: visited) ].
	^ self
		marshalConstructedObjectExpressionForReceiver: 'Array new: ', anArray size printString
		statements: statements
]

{ #category : 'private - marshaling' }
GbsDirtyReplicateStoreTraversal >> marshalAssociationArgumentToScript: anAssociation visited: visited [
	^ '(Association key: ',
		(self argumentScriptFor: anAssociation key visited: visited),
		' value: ',
		(self argumentScriptFor: anAssociation value visited: visited),
		')'
]

{ #category : 'private - marshaling' }
GbsDirtyReplicateStoreTraversal >> marshalCollectionArgumentToScript: aCollection receiver: receiverString visited: visited [
	| statements |
	statements := OrderedCollection new: aCollection size.
	aCollection do: [ :each |
		statements add: 'add: ', (self argumentScriptFor: each visited: visited) ].
	^ self
		marshalConstructedObjectExpressionForReceiver: receiverString
		statements: statements
]

{ #category : 'private - marshaling' }
GbsDirtyReplicateStoreTraversal >> marshalConstructedArgumentToScript: anObject visited: visited [
	(visited includes: anObject) ifTrue: [
		self error: 'Cyclic local object graphs are not supported for dirty replicate flush.' ].
	visited add: anObject.
	^ [
		anObject class == Array ifTrue: [
			^ self marshalArrayArgumentToScript: anObject visited: visited ].
		anObject class == OrderedCollection ifTrue: [
			^ self
				marshalCollectionArgumentToScript: anObject
				receiver: 'OrderedCollection new'
				visited: visited ].
		anObject class == Set ifTrue: [
			^ self
				marshalCollectionArgumentToScript: anObject
				receiver: 'Set new'
				visited: visited ].
		anObject class == IdentitySet ifTrue: [
			^ self
				marshalCollectionArgumentToScript: anObject
				receiver: 'IdentitySet new'
				visited: visited ].
		anObject class == Bag ifTrue: [
			^ self
				marshalCollectionArgumentToScript: anObject
				receiver: 'Bag new'
				visited: visited ].
		anObject class == Dictionary ifTrue: [
			^ self
				marshalDictionaryArgumentToScript: anObject
				receiver: 'Dictionary new'
				visited: visited ].
		anObject class == IdentityDictionary ifTrue: [
			^ self
				marshalDictionaryArgumentToScript: anObject
				receiver: 'IdentityDictionary new'
				visited: visited ].
		anObject class == Association ifTrue: [
			^ self marshalAssociationArgumentToScript: anObject visited: visited ].
		session marshalArgumentToScript: anObject visited: visited ]
		ensure: [ visited remove: anObject ifAbsent: [ ] ]
]

{ #category : 'private - marshaling' }
GbsDirtyReplicateStoreTraversal >> marshalConstructedObjectExpressionForReceiver: receiverString statements: statements [
	^ String streamContents: [ :stream |
		| first |
		stream
			nextPutAll: '((';
			nextPutAll: receiverString;
			nextPut: $).
		first := true.
		statements do: [ :each |
			first
				ifTrue: [
					stream nextPut: Character space.
					first := false ]
				ifFalse: [ stream nextPutAll: '; ' ].
			stream nextPutAll: each ].
		first ifTrue: [ stream nextPut: Character space ] ifFalse: [ stream nextPutAll: '; ' ].
		stream nextPutAll: 'yourself)' ]
]

{ #category : 'private - marshaling' }
GbsDirtyReplicateStoreTraversal >> marshalDictionaryArgumentToScript: aDictionary receiver: receiverString visited: visited [
	| statements |
	statements := OrderedCollection new: aDictionary size.
	aDictionary keysAndValuesDo: [ :key :value |
		statements add:
			'at: ', (self argumentScriptFor: key visited: visited),
				' put: ',
				(self argumentScriptFor: value visited: visited) ].
	^ self
		marshalConstructedObjectExpressionForReceiver: receiverString
		statements: statements
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> namedSlotCountForObject: anObject [
	| names |
	anObject ifNil: [ ^ 0 ].
	(anObject class respondsTo: #allInstVarNames) ifFalse: [ ^ 0 ].
	names := [ anObject class allInstVarNames ] on: Error do: [ #() ].
	^ names size
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> namedSlotFlushMappingsForObject: anObject [
	| replicator offsets mappings |
	replicator := self replicatorForNamedObject: anObject.
	(replicator notNil and: [
		(replicator respondsTo: #usesInstVarMap)
			and: [ replicator usesInstVarMap ] ]) ifTrue: [
		offsets := replicator serverToClientOffsets.
		mappings := OrderedCollection new.
		offsets doWithIndex: [ :clientIndex :serverIndex |
			clientIndex ifNotNil: [
				mappings add: { serverIndex. clientIndex } ] ].
		^ mappings asArray ].
	^ (1 to: (self namedSlotCountForObject: anObject)) collect: [ :index |
		{ index. index } ]
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> namedSlotFlushValuesForObject: anObject [
	| replicator |
	replicator := self replicatorForNamedObject: anObject.
	(replicator notNil and: [ replicator respondsTo: #dirtyStoreNamedValuesFor:unmappedValue: ]) ifTrue: [
		^ replicator dirtyStoreNamedValuesFor: anObject unmappedValue: nil ].
	^ nil
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> indexableFlushValuesForObject: anObject [
	| replicator |
	replicator := self replicatorForNamedObject: anObject.
	(replicator notNil and: [ replicator respondsTo: #dirtyStoreIndexableValuesFor: ]) ifTrue: [
		^ replicator dirtyStoreIndexableValuesFor: anObject ].
	^ #()
]

{ #category : 'private - tracking' }
GbsDirtyReplicateStoreTraversal >> oopForObject: anObject [
	^ GbsMaterializedObjectDirtyTracker oopForObject: anObject inSession: session
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> dirtyStoreEntryFor: anObject [
	| replicator |
	replicator := self replicatorForObject: anObject.
	(replicator notNil and: [ replicator respondsTo: #store:inTraversal: ]) ifTrue: [
		^ replicator store: anObject inTraversal: self ].
	^ self dirtyStoreEntryFor: anObject replicator: replicator
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> dirtyStoreEntryFor: anObject replicator: aReplicator [
	| oop classOop isNew allocation |
	(GbsMaterializedObjectDirtyTracker canTrackObject: anObject) ifFalse: [ ^ nil ].
	oop := self oopForObject: anObject.
	classOop := nil.
	isNew := false.
	oop ifNil: [
		(self shouldAllocateOopForNewDirtyObject: anObject replicator: aReplicator) ifFalse: [ ^ nil ].
		classOop := self classOopForNewObject: anObject replicator: aReplicator.
		classOop ifNil: [
			self error: 'Cannot dirty-store new ', anObject class name, ' because no GemStone class OOP could be resolved.' ].
		allocation := self allocateOopForNewDirtyObject: anObject.
		oop := allocation.
		isNew := true ].
	^ {
		oop.
		anObject.
		(self kindForObject: anObject replicator: aReplicator).
		aReplicator.
		classOop.
		isNew }
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> shouldAllocateOopForNewDirtyObject: anObject replicator: aReplicator [
	(GbsMaterializedObjectDirtyTracker canTrackObject: anObject) ifFalse: [ ^ false ].
	(GbsMaterializedObjectDirtyTracker sessionTrackingObject: anObject) == session ifTrue: [ ^ true ].
	^ false
]

{ #category : 'private - free oops' }
GbsDirtyReplicateStoreTraversal >> allocateOopForNewDirtyObject: anObject [
	| oop |
	oop := self freeOopStream nextFreeOop.
	GbsMaterializedObjectDirtyTracker
		registerObject: anObject
		oop: oop
		session: session.
	GbsSessionLifecycleManager noteAllocatedFreeOop: oop forSession: session.
	^ oop
]

{ #category : 'private - free oops' }
GbsDirtyReplicateStoreTraversal >> freeOopStream [
	(session respondsTo: #freeOopStream) ifTrue: [ ^ session freeOopStream ].
	^ GbxFreeOopStream for: session
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> classOopForNewObject: anObject replicator: aReplicator [
	| classOop |
	(aReplicator notNil and: [ aReplicator respondsTo: #dirtyStoreServerClassOopFor:inTraversal: ]) ifTrue: [
		classOop := aReplicator dirtyStoreServerClassOopFor: anObject inTraversal: self.
		classOop ifNotNil: [ ^ classOop ] ].
	^ self classOopForServerBehavior: anObject class
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> classOopForServerBehavior: aBehaviorOrName [
	| name key |
	aBehaviorOrName ifNil: [ ^ nil ].
	aBehaviorOrName isInteger ifTrue: [ ^ aBehaviorOrName ].
	name := ((aBehaviorOrName isString) or: [ aBehaviorOrName isSymbol ])
		ifTrue: [ aBehaviorOrName asString ]
		ifFalse: [
			((aBehaviorOrName isKindOf: Behavior)
				or: [
					(aBehaviorOrName respondsTo: #isBehavior)
						and: [ aBehaviorOrName isBehavior ] ])
				ifTrue: [ aBehaviorOrName name asString ]
				ifFalse: [
					((aBehaviorOrName respondsTo: #oop) and: [ aBehaviorOrName oop notNil ]) ifTrue: [
						^ aBehaviorOrName oop ].
					(aBehaviorOrName respondsTo: #name)
						ifTrue: [ aBehaviorOrName name asString ]
						ifFalse: [ aBehaviorOrName asString ] ] ].
	name isEmpty ifTrue: [ ^ nil ].
	key := { #serverClassOop. name }.
	^ self classOopCache
		at: key
		ifAbsentPut: [
			| oop |
			oop := [ session
				returnRemoteCommandBody: '| class |
class := System myUserProfile symbolList objectNamed: className asSymbol.
class ifNil: [ class := GsSession currentSession resolveSymbol: className asSymbol ].
class ifNil: [ nil ] ifNotNil: [ class asOop ]'
				literalBindings: (Dictionary new
					at: 'className' put: name;
					yourself)
				oopBindings: Dictionary new ]
				on: Error
				do: [ ^ nil ].
			oop := self remoteSmallIntegerValueFromResultOop: oop.
			(oop isNil or: [ oop = 20 ]) ifTrue: [ ^ nil ].
			self unsignedOopForSignedOop: oop asInteger ]
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> remoteSmallIntegerValueFromResultOop: resultOop [
	resultOop ifNil: [ ^ nil ].
	((resultOop isInteger) and: [ (resultOop bitAnd: 7) = 2 ]) ifFalse: [
		^ resultOop ].
	^ [ session resultFor: resultOop ]
		on: Error
		do: [
			(resultOop - 2) // 8 ]
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> classOopCache [
	^ (session class weakRegistryNamed: #GbsSessionDirtyStoreClassOopCaches)
		at: session
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> unsignedOopForSignedOop: anInteger [
	anInteger >= 0 ifTrue: [ ^ anInteger ].
	^ (1 bitShift: 64) + anInteger
]

{ #category : 'private - reporting' }
GbsDirtyReplicateStoreTraversal >> recordNativeFlushForEntries: entries [
	self incrementDirtyStoreReportAt: #nativeFlushCount by: 1.
	self incrementDirtyStoreReportAt: #nativeEntryCount by: entries size
]

{ #category : 'private - reporting' }
GbsDirtyReplicateStoreTraversal >> recordRemoteCommandForEntries: entries [
	self incrementDirtyStoreReportAt: #remoteCommandCount by: 1.
	self incrementDirtyStoreReportAt: #remoteCommandEntryCount by: entries size.
	(entries anySatisfy: [ :entry | self requiresSemanticStoreForEntry: entry ])
		ifTrue: [ self incrementDirtyStoreReportAt: #semanticCommandCount by: 1 ]
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> replicatorForNamedObject: anObject [
	^ self replicatorForObject: anObject
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> replicatorForObject: anObject [
	(session notNil and: [ session respondsTo: #replicatorForClient:ifAbsent: ]) ifFalse: [
		^ nil ].
	^ [ session
		replicatorForClient: anObject
		ifAbsent: [ nil ] ]
		on: Error
		do: [ nil ]
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> replicationPolicy [
	^ [ GbsReplicationPolicy forSession: session ] on: Error do: [ nil ]
]

{ #category : 'private - reporting' }
GbsDirtyReplicateStoreTraversal >> incrementDirtyStoreReportAt: key by: amount [
	| report |
	report := self class dirtyStoreTraversalReportStorageForSession: session.
	report at: key put: (report at: key ifAbsent: [ 0 ]) + amount.
	^ report
]

{ #category : 'private - reporting' }
GbsDirtyReplicateStoreTraversal >> recordNativeCapabilityReportFrom: serverInterface [
	| report capabilityReport |
	serverInterface ifNil: [ ^ self ].
	(serverInterface respondsTo: #nativeStoreTraversalCapabilityReport) ifFalse: [ ^ self ].
	capabilityReport := [
		serverInterface nativeStoreTraversalCapabilityReport
	] on: Error do: [ :ex |
		Dictionary new
			at: #error put: ex messageText;
			yourself ].
	report := self class dirtyStoreTraversalReportStorageForSession: session.
	report at: #nativeCapabilityReport put: capabilityReport.
	^ capabilityReport
]

{ #category : 'private - reporting' }
GbsDirtyReplicateStoreTraversal >> recordNativeFallbackReason: reasonSymbol details: detailObject [
	| report |
	report := self class dirtyStoreTraversalReportStorageForSession: session.
	report
		at: #nativeFallbackCount put: (report at: #nativeFallbackCount ifAbsent: [ 0 ]) + 1;
		at: #nativeFallbackReason put: reasonSymbol;
		at: #nativeFallbackDetails put: detailObject.
	^ reasonSymbol
]

{ #category : 'private - commands' }
GbsDirtyReplicateStoreTraversal >> remoteCommandForEntries: entries [
	| argumentNames argumentScripts body assignmentNames assignmentScripts |
	argumentNames := OrderedCollection new.
	argumentScripts := OrderedCollection new.
	body := self
		bodyForEntries: entries
		argumentNames: argumentNames
		argumentScripts: argumentScripts.
	assignmentNames := OrderedCollection with: 'object'.
	assignmentNames addAll: argumentNames.
	assignmentScripts := OrderedCollection with: 'nil'.
	assignmentScripts addAll: argumentScripts.
	^ GbsRemoteCommand
		blockBody: (GbsRemoteCommand
			body: body
			withAssignmentsNamed: assignmentNames asArray
			scripts: assignmentScripts asArray)
		argumentNames: #()
		argumentScripts: #()
]

{ #category : 'private - arguments' }
GbsDirtyReplicateStoreTraversal >> remoteObjectExpressionForOop: anOop [
	^ GbsRemoteScriptBuilder objectForOop: anOop
]

{ #category : 'accessing' }
GbsDirtyReplicateStoreTraversal >> session [
	^ session
]

{ #category : 'accessing' }
GbsDirtyReplicateStoreTraversal >> session: aSession [
	session := aSession
]

{ #category : 'private - marshaling' }
GbsDirtyReplicateStoreTraversal >> shouldMarshalConstructedObject: anObject [
	anObject ifNil: [ ^ false ].
	(anObject class == Array) ifTrue: [ ^ true ].
	(anObject class == OrderedCollection) ifTrue: [ ^ true ].
	(anObject class == Set) ifTrue: [ ^ true ].
	(anObject class == IdentitySet) ifTrue: [ ^ true ].
	(anObject class == Bag) ifTrue: [ ^ true ].
	(anObject class == Dictionary) ifTrue: [ ^ true ].
	(anObject class == IdentityDictionary) ifTrue: [ ^ true ].
	(anObject class == Association) ifTrue: [ ^ true ].
	^ false
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> shouldUseBinaryStoreTraversalBufferForEntries: entries [
	| transport server buffer nativeEntries |
	entries isEmpty ifTrue: [ ^ false ].
	(self entriesRequireBinaryStoreTraversal: entries) ifTrue: [ ^ true ].
	transport := self storeTraversalTransport.
	((transport = #binary) or: [ transport = #binaryRequired ]) ifFalse: [ ^ false ].
	nativeEntries := self nativeStoreTraversalEntriesFor: entries.
	nativeEntries isEmpty ifTrue: [
		self recordNativeFallbackReason: #noNativeEntries details: 'No dirty entries can be encoded with the native dirty-store traversal buffer.'.
		^ false ].
	server := [ session serverInterface ] on: Error do: [ nil ].
	server ifNil: [
		self recordNativeFallbackReason: #noServerInterface details: 'No server interface is available for native dirty-store traversal.'.
		^ false ].
	self recordNativeCapabilityReportFrom: server.
	(server respondsTo: #supportsDirtyStoreTraversalBufferTransport) ifFalse: [
		self recordNativeFallbackReason: #missingCapabilityProbe details: 'Server interface does not answer supportsDirtyStoreTraversalBufferTransport.'.
		^ false ].
	(server supportsDirtyStoreTraversalBufferTransport == true) ifFalse: [
		self recordNativeFallbackReason: #transportUnsupported details: 'Native dirty-store traversal buffer transport is not supported by this server interface.'.
		^ false ].
	(self supportsNativeStoreTraversalReportShapeOn: server) ifFalse: [
		self recordNativeFallbackReason: #unsupportedReportShape details: 'Native dirty-store traversal report shape is unsupported for this GemStone/GCI version.'.
		^ false ].
	(server respondsTo: #storeTraversalBuffer:) ifFalse: [
		self recordNativeFallbackReason: #missingStoreTraversalBuffer details: 'Server interface does not answer storeTraversalBuffer:.'.
		^ false ].
	buffer := self dirtyStoreTraversalBufferForEntries: nativeEntries.
	buffer canProduceNativeTraversalBuffer ifFalse: [
		self recordNativeFallbackReason: #encodingUnsupported details: buffer nativeEncodingFailureSummary.
		^ false ].
	^ true
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> nativeStoreTraversalEntriesFor: entries [
	| nativeEntries seenOops |
	nativeEntries := OrderedCollection new.
	seenOops := Set new.
	entries do: [ :entry | | kind expansionEntries |
		(self requiresSemanticStoreForEntry: entry) ifFalse: [
			kind := entry at: 3.
			expansionEntries := (#(#dictionary #identityDictionary) includes: kind)
				ifTrue: [
					self
						nativeAssociationEntriesForDictionaryEntry: entry
						ifAbsent: [ #() ] ]
				ifFalse: [
					(#(#set #bag) includes: kind)
						ifTrue: [
								self
									nativeStructuralEntriesForHashedCollectionEntry: entry
									ifAbsent: [ #() ] ]
							ifFalse: [ { entry } ] ].
			expansionEntries do: [ :nativeEntry |
				(seenOops includes: nativeEntry first) ifFalse: [
					seenOops add: nativeEntry first.
					nativeEntries add: nativeEntry ] ] ] ].
	^ nativeEntries asArray
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> requiresSemanticStoreForEntry: entry [
	| kind |
	(self semanticDirtyStoreRequestedBy: entry second) ifTrue: [ ^ true ].
	(self entryIsNewObject: entry) ifTrue: [ ^ false ].
	kind := entry at: 3.
	(#(#dictionary #identityDictionary) includes: kind) ifTrue: [
		^ (self canNativeStoreDictionaryEntry: entry) not ].
	^ false
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> nativeStructuralEntriesForHashedCollectionEntry: entry ifAbsent: absentBlock [
	^ self nativeEntryExpansionCache
		at: entry first
		ifAbsentPut: [
			self
				buildNativeStructuralEntriesForHashedCollectionEntry: entry
				ifAbsent: absentBlock ]
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> nativeEntryExpansionCache [
	^ nativeEntryExpansionCache ifNil: [ nativeEntryExpansionCache := Dictionary new ]
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> buildNativeStructuralEntriesForHashedCollectionEntry: entry ifAbsent: absentBlock [
	^ { entry }
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> canNativeStoreDictionaryEntry: entry [
	| associations buffer |
	(self entryIsNewObject: entry) ifTrue: [ ^ true ].
	associations := entry second associations asArray.
	associations isEmpty ifTrue: [ ^ true ].
	buffer := self dirtyStoreTraversalBufferForEntries: { entry }.
	(self dictionaryAssociationsAreMapped: associations) ifFalse: [
		[ buffer
			registerRemoteAssociationsForDictionaryEntry: entry
			associations: associations ]
			on: Error
			do: [ ^ false ] ].
	(self
		remoteAssociationCountMatchesForDictionaryEntry: entry
		associations: associations
		using: buffer) ifFalse: [ ^ false ].
	^ self dictionaryAssociationsAreMapped: associations
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> nativeAssociationEntriesForDictionaryEntry: entry ifAbsent: absentBlock [
	| associations buffer nativeEntries |
	associations := entry second associations asArray.
	associations isEmpty ifTrue: [
		^ (self entryIsNewObject: entry)
			ifTrue: [ { entry } ]
			ifFalse: [ #() ] ].
	buffer := self dirtyStoreTraversalBufferForEntries: { entry }.
	(self dictionaryAssociationsAreMapped: associations) ifFalse: [
		[ buffer
			registerRemoteAssociationsForDictionaryEntry: entry
			associations: associations ]
			on: Error
			do: [ ] ].
	(self entryIsNewObject: entry)
		ifTrue: [
			nativeEntries := OrderedCollection new: associations size + 1.
			]
		ifFalse: [ nativeEntries := OrderedCollection new: associations size ].
	associations do: [ :association | | associationOop associationWasNew |
		associationWasNew := false.
		associationOop := [ self oopForObject: association ] on: Error do: [ nil ].
		associationOop ifNil: [
			(self entryIsNewObject: entry)
				ifTrue: [
					associationOop := self tryAllocateDictionaryAssociation: association ifAbsent: [ ^ absentBlock value ].
					associationWasNew := true ]
				ifFalse: [ ^ absentBlock value ] ].
		nativeEntries add: {
			associationOop.
			association.
			#association.
			nil.
				(associationWasNew ifTrue: [ self classOopForServerBehavior: 'Association' ] ifFalse: [ nil ]).
				associationWasNew } ].
	(self entryIsNewObject: entry) ifTrue: [
		nativeEntries add: entry ].
	^ nativeEntries asArray
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> dictionaryAssociationsAreMapped: associations [
	^ associations allSatisfy: [ :association |
		(self oopForObject: association) notNil ]
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> tryAllocateDictionaryAssociation: association ifAbsent: absentBlock [
	| classOop oop |
	(GbsMaterializedObjectDirtyTracker canTrackObject: association) ifFalse: [ ^ absentBlock value ].
	classOop := self classOopForServerBehavior: 'Association'.
	classOop ifNil: [ ^ absentBlock value ].
	GbsMaterializedObjectDirtyTracker registerObject: association forSession: session.
	oop := self allocateOopForNewDirtyObject: association.
	^ oop
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> remoteAssociationCountMatchesForDictionaryEntry: entry associations: associations using: buffer [
	| maps remoteAssociationsByKey |
	maps := [ buffer remoteDictionaryAssociationOopMapsFor: entry first ]
		on: Error
		do: [ ^ true ].
	remoteAssociationsByKey := maps at: #byKeyOop ifAbsent: [ Dictionary new ].
	^ remoteAssociationsByKey size = associations size
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> semanticDirtyStoreRequestedBy: anObject [
	(anObject respondsTo: #gbsDirtyStoreRequiresSemanticCommand) ifFalse: [ ^ false ].
	^ [ anObject gbsDirtyStoreRequiresSemanticCommand == true ]
		on: Error
		do: [ false ]
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> semanticStoreEntriesFor: entries [
	^ entries select: [ :entry | self requiresSemanticStoreForEntry: entry ]
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> entriesRequireBinaryStoreTraversal: entries [
	^ entries anySatisfy: [ :entry | self entryIsNewObject: entry ]
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> ensureBinaryStoreTraversalAvailableForEntries: entries [
	| server buffer |
	server := [ session serverInterface ] on: Error do: [ nil ].
	server ifNil: [
		self recordNativeFallbackReason: #noServerInterface details: 'No server interface is available for native dirty-store traversal.'.
		self error: 'Dirty store traversal buffer transport is required, but no server interface is available.' ].
	self recordNativeCapabilityReportFrom: server.
	(server respondsTo: #supportsDirtyStoreTraversalBufferTransport) ifFalse: [
		self recordNativeFallbackReason: #missingCapabilityProbe details: 'Server interface does not answer supportsDirtyStoreTraversalBufferTransport.'.
		self error: 'Dirty store traversal buffer transport is required, but the server interface has no capability probe.' ].
	(server supportsDirtyStoreTraversalBufferTransport == true) ifFalse: [
		self recordNativeFallbackReason: #transportUnsupported details: 'Native dirty-store traversal buffer transport is not supported by this server interface.'.
		self error: 'Dirty store traversal buffer transport is required, but native GCI store traversal is unavailable.' ].
	(self supportsNativeStoreTraversalReportShapeOn: server) ifFalse: [
		self recordNativeFallbackReason: #unsupportedReportShape details: 'Native dirty-store traversal report shape is unsupported for this GemStone/GCI version.'.
		self error: 'Dirty store traversal buffer transport is required, but the native GCI store traversal report shape is unsupported for this GemStone/GCI version.' ].
	(server respondsTo: #storeTraversalBuffer:) ifFalse: [
		self recordNativeFallbackReason: #missingStoreTraversalBuffer details: 'Server interface does not answer storeTraversalBuffer:.'.
		self error: 'Dirty store traversal buffer transport is required, but no storeTraversalBuffer: transport is installed.' ].
	buffer := self dirtyStoreTraversalBufferForEntries: (self nativeStoreTraversalEntriesFor: entries).
	buffer canProduceNativeTraversalBuffer ifFalse: [
		self recordNativeFallbackReason: #encodingUnsupported details: buffer nativeEncodingFailureSummary.
		self error: 'Dirty store traversal buffer transport is required, but this batch cannot be encoded natively. Unencodable entries: ', buffer nativeEncodingFailureSummary ].
	^ true
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> supportsNativeStoreTraversalReportShapeOn: serverInterface [
	| policy |
	policy := self replicationPolicy.
	(policy notNil and: [
		(policy respondsTo: #nativeStoreTraversalShapeValidationEnabled)
			and: [ policy nativeStoreTraversalShapeValidationEnabled == false ] ]) ifTrue: [
		^ true ].
	(serverInterface respondsTo: #supportsNativeStoreTraversalReportShape) ifFalse: [ ^ false ].
	^ serverInterface supportsNativeStoreTraversalReportShape == true
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> entryHasReplicator: entry [
	^ entry size >= 4 and: [ (entry at: 4) notNil ]
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> entryIsNewObject: entry [
	^ entry size >= 6 and: [ (entry at: 6) == true ]
]

{ #category : 'private - flushing' }
GbsDirtyReplicateStoreTraversal >> storeTraversalBuffer: aBuffer on: serverInterface releasingExportSetReleaseOops: releaseDictionary [
	| noLongerReplicatedOops gcedOops result |
	(releaseDictionary isNil or: [ releaseDictionary isEmpty ]) ifTrue: [
		^ serverInterface storeTraversalBuffer: aBuffer ].
	noLongerReplicatedOops := releaseDictionary at: #noLongerReplicated ifAbsent: [ #() ].
	gcedOops := releaseDictionary at: #gced ifAbsent: [ #() ].
	(noLongerReplicatedOops isEmpty and: [ gcedOops isEmpty ]) ifTrue: [
		^ serverInterface storeTraversalBuffer: aBuffer ].
	(gcedOops isEmpty and: [
		serverInterface respondsTo: #storeTraversalBuffer:releasingNoLongerReplicatedOops: ]) ifTrue: [
		result := [
			serverInterface
				storeTraversalBuffer: aBuffer
				releasingNoLongerReplicatedOops: noLongerReplicatedOops ]
			on: GbsError
			do: [ :ex |
				self
					storeTraversalBuffer: aBuffer
					on: serverInterface
					fallbackFromCombinedReleaseError: ex
					noLongerReplicatedOops: noLongerReplicatedOops
					gcedOops: #() ].
		GbsSessionLifecycleManager
			acknowledgeNoLongerReplicatedOops: noLongerReplicatedOops
			forSession: session.
		^ result ].
	(serverInterface respondsTo: #storeTraversalBuffer:releasingNoLongerReplicatedOops:gcedOops:) ifFalse: [
		^ serverInterface storeTraversalBuffer: aBuffer ].
	result := [
		serverInterface
			storeTraversalBuffer: aBuffer
			releasingNoLongerReplicatedOops: noLongerReplicatedOops
			gcedOops: gcedOops ]
		on: GbsError
		do: [ :ex |
			self
				storeTraversalBuffer: aBuffer
				on: serverInterface
				fallbackFromCombinedReleaseError: ex
				noLongerReplicatedOops: noLongerReplicatedOops
				gcedOops: gcedOops ].
	GbsSessionLifecycleManager
		acknowledgeNoLongerReplicatedOops: noLongerReplicatedOops
		forSession: session.
	GbsSessionLifecycleManager
		acknowledgeGcedOops: gcedOops
		forSession: session.
	^ result
]

{ #category : 'private - flushing' }
GbsDirtyReplicateStoreTraversal >> storeTraversalBuffer: aBuffer on: serverInterface fallbackFromCombinedReleaseError: anError noLongerReplicatedOops: noLongerReplicatedOops gcedOops: gcedOops [
	| releaseOops |
	(anError messageText includesSubstring: 'GciStoreTravDoTravRefs_ failed')
		ifFalse: [ anError pass ].
	serverInterface storeTraversalBuffer: aBuffer.
	releaseOops := noLongerReplicatedOops asArray, gcedOops asArray.
	releaseOops isEmpty ifFalse: [
		GbsSessionLifecycleManager releaseOops: releaseOops forSession: session ].
	^ 1
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> storeTraversalTransport [
	| policy |
	policy := self replicationPolicy.
	policy ifNil: [ ^ 'script' ].
	(policy respondsTo: #storeTraversalTransport) ifFalse: [ ^ 'script' ].
	(policy respondsTo: #storeTraversalTransportSymbol) ifTrue: [
		^ policy storeTraversalTransportSymbol ].
	^ (policy storeTraversalTransport ifNil: [ 'script' ]) asSymbol
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> transportRequiresBinary [
	^ self storeTraversalTransport = #binaryRequired
]

{ #category : 'private - lifecycle' }
GbsDirtyReplicateStoreTraversal >> supportsNoLongerReplicatedStoreTraversalOn: serverInterface [
	(serverInterface respondsTo: #storeTraversalBuffer:releasingNoLongerReplicatedOops:) ifFalse: [ ^ false ].
	(serverInterface respondsTo: #supportsNoLongerReplicatedStoreTraversalTransport) ifFalse: [ ^ false ].
	^ serverInterface supportsNoLongerReplicatedStoreTraversalTransport == true
]

{ #category : 'private - names' }
GbsDirtyReplicateStoreTraversal >> valueArgumentNameForEntry: entryIndex element: elementIndex [
	^ 'value' , entryIndex asString , '_' , elementIndex asString
]
