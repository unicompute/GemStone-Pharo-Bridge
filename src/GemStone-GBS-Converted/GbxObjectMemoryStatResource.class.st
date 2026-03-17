Class {
	#name : 'GbxObjectMemoryStatResource',
	#superclass : 'GbxStatResource',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'archiving' }
GbxObjectMemoryStatResource >> instanceDescription

	^'ObjectMemoryStats'

{ #category : 'archiving' }
GbxObjectMemoryStatResource >> writeSampleTo: statArchive
	"Iterate over each stat to write to archive file"

	| om |
	om := ObjectMemory current.
	stats do: [:stat | stat writeSampleFrom: om to: statArchive]

{ #category : 'initialize-release' }
GbxObjectMemoryStatResource >> newincGCStateStat
	"Return a new GbxStat for the given stat name"

	| desc |
	desc := self class statDescriptors detect: [:sd | sd name = 'incGCState'].
	^GbxIncGcStateStat newWithDescription: desc

{ #category : 'initialize-release' }
GbxObjectMemoryStatResource >> newStatFor: statName
	"Return a new GbxStat for the given stat name"

	| desc |
	desc := self class statDescriptors detect: [:sd | sd name = statName].
	^GbxObjectMemoryStat newWithDescription: desc

{ #category : 'initialize-release' }
GbxObjectMemoryStatResource >> initializeStatistics
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

{ #category : 'class initialization' }
GbxObjectMemoryStatResource class >> initialize
	"Create GbxStatDescriptors for this stat resource"
	"self initialize"

	singleton := nil.
	statDescriptors := OrderedCollection new.
	self
		addStatDescriptor: (GbxStatDescriptor
					name: 'allocFailures'
					description: 'The number of OldSpace allocations that failed to find a sufficiently large data chunk on the threaded free list; hence the allocation was probably satisfied by eating into the contiguous free space between the OT and the data heap.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'allocations');
		addStatDescriptor: (GbxStatDescriptor
					name: 'allocMatches'
					description: 'The number of OldSpace allocations that succeeded with an exact match.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: true
					unit: 'allocations');
		addStatDescriptor: (GbxStatDescriptor
					name: 'allocProbes'
					description: 'The number of threaded data chunks examined by OldSpace allocations.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'chunks');
		addStatDescriptor: (GbxStatDescriptor
					name: 'allocSplits'
					description: 'The number of OldSpace allocations that succeeded by splitting a data chunk on the free list.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'allocations');
		addStatDescriptor: (GbxStatDescriptor
					name: 'availableContiguousFixedSpace'
					description: 'The size (in bytes) of the largest chunk of contiguous free space in FixedSpace'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: true
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'availableContiguousOldSpace'
					description: 'The size (in bytes) of the largest chunk of contiguous free space in OldSpace after subtracting off the space reserved for use by the virtual machine. This figure does not include the free space on the threaded free lists. Contiguous space is consumed when an object will not fit in an entry on the threaded free lists.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: true
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'availableContiguousSpace'
					description: 'The size (in bytes) of the largest chunk of contiguous free space in old and fixed space after subtracting off the space reserved for use by the virtual machine. This figure does not include the free space on the threaded free lists. Contiguous space is consumed when an object will not fit in an entry on the threaded free lists.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: true
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'availableFreeBytes'
					description: 'The number of free memory bytes available in the heap.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: true
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'availableFreeEdenBytes'
					description: 'The number of free memory bytes available in eden.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: true
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'availableFreeFixedSpaceBytes'
					description: 'The number of free FixedSpace bytes available for use (i.e., threadedDataBytes + contiguousFreeBytes.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: true
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'availableFreeLargeSpaceBytes'
					description: 'The number of free LargeSpace bytes available for use (i.e., threadedDataBytes + contiguousFreeBytes.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: true
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'availableFreeOldSpaceBytes'
					description: 'The number of free OldSpace bytes available for use (i.e., threadedDataBytes + contiguousFreeBytes - reservedContiguousFreeBytes.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: true
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'availableFreeOldSpaceBytesLimit'
					description: 'The LowSpaceSemaphore is signalled by the virtual machine when the availableFreeOldSpaceBytes drops below this limit.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'compCodeCacheBytes'
					description: 'The size of the compiledCodeCache in bytes.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'contiguousFreeOldBytes'
					description: 'The total number of contiguous free bytes in OldSpace. This figure does not include any space on the threaded free lists. Some of this space is reserved for use by the virtual machine.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: true
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'dynamicallyAllocatedFootprint'
					description: 'The total size (in bytes) of the dynamically allocated footprint.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'edenBytes'
					description: 'The size of Eden in bytes.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'edenUsedBytes'
					description: 'The number of used bytes in Eden.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'edenUsedBytesScavengeThreshold'
					description: 'The scavenger will be invoked when edenUsedBytes exceeds this threshold.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'enumerationCallsPerMillisecond'
					description: 'How many objects per millisecond were processed in the most recent invocation of allInstancesWeakly:. This can be used to estimate the system''s object scanning performance for tasks like incremental marking.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'objects/ms');
		addStatDescriptor: (GbxStatDescriptor
					name: 'fixedBytes'
					description: 'The size of FixedSpace in bytes.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'fixedSegments'
					description: 'The number of FixedSpace segments.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'segments');
		addStatDescriptor: (GbxStatDescriptor
					name: 'fixedUsedBytes'
					description: 'The usage of FixedSpace in bytes.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'fixedUsedObjects'
					description: 'The usage of FixedSpace in objects.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'objects');
		addStatDescriptor: (GbxStatDescriptor
					name: 'freePermBytes'
					description: 'The number of free PermSpace bytes.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: true
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incAbortedCount'
					description: 'The number of times the incremental GC aborted its mark phase.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'aborts');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incGCState'
					description: 'The current state of the incremental garbage collector. 0 = resting, 1 = marking, 2 = aborting, 3 = sweeping.'
					type: GemStone.Gbs.GbxStatArchiver.TypeByte8
					isCounter: false
					isLargerBetter: false
					unit: 'enumeration');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incMarkedBytes'
					description: 'The total bytes of data in the marked objects.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incMarkedObjects'
					description: 'The number of objects currently marked.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'objects');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incMarkedWeakBytes'
					description: 'The total bytes of data in the marked objects that are weak.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incMarkedWeakObjects'
					description: 'The number of marked objects that are weak.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incMarkStackOverflows'
					description: 'The number of times the incremental GC''s mark stack overflowed.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'overflows');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incNilledBytes'
					description: 'The number of bytes in the weak objects examined so far.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incNilledObjects'
					description: 'The number of weak objects examined so far (to see if they contain dead references that need nilling out).'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'objects');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incReclaimedBytes'
					description: 'The bytes of data reclaimed so far in this collection.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incReclaimedObjects'
					description: 'The number of objects reclaimed so far in this collection.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'objects');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incSweepAllocatedBytes'
					description: 'The bytes of data in the OldSpace objects allocated since the start of the incremental sweep phase.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incSweepAllocatedObjects'
					description: 'The number of OldSpace objects allocated since the start of the incremental sweep phase.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'objects');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incSweptObjects'
					description: 'The number of objects swept so far in this collection.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'objects');
		addStatDescriptor: (GbxStatDescriptor
					name: 'incUnmarkedObjects'
					description: 'The number of objects unmarked since aborting the incremental GC.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'objects');
		addStatDescriptor: (GbxStatDescriptor
					name: 'largeBytes'
					description: 'The size of LargeSpace in bytes.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'largeFreeBytesTenuringThreshold'
					description: 'The scavenger will tenure LargeSpace objects when the free bytes in LargeSpace drops below this threshold.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'largeUsedBytes'
					description: 'The the number of used bytes in LargeSpace.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'largeUsedObjects'
					description: 'The number of objects housed in LargeSpace.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'objects');
		addStatDescriptor: (GbxStatDescriptor
					name: 'maximalFreeOldBytes'
					description: 'The size in bytes of the largest chunk of contiguous free bytes in OldSpace.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'nativeStackSpills'
					description: 'The number of times the native stack was not large enough to hold all the internal representation of Smalltalk process frames, thus forcing a spill of context objects into new space.  This number is also incremented every time a new Smalltalk process is forked. Excessively high values should be taken as a hint to either increase the native stack space size via ObjectMemory class>>sizesAtStartup:, or to adopt an implementation strategy that forks Smalltalk processes less often.  See also ObjectMemory class>>sizesAtStartup for more information.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'spills');
		addStatDescriptor: (GbxStatDescriptor
					name: 'newBytesAvailableForStorage'
					description: 'The number of bytes that can be used to house objects in new space.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'numCompactNMethods'
					description: 'The number of times the compiled code cache was compacted due to lack of space.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'compactions');
		addStatDescriptor: (GbxStatDescriptor
					name: 'numDataCompactions'
					description: 'The number of OldSpace data compactions that have been performed since the start of the VM.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'compactions');
		addStatDescriptor: (GbxStatDescriptor
					name: 'numGCs'
					description: 'The number of compacting GCs that have been performed since the start of the VM.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'GCs');
		addStatDescriptor: (GbxStatDescriptor
					name: 'numGlobalGCs'
					description: 'The number of global GCs that have been performed since the start of the VM.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'GCs');
		addStatDescriptor: (GbxStatDescriptor
					name: 'numIncGCs'
					description: 'The number of incremental GCs that have been performed since the start of the VM.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'GCs');
		addStatDescriptor: (GbxStatDescriptor
					name: 'numMarkStackOverflows'
					description: 'The number of times the GC mark stack overflowed.  This should be avoided because it makes GC considerably slower.  To address this issue, increase the size of new space (eden + survivor).'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'overflows');
		addStatDescriptor: (GbxStatDescriptor
					name: 'numScavenges'
					description: 'The number of new space scavenges that VW has performed since the launch of the VM'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'scavenges');
		addStatDescriptor: (GbxStatDescriptor
					name: 'numWeakObjectListOverflows'
					description: 'The number of times the weak object list overflowed during GC. This should be avoided because then not all weak objects are processed in a single GC. To address this issue, increase the size of compiled code cache space.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: true
					isLargerBetter: false
					unit: 'overflows');
		addStatDescriptor: (GbxStatDescriptor
					name: 'oldBytes'
					description: 'The size of OldSpace in bytes."'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'oldDataBytes'
					description: 'The total data bytes in OldSpace, including the threaded free data.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'oldRtBytes'
					description: 'The size of the old remembered table in bytes.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'oldRtEntries'
					description: 'The size of the old remembered table in terms of the total number of entries.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'RtEntries');
		addStatDescriptor: (GbxStatDescriptor
					name: 'oldRtUsedEntries'
					description: 'The number of actual entries in the old remembered table.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'RtEntries');
		addStatDescriptor: (GbxStatDescriptor
					name: 'oldSegments'
					description: 'The number of OldSpace segments.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'segments');
		addStatDescriptor: (GbxStatDescriptor
					name: 'oopsLeft'
					description: 'Estimate of the number of additional objects that can be housed in object memory.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'objects');
		addStatDescriptor: (GbxStatDescriptor
					name: 'permBytes'
					description: 'The size of PermSpace in bytes.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'permDataBytes'
					description: 'The total data bytes in PermSpace.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'permOTEs'
					description: 'The number of entries in the PermSpace OT'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'entries');
		addStatDescriptor: (GbxStatDescriptor
					name: 'reservedContiguousFreeBytes'
					description: 'The bytes of contiguous free space reserved for use by the virtual machine.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'rtBytes'
					description: 'The size of the remembered table in bytes'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'rtEntries'
					description: 'The size of the remembered table in terms of the total number of entries.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'entries');
		addStatDescriptor: (GbxStatDescriptor
					name: 'rtUsedEntries'
					description: 'The number of actual entries in the remembered table.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'entries');
		addStatDescriptor: (GbxStatDescriptor
					name: 'stackBytes'
					description: 'The size of StackSpace in bytes.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'survBytes'
					description: 'The size of a single SurvivorSpace in bytes.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'survUsedBytes'
					description: 'The number of used bytes in the occupied SurvivorSpace.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'survUsedBytesTenuringThreshold'
					description: 'The scavenger will start to tenure objects when survUsedBytes exceeds this threshold.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'threadedDataBytes'
					description: 'The number of bytes of data in OldSpace''s free list.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'bytes');
		addStatDescriptor: (GbxStatDescriptor
					name: 'threadedDataEntries'
					description: 'The number of data chunks in OldSpace''s free list.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'chunks');
		addStatDescriptor: (GbxStatDescriptor
					name: 'threadedOTEntries'
					description: 'The number of OTEs in OldSpace''s free list.'
					type: GemStone.Gbs.GbxStatArchiver.TypeInt32
					isCounter: false
					isLargerBetter: false
					unit: 'entries')

{ #category : 'accessing' }
GbxObjectMemoryStatResource class >> singleton

	singleton == nil ifTrue: [singleton := self basicNew initializeStatistics].
	^singleton

{ #category : 'archiving' }
GbxObjectMemoryStatResource class >> resourceTypeName
	^'ObjectMemory'

{ #category : 'archiving' }
GbxObjectMemoryStatResource class >> resourceTypeDescription
	^'Statistics associated with VW''s memory and garbage collection'

{ #category : 'archiving' }
GbxObjectMemoryStatResource class >> resourceTypeId
	^3

