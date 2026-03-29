Class {
	#name : 'GbxObjectMemoryStatResource',
	#superclass : 'GbxStatResource',
	#classInstVars : [
		'singleton'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'class initialization' }
GbxObjectMemoryStatResource class >> initialize [
	singleton := nil.
	statDescriptors := OrderedCollection new.
	self statNames do: [ :name |
		self addStatDescriptor: (GbxStatDescriptor
			name: name
			description: name
			type: (name = 'incGCState'
				ifTrue: [ GbxStatArchiver TypeByte8 ]
				ifFalse: [ GbxStatArchiver TypeInt32 ])
			isCounter: (self counterStatNames includes: name)
			isLargerBetter: false
			unit: '') ]
]

{ #category : 'class initialization' }
GbxObjectMemoryStatResource class >> counterStatNames [
	^ #(
		allocFailures allocMatches allocProbes allocSplits
		incAbortedCount incMarkStackOverflows nativeStackSpills
		numCompactNMethods numDataCompactions numGCs numGlobalGCs
		numIncGCs numMarkStackOverflows numScavenges
		numWeakObjectListOverflows
	)
]

{ #category : 'archiving' }
GbxObjectMemoryStatResource class >> resourceTypeId [
	^ 3
]

{ #category : 'archiving' }
GbxObjectMemoryStatResource class >> resourceTypeName [
	^ 'ObjectMemory'
]

{ #category : 'accessing' }
GbxObjectMemoryStatResource class >> singleton [
	^ singleton ifNil: [ singleton := self new ]
]

{ #category : 'class initialization' }
GbxObjectMemoryStatResource class >> statNames [
	^ #(
		allocFailures allocMatches allocProbes allocSplits
		availableContiguousFixedSpace availableContiguousOldSpace availableContiguousSpace
		availableFreeBytes availableFreeEdenBytes availableFreeFixedSpaceBytes
		availableFreeLargeSpaceBytes availableFreeOldSpaceBytes availableFreeOldSpaceBytesLimit
		compCodeCacheBytes contiguousFreeOldBytes dynamicallyAllocatedFootprint
		edenBytes edenUsedBytes edenUsedBytesScavengeThreshold
		enumerationCallsPerMillisecond fixedBytes fixedSegments fixedUsedBytes fixedUsedObjects
		freePermBytes incAbortedCount incGCState incMarkedBytes incMarkedObjects
		incMarkedWeakBytes incMarkedWeakObjects incMarkStackOverflows incNilledBytes
		incNilledObjects incReclaimedBytes incReclaimedObjects incSweepAllocatedBytes
		incSweepAllocatedObjects incSweptObjects incUnmarkedObjects largeBytes
		largeFreeBytesTenuringThreshold largeUsedBytes largeUsedObjects maximalFreeOldBytes
		nativeStackSpills newBytesAvailableForStorage numCompactNMethods
		numDataCompactions numGCs numGlobalGCs numIncGCs numMarkStackOverflows
		numScavenges numWeakObjectListOverflows oldBytes oldDataBytes oldRtBytes
		oldRtEntries oldRtUsedEntries oldSegments oopsLeft permBytes permDataBytes
		permOTEs reservedContiguousFreeBytes rtBytes rtEntries rtUsedEntries stackBytes
		survBytes survUsedBytes survUsedBytesTenuringThreshold threadedDataBytes
		threadedDataEntries threadedOTEntries
	)
]

{ #category : 'initialize-release' }
GbxObjectMemoryStatResource >> initializeStatistics [
	| specialDescriptor |

	super initializeStatistics.
	specialDescriptor := self lookupDescriptorNamed: 'incGCState'.
	self class statDescriptors do: [ :descriptor |
		stats add: (descriptor == specialDescriptor
			ifTrue: [ self newincGCStateStat ]
			ifFalse: [ self newStatFor: descriptor name ]) ]
]

{ #category : 'archiving' }
GbxObjectMemoryStatResource >> instanceDescription [
	^ 'ObjectMemoryStats'
]

{ #category : 'initialize-release' }
GbxObjectMemoryStatResource >> newincGCStateStat [
	| desc |

	desc := self lookupDescriptorNamed: 'incGCState'.
	^ GbxIncGcStateStat newWithDescription: desc
]

{ #category : 'initialize-release' }
GbxObjectMemoryStatResource >> newStatFor: statName [
	| desc |

	desc := self lookupDescriptorNamed: statName.
	desc ifNil: [ ^ nil ].
	^ GbxObjectMemoryStat newWithDescription: desc
]

{ #category : 'archiving' }
GbxObjectMemoryStatResource >> writeSampleTo: statArchive [
	| objectMemoryClass objectMemory |

	objectMemoryClass := Smalltalk globals at: #ObjectMemory ifAbsent: [ nil ].
	objectMemory := (objectMemoryClass notNil and: [ objectMemoryClass respondsTo: #current ])
		ifTrue: [ objectMemoryClass current ]
		ifFalse: [ nil ].
	stats do: [ :stat | stat writeSampleFrom: objectMemory to: statArchive ]
]
