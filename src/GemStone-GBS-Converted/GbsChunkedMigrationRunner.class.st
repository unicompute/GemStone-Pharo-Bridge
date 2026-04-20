Class {
	#name : 'GbsChunkedMigrationRunner',
	#superclass : 'Object',
	#instVars : [
		'session',
		'sourceClassReference',
		'targetClassReference',
		'chunkSize',
		'checkpointKey',
		'migrationName',
		'version',
		'maxCommitRetries'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsChunkedMigrationRunner class >> on: aSession source: aSourceReference target: aTargetReference [
	^ self new
		session: aSession;
		sourceClassReference: aSourceReference;
		targetClassReference: aTargetReference;
		chunkSize: 100;
		maxCommitRetries: 3;
		yourself
]

{ #category : 'instance creation' }
GbsChunkedMigrationRunner class >> on: aSession source: aSourceReference target: aTargetReference named: aName version: aVersion [
	^ (self
		on: aSession
		source: aSourceReference
		target: aTargetReference)
			migrationName: aName;
			version: aVersion;
			yourself
]

{ #category : 'private' }
GbsChunkedMigrationRunner >> classExpressionFor: aClassOrName [
	(aClassOrName respondsTo: #proxy) ifTrue: [
		^ self classExpressionFor: aClassOrName proxy ].
	(aClassOrName isKindOf: GbsProxy) ifTrue: [
		^ '(Object _objectForOop: ', aClassOrName oop printString, ')' ].
	(aClassOrName isBehavior or: [
		aClassOrName class name asString includesSubstring: 'Behavior' ]) ifTrue: [
		^ self classExpressionFor: aClassOrName name ].
	((aClassOrName isString) or: [ aClassOrName isSymbol ]) ifTrue: [
		^ String streamContents: [ :stream |
			stream
				nextPutAll: '[:name | System myUserProfile symbolList objectNamed: name asSymbol] value: ';
				nextPutAll: (session marshalArgumentToScript: aClassOrName) ] ].
	self error: 'Unsupported class reference: ', aClassOrName printString
]

{ #category : 'private' }
GbsChunkedMigrationRunner >> checkpointRoot [
	^ session bridgeRoot
]

{ #category : 'private' }
GbsChunkedMigrationRunner >> appliedVersionsKey [
	^ ('gbsAppliedMigrations:' , self migrationName) asSymbol
]

{ #category : 'querying' }
GbsChunkedMigrationRunner >> appliedVersions [
	| versions |
	versions := self checkpointRoot at: self appliedVersionsKey ifAbsent: [ #() ].
	^ versions asArray
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> checkpointKey [
	checkpointKey ifNil: [
		checkpointKey := ('gbsMigration:' , self sourceLabel , '->' , self targetLabel) asSymbol ].
	^ checkpointKey
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> checkpointKey: anObject [
	checkpointKey := anObject
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> chunkSize [
	^ chunkSize ifNil: [ 100 ]
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> chunkSize: anInteger [
	chunkSize := (anInteger ifNil: [ 100 ] ifNotNil: [ anInteger asInteger ]) max: 1
]

{ #category : 'testing' }
GbsChunkedMigrationRunner >> hasAppliedVersion [
	version ifNil: [ ^ false ].
	^ self appliedVersions includes: version
]

{ #category : 'actions' }
GbsChunkedMigrationRunner >> clearCheckpoint [
	self checkpointRoot removeKey: self checkpointKey ifAbsent: [ nil ].
	^ self
]

{ #category : 'testing' }
GbsChunkedMigrationRunner >> hasCheckpoint [
	^ self checkpointRoot includesKey: self checkpointKey
]

{ #category : 'private' }
GbsChunkedMigrationRunner >> listInstanceOopsScript [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| cls instances |
	cls := ';
			nextPutAll: (self classExpressionFor: self sourceClassReference);
			nextPutAll: '.
	cls ifNil: [ #() ] ifNotNil: [
		instances := (SystemRepository listInstances: { cls }) at: 1.
		instances collect: [ :each | each asOop ] ]' ]
]

{ #category : 'private' }
GbsChunkedMigrationRunner >> migrateChunkScriptForOops: oopCollection [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '| fromClass toClass instances |
	fromClass := ';
			nextPutAll: (self classExpressionFor: self sourceClassReference);
			nextPutAll: '.
	toClass := ';
			nextPutAll: (self classExpressionFor: self targetClassReference);
			nextPutAll: '.
	(fromClass isNil or: [ toClass isNil ]) ifTrue: [ 0 ] ifFalse: [
		instances := OrderedCollection new.
		';
			nextPutAll: (' . ' join: (oopCollection collect: [ :each |
				'instances add: (Object _objectForOop: ', each asInteger printString, ')' ]));
			nextPutAll: '.
		fromClass migrateInstances: instances asArray to: toClass.
		instances size ]' ]
]

{ #category : 'actions' }
GbsChunkedMigrationRunner >> prepareCheckpoint [
	^ session withCommitRetryCount: self maxCommitRetries do: [
		| oops |
		oops := session executeScriptAndFetchObject: self listInstanceOopsScript.
		oops ifNil: [ oops := #() ].
		self checkpointRoot at: self checkpointKey put: oops asArray.
		{
			#checkpointKey -> self checkpointKey.
			#remaining -> oops size.
			#committed -> true } asDictionary ]
]

{ #category : 'querying' }
GbsChunkedMigrationRunner >> remainingOops [
	^ self checkpointRoot at: self checkpointKey ifAbsent: [ #() ]
]

{ #category : 'actions' }
GbsChunkedMigrationRunner >> runNextChunk [
	| remaining batchCount batch migratedCount newRemaining |
	remaining := self remainingOops asOrderedCollection.
	remaining isEmpty ifTrue: [
		^ {
			#processed -> 0.
			#migrated -> 0.
			#remaining -> 0.
			#committed -> true } asDictionary ].
	^ session withCommitRetryCount: self maxCommitRetries do: [
		batchCount := self chunkSize min: remaining size.
		batch := (remaining copyFrom: 1 to: batchCount) asArray.
		migratedCount := session executeScriptAndFetchObject: (self migrateChunkScriptForOops: batch).
		newRemaining := remaining allButFirst: batchCount.
		newRemaining isEmpty
			ifTrue: [ self clearCheckpoint ]
			ifFalse: [ self checkpointRoot at: self checkpointKey put: newRemaining asArray ].
		{
			#processed -> batchCount.
			#migrated -> (migratedCount ifNil: [ 0 ]).
			#remaining -> newRemaining size.
			#committed -> true } asDictionary ]
]

{ #category : 'actions' }
GbsChunkedMigrationRunner >> runToCompletion [
	| results next |
	results := OrderedCollection new.
	[self hasCheckpoint not] whileTrue: [ self prepareCheckpoint ].
	[
		next := self runNextChunk.
		results add: next.
		((next at: #processed ifAbsent: [ 0 ]) = 0)
			or: [ (next at: #committed ifAbsent: [ true ]) = false ] ] whileFalse.
	^ results asArray
]

{ #category : 'actions' }
GbsChunkedMigrationRunner >> runToCompletionAndMarkApplied [
	| results |
	results := self runToCompletion.
	(self remainingOops isEmpty and: [ version notNil ]) ifTrue: [
		self markAppliedVersion ].
	^ results
]

{ #category : 'actions' }
GbsChunkedMigrationRunner >> markAppliedVersion [
	| versions |
	version ifNil: [ ^ self ].
	^ session withCommitRetryCount: self maxCommitRetries do: [
		versions := self appliedVersions asOrderedCollection.
		(versions includes: version) ifFalse: [ versions add: version ].
		self checkpointRoot at: self appliedVersionsKey put: versions asArray.
		versions asArray ]
]

{ #category : 'actions' }
GbsChunkedMigrationRunner >> unmarkAppliedVersion [
	| versions |
	version ifNil: [ ^ #() ].
	^ session withCommitRetryCount: self maxCommitRetries do: [
		versions := self appliedVersions asOrderedCollection.
		versions remove: version ifAbsent: [ ].
		self checkpointRoot at: self appliedVersionsKey put: versions asArray.
		versions asArray ]
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> maxCommitRetries [
	^ maxCommitRetries ifNil: [ 3 ]
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> maxCommitRetries: anInteger [
	maxCommitRetries := (anInteger ifNil: [ 3 ] ifNotNil: [ anInteger asInteger ]) max: 0
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> migrationName [
	^ migrationName ifNil: [ self sourceLabel , '->' , self targetLabel ]
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> migrationName: aString [
	migrationName := aString ifNil: [ nil ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> session [
	^ session
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> sourceClassReference [
	^ sourceClassReference
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> sourceClassReference: anObject [
	sourceClassReference := anObject
]

{ #category : 'querying' }
GbsChunkedMigrationRunner >> sourceLabel [
	^ sourceClassReference
		ifNil: [ '<nil>' ]
		ifNotNil: [ sourceClassReference asString ]
]

{ #category : 'printing' }
GbsChunkedMigrationRunner >> statusReportText [
	| remaining |
	remaining := self remainingOops.
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Chunked Migration Runner';
			cr; cr;
			nextPutAll: 'Source: ';
			nextPutAll: self sourceLabel;
			cr;
			nextPutAll: 'Target: ';
			nextPutAll: self targetLabel;
			cr;
			nextPutAll: 'Migration: ';
			nextPutAll: self migrationName;
			cr;
			nextPutAll: 'Version: ';
			nextPutAll: (version ifNil: [ '<none>' ] ifNotNil: [ version printString ]);
			cr;
			nextPutAll: 'Applied: ';
			nextPutAll: self hasAppliedVersion printString;
			cr;
			nextPutAll: 'Checkpoint: ';
			nextPutAll: self checkpointKey asString;
			cr;
			nextPutAll: 'Chunk Size: ';
			nextPutAll: self chunkSize printString;
			cr;
			nextPutAll: 'Remaining: ';
			nextPutAll: remaining size printString ]
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> targetClassReference [
	^ targetClassReference
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> targetClassReference: anObject [
	targetClassReference := anObject
]

{ #category : 'querying' }
GbsChunkedMigrationRunner >> targetLabel [
	^ targetClassReference
		ifNil: [ '<nil>' ]
		ifNotNil: [ targetClassReference asString ]
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> version [
	^ version
]

{ #category : 'accessing' }
GbsChunkedMigrationRunner >> version: anObject [
	version := anObject
]
