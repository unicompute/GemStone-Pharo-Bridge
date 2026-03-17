Class {
	#name : 'GbxBehaviorOopMapNode',
	#superclass : 'GbxOopKeyedNode',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private-enumerating' }
GbxBehaviorOopMapNode >> elementsDo: aBlock
	"Iterate through all of my elements, free or not, evaluating the two-argument block for each 
	SmallInteger key and client object.

	Sender must hold the session's sessionProtect"

	| lastSegment |
	1 to: self basicSize - 1
		do: 
			[:segnum |
			| segment |
			segment := self basicAt: segnum.
			1 to: 2047
				by: 2
				do: [:i | aBlock value: (segment basicAt: i) value: (segment basicAt: i + 1)]].
	"Each segment but the last is full size, 1024 entries. The last will be shorter."
	lastSegment := self basicAt: self basicSize.
	1 to: tableSize \\ 1024 * 2 - 1
		by: 2
		do: 
			[:i |
			aBlock value: (lastSegment basicAt: i) value: (lastSegment basicAt: i + 1)]

{ #category : 'accessing' }
GbxBehaviorOopMapNode >> clientAtOop: oop
	"Answer the client object associated with the given oop. If I don't have one, answer NotCachedToken"
	"Sender must hold my session's sessionProtect"

	| key index segnum segment segmentSize offset keyOffset thisKey |
	key := oop oopNumberLower3 + 1.
	"index is 0-based"
	index := key hashMultiply \\ tableSize.
	"segnum is 1-based"
	segnum := index // 1024 + 1.
	"offset is 0-based"
	offset := index \\ 1024.
	segment := self basicAt: segnum.
	segmentSize := segnum == self basicSize
				ifFalse: [1024]
				ifTrue: [tableSize \\ 1024].
	
	["Final segment size will be less than 1024, since tableSize is prime"
	keyOffset := offset * 2 + 1.
	thisKey := segment basicAt: keyOffset.
	thisKey == key or: [thisKey == nil]]
			whileFalse: 
				[offset := offset + 1.
				offset == segmentSize
					ifTrue: 
						[offset := 0.
						segnum := segnum + 1.
						segnum > self basicSize ifTrue: [segnum := 1].
						segment := self basicAt: segnum.
						segmentSize := segnum == self basicSize
									ifFalse: [1024]
									ifTrue: [tableSize \\ 1024]]].
	^thisKey == key
		ifTrue: 
			["found"
			segment basicAt: keyOffset + 1]
		ifFalse: 
			["key not found"
			notCachedToken]

{ #category : 'accessing' }
GbxBehaviorOopMapNode >> atOop: oop putClient: client
	"Add an association between the given oop and client object, which will be a replicator.
	Answer the client replicator."
	"Sender must hold my session's sessionProtect"

	| key index segnum segment segmentSize offset keyOffset thisKey |
	key := oop oopNumberLower3 + 1.
	"index is 0-based"
	index := key hashMultiply \\ tableSize.
	"segnum is 1-based"
	segnum := index // 1024 + 1.
	"offset is 0-based"
	offset := index \\ 1024.
	segment := self basicAt: segnum.
	"Final segment size will be less than 1024, since tableSize is prime"
	segmentSize := segnum == self basicSize
				ifFalse: [1024]
				ifTrue: [tableSize \\ 1024].
	
	[keyOffset := offset * 2 + 1.
	thisKey := segment basicAt: keyOffset.
	thisKey == nil or: [thisKey == key]]
			whileFalse: 
				[offset := offset + 1.
				offset == segmentSize
					ifTrue: 
						[offset := 0.
						segnum := segnum + 1.
						segnum > self basicSize ifTrue: [segnum := 1].
						segment := self basicAt: segnum.
						segmentSize := segnum == self basicSize
									ifFalse: [1024]
									ifTrue: [tableSize \\ 1024]]].
	thisKey == key
		ifTrue: 
			["existing entry"
			segment basicAt: keyOffset + 1 put: client]
		ifFalse: 
			["new entry"
			segment
				basicAt: keyOffset put: key;
				basicAt: keyOffset + 1 put: client.
			tally := tally + 1.
			tally * 10 // 7 > tableSize ifTrue: [self makeRoom]].
	^client

{ #category : 'private-accessing' }
GbxBehaviorOopMapNode >> segmentClass

	^GbxBehaviorMapTableSegment

{ #category : 'private-removing' }
GbxBehaviorOopMapNode >> removeElementAt: index
	"Remove element (key, client) at index. Index is 0-based within my table.
	Must fix any collision chains that are disturbed by this deletion. The invariant that must be preserved is that if you start at the hash index of a key and proceed to higher indexes, wrapping to zero if you would otherwise exceed table size (this direction is known here as 'clockwise') you must either find the hashed key without encountering a nil key, or the hashed key is not present.

	Sender must hold my session's sessionProtect."

	| removalIndex removalSegment removalKeyOffset currentIndex currentKey hashIndex currentKeyOffset currentSegment minimumTableSize |
	removalIndex := currentIndex := index.
	removalSegment := self basicAt: removalIndex // 1024 + 1.
	removalKeyOffset := removalIndex \\ 1024 * 2 + 1.
	
	[currentIndex := currentIndex + 1.
	currentIndex = tableSize ifTrue: [currentIndex := 0].
	currentSegment := self basicAt: currentIndex // 1024 + 1.
	currentKeyOffset := currentIndex \\ 1024 * 2 + 1.
	currentKey := currentSegment basicAt: currentKeyOffset.
	currentKey == nil]
			whileFalse: 
				[| needSwap |
				hashIndex := currentKey hashMultiply \\ tableSize.
				needSwap := currentIndex > removalIndex
							ifTrue: [hashIndex <= removalIndex or: [hashIndex > currentIndex]]
							ifFalse: [hashIndex <= removalIndex and: [hashIndex > currentIndex]].
				needSwap
					ifTrue: 
						[removalSegment basicAt: removalKeyOffset put: currentKey.	"key"
						removalSegment basicAt: removalKeyOffset + 1
							put: (currentSegment basicAt: currentKeyOffset + 1).	"client"
						removalIndex := currentIndex.
						removalSegment := currentSegment.
						removalKeyOffset := currentKeyOffset]].
	"At this point, all needed swaps have been performed, but we haven't nilled the last one yet."
	removalSegment basicAt: removalKeyOffset put: nil.	"key"
	removalSegment basicAt: removalKeyOffset + 1 put: nil.	"client"
	tally := tally - 1.
	"Shrink if we're mostly empty space. Still, don't shrink past initial size, and leave room for at least doubling size
	before having to grow again."
	(tally < (tableSize // 10) and: 
			[minimumTableSize := Set
						goodSizeFrom: owningMap session configuration serverMapLeafCapacity * 3
								// 2.	"Minimum is allowed to change during a session, so we don't cache it."
			tableSize > minimumTableSize])
		ifTrue: 
			[self
				changeCapacityTo: (minimumTableSize max: (Set goodSizeFrom: tally * 2))]

{ #category : 'removing' }
GbxBehaviorOopMapNode >> removeOop: oop
	"Remove the mapped client object (a replicator) for the oop. Answer the formerly-mapped replicator, or nil if not found."
	"Sender must hold my session's accessProtect."

	| key index segnum segment segmentSize offset keyOffset thisKey |
	key := oop oopNumberLower3 + 1.
	"index is 0-based"
	index := key hashMultiply \\ tableSize.
	"segnum is 1-based"
	segnum := index // 1024 + 1.
	"offset is 0-based"
	offset := index \\ 1024.
	segment := self basicAt: segnum.
	"Final segment size will be less than 1024, since tableSize is prime"
	segmentSize := segnum == self basicSize
				ifFalse: [1024]
				ifTrue: [tableSize \\ 1024].
	
	[keyOffset := offset * 2 + 1.
	thisKey := segment basicAt: keyOffset.
	thisKey == nil or: [thisKey == key]]
			whileFalse: 
				[offset := offset + 1.
				offset == segmentSize
					ifTrue: 
						[offset := 0.
						segnum := segnum + 1.
						segnum > self basicSize ifTrue: [segnum := 1].
						segment := self basicAt: segnum.
						segmentSize := segnum == self basicSize
									ifFalse: [1024]
									ifTrue: [tableSize \\ 1024]]].
	^thisKey == key
		ifTrue: 
			["found"
			| replicator |
			replicator := segment basicAt: keyOffset + 1.
			self removeElementAt: (segnum - 1) * 1024 + offset.
			replicator]
		ifFalse: 
			["key not found, answer nil"
			nil]

{ #category : 'private-growing and shrinking' }
GbxBehaviorOopMapNode >> changeCapacityTo: newCapacity
	"Change my table size to newCapacity, which may be either larger or smaller than my current tableSize.
	The sender should assure that newCapacity is large enough to hold my current contents while leaving at least 30% of the table free. NewCapacity should also be a good prime number.
	The basic strategy is to copy all of my elements to a new node, then tell my parent to replace me with that new node."
	"Sender must hold my session's sessionProtect"

	| copy |
	copy := self class
				owningMap: owningMap
				parentIndex: parentIndex
				capacity: newCapacity.
	self elementsDo: 
			[:key :clientObj |
			key ~~ nil ifTrue: [copy addElementKey: key clientObj: clientObj]].
	owningMap replaceNodeAt: parentIndex with: copy

{ #category : 'private-growing and shrinking' }
GbxBehaviorOopMapNode >> addElementKey: key clientObj: client del: delegate
	"Only for use when changing capacity. Add the given key/client/delegate trio. 
	Assume we don't already have such an entry for this key.
	del and clientObj may both be zero, and client may be nil, but key must be valid (non-nil)"
	"index is 0-based"
	"Sender must hold my session's sessionProtect"

	| index segnum segment segmentSize offset keyOffset thisKey |
	index := key hashMultiply \\ tableSize.
	"segnum is 1-based"
	segnum := index // 1024 + 1.
	"offset is 0-based"
	offset := index \\ 1024.
	segment := self basicAt: segnum.
	"Final segment size will be less than 1024, since tableSize is prime"
	segmentSize := segnum == self basicSize
				ifFalse: [1024]
				ifTrue: [tableSize \\ 1024].
	
	[keyOffset := offset * 3 + 1.
	thisKey := segment basicAt: keyOffset.
	thisKey == nil]
			whileFalse: 
				[offset := offset + 1.
				offset == segmentSize
					ifTrue: 
						[offset := 0.
						segnum := segnum + 1.
						segnum > self basicSize ifTrue: [segnum := 1].
						segment := self basicAt: segnum.
						segmentSize := segnum == self basicSize
									ifFalse: [1024]
									ifTrue: [tableSize \\ 1024]]].
	segment
		basicAt: keyOffset put: key;
		basicAt: keyOffset + 1 put: client;
		basicAt: keyOffset + 2 put: delegate.
	(client == 0 or: [delegate == 0]) ifTrue: [segment mourn].
	tally := tally + 1

{ #category : 'private-growing and shrinking' }
GbxBehaviorOopMapNode >> addElementKey: key clientObj: client
	"Only for use when changing capacity. Add the given key/client/ pair. 
	Assume we don't already have such an entry for this key."
	"Sender must hold my session's sessionProtect"

	| index segnum segment segmentSize offset keyOffset thisKey |
	index := key hashMultiply \\ tableSize.	"index is 0-based"
	"segnum is 1-based"
	segnum := index // 1024 + 1.
	"offset is 0-based"
	offset := index \\ 1024.
	segment := self basicAt: segnum.
	"Final segment size will be less than 1024, since tableSize is prime"
	segmentSize := segnum == self basicSize
				ifFalse: [1024]
				ifTrue: [tableSize \\ 1024].
	
	[keyOffset := offset * 2 + 1.
	thisKey := segment basicAt: keyOffset.
	thisKey == nil]
			whileFalse: 
				[offset := offset + 1.
				offset == segmentSize
					ifTrue: 
						[offset := 0.
						segnum := segnum + 1.
						segnum > self basicSize ifTrue: [segnum := 1].
						segment := self basicAt: segnum.
						segmentSize := segnum == self basicSize
									ifFalse: [1024]
									ifTrue: [tableSize \\ 1024]]].
	segment
		basicAt: keyOffset put: key;
		basicAt: keyOffset + 1 put: client.
	tally := tally + 1

{ #category : 'private-auditing' }
GbxBehaviorOopMapNode >> auditUnusedSpaceInto: results
	" Things checked here:
	* My last segment contains only nils past tableSize"

	| lastSegment numUsed |
	lastSegment := self basicAt: self basicSize.
	numUsed := tableSize \\ 1024.	"tableSize is prime, so usedEntries will never be 0."
	numUsed * 2 + 1 to: 2048
		do: 
			[:i |
			results
				assert: (lastSegment basicAt: i) == nil
				node: self
				description: 'Found %1 past end of table , expected %2.'
				actual: (lastSegment basicAt: i)
				expected: 'nil']

{ #category : 'private-auditing' }
GbxBehaviorOopMapNode >> auditHashingInto: results
	" Things checked here:
	* each used element can be found from its key's hash without probing past a nil key"

	| indexOfFirstNil indexOfMostRecentNil index key hashIsCorrect |
	indexOfFirstNil := 0.
	"find first nil"
	
	[| segment keyOffset |
	segment := self basicAt: indexOfFirstNil // 1024 + 1.
	keyOffset := indexOfFirstNil \\ 1024 * 2 + 1.
	key := segment basicAt: keyOffset.
	key == nil or: [indexOfFirstNil = (tableSize - 1)]]
			whileFalse: [indexOfFirstNil := indexOfFirstNil + 1].
	results
		assert: key == nil
		node: self
		description: 'no nil keys found in table!'
		actual: nil
		expected: nil.
	index := indexOfMostRecentNil := indexOfFirstNil.
	"scan table from this point, and wrap around to this point"
	
	[index := index + 1.
	index = tableSize ifTrue: [index := 0].
	index = indexOfFirstNil]
			whileFalse: 
				[| segment keyOffset hashIndex |
				segment := self basicAt: index // 1024 + 1.
				keyOffset := index \\ 1024 * 2 + 1.
				key := segment basicAt: keyOffset.
				key == nil
					ifTrue: 
						[indexOfMostRecentNil := index.
						hashIsCorrect := true]
					ifFalse: 
						[hashIndex := key hashMultiply \\ tableSize.
						hashIsCorrect := index > indexOfMostRecentNil
									ifTrue: [hashIndex > indexOfMostRecentNil and: [hashIndex <= index]]
									ifFalse: [hashIndex <= index or: [hashIndex > indexOfMostRecentNil]]].
				results
					assert: hashIsCorrect
					node: self
					description: 'key with hash index %1 found at index %2'
					actual: hashIndex
					expected: index printString , ' with intervening nil at: '
							, indexOfMostRecentNil printString]

