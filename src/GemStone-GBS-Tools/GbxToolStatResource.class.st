Class {
	#name : 'GbxToolStatResource',
	#superclass : 'Object',
	#instVars : [
		'name',
		'stats',
		'resourceType',
		'instanceId',
		'interval'
	],
	#classVars : [
		'statDescriptors'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'initialize-release' }
GbxToolStatResource class >> addStatDescriptor: aGbxStatDescriptor [
	statDescriptors ifNil: [ statDescriptors := OrderedCollection new ].
	statDescriptors add: aGbxStatDescriptor.
	aGbxStatDescriptor setId: statDescriptors size - 1
]

{ #category : 'instance creation' }
GbxToolStatResource class >> named: aString [
	^ self new
		name: aString;
		yourself
]

{ #category : 'instance creation' }
GbxToolStatResource class >> named: aString type: aSymbol [
	^ self new
		name: aString;
		resourceType: aSymbol;
		yourself
]

{ #category : 'instance creation' }
GbxToolStatResource class >> new [
	^ super new initializeStatistics
]

{ #category : 'initialize-release' }
GbxToolStatResource class >> newStatFor: statName [
	^ GbxToolStatDescriptor
		name: statName
		description: statName
		type: 5
		isCounter: true
		isLargerBetter: true
		unit: ''
]

{ #category : 'archiving' }
GbxToolStatResource class >> numberOfDescriptors [
	^ self statDescriptors size
]

{ #category : 'archiving' }
GbxToolStatResource class >> resourceTypeDescription [
	^ self name
]

{ #category : 'archiving' }
GbxToolStatResource class >> resourceTypeId [
	^ -1
]

{ #category : 'archiving' }
GbxToolStatResource class >> resourceTypeName [
	^ self name
]

{ #category : 'accessing' }
GbxToolStatResource class >> statDescriptors [
	^ statDescriptors ifNil: [ statDescriptors := OrderedCollection new ]
]

{ #category : 'archiving' }
GbxToolStatResource class >> writeDescriptorInformationOn: statArchiver [
	self statDescriptors do: [ :desc | desc writeToArchiver: statArchiver ]
]

{ #category : 'accessing' }
GbxToolStatResource >> addStat: aStat [
	| existing |
	existing := self statAt: aStat name.
	existing ifNotNil: [ stats remove: existing ifAbsent: [ ] ].
	stats add: aStat
]

{ #category : 'accessing' }
GbxToolStatResource >> addStatNamed: statName description: statDescription category: statCategory [
	| descriptor stat |
	descriptor := GbxToolStatDescriptor
		named: statName
		description: statDescription
		category: statCategory.
	stat := GbxToolStat newWithDescription: descriptor value: 0.
	self addStat: stat.
	^ stat
]

{ #category : 'archiving' }
GbxToolStatResource >> closedArchive [
	stats do: [ :stat |
		(stat respondsTo: #closedArchive) ifTrue: [ stat closedArchive ] ]
]

{ #category : 'accessing' }
GbxToolStatResource >> collectStats [
	"Collect statistics from the resource"
	self subclassResponsibility
]

{ #category : 'initialization' }
GbxToolStatResource >> initialize [
	super initialize.
	stats := OrderedCollection new.
]

{ #category : 'initialize-release' }
GbxToolStatResource >> initializeStatistics [
	self
		addStatDescriptor: (GbxStatDescriptor 
					name: 'bytesSentByStoreTraversal'
					description: 'The number of bytes sent cumulatively by store traversal calls'
					type: #int32
					isCounter: true
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'bytesTraversed'
					description: 'The cumulative number of bytes returned by traversal calls'
					type: #int32
					isCounter: true
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'changedObjNotifications'
					description: 'The number of changed object notifications received'
					type: #int32
					isCounter: true
					isLargerBetter: false
					unit: 'notifications');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'freeOopsFetched'
					description: 'The number of free oops fetched'
					type: #int32
					isCounter: true
					isLargerBetter: false
					unit: 'oops');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'gciCallsToGem'
					description: 'The number of gci calls made that communicate with the gem'
					type: #int32
					isCounter: true
					isLargerBetter: false
					unit: 'calls to gem');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'gciCallsToGemTime'
					description: 'The amount of time spent in gci calls that communicate with the gem'
					type: #long64
					isCounter: true
					isLargerBetter: false
					unit: 'microseconds');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'gciErrors'
					description: 'The number of errors reported by GciErr()'
					type: #int32
					isCounter: true
					isLargerBetter: false
					unit: 'errors');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'lostOtRoots'
					description: 'The number of lost OT roots'
					type: #int32
					isCounter: true
					isLargerBetter: false
					unit: 'roots');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'objectsStoredByTraversal'
					description: 'The number of objects stored by traversal'
					type: #int32
					isCounter: true
					isLargerBetter: false
					unit: 'objects');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'storeTraversals'
					description: 'The number of store traversal calls'
					type: #int32
					isCounter: true
					isLargerBetter: false
					unit: 'calls');
		addStatDescriptor: (GbxStatDescriptor 
					name: 'traverseCalls'
					description: 'The number of traversal calls'
					type: #int32
					isCounter: true
					isLargerBetter: false
					unit: 'calls').
	^ self
]

{ #category : 'archiving' }
GbxToolStatResource >> instanceDescription [
	^ self printString
]

{ #category : 'archiving' }
GbxToolStatResource >> instanceId [
	^ instanceId
]

{ #category : 'archiving' }
GbxToolStatResource >> instanceId: anInteger [
	instanceId := anInteger
]

{ #category : 'accessing' }
GbxToolStatResource >> interval [
	^ interval ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxToolStatResource >> interval: milliseconds [
	interval := milliseconds
]

{ #category : 'accessing' }
GbxToolStatResource >> name [
	^ name
]

{ #category : 'accessing' }
GbxToolStatResource >> name: aString [
	name := aString
]

{ #category : 'initialize-release' }
GbxToolStatResource >> newGbxStatFor: statName value: initialValue [
	| desc stat |
	desc := self class statDescriptors detect: [ :sd | sd name = statName ] ifNone: [ nil ].
	desc ifNil: [ ^ nil ].
	stat := GbxToolStat newWithDescription: desc value: initialValue.
	stats add: stat.
	^ stat
]

{ #category : 'printing' }
GbxToolStatResource >> printOn: aStream [
	aStream
		nextPutAll: 'a ';
		nextPutAll: self class name.
	name ifNotNil: [
		aStream
			nextPutAll: ' named: ';
			nextPutAll: name ]
]

{ #category : 'accessing' }
GbxToolStatResource >> printString [
	^ resourceType ifNil: [ name ] ifNotNil: [ name, ' (', resourceType asString, ')' ]
]

{ #category : 'accessing' }
GbxToolStatResource >> resourceType [
	^ resourceType
]

{ #category : 'accessing' }
GbxToolStatResource >> resourceType: aSymbol [
	resourceType := aSymbol
]

{ #category : 'accessing' }
GbxToolStatResource >> statAt: aString [
	^ stats detect: [ :each | each name = aString ] ifNone: [ nil ]
]

{ #category : 'accessing' }
GbxToolStatResource >> statAt: aString ifPresent: presentBlock [
	| stat |
	stat := self statAt: aString.
	stat ifNotNil: [ ^ presentBlock value: stat ].
	^ nil
]

{ #category : 'accessing' }
GbxToolStatResource >> statAt: aString ifPresent: presentBlock ifAbsent: absentBlock [
	| stat |
	stat := self statAt: aString.
	^ stat
		ifNil: [ absentBlock value ]
		ifNotNil: [ presentBlock value: stat ]
]

{ #category : 'accessing' }
GbxToolStatResource >> stats [
	^ stats
]

{ #category : 'accessing' }
GbxToolStatResource >> summary [
	"Return a summary string of all stats"
	| stream |
	
	stream := WriteStream on: String new.
	stream nextPutAll: name; cr.
	
	stats do: [ :stat |
		stream
			tab; nextPutAll: stat name; tab;
			nextPutAll: stat value asString; cr.
	].
	
	^ stream contents
]

{ #category : 'accessing' }
GbxToolStatResource >> updateStat: aString value: aValue [
	| stat |
	stat := self statAt: aString.
	stat ifNil: [
		stat := GbxToolStat named: aString.
		self addStat: stat ].
	(stat respondsTo: #setValue:)
		ifTrue: [ stat setValue: aValue ]
		ifFalse: [ stat value: aValue ]
]

{ #category : 'archiving' }
GbxToolStatResource >> writeSampleTo: statArchive [
	stats do: [ :stat |
		(stat respondsTo: #writeSampleTo:) ifTrue: [ stat writeSampleTo: statArchive ] ]
]
