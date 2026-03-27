Class {
	#name : 'GbxServerMapNode',
	#superclass : 'GbxOopKeyedNode',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'replication support' }
GbxServerMapNode >> beStrongAndFinalizeIntoNoLongerReplicatedBuffer: noLongerReplicatedBuffer gcedBuffer: gcedBuffer
[
	"1. Change all of my references to delegates and to client objects to strong references. 
	2. Scan all node table segments that need finalization, and add appropriate oops into the given buffers.
	Either or both of the delegate and the client object may have been collected. 
	For each element that has had either delegate or client object collected, first change the reference(s)
	from 0 to nil. Then apply the rules.
	The rules:
		* If both delegate and client object are now nil, add oop to gcedBuffer and reclaim the element
		* If clientObject is nil, but delegate is not, add oop to stubbedBuffer
		* If delegate is nil but client object is not, do nothing (possibly assert that this shouldn't happen,
			since the delegate should really not become unreferenced before its client object does)."
	"The sender must hold my session's sessionProtect"

	| minimumTableSize |
	1 to: self basicSize do: [:i | (self basicAt: i) beStrongAndFinalizeIntoNoLongerReplicatedBuffer: noLongerReplicatedBuffer gcedBuffer: gcedBuffer].
	(tally < (tableSize // 10) and: 
			[minimumTableSize := Set goodSizeFrom: owningMap session configuration serverMapLeafCapacity * 3 // 2.	"Minimum is allowed to change during a session, so we don't cache it."
			tableSize > minimumTableSize])
		ifTrue: [self changeCapacityTo: (minimumTableSize max: (Set goodSizeFrom: tally * 2))]
]

{ #category : 'replication support' }
GbxServerMapNode >> beWeak
[
	"Change all of my references to delegates and to client objects to weak references."
	"The sender must hold my session's sessionProtect"

	1 to: self basicSize do: [:i | (self basicAt: i) beWeak: true]
]

{ #category : 'private-enumerating' }
GbxServerMapNode >> elementsDo: aBlock
[
	"Iterate through all of my elements, free or not, evaluating the three-argument block for each 
	SmallInteger key, client object, and delegate.

	Sender must hold the session's sessionProtect"

	| lastSegment |
	1 to: self basicSize - 1
		do: 
			[:segnum |
			| segment |
			segment := self basicAt: segnum.
			1 to: 3070
				by: 3
				do: 
					[:i |
					aBlock
						value: (segment basicAt: i)
						value: (segment basicAt: i + 1)
						value: (segment basicAt: i + 2)]].
	"Each segment but the last is full size, 1024 entries. The last will be shorter."
	lastSegment := self basicAt: self basicSize.
	1 to: tableSize \\ 1024 * 3 - 2
		by: 3
		do: 
			[:i |
			aBlock
				value: (lastSegment basicAt: i)
				value: (lastSegment basicAt: i + 1)
				value: (lastSegment basicAt: i + 2)]
]

{ #category : 'accessing' }
GbxServerMapNode >> delegateForOop: oop
[
	" Answer the canonical delegate for he oop. If the given oop is a delegate, and there is no 
	canonical delegate for the oop, it becomes the canonical delegate for the oop.
	oop may be a delegate or a HeapOop. It must not be a GbxKernelOop"
	"Sender must hold my session's sessionProtect"

	| key index segnum segment segmentSize offset keyOffset thisKey delegate |
	key := oop oopNumberLower3 + 1.
	"index is 0-based"
	index := key hashMultiply \\ tableSize.
	"segnum is 1-based"
	segnum := index // 1024 + 1.
	"offset is 0-based"
	offset := index \\ 1024.
	segment := self basicAt: segnum.
	segmentSize := segnum == self basicSize ifFalse: [1024] ifTrue: [tableSize \\ 1024].
	
	["Final segment size will be less than 1024, since tableSize is prime"
	keyOffset := offset * 3 + 1.
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
						segmentSize := segnum == self basicSize ifFalse: [1024] ifTrue: [tableSize \\ 1024]]].
	thisKey == key
		ifTrue: 
			["found key"
			delegate := segment basicAt: keyOffset + 2.
			(delegate == nil or: [delegate == 0])
				ifTrue: 
					[delegate := self newDelegateFromOop: oop.
					segment basicAt: keyOffset + 2 put: delegate]]
		ifFalse: 
			["new entry"
			delegate := self newDelegateFromOop: oop.
			segment
				basicAt: keyOffset put: key;
				basicAt: keyOffset + 2 put: delegate.
			tally := tally + 1.
			tally * 10 // 7 > tableSize ifTrue: [self makeRoom]].
	^delegate
]

{ #category : 'accessing' }
GbxServerMapNode >> clientAtOop: oop
[
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
	segmentSize := segnum == self basicSize ifFalse: [1024] ifTrue: [tableSize \\ 1024].
	
	["Final segment size will be less than 1024, since tableSize is prime"
	keyOffset := offset * 3 + 1.
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
						segmentSize := segnum == self basicSize ifFalse: [1024] ifTrue: [tableSize \\ 1024]]].
	^thisKey == key
		ifTrue: 
			["found"
			| clientObj |
			clientObj := segment basicAt: keyOffset + 1.
			(clientObj == nil or: [clientObj == 0]) ifTrue: [notCachedToken] ifFalse: [clientObj]]
		ifFalse: 
			["key not found"
			notCachedToken]
]

{ #category : 'accessing' }
GbxServerMapNode >> atOop: oop putClient: client
[
	"Add an association between the given oop and client object.
	Answer the canonical delegate for the given oop."
	"Sender must hold my session's sessionProtect"

	| key index segnum segment segmentSize offset keyOffset thisKey delegate |
	key := oop oopNumberLower3 + 1.
	"index is 0-based"
	index := key hashMultiply \\ tableSize.
	"segnum is 1-based"
	segnum := index // 1024 + 1.
	"offset is 0-based"
	offset := index \\ 1024.
	segment := self basicAt: segnum.
	"Final segment size will be less than 1024, since tableSize is prime"
	segmentSize := segnum == self basicSize ifFalse: [1024] ifTrue: [tableSize \\ 1024].
	
	[keyOffset := offset * 3 + 1.
	thisKey := segment basicAt: keyOffset.
	thisKey == nil or: [thisKey == key]] whileFalse: 
				[offset := offset + 1.
				offset == segmentSize
					ifTrue: 
						[offset := 0.
						segnum := segnum + 1.
						segnum > self basicSize ifTrue: [segnum := 1].
						segment := self basicAt: segnum.
						segmentSize := segnum == self basicSize ifFalse: [1024] ifTrue: [tableSize \\ 1024]]].
	thisKey == key
		ifTrue: 
			["existing entry"
			segment basicAt: keyOffset + 1 put: client.
			delegate := segment basicAt: keyOffset + 2.
			(delegate == 0 or: [delegate == nil]) ifTrue: [segment basicAt: keyOffset + 2 put: (delegate := self newDelegateFromOop: oop)]]
		ifFalse: 
			["new entry"
			delegate := self newDelegateFromOop: oop.
			segment
				basicAt: keyOffset put: key;
				basicAt: keyOffset + 1 put: client;
				basicAt: keyOffset + 2 put: delegate.
			tally := tally + 1.
			tally * 10 // 7 > tableSize ifTrue: [self makeRoom]].
	^delegate
]

{ #category : 'enumeration' }
GbxServerMapNode >> delegatesAndClientObjsDo: aBlock
[
	"For each entry I hold, evaluate the given two-argument block with arguments of the delegate and the client object.
	The delegate will not be nil, but the client object may be nil."
	"Sender must hold my session's accessProtect."

	self elementsDo: 
			[:key :clientObj :del |
			(key ~~ nil and: [del ~~ nil and: [del ~~ 0]])
				ifTrue: [aBlock value: del value: (clientObj == 0 ifTrue: [nil] ifFalse: [clientObj])]]
]

{ #category : 'testing' }
GbxServerMapNode >> isWeak
[

	^owningMap isWeak
]

{ #category : 'private' }
GbxServerMapNode >> beWeak: aBoolean
[
	"Sender must hold my session's sessionProtect"

	1 to: self basicSize do: [:i | (self basicAt: i) beWeak: aBoolean]
]

{ #category : 'private' }
GbxServerMapNode >> newDelegateFromOop: oop
[
	^oop isGSObject ifTrue: [oop] ifFalse: [oop asNewDelegateInSession: owningMap session]
]

{ #category : 'private-removing' }
GbxServerMapNode >> removeElementAt: index
[
	"Remove element (key, client, delegate) at index. Index is 0-based within my table.
	Must fix any collision chains that are disturbed by this deletion. The invariant that must be preserved is that if you start at the hash index of a key and proceed to higher indexes, wrapping to zero if you would otherwise exceed table size (this direction is known here as 'clockwise') you must either find the hashed key without encountering a nil key, or the hashed key is not present.

	Sender must hold my session's sessionProtect."

	| removalIndex removalSegment removalKeyOffset currentIndex currentKey hashIndex currentKeyOffset currentSegment |
	removalIndex := currentIndex := index.
	removalSegment := self basicAt: removalIndex // 1024 + 1.
	removalKeyOffset := removalIndex \\ 1024 * 3 + 1.
	
	[currentIndex := currentIndex + 1.
	currentIndex = tableSize ifTrue: [currentIndex := 0].
	currentSegment := self basicAt: currentIndex // 1024 + 1.
	currentKeyOffset := currentIndex \\ 1024 * 3 + 1.
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
						removalSegment basicAt: removalKeyOffset + 1 put: (currentSegment basicAt: currentKeyOffset + 1).	"client"
						removalSegment basicAt: removalKeyOffset + 2 put: (currentSegment basicAt: currentKeyOffset + 2).	"delegate"
						removalIndex := currentIndex.
						removalSegment := currentSegment.
						removalKeyOffset := currentKeyOffset]].
	"At this point, all needed swaps have been performed, but we haven't nilled the last one yet."
	removalSegment basicAt: removalKeyOffset put: nil.	"key"
	removalSegment basicAt: removalKeyOffset + 1 put: nil.	"client"
	removalSegment basicAt: removalKeyOffset + 2 put: nil.	"delegate"
	tally := tally - 1
	"Do not shrink at this time. I shrink only after a finalization sweep to make sure that
	I only shrink once should a very large proportion of my contents be GCed at the same time."
]

{ #category : 'removing' }
GbxServerMapNode >> pretendClientIsCollected: oop
[
	"Put a nil in the client slot corresponding to oop (normally a Delegate).
	This formerly left a tombstone there, but updating of the gem's export set is now
	done by the sender of this message.
	If no corresponding key found, do nothing, though this should normally not happen."
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
	
	[keyOffset := offset * 3 + 1.
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
			["found"
			segment basicAt: keyOffset + 1 put: nil]
		ifFalse: 
			["not found, ignore"
			]
]

{ #category : 'removing' }
GbxServerMapNode >> removeOop: oop
[
	"Remove the mapped client object *and delegate* for the oop. The answer from this method should not be used.
	This is used only in a few exceptional circumstances. Most explicit unmapping should use #pretendClientIsCollected:. This method will not update the server's export set and referenced set, and thus can result in server-side collection of an object for which someone is still holding a delegate."
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
	
	[keyOffset := offset * 3 + 1.
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
			["found"
			self removeElementAt: (segnum - 1) * 1024 + offset]
		ifFalse: 
			["key not found, do nothing"
			]
]

{ #category : 'private-accessing' }
GbxServerMapNode >> segmentClass
[

	^GbxServerMapTableSegment
]

{ #category : 'private-growing and shrinking' }
GbxServerMapNode >> changeCapacityTo: newCapacity
[
	"Change my table size to newCapacity, which may be either larger or smaller than my current tableSize.
	The sender should assure that newCapacity is large enough to hold my current contents while leaving at least 30% of the table free. NewCapacity should also be a good prime number.
	The basic strategy is to copy all of my elements to a new node, then tell my parent to replace me with that new node."
	"Sender must hold my session's sessionProtect"

	| copy |
	copy := self class
				owningMap: owningMap
				parentIndex: parentIndex
				capacity: newCapacity.
	copy beWeak: self isWeak.
	self beWeak: false.	"Keep all contents alive at least until copy is complete (and in fact until I am GCed)"
	self elementsDo: 
			[:key :clientObj :del |
			key ~~ nil ifTrue: [copy addElementKey: key clientObj: clientObj del: del]].	"Copy including unfinalized tombstones."
	owningMap replaceNodeAt: parentIndex with: copy
]

{ #category : 'private-growing and shrinking' }
GbxServerMapNode >> addElementKey: key clientObj: client del: delegate
[
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
]

{ #category : 'private-auditing' }
GbxServerMapNode >> auditHashingInto: results
[
	" Things checked here:
	* each used element can be found from its key's hash without probing past a nil key"

	| indexOfFirstNil indexOfMostRecentNil index key hashIsCorrect |
	indexOfFirstNil := 0.
	"find first nil"
	
	[| segment keyOffset |
	segment := self basicAt: indexOfFirstNil // 1024 + 1.
	keyOffset := indexOfFirstNil \\ 1024 * 3 + 1.
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
	index = indexOfFirstNil] whileFalse: 
				[| segment keyOffset hashIndex |
				segment := self basicAt: index // 1024 + 1.
				keyOffset := index \\ 1024 * 3 + 1.
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
					expected: index printString , ' with intervening nil at: ' , indexOfMostRecentNil printString]
]

{ #category : 'private-auditing' }
GbxServerMapNode >> auditUnusedSpaceInto: results
[
	" Things checked here:
	* My last segment contains only nils past tableSize"

	| lastSegment numUsed |
	lastSegment := self basicAt: self basicSize.
	numUsed := tableSize \\ 1024.	"tableSize is prime, so usedEntries will never be 0."
	numUsed * 3 + 1 to: 3072
		do: 
			[:i |
			results
				assert: (lastSegment basicAt: i) == nil
				node: self
				description: 'Found %1 past end of table , expected %2.'
				actual: (lastSegment basicAt: i)
				expected: 'nil']
]

