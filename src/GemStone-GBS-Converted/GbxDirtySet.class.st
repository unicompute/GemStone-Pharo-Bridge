Class {
	#name : 'GbxDirtySet',
	#superclass : 'Object',
	#instVars : [
		'tombstone',
		'tally'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'enumerating' }
GbxDirtySet >> destructiveDo: aBlock
[
	"Evaluate aBlock at least once for each of my elements, with that element as an argument.
	After evaluating the block, remove the element from myself.
	Evaluation of the block is allowed to add elements to myself, though this may result
	in iterating the same element more than once (which is benign in context, since the
	object will be ignored if its delegate is no longer marked dirty).
	This method does not return until I am completely empty.
	Note that adding while enumerating might cause me to grow during enumeration."

	[tally > 0] whileTrue: 
			[| currentIndex |
			currentIndex := 1.
			[currentIndex > self basicSize] whileFalse: 
					[| currentKey |
					currentKey := self basicAt: currentIndex.
					currentKey ~~ nil & (currentKey ~~ tombstone)
						ifTrue: 
							["Evaluate the block *before* actually removing, since a nested
							 interaction could encounter an async abort before the block 
							 puts the object in the dirtyAwaitingPacking."
							aBlock value: currentKey.
							"If block evaluation has grown the collection and moved our current key,
							don't remove it; we'll encounter it again in its new position and it will be
							ignored since its delegate will not be dirty at that time."
							(self basicAt: currentIndex) == currentKey
								ifTrue: 
									[self basicAt: currentIndex put: tombstone.
									tally := tally - 1]].
					currentIndex := currentIndex + 1]]
]

{ #category : 'enumerating' }
GbxDirtySet >> emptyInto: resultCollection forSession: session
[

	self destructiveDo: 
			[:each |
			resultCollection add: each.
			(each asGSObjectInSession: session) clearDirtyBit]
]

{ #category : 'accessing' }
GbxDirtySet >> add: anObject
[
	"Add the object if not already here by identity."

	| currentIndex currentKey |
	self growIfNeeded.
	currentIndex := anObject identityHash hashMultiply \\ self basicSize + 1.
	
	[currentKey := self basicAt: currentIndex.
	currentKey == nil | (currentKey == tombstone) | (currentKey == anObject)]
			whileFalse: 
				[currentIndex := currentIndex + 1.
				currentIndex > self basicSize ifTrue: [currentIndex := 1]].
	currentKey == anObject
		ifFalse: 
			[self basicAt: currentIndex put: anObject.
			tally := tally + 1].
	^anObject
]

{ #category : 'accessing' }
GbxDirtySet >> size
[

	^tally
]

{ #category : 'initialize-release' }
GbxDirtySet >> initialize
[

	tombstone := Object new.
	tally := 0
]

{ #category : 'testing' }
GbxDirtySet >> isEmpty
[

	^tally = 0
]

{ #category : 'private' }
GbxDirtySet >> growIfNeeded
[
	"Max loading of ~75%"

	tally * 4 // self basicSize > 2 ifTrue: [self grow]
]

{ #category : 'private' }
GbxDirtySet >> grow
[
	"Make myself the next good capacity greater than double my current capacity."

	| newSelf |
	newSelf := self class new: self basicSize * 2.
	1 to: self basicSize
		do: 
			[:i |
			| element |
			element := self basicAt: i.
			element ~~ nil & (element ~~ tombstone) ifTrue: [newSelf add: element]].
	self become: newSelf
]

{ #category : 'private' }
GbxDirtySet >> indexOf: key
[
	"Answer the index where anObject is, or nil if the object is not found.
	Must search past tombstones. The table will never be full, but could have no nils (all unused slots tombstones),
	so stop search if we've gone once around."

	| startIndex currentIndex currentKey stopLooking |
	stopLooking := false.
	startIndex := currentIndex := key identityHash hashMultiply
						\\ self basicSize + 1.
	
	[currentKey := self basicAt: currentIndex.
	stopLooking | (currentKey == nil) | (currentKey == key)]
			whileFalse: 
				[currentIndex := currentIndex + 1.
				currentIndex > self basicSize ifTrue: [currentIndex := 1].
				currentIndex = startIndex ifTrue: [stopLooking := true]].
	^currentKey == key ifTrue: [currentIndex] ifFalse: [nil]
]

{ #category : 'instance creation' }
GbxDirtySet class >> new: capacity
[

	| tableSize |
	tableSize := Set goodSizeFrom: capacity.
	^(self basicNew: tableSize)
		initialize;
		yourself
]

