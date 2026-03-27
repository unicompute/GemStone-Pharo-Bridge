Class {
	#name : 'GbxOopKeyedNode',
	#superclass : 'Object',
	#instVars : [
		'upperBytes',
		'notCachedToken',
		'owningMap',
		'parentIndex',
		'tableSize',
		'tally'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'auditing' }
GbxOopKeyedNode >> auditInto: results parent: expectedParent parentIndex: expectedParentIndex session: aSession
[
	"Check my consistency just about every way possible."
	"Tally vs. used element checks are per-node, so reset the count for this node."

	results numUsedElements: 0.
	"Things that can be checked at this level:

	* The serverMap that is requesting this audit is the same map that I believe to be my parent
	* I appear at parentIndex in owningMap
	* upperBytes is consistent with my parentIndex"
	self auditParentage: expectedParent index: expectedParentIndex into: results.

	"* My tableSize is prime
	* My basic size is consistent with tableSize
	* My tableSize is consistent with my tally"
	self auditTableSizeInto: results.
	"* Each of my indexed instvars refers to a unique TableSegment"
	self auditUniqueSegmentsInto: results.
	"* My last segment contains only nils past tableSize"
	self auditUnusedSpaceInto: results.

	"* tally is equal to the number of used elements
	* all used elements have keys that are SmallIntegers in the correct range (1 to 2**24, inclusive)
	* all unused elements have nil keys
	* no used element should have a delegate or special for a client object
	* each used element has the correct delegate, or 0
	* each used element that has a non-zero client object should also have a non-zero delegate
	* each unused element should have a nil delegate and a nil clientObj"
	self auditSegmentsInto: results session: aSession.
	"* each used element can be found from its key's hash without probing past a nil key"
	self auditHashingInto: results
]

{ #category : 'auditing' }
GbxOopKeyedNode >> auditUnusedSpaceInto: results
[
	self subclassResponsibility
]

{ #category : 'auditing' }
GbxOopKeyedNode >> auditHashingInto: results
[
	self subclassResponsibility
]

{ #category : 'accessing' }
GbxOopKeyedNode >> size
[
	"Answer how many keys I have records for. This will include keys for which I only have a delegate but no client object, and keys for which the client object and/or delegate have been GCed but not yet finalized."

	^tally
]

{ #category : 'private-accessing' }
GbxOopKeyedNode >> segmentClass
[

	self subclassResponsibility
]

{ #category : 'private-accessing' }
GbxOopKeyedNode >> owningMap: anObject
[
	owningMap := anObject
]

{ #category : 'private-accessing' }
GbxOopKeyedNode >> parentIndex: anObject
[
	parentIndex := anObject
]

{ #category : 'private-growing and shrinking' }
GbxOopKeyedNode >> makeRoom
[
	"Make room for at least one new entry.
	Can't finalize, since we don't have a container to finalize into, so just grow."
	"Sender must hold the owning session's access lock"
	"Works best with a prime tableSize"
	"Growing to double the size can fail by running out of room in the collision chain, if
	we're unlucky. As long as the collision chain is 1/3 the size of the table, however, 
	growing must succeed as long as we increase the table size by at least 4x, since
	the collision chain area is then big enough to hold the entire collection."

	self changeCapacityTo: (Set goodSizeFrom: tableSize * 2)
]

{ #category : 'initialize-release' }
GbxOopKeyedNode >> initializeForCapacity: capacity
[
	tableSize := capacity.
	notCachedToken := NotCachedToken.
	upperBytes := parentIndex - 1.
	tally := 0.
	1 to: self basicSize
		do: 
			[:i |
			self basicAt: i
				put: (self segmentClass parent: self index: i upperBytes: upperBytes)]
]

{ #category : 'private-auditing' }
GbxOopKeyedNode >> auditUniqueSegmentsInto: results
[
	" Things checked here:
	* Each of my indexed instvars refers to a unique TableSegment"

	| uniqueSegments |
	uniqueSegments := IdentitySet new.
	1 to: self basicSize
		do: 
			[:i |
			| segment |
			segment := self basicAt: i.
			uniqueSegments add: segment.
			results
				assert: segment class == GbxServerMapTableSegment
				node: self
				description: 'Found table segment of class %1, expected %2.'
				actual: segment class
				expected: 'GbxServerMapTableSegment'].
	results
		assert: self basicSize == uniqueSegments size
		node: self
		description: 'Table segments not unique. Found %1 unique segments, expected %2.'
		actual: uniqueSegments size
		expected: self basicSize printString
]

{ #category : 'private-auditing' }
GbxOopKeyedNode >> auditIsPrime: anInteger
[
	" a poor man's prime number check"

	anInteger < 2 ifTrue: [^false].
	anInteger even ifTrue: [^anInteger = 2].
	2 to: anInteger sqrt truncated
		by: 2
		do: [:idx | anInteger \\ idx = 0 ifTrue: [^false]].
	^true
]

{ #category : 'private-auditing' }
GbxOopKeyedNode >> auditSegmentsInto: results session: aSession
[
	" Things checked here:
	* tally is equal to the number of used elements
	* all used elements have keys that are SmallIntegers in the correct range (1 to 2**24, inclusive)
	* all unused elements have nil keys
	* no used element should have a delegate or special for a client object
	* each used element has the correct delegate, or 0
	* each used element that has a non-zero client object should also have a non-zero delegate
	* each unused element should have a nil delegate and a nil clientObj"

	1 to: self basicSize
		do: 
			[:i |
			| segment |
			segment := self basicAt: i.
			segment
				auditInto: results
				parent: self
				parentIndex: i
				upperBytes: upperBytes
				session: aSession].
	results
		assert: tally = results numUsedElements
		node: self
		description: 'found %1 used elements in table, but tally is %2.'
		actual: results numUsedElements
		expected: tally printString
]

{ #category : 'private-auditing' }
GbxOopKeyedNode >> auditTableSizeInto: results
[
	" Things checked here:
	* My tableSize is prime
	* My basic size is consistent with tableSize
	* My tableSize is consistent with my tally"

	| expectedBasicSize minimumTableSize tableSizeLowBound tableSizeHighBound |
	results
		assert: (self auditIsPrime: tableSize)
		node: self
		description: 'tableSize %1 not prime.'
		actual: tableSize
		expected: 'a prime number'.
	expectedBasicSize := tableSize // 1024 + 1.
	results
		assert: self basicSize == expectedBasicSize
		node: self
		description: 'basicSize=%1, expected %2'
		actual: self basicSize
		expected: expectedBasicSize printString.
	minimumTableSize := Set
				goodSizeFrom: owningMap session configuration serverMapLeafCapacity * 3
						// 2.
	tableSizeLowBound := minimumTableSize max: tally // 0.7.
	tableSizeHighBound := minimumTableSize max: tally * 10 + 9.
	results
		assert: (tableSize between: tableSizeLowBound and: tableSizeHighBound)
		node: self
		description: 'tableSize=%1, expected %2'
		actual: tableSize
		expected: 'between ' , tableSizeLowBound printString , ' and '
				, tableSizeHighBound printString
]

{ #category : 'private-auditing' }
GbxOopKeyedNode >> auditParentage: expectedParent index: expectedParentIndex into: results
[
	" Things checked here:
	* The serverMap that is requesting this audit is the same map that I believe to be my parent
	* I appear at parentIndex in owningMap
	* upperBytes is consistent with my parentIndex"

	| expectedUpperBytes |
	results
		assert: owningMap == expectedParent
		node: self
		description: 'owningMap  %1, expected %2.'
		actual: (Array with: owningMap with: owningMap identityHash)
		expected: expectedParent printString
				, expectedParent identityHash printString.
	results
		assert: parentIndex == expectedParentIndex
		node: self
		description: 'parentIndex=%1, expected %2'
		actual: parentIndex
		expected: expectedParentIndex printString.
	expectedUpperBytes := parentIndex - 1.
	results
		assert: upperBytes == expectedUpperBytes
		node: self
		description: 'upperBytes=%1, expected %2'
		actual: upperBytes
		expected: expectedUpperBytes printString
]

{ #category : 'instance creation' }
GbxOopKeyedNode class >> owningMap: serverMap parentIndex: index capacity: capacity
[
	"Leave enough extra capacity so we can reach at least size entries while still under the 70% limit."

	| inst |
	inst := self basicNew: capacity // 1024 + 1.
	inst
		owningMap: serverMap;
		parentIndex: index;
		initializeForCapacity: capacity.
	^inst
]

{ #category : 'instance creation' }
GbxOopKeyedNode class >> owningMap: serverMap parentIndex: index initialSize: size
[
	"Leave enough extra capacity so we can reach at least size entries while still under the 70% limit."

	^self
		owningMap: serverMap
		parentIndex: index
		capacity: (Set goodSizeFrom: size * 3 // 2)
]

