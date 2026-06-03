Class {
	#name : 'GbsDirtyReplicateStoreTraversal',
	#superclass : 'Object',
	#instVars : [
		'session'
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

{ #category : 'private - arguments' }
GbsDirtyReplicateStoreTraversal >> addArgumentNamed: name value: value toNames: argumentNames scripts: argumentScripts [
	argumentNames add: name.
	argumentScripts add: (self argumentScriptFor: value visited: IdentitySet new).
	^ name
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
	| slotCount |
	slotCount := self namedSlotCountForObject: anObject.
	1 to: slotCount do: [ :index | | valueName |
		valueName := self
			addArgumentNamed: (self valueArgumentNameForEntry: entryIndex element: index)
			value: (anObject instVarAt: index)
			toNames: argumentNames
			scripts: argumentScripts.
		stream
			nextPutAll: 'object instVarAt: ';
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

{ #category : 'private - flushing' }
GbsDirtyReplicateStoreTraversal >> dirtyStoreTraversalBufferForEntries: entries [
	^ GbsDirtyStoreTraversalBuffer entries: entries session: session
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> entriesForDirtyObjects [
	| entries |
	entries := OrderedCollection new.
	self dirtyObjects do: [ :object | | oop |
		oop := self oopForObject: object.
		(oop notNil and: [ GbsMaterializedObjectDirtyTracker canTrackObject: object ])
			ifTrue: [ entries add: { oop. object. (self kindForObject: object) } ] ].
	^ (entries asSortedCollection: [ :left :right | left first < right first ]) asArray
]

{ #category : 'flushing' }
GbsDirtyReplicateStoreTraversal >> flush [
	| entries |
	entries := self entriesForDirtyObjects.
	entries isEmpty ifTrue: [ ^ #() ].
	self flushEntries: entries.
	GbsMaterializedObjectDirtyTracker
		clearDirtyObjects: (entries collect: [ :entry | entry second ])
		forSession: session.
	^ (entries collect: [ :entry | entry first ]) asArray
]

{ #category : 'private - flushing' }
GbsDirtyReplicateStoreTraversal >> flushEntries: entries [
	| buffer |
	(self shouldUseBinaryStoreTraversalBufferForEntries: entries) ifTrue: [
		^ self flushEntriesWithBinaryStoreTraversalBuffer: entries ].
	(self semanticStoreEntriesFor: entries) size = entries size ifTrue: [
		^ self flushEntriesWithRemoteCommand: entries ].
	self transportRequiresBinary ifTrue: [
		buffer := self dirtyStoreTraversalBufferForEntries: entries.
		buffer canProduceNativeTraversalBuffer ifFalse: [
			self error: 'Dirty store traversal buffer transport is required, but this dirty batch cannot be encoded natively. Native dirty store traversal supports mapped Arrays, Associations, OrderedCollections, and named-slot objects with OOP-addressable values. Dictionaries, Sets, and Bags require semantic store commands. Unencodable entries: ', buffer nativeEncodingFailureSummary ].
		self error: 'Dirty store traversal buffer transport is required but unavailable.' ].
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
	session addStoreTraversal: self.
	^ [ session returnRemoteCommandOop: (self remoteCommandForEntries: entries) ]
		ensure: [ session removeStoreTraversal: self ]
]

{ #category : 'private - flushing' }
GbsDirtyReplicateStoreTraversal >> flushNativeEntriesWithBinaryStoreTraversalBuffer: entries [
	| buffer server exportSetReleaseOops |
	buffer := self dirtyStoreTraversalBufferForEntries: entries.
	server := session serverInterface.
	exportSetReleaseOops := self exportSetReleaseOopsForStoreTraversalUsing: server.
	(server respondsTo: #ensureDirtyObjectsInitialized) ifTrue: [
		server ensureDirtyObjectsInitialized ].
	session addStoreTraversal: self.
	^ [
		self
			storeTraversalBuffer: buffer
			on: server
			releasingExportSetReleaseOops: exportSetReleaseOops
	]
			ensure: [ session removeStoreTraversal: self ]
]

{ #category : 'private - names' }
GbsDirtyReplicateStoreTraversal >> keyArgumentNameForEntry: entryIndex element: elementIndex [
	^ 'key' , entryIndex asString , '_' , elementIndex asString
]

{ #category : 'private - entries' }
GbsDirtyReplicateStoreTraversal >> kindForObject: anObject [
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

{ #category : 'private - tracking' }
GbsDirtyReplicateStoreTraversal >> oopForObject: anObject [
	^ GbsMaterializedObjectDirtyTracker oopForObject: anObject inSession: session
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> replicationPolicy [
	^ [ GbsReplicationPolicy forSession: session ] on: Error do: [ nil ]
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
	transport := self storeTraversalTransport.
	((transport = #binary) or: [ transport = #binaryRequired ]) ifFalse: [ ^ false ].
	nativeEntries := self nativeStoreTraversalEntriesFor: entries.
	nativeEntries isEmpty ifTrue: [ ^ false ].
	server := [ session serverInterface ] on: Error do: [ nil ].
	server ifNil: [ ^ false ].
	(server respondsTo: #supportsDirtyStoreTraversalBufferTransport) ifFalse: [ ^ false ].
	(server supportsDirtyStoreTraversalBufferTransport == true) ifFalse: [ ^ false ].
	(server respondsTo: #storeTraversalBuffer:) ifFalse: [ ^ false ].
	buffer := self dirtyStoreTraversalBufferForEntries: nativeEntries.
	^ buffer canProduceNativeTraversalBuffer
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> nativeStoreTraversalEntriesFor: entries [
	^ entries reject: [ :entry | self requiresSemanticStoreForEntry: entry ]
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> requiresSemanticStoreForEntry: entry [
	^ #(#dictionary #identityDictionary #set #bag) includes: (entry at: 3)
]

{ #category : 'private - policy' }
GbsDirtyReplicateStoreTraversal >> semanticStoreEntriesFor: entries [
	^ entries select: [ :entry | self requiresSemanticStoreForEntry: entry ]
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
