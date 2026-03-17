Class {
	#name : 'GbxServerMapTableSegment',
	#superclass : 'GbxHashTableSegment',
	#instVars : [
		'needFinalization'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'replication support' }
GbxServerMapTableSegment >> beStrongAndFinalizeIntoNoLongerReplicatedBuffer: noLongerReplicatedBuffer gcedBuffer: gcedBuffer
	"1. Change all of my references to delegates and to client objects to strong references. 
	2. If I need finalization, finalize my piece of the table and add appropriate oops into the given buffers.
	Either or both of the delegate and the client object may have been collected. 
	For each element that has had either delegate or client object collected, first change the reference(s)
	from 0 to nil. Then apply the rules.
	The rules:
		* If both delegate and client object are now nil, add oop to gcedBuffer and reclaim the element
		* If clientObject is nil, but delegate is not, add oop to noLongerReplicatedBuffer
		* If delegate is nil but client object is not, do nothing (could assert that this shouldn't happen,
			since the delegate should really not become unreferenced before its client object does)."
	"The sender must hold my session's sessionProtect"

	self beWeak: false.	"FIRST, become strong so nothing can be collected while we finalize."
	needFinalization
		ifTrue: 
			[| tombstoneIndex |
			tombstoneIndex := 1.
			
			[tombstoneIndex := self
						indexOf: 0
						replaceWith: nil
						startingAt: tombstoneIndex
						stoppingAt: 3072.
			tombstoneIndex == 0]
					whileFalse: 
						[| offsetFromKey key |
						offsetFromKey := (tombstoneIndex - 1) \\ 3.
						key := self basicAt: tombstoneIndex - offsetFromKey.
						offsetFromKey == 0
							ifTrue: [self gbsMessenger error: 'Tombstone found in key location'].
						offsetFromKey == 1
							ifTrue: 
								["client object has been collected"
								| delegate |
								delegate := self basicAt: tombstoneIndex + 1.
								delegate == 0
									ifTrue: 
										["If more than one GC cycle has happened between round trips, 
										both client obj and delegate can be tombstones"
										gcedBuffer addUpper: upperBytes lower3: key - 1.
										parent
											removeElementAt: (parentIndex - 1) * 1024 + ((tombstoneIndex - 2) / 3).
										"Removed element, need to search the element that may have taken my place at this index"
										tombstoneIndex := tombstoneIndex - 1]
									ifFalse: 
										[delegate inExport
											ifTrue: 
												[noLongerReplicatedBuffer addFromDelegate: delegate.
												delegate noLongerExported].
										delegate clearIdentityClampedBit	"If it was identity clamped, it isn't any more. Client obj is gone."]].
						offsetFromKey == 2
							ifTrue: 
								["delegate has been collected"
								| clientObj |
								clientObj := self basicAt: tombstoneIndex - 1.
								clientObj == nil
									ifTrue: 
										["Delegate has been collected, client was never there or was previously collected."
										gcedBuffer addUpper: upperBytes lower3: key - 1.
										parent
											removeElementAt: (parentIndex - 1) * 1024 + ((tombstoneIndex - 3) / 3).
										"Removed element, need to search the element that may have taken my place at this index"
										tombstoneIndex := tombstoneIndex - 2]
									ifFalse: [self gbsMessenger error: 'Delegate GCed before client object']]].
			needFinalization := false]

{ #category : 'enumeration' }
GbxServerMapTableSegment >> delegatesAndClientObjsDo: aBlock
	"For each entry I hold, evaluate the given two-argument block with arguments of the delegate and the client object.
	The delegate will not be nil, but the client object may be nil."
	"Sender must hold my session's accessProtect."

	1 to: 3072
		by: 3
		do: 
			[:keyIndex |
			(self basicAt: keyIndex) ~~ nil
				ifTrue: 
					[| delegate clientObj |
					clientObj := self basicAt: keyIndex + 1.
					clientObj == 0 ifTrue: [clientObj := nil].
					delegate := self basicAt: keyIndex + 2.
					delegate == 0 ifTrue: [delegate := nil].
					delegate ~~ nil ifTrue: [aBlock value: delegate value: clientObj]]]

{ #category : 'finalization' }
GbxServerMapTableSegment >> mourn
	"Sent in the VW high-priority finalization thread. Just record the fact that finalization is needed,
	the finalization will be done by another thread before replication."

	needFinalization := true

{ #category : 'primitives' }
GbxServerMapTableSegment >> beWeak: aBoolean
	"Determine whether the receiver references its contents weakly or not.
	 Answer the receiver's previous weakness state."
	<primitive: 467>

	^self primitiveFailed

{ #category : 'primitives' }
GbxServerMapTableSegment >> isWeak
	"Answer if the receiver references its contents weakly."
	<primitive: 465>

	^self primitiveFailed

{ #category : 'primitives' }
GbxServerMapTableSegment >> indexOf: oldValue replaceWith: newValue startingAt: startIndex stoppingAt: stopIndex
	"Searches the specified portion of the receiver for the first reference 
	to oldValue, replacing that reference with newValue, and answers
	the 1-based index at which the oldValue was found. Zero is returned if
	the oldValue cannot be found. The search is restricted to and inclusive
	of the specified start and stop indices. The primitive fails if the start and
	stop indices are not SmallIntegers or if either is out of range."
	<primitive: 422>

	self primitiveFailed

{ #category : 'initialize-release' }
GbxServerMapTableSegment >> initialize

	needFinalization := false.
	self beWeak: parent isWeak.

{ #category : 'private-auditing' }
GbxServerMapTableSegment >> auditUsedElementKey: key client: client delegate: del into: results session: aSession
	"Element is used (valid key) but may have unfinalized tombstone for client and/or delegate.
	Things checked here:
	* all used elements have keys that are SmallIntegers in the correct range (1 to 2**24, inclusive)
	* no used element should have a delegate or special for a client object
	* each used element has the correct delegate, or 0
	* each used element that has a valid client object should also have a valid delegate"

	results
		assert: (key isInteger and: [key between: 1 and: 2 ** 24])
		node: self
		description: 'found key  %1, expected %2.'
		actual: key
		expected: 'SmallInteger between 1 and 2**24, inclusive'.
	results
		assert: (client == nil or: 
					[client == 0 or: 
							[client gbxIsProxy
								or: [client isGSObject not and: [(client gbxIsServerSpecialInSession: aSession) not]]]])
		node: self
		description: 'found client object %1, expected %2.'
		actual: client
		expected: 'any object neither a delegate nor an object having immediate format on the server'.
	results
		assert: (del == 0 or: [del isKindOf: GbxDelegate])
		node: self
		description: 'Found non-delegate %1 in delegate slot, expected %2.'
		actual: del
		expected: 'an instance of a GbxDelegate subclass'.
	del == 0
		ifTrue: 
			[results
				assert: (client == 0 or: [client == nil])
				node: self
				description: 'Found valid client object %1 when delegate was 0, expected %2.'
				actual: client
				expected: 'nil or 0'].
	(del isKindOf: GbxDelegate)
		ifTrue: 
			[results
				assert: del oopNumberHighBytes = upperBytes
				node: self
				description: 'Found delegate with upperBytes %1, expected %2.'
				actual: del
				expected: upperBytes printString.
			results
				assert: del oopNumberLower3 = (key - 1)
				node: self
				description: 'Found delegate with lower bytes %1, expected %2.'
				actual: del
				expected: (key - 1) printString]

{ #category : 'private-auditing' }
GbxServerMapTableSegment >> auditParentage: expectedParent index: expectedParentIndex upperBytes: expectedUpperBytes into: results
	"Things checked here:
	* my parent and index agree with those passed in
	* my upperBytes is the same as my parent's
	* needFinalization is a boolean
	* my basic size is correct"

	results
		assert: parent == expectedParent
		node: self
		description: 'parent  %1, expected %2.'
		actual: (Array with: parent with: parent identityHash)
		expected: expectedParent printString
				, expectedParent identityHash printString.
	results
		assert: parentIndex == expectedParentIndex
		node: self
		description: 'parentIndex=%1, expected %2'
		actual: parentIndex
		expected: expectedParentIndex printString.
	results
		assert: upperBytes == expectedUpperBytes
		node: self
		description: 'upperBytes=%1, expected %2'
		actual: upperBytes
		expected: expectedUpperBytes printString.
	results
		assert: (needFinalization == true or: [needFinalization == false])
		node: self
		description: 'needFinalization=%1, expected %2'
		actual: needFinalization
		expected: 'a boolean'.
	results
		assert: self basicSize == 3072
		node: self
		description: 'segment basicSize=%1, expected %2'
		actual: self basicSize
		expected: '3072'

{ #category : 'private-auditing' }
GbxServerMapTableSegment >> auditElementsInto: results session: aSession
	"Things checked here:
	* all used elements have keys that are SmallIntegers in the correct range (1 to 2**24, inclusive)
	* all unused elements have nil keys
	* no used element should have a delegate or special for a client object
	* each used element has the correct delegate, or 0
	* each used element that has a non-zero client object should also have a non-zero delegate
	* each unused element should have a nil delegate and a nil clientObj"

	| numUsedElements |
	numUsedElements := 0.
	1 to: 3070
		by: 3
		do: 
			[:i |
			| key client del |
			key := self basicAt: i.
			client := self basicAt: i + 1.
			del := self basicAt: i + 2.
			key == nil
				ifTrue: [self auditNilElementClient: client delegate: del into: results]
				ifFalse: 
					[numUsedElements := numUsedElements + 1.
					self
						auditUsedElementKey: key
						client: client
						delegate: del
						into: results
						session: aSession]].
	results addUsedElements: numUsedElements

{ #category : 'private' }
GbxServerMapTableSegment class >> instanceBasicSize

	^3072

{ #category : 'private' }
GbxServerMapTableSegment class >> gbxShouldMournEarly
	"GBS private. Answer true if my instances implement #mourn in a trivial manner that cannot block or error, 
	and it is important that all of them be mourned before any normal mourning is done."

	^true

