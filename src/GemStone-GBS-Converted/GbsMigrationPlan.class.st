Class {
	#name : 'GbsMigrationPlan',
	#superclass : 'Object',
	#instVars : [
		'entries',
		'sourceReference',
		'targetReference',
		'includesSubclasses'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsMigrationPlan class >> on: aSession rawEntries: rawEntries source: aSourceReference target: aTargetReference includesSubclasses: aBoolean [
	^ self new
		entries: (self entriesFromRaw: rawEntries session: aSession);
		sourceReference: aSourceReference;
		targetReference: aTargetReference;
		includesSubclasses: aBoolean;
		yourself
]

{ #category : 'private' }
GbsMigrationPlan class >> entriesFromRaw: rawEntries session: aSession [
	rawEntries ifNil: [ ^ #() ].
	^ rawEntries collect: [ :each |
		GbsMigrationPlanEntry
			sourceName: (each at: 2 ifAbsent: [ '' ])
			proxy: (aSession objectForOop: (each at: 1 ifAbsent: [ 20 ]))
			version: (each at: 3 ifAbsent: [ 0 ])
			numberOfVersions: (each at: 4 ifAbsent: [ 0 ])
			targetName: (each at: 6 ifAbsent: [ '' ])
			targetProxy: (aSession objectForOop: (each at: 5 ifAbsent: [ 20 ]))
			count: (each at: 7 ifAbsent: [ 0 ]) ]
]

{ #category : 'querying' }
GbsMigrationPlan >> affectedClassCount [
	^ self affectedEntries size
]

{ #category : 'querying' }
GbsMigrationPlan >> affectedEntries [
	^ self entries select: [ :each |
		each hasAffectedInstances ]
]

{ #category : 'querying' }
GbsMigrationPlan >> affectedEntriesByDescendingImpact [
	^ (self affectedEntries asSortedCollection: [ :left :right |
		left instanceCount = right instanceCount
			ifTrue: [ left sourceName <= right sourceName ]
			ifFalse: [ left instanceCount > right instanceCount ] ]) asArray
]

{ #category : 'accessing' }
GbsMigrationPlan >> entries [
	^ entries ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsMigrationPlan >> entries: aCollection [
	entries := aCollection ifNil: [ #() ]
]

{ #category : 'querying' }
GbsMigrationPlan >> hasAffectedInstances [
	^ self totalInstanceCount > 0
]

{ #category : 'accessing' }
GbsMigrationPlan >> includesSubclasses [
	^ includesSubclasses == true
]

{ #category : 'accessing' }
GbsMigrationPlan >> includesSubclasses: aBoolean [
	includesSubclasses := aBoolean == true
]

{ #category : 'querying' }
GbsMigrationPlan >> impactSummaryLines [
	^ self affectedEntriesByDescendingImpact collect: [ :each |
		String streamContents: [ :stream |
			stream
				nextPutAll: each sourceName.
			each targetName = each sourceName ifFalse: [
				stream
					nextPutAll: ' -> ';
					nextPutAll: each targetName ].
			stream
				nextPutAll: ' (';
				print: each instanceCount;
				nextPutAll: ' instances)' ] ]
]

{ #category : 'querying' }
GbsMigrationPlan >> impactSummaryString [
	^ String streamContents: [ :stream |
		stream
			print: self totalInstanceCount;
			nextPutAll: ' instances across ';
			print: self affectedClassCount;
			nextPutAll: ' classes'.
		self includesSubclasses ifTrue: [
			stream nextPutAll: ' including subclasses' ].
		self impactSummaryLines do: [ :each |
			stream
				cr;
				nextPutAll: each ] ]
]

{ #category : 'querying' }
GbsMigrationPlan >> isEmpty [
	^ self entries isEmpty
]

{ #category : 'printing' }
GbsMigrationPlan >> printOn: aStream [
	aStream
		nextPutAll: 'MigrationPlan(';
		print: self entries size;
		nextPutAll: ' entries, ';
		print: self totalInstanceCount;
		nextPutAll: ' instances)'
]

{ #category : 'accessing' }
GbsMigrationPlan >> sourceReference [
	^ sourceReference
]

{ #category : 'accessing' }
GbsMigrationPlan >> sourceReference: anObject [
	sourceReference := anObject
]

{ #category : 'querying' }
GbsMigrationPlan >> sourceNames [
	^ (self entries collect: [ :each | each sourceName ]) asSet asArray
]

{ #category : 'accessing' }
GbsMigrationPlan >> targetReference [
	^ targetReference
]

{ #category : 'accessing' }
GbsMigrationPlan >> targetReference: anObject [
	targetReference := anObject
]

{ #category : 'querying' }
GbsMigrationPlan >> targetNames [
	^ (self entries collect: [ :each | each targetName ]) asSet asArray
]

{ #category : 'querying' }
GbsMigrationPlan >> totalInstanceCount [
	^ self entries
		inject: 0
		into: [ :sum :each | sum + each instanceCount ]
]
