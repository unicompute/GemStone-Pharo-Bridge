Class {
	#name : 'GbxStatResource',
	#superclass : 'Object',
	#instVars : [
		'name',
		'stats',
		'resourceType',
		'instanceId'
	],
	#classVars : [
		'statDescriptors'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'initialize-release' }
GbxStatResource class >> addStatDescriptor: aGbxStatDescriptor [
	statDescriptors ifNil: [ statDescriptors := OrderedCollection new ].
	statDescriptors add: aGbxStatDescriptor.
	aGbxStatDescriptor setId: statDescriptors size - 1
]

{ #category : 'instance creation' }
GbxStatResource class >> named: aString [
	^ self new
		name: aString;
		yourself
]

{ #category : 'instance creation' }
GbxStatResource class >> named: aString type: aSymbol [
	^ self new
		name: aString;
		resourceType: aSymbol;
		yourself
]

{ #category : 'instance creation' }
GbxStatResource class >> new [
	^ super new initializeStatistics
]

{ #category : 'initialize-release' }
GbxStatResource class >> newStatFor: statName [
	^ GbxStatDescriptor
		name: statName
		description: statName
		type: 5
		isCounter: true
		isLargerBetter: true
		unit: ''
]

{ #category : 'archiving' }
GbxStatResource class >> numberOfDescriptors [
	^ self statDescriptors size
]

{ #category : 'archiving' }
GbxStatResource class >> resourceTypeDescription [
	^ self name
]

{ #category : 'archiving' }
GbxStatResource class >> resourceTypeId [
	^ -1
]

{ #category : 'archiving' }
GbxStatResource class >> resourceTypeName [
	^ self name
]

{ #category : 'accessing' }
GbxStatResource class >> statDescriptors [
	^ statDescriptors ifNil: [ statDescriptors := OrderedCollection new ]
]

{ #category : 'archiving' }
GbxStatResource class >> writeDescriptorInformationOn: statArchiver [
	self statDescriptors do: [ :desc | desc writeToArchiver: statArchiver ]
]

{ #category : 'initialization' }
GbxStatResource >> initialize [
	super initialize.
	stats := OrderedCollection new.
]

{ #category : 'accessing' }
GbxStatResource >> addStat: aStat [
	| existing |
	existing := self statAt: aStat name.
	existing ifNotNil: [ stats remove: existing ifAbsent: [ ] ].
	stats add: aStat
]

{ #category : 'archiving' }
GbxStatResource >> closedArchive [
	stats do: [ :stat |
		(stat respondsTo: #closedArchive) ifTrue: [ stat closedArchive ] ]
]

{ #category : 'accessing' }
GbxStatResource >> collectStats [
	"Collect statistics from the resource"
	self subclassResponsibility
]

{ #category : 'initialize-release' }
GbxStatResource >> initializeStatistics [
	^ self
]

{ #category : 'archiving' }
GbxStatResource >> instanceDescription [
	^ self printString
]

{ #category : 'archiving' }
GbxStatResource >> instanceId [
	^ instanceId
]

{ #category : 'archiving' }
GbxStatResource >> instanceId: anInteger [
	instanceId := anInteger
]

{ #category : 'accessing' }
GbxStatResource >> name [
	^ name
]

{ #category : 'accessing' }
GbxStatResource >> name: aString [
	name := aString
]

{ #category : 'initialize-release' }
GbxStatResource >> newGbxStatFor: statName value: initialValue [
	| desc stat |
	desc := self class statDescriptors detect: [ :sd | sd name = statName ] ifNone: [ nil ].
	desc ifNil: [ ^ nil ].
	stat := GbxStat newWithDescription: desc value: initialValue.
	stats add: stat.
	^ stat
]

{ #category : 'printing' }
GbxStatResource >> printOn: aStream [
	aStream
		nextPutAll: 'a ';
		nextPutAll: self class name.
	name ifNotNil: [
		aStream
			nextPutAll: ' named: ';
			nextPutAll: name ]
]

{ #category : 'accessing' }
GbxStatResource >> printString [
	^ resourceType ifNil: [ name ] ifNotNil: [ name, ' (', resourceType asString, ')' ]
]

{ #category : 'accessing' }
GbxStatResource >> resourceType [
	^ resourceType
]

{ #category : 'accessing' }
GbxStatResource >> resourceType: aSymbol [
	resourceType := aSymbol
]

{ #category : 'accessing' }
GbxStatResource >> statAt: aString [
	^ stats detect: [ :each | each name = aString ] ifNone: [ nil ]
]

{ #category : 'accessing' }
GbxStatResource >> statAt: aString ifPresent: presentBlock [
	| stat |
	stat := self statAt: aString.
	stat ifNotNil: [ ^ presentBlock value: stat ].
	^ nil
]

{ #category : 'accessing' }
GbxStatResource >> statAt: aString ifPresent: presentBlock ifAbsent: absentBlock [
	| stat |
	stat := self statAt: aString.
	^ stat
		ifNil: [ absentBlock value ]
		ifNotNil: [ presentBlock value: stat ]
]

{ #category : 'accessing' }
GbxStatResource >> stats [
	^ stats
]

{ #category : 'accessing' }
GbxStatResource >> summary [
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
GbxStatResource >> updateStat: aString value: aValue [
	| stat |
	stat := self statAt: aString.
	stat ifNil: [
		stat := GbxStat named: aString.
		self addStat: stat ].
	(stat respondsTo: #setValue:)
		ifTrue: [ stat setValue: aValue ]
		ifFalse: [ stat value: aValue ]
]

{ #category : 'archiving' }
GbxStatResource >> writeSampleTo: statArchive [
	stats do: [ :stat |
		(stat respondsTo: #writeSampleTo:) ifTrue: [ stat writeSampleTo: statArchive ] ]
]
