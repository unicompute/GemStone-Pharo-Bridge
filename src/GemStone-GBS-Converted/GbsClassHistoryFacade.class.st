Class {
	#name : 'GbsClassHistoryFacade',
	#superclass : 'Object',
	#instVars : [
		'session',
		'classReference'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsClassHistoryFacade class >> on: aSession class: aClassOrName [
	^ self new
		session: aSession;
		classReference: aClassOrName;
		yourself
]

{ #category : 'accessing' }
GbsClassHistoryFacade >> classReference [
	^ classReference
]

{ #category : 'accessing' }
GbsClassHistoryFacade >> classReference: aClassOrName [
	classReference := aClassOrName
]

{ #category : 'querying' }
GbsClassHistoryFacade >> canMigrateInstances [
	^ self size > 1
]

{ #category : 'private' }
GbsClassHistoryFacade >> holderFromEntry: anEntry [
	^ GbxClassHolder
		name: (anEntry at: 2)
		proxy: (session objectForOop: (anEntry at: 1))
		version: (anEntry at: 3)
		numberOfVersions: (anEntry at: 4)
]

{ #category : 'querying' }
GbsClassHistoryFacade >> holders [
	| entries |
	entries := self versionEntries.
	^ entries reversed collect: [ :each | self holderFromEntry: each ]
]

{ #category : 'querying' }
GbsClassHistoryFacade >> latestVersion [
	| entries |
	entries := self versionEntries.
	entries isEmpty ifTrue: [ ^ nil ].
	^ session objectForOop: (entries last at: 1)
]

{ #category : 'querying' }
GbsClassHistoryFacade >> latestHolder [
	| allHolders |
	allHolders := self holders.
	allHolders isEmpty ifTrue: [ ^ nil ].
	^ allHolders first
]

{ #category : 'mutating' }
GbsClassHistoryFacade >> makeCurrentIn: aDictionaryOrName [
	| dictionary selected |
	dictionary := (aDictionaryOrName isString or: [ aDictionaryOrName isSymbol ])
		ifTrue: [ session namedObjectAt: aDictionaryOrName ]
		ifFalse: [ aDictionaryOrName ].
	selected := self selectedVersion.
	selected ifNil: [ ^ nil ].
	dictionary at: self selectedVersionName put: selected.
	^ selected
]

{ #category : 'mutating' }
GbsClassHistoryFacade >> migrateInstancesTo: aTargetClassOrHolder [
	^ self migrateInstancesTo: aTargetClassOrHolder allowAbort: false
]

{ #category : 'querying' }
GbsClassHistoryFacade >> previewMigrationTo: aTargetClassOrHolder [
	^ self previewMigrationTo: aTargetClassOrHolder allowAbort: false
]

{ #category : 'querying' }
GbsClassHistoryFacade >> previewMigrationTo: aTargetClassOrHolder allowAbort: aBoolean [
	^ session
		previewMigrationFrom: self selectedVersion
		to: aTargetClassOrHolder
		allowAbort: aBoolean
]

{ #category : 'querying' }
GbsClassHistoryFacade >> previewOldVersionsToLatest [
	^ self previewOldVersionsToLatestAllowAbort: false
]

{ #category : 'querying' }
GbsClassHistoryFacade >> previewOldVersionsToLatestAllowAbort: aBoolean [
	^ session
		previewMigrationWithSubclassesOf: self latestVersion
		allowAbort: aBoolean
]

{ #category : 'mutating' }
GbsClassHistoryFacade >> migrateInstancesTo: aTargetClassOrHolder allowAbort: aBoolean [
	^ session
		migrateInstancesFrom: self selectedVersion
		to: aTargetClassOrHolder
		allowAbort: aBoolean
]

{ #category : 'mutating' }
GbsClassHistoryFacade >> executePreviewPlan: aMigrationPlan [
	^ self
		executePreviewPlan: aMigrationPlan
		allowAbort: false
]

{ #category : 'mutating' }
GbsClassHistoryFacade >> executePreviewPlan: aMigrationPlan allowAbort: aBoolean [
	aMigrationPlan ifNil: [ ^ 0 ].
	aMigrationPlan includesSubclasses ifTrue: [
		^ self migrateOldVersionsToLatestAllowAbort: aBoolean ].
	^ session
		migrateInstancesFrom: aMigrationPlan sourceReference
		to: aMigrationPlan targetReference
		allowAbort: aBoolean
]

{ #category : 'mutating' }
GbsClassHistoryFacade >> migrateOldVersionsToLatest [
	^ self migrateOldVersionsToLatestAllowAbort: false
]

{ #category : 'mutating' }
GbsClassHistoryFacade >> migrateOldVersionsToLatestAllowAbort: aBoolean [
	^ session
		migrateInstancesWithSubclassesOf: self latestVersion
		allowAbort: aBoolean
]

{ #category : 'querying' }
GbsClassHistoryFacade >> selectedHolder [
	| entry |
	entry := self selectedVersionEntry.
	entry ifNil: [ ^ nil ].
	^ self holderFromEntry: entry
]

{ #category : 'querying' }
GbsClassHistoryFacade >> selectedVersion [
	| requestedName historicalEntry |
	(classReference respondsTo: #proxy) ifTrue: [ ^ classReference proxy ].
	(classReference isKindOf: GbsProxy) ifTrue: [ ^ classReference ].
	(classReference isBehavior or: [
		classReference class name asString includesSubstring: 'Behavior' ]) ifTrue: [
		^ session namedObjectAt: classReference name ].
	((classReference isString) or: [ classReference isSymbol ]) ifTrue: [
		requestedName := classReference asString.
		historicalEntry := self versionEntries
			detect: [ :each | (each at: 2 ifAbsent: [ '' ]) = requestedName ]
			ifNone: [ nil ].
		historicalEntry ifNotNil: [ ^ session objectForOop: (historicalEntry at: 1) ].
		^ session namedObjectAt: classReference ifAbsent: [ nil ] ].
	^ nil
]

{ #category : 'private' }
GbsClassHistoryFacade >> selectedVersionEntry [
	| selected |
	selected := self selectedVersion.
	selected ifNil: [ ^ nil ].
	^ self versionEntries
		detect: [ :each | (each at: 1) = selected oop ]
		ifNone: [ nil ]
]

{ #category : 'querying' }
GbsClassHistoryFacade >> selectedVersionName [
	| entry |
	entry := self selectedVersionEntry.
	entry ifNotNil: [ ^ entry at: 2 ].
	(classReference respondsTo: #name) ifTrue: [ ^ classReference name ].
	^ classReference asString
]

{ #category : 'querying' }
GbsClassHistoryFacade >> oldVersionHolders [
	^ self holders select: [ :each |
		each version < each numberOfVersions ]
]

{ #category : 'querying' }
GbsClassHistoryFacade >> oldVersionNamesToRemove [
	| latestName |
	latestName := self latestHolder
		ifNil: [ nil ]
		ifNotNil: [ :holder | holder name ].
	^ (self oldVersionHolders
		collect: [ :each | each name ]
		thenReject: [ :each | each isNil or: [ each = latestName ] ]) asSet asArray
]

{ #category : 'accessing' }
GbsClassHistoryFacade >> session [
	^ session
]

{ #category : 'accessing' }
GbsClassHistoryFacade >> session: aSession [
	session := aSession
]

{ #category : 'mutating' }
GbsClassHistoryFacade >> removeOldVersionBindingsFrom: aDictionaryOrName [
	| dictionary removed |
	dictionary := (aDictionaryOrName isString or: [ aDictionaryOrName isSymbol ])
		ifTrue: [ session namedObjectAt: aDictionaryOrName ]
		ifFalse: [ aDictionaryOrName ].
	removed := OrderedCollection new.
	self oldVersionNamesToRemove do: [ :each |
		(self removeBindingNamed: each fromDictionary: dictionary) ifTrue: [
			removed add: each ] ].
	^ removed asArray
]

{ #category : 'querying' }
GbsClassHistoryFacade >> size [
	^ self versionEntries size
]

{ #category : 'querying' }
GbsClassHistoryFacade >> versionEntries [
	^ session
		executeScriptAndFetchObject: self versionEntriesScript
]

{ #category : 'private' }
GbsClassHistoryFacade >> versionEntriesScript [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| cls history total entries | cls := ';
			nextPutAll: (session repository classExpressionFor: classReference);
			nextPutAll: '. cls ifNil: [ #() ] ifNotNil: [ history := cls classHistory. total := history size. entries := OrderedCollection new. history do: [ :each | entries add: (Array with: each asOop with: each name asString with: (history indexOf: each) with: total) ]. entries asArray ]' ]
]

{ #category : 'private' }
GbsClassHistoryFacade >> removeBindingKey: aKey fromDictionary: aDictionary [
	| present |
	present := [ aDictionary includesKey: aKey ] on: Error do: [ false ].
	present ifFalse: [ ^ false ].
	[ aDictionary removeKey: aKey ] on: Error do: [ ^ false ].
	^ true
]

{ #category : 'private' }
GbsClassHistoryFacade >> removeBindingNamed: aString fromDictionary: aDictionary [
	(self removeBindingKey: aString fromDictionary: aDictionary) ifTrue: [ ^ true ].
	^ self
		removeBindingKey: aString asSymbol
		fromDictionary: aDictionary
]
