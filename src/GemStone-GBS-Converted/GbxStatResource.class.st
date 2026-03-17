Class {
	#name : 'GbxStatResource',
	#superclass : 'Object',
	#instVars : [
		'instanceId',
		'stats'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'printing' }
GbxStatResource >> printOn: aStream

	aStream
		nextPutAll: 'a ';
		nextPutAll: self class name;
		nextPut: $:.
	(self class organization listAtCategoryNamed: #'stat accessing') do: 
			[:selector |
			aStream
				cr;
				tab;
				nextPutAll: selector;
				nextPutAll: ': '.
			([self perform: selector] on: Error do: [:ex | 'got exception: ' , ex description]) printOn: aStream]

{ #category : 'archiving' }
GbxStatResource >> closedArchive

	stats do: [ :stat | stat closedArchive ]

{ #category : 'archiving' }
GbxStatResource >> instanceId: anInteger 
	instanceId := anInteger

{ #category : 'archiving' }
GbxStatResource >> instanceDescription

	^self subclassResponsibility

{ #category : 'archiving' }
GbxStatResource >> instanceId
	^instanceId

{ #category : 'archiving' }
GbxStatResource >> writeSampleTo: statArchive 
	"Iterate over each stat to write to archive file"
	stats do: [ :stat | stat writeSampleTo: statArchive ]

{ #category : 'initialize-release' }
GbxStatResource >> initializeStatistics

	"Subclasses should reimplement this method and call super initializeStatistics first"
	stats := OrderedCollection new

{ #category : 'initialize-release' }
GbxStatResource >> newGbxStatFor: statName value: initialValue

	"Return a new GbxStat for the given stat name"

	| desc stat |
	desc := self class statDescriptors detect: [ :sd | sd name = statName ].
	stat := GbxStat newWithDescription: desc value: initialValue.
	stats add: stat.
	^stat

{ #category : 'accessing' }
GbxStatResource class >> statDescriptors
	"An OrderedCollection of GbxStatDescriptor instances describing the stats held by
	 an instance of this stat resource class."
	^statDescriptors

{ #category : 'archiving' }
GbxStatResource class >> resourceTypeName
	^self subclassResponsibility

{ #category : 'archiving' }
GbxStatResource class >> resourceTypeDescription
	^self subclassResponsibility

{ #category : 'archiving' }
GbxStatResource class >> resourceTypeId
	^self subclassResponsibility

{ #category : 'archiving' }
GbxStatResource class >> writeDescriptorInformationOn: statArchiver 
	statDescriptors do: [:desc | desc writeToArchiver: statArchiver]

{ #category : 'archiving' }
GbxStatResource class >> numberOfDescriptors
	^statDescriptors size

{ #category : 'instance creation' }
GbxStatResource class >> new

	^super new initializeStatistics

{ #category : 'initialize-release' }
GbxStatResource class >> addStatDescriptor: aGbxStatDescriptor

	statDescriptors add: aGbxStatDescriptor.
	"Set the descriptor id to a zero-based index into the stat descriptor 
	collection for this class.  This is used when writing to the java-encoded
	archive."
	aGbxStatDescriptor setId: statDescriptors size - 1

