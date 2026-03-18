Class {
	#name : 'GbxObjectMemoryStatResource',
	#superclass : 'GbxStatResource',
	#instVars : [
	],
	#classVars : [
		'singleton',
		'statDescriptors'
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'archiving' }
GbxObjectMemoryStatResource >> instanceDescription
[

	^'ObjectMemoryStats'
]

{ #category : 'archiving' }
GbxObjectMemoryStatResource >> writeSampleTo: statArchive
[
	"Iterate over each stat to write to archive file"

	| om |
	om := ObjectMemory current.
	stats do: [:stat | stat writeSampleFrom: om to: statArchive]
]

{ #category : 'initialize-release' }
GbxObjectMemoryStatResource >> newincGCStateStat
[
	"Return a new GbxStat for the given stat name"

	| desc |
	desc := self class statDescriptors detect: [:sd | sd name = 'incGCState'].
	^GbxIncGcStateStat newWithDescription: desc
]

{ #category : 'initialize-release' }
GbxObjectMemoryStatResource >> newStatFor: statName
[
	"Return a new GbxStat for the given stat name"

	| desc |
	desc := self class statDescriptors detect: [:sd | sd name = statName].
	^GbxObjectMemoryStat newWithDescription: desc
]

{ #category : 'initialize-release' }
GbxObjectMemoryStatResource >> initializeStatistics
[
	"Set the receiver's statistics to 0"

	super initializeStatistics.
	stats
		add: (self newStatFor: 'allocFailures');
		add: (self newStatFor: 'allocMatches');
		add: (self newStatFor: 'allocProbes');
		add: (self newStatFor: 'allocSplits');
		add: (self newStatFor: 'availableContiguousFixedSpace');
		add: (self newStatFor: 'availableContiguousOldSpace');
		add: (self newStatFor: 'availableContiguousSpace');
		add: (self newStatFor: 'availableFreeBytes');
		add: (self newStatFor: 'availableFreeEdenBytes');
		add: (self newStatFor: 'availableFreeFixedSpaceBytes');
		add: (self newStatFor: 'availableFreeLargeSpaceBytes');
		add: (self newStatFor: 'availableFreeOldSpaceBytes');
		add: (self newStatFor: 'availableFreeOldSpaceBytesLimit');
		add: (self newStatFor: 'compCodeCacheBytes');
		add: (self newStatFor: 'contiguousFreeOldBytes');
		add: (self newStatFor: 'dynamicallyAllocatedFootprint');
		add: (self newStatFor: 'edenBytes');
		add: (self newStatFor: 'edenUsedBytes');
		add: (self newStatFor: 'edenUsedBytesScavengeThreshold');
		add: (self newStatFor: 'enumerationCallsPerMillisecond');
		add: (self newStatFor: 'fixedBytes');
		add: (self newStatFor: 'fixedSegments');
		add: (self newStatFor: 'fixedUsedBytes');
		add: (self newStatFor: 'fixedUsedObjects');
		add: (self newStatFor: 'freePermBytes');
		add: (self newStatFor: 'incAbortedCount');
		add: self newincGCStateStat;
		add: (self newStatFor: 'incMarkedBytes');
		add: (self newStatFor: 'incMarkedObjects');
		add: (self newStatFor: 'incMarkedWeakBytes');
		add: (self newStatFor: 'incMarkedWeakObjects');
		add: (self newStatFor: 'incMarkStackOverflows');
		add: (self newStatFor: 'incNilledBytes');
		add: (self newStatFor: 'incNilledObjects');
		add: (self newStatFor: 'incReclaimedBytes');
		add: (self newStatFor: 'incReclaimedObjects');
		add: (self newStatFor: 'incSweepAllocatedBytes');
		add: (self newStatFor: 'incSweepAllocatedObjects');
		add: (self newStatFor: 'incSweptObjects');
		add: (self newStatFor: 'incUnmarkedObjects');
		add: (self newStatFor: 'largeBytes');
		add: (self newStatFor: 'largeFreeBytesTenuringThreshold');
		add: (self newStatFor: 'largeUsedBytes');
		add: (self newStatFor: 'largeUsedObjects');
		add: (self newStatFor: 'maximalFreeOldBytes');
		add: (self newStatFor: 'nativeStackSpills');
		add: (self newStatFor: 'newBytesAvailableForStorage');
		add: (self newStatFor: 'numCompactNMethods');
		add: (self newStatFor: 'numDataCompactions');
		add: (self newStatFor: 'numGCs');
		add: (self newStatFor: 'numGlobalGCs');
		add: (self newStatFor: 'numIncGCs');
		add: (self newStatFor: 'numMarkStackOverflows');
		add: (self newStatFor: 'numScavenges');
		add: (self newStatFor: 'numWeakObjectListOverflows');
		add: (self newStatFor: 'oldBytes');
		add: (self newStatFor: 'oldDataBytes');
		add: (self newStatFor: 'oldRtBytes');
		add: (self newStatFor: 'oldRtEntries');
		add: (self newStatFor: 'oldRtUsedEntries');
		add: (self newStatFor: 'oldSegments');
		add: (self newStatFor: 'oopsLeft');
		add: (self newStatFor: 'permBytes');
		add: (self newStatFor: 'permDataBytes');
		add: (self newStatFor: 'permOTEs');
		add: (self newStatFor: 'reservedContiguousFreeBytes');
		add: (self newStatFor: 'rtBytes');
		add: (self newStatFor: 'rtEntries');
		add: (self newStatFor: 'rtUsedEntries');
		add: (self newStatFor: 'stackBytes');
		add: (self newStatFor: 'survBytes');
		add: (self newStatFor: 'survUsedBytes');
		add: (self newStatFor: 'survUsedBytesTenuringThreshold');
		add: (self newStatFor: 'threadedDataBytes');
		add: (self newStatFor: 'threadedDataEntries');
		add: (self newStatFor: 'threadedOTEntries')
]

{ #category : 'class initialization' }
GbxObjectMemoryStatResource class >> initialize
[
	"Create GbxStatDescriptors for this stat resource"
	"self initialize"

	singleton := nil.
	statDescriptors := OrderedCollection new.
	self
		addStatDescriptor: (self newStatFor: 'allocFailures');
		addStatDescriptor: (self newStatFor: 'allocMatches');
		addStatDescriptor: (self newStatFor: 'allocProbes');
		addStatDescriptor: (self newStatFor: 'allocSplits');
		addStatDescriptor: (self newStatFor: 'availableContiguousFixedSpace');
		addStatDescriptor: (self newStatFor: 'availableContiguousOldSpace');
		addStatDescriptor: (self newStatFor: 'availableContiguousSpace');
		addStatDescriptor: (self newStatFor: 'availableFreeBytes');
		addStatDescriptor: (self newStatFor: 'availableFreeEdenBytes');
		addStatDescriptor: (self newStatFor: 'availableFreeFixedSpaceBytes');
		addStatDescriptor: (self newStatFor: 'availableFreeLargeSpaceBytes');
		addStatDescriptor: (self newStatFor: 'availableFreeOldSpaceBytes');
		addStatDescriptor: (self newStatFor: 'availableFreeOldSpaceBytesLimit');
		addStatDescriptor: (self newStatFor: 'compCodeCacheBytes');
		addStatDescriptor: (self newStatFor: 'contiguousFreeOldBytes');
		addStatDescriptor: (self newStatFor: 'dynamicallyAllocatedFootprint');
		addStatDescriptor: (self newStatFor: 'edenBytes');
		addStatDescriptor: (self newStatFor: 'edenUsedBytes');
		addStatDescriptor: (self newStatFor: 'edenUsedBytesScavengeThreshold');
		addStatDescriptor: (self newStatFor: 'enumerationCallsPerMillisecond');
		addStatDescriptor: (self newStatFor: 'fixedBytes');
		addStatDescriptor: (self newStatFor: 'fixedSegments');
		addStatDescriptor: (self newStatFor: 'fixedUsedBytes');
		addStatDescriptor: (self newStatFor: 'fixedUsedObjects');
		addStatDescriptor: (self newStatFor: 'freePermBytes');
		addStatDescriptor: (self newStatFor: 'incAbortedCount');
		addStatDescriptor: (self newStatFor: 'incMarkedBytes');
		addStatDescriptor: (self newStatFor: 'incMarkedObjects');
		addStatDescriptor: (self newStatFor: 'incMarkedWeakBytes');
		addStatDescriptor: (self newStatFor: 'incMarkedWeakObjects');
		addStatDescriptor: (self newStatFor: 'incMarkStackOverflows');
		addStatDescriptor: (self newStatFor: 'incNilledBytes');
		addStatDescriptor: (self newStatFor: 'incNilledObjects');
		addStatDescriptor: (self newStatFor: 'incReclaimedBytes');
		addStatDescriptor: (self newStatFor: 'incReclaimedObjects');
		addStatDescriptor: (self newStatFor: 'incSweepAllocatedBytes');
		addStatDescriptor: (self newStatFor: 'incSweepAllocatedObjects');
		addStatDescriptor: (self newStatFor: 'incSweptObjects');
		addStatDescriptor: (self newStatFor: 'incUnmarkedObjects');
		addStatDescriptor: (self newStatFor: 'largeBytes');
		addStatDescriptor: (self newStatFor: 'largeFreeBytesTenuringThreshold');
		addStatDescriptor: (self newStatFor: 'largeUsedBytes');
		addStatDescriptor: (self newStatFor: 'largeUsedObjects');
		addStatDescriptor: (self newStatFor: 'maximalFreeOldBytes');
		addStatDescriptor: (self newStatFor: 'nativeStackSpills');
		addStatDescriptor: (self newStatFor: 'newBytesAvailableForStorage');
		addStatDescriptor: (self newStatFor: 'numCompactNMethods');
		addStatDescriptor: (self newStatFor: 'numDataCompactions');
		addStatDescriptor: (self newStatFor: 'numGCs');
		addStatDescriptor: (self newStatFor: 'numGlobalGCs');
		addStatDescriptor: (self newStatFor: 'numIncGCs');
		addStatDescriptor: (self newStatFor: 'numMarkStackOverflows');
		addStatDescriptor: (self newStatFor: 'numScavenges');
		addStatDescriptor: (self newStatFor: 'numWeakObjectListOverflows');
		addStatDescriptor: (self newStatFor: 'oldBytes');
		addStatDescriptor: (self newStatFor: 'oldDataBytes');
		addStatDescriptor: (self newStatFor: 'oldRtBytes');
		addStatDescriptor: (self newStatFor: 'oldRtEntries');
		addStatDescriptor: (self newStatFor: 'oldRtUsedEntries');
		addStatDescriptor: (self newStatFor: 'oldSegments');
		addStatDescriptor: (self newStatFor: 'oopsLeft');
		addStatDescriptor: (self newStatFor: 'permBytes');
		addStatDescriptor: (self newStatFor: 'permDataBytes');
		addStatDescriptor: (self newStatFor: 'permOTEs');
		addStatDescriptor: (self newStatFor: 'reservedContiguousFreeBytes');
		addStatDescriptor: (self newStatFor: 'rtBytes');
		addStatDescriptor: (self newStatFor: 'rtEntries');
		addStatDescriptor: (self newStatFor: 'rtUsedEntries');
		addStatDescriptor: (self newStatFor: 'stackBytes');
		addStatDescriptor: (self newStatFor: 'survBytes');
		addStatDescriptor: (self newStatFor: 'survUsedBytes');
		addStatDescriptor: (self newStatFor: 'survUsedBytesTenuringThreshold');
		addStatDescriptor: (self newStatFor: 'threadedDataBytes');
		addStatDescriptor: (self newStatFor: 'threadedDataEntries');
		addStatDescriptor: (self newStatFor: 'threadedOTEntries')
]

{ #category : 'accessing' }
GbxObjectMemoryStatResource class >> singleton
[

	singleton == nil ifTrue: [singleton := self basicNew initializeStatistics].
	^singleton
]

{ #category : 'archiving' }
GbxObjectMemoryStatResource class >> resourceTypeName
[
	^'ObjectMemory'
]

{ #category : 'archiving' }
GbxObjectMemoryStatResource class >> resourceTypeDescription
[
	^'Statistics associated with VW''s memory and garbage collection'
]

{ #category : 'archiving' }
GbxObjectMemoryStatResource class >> resourceTypeId
[
	^3
]

