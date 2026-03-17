Class {
	#name : #'GbxLargeIdentityDictionary',
	#superclass : #'GbxLargeIdentityKeyedCollection',
	#instVars : [ #'weakness' #'numElements' #'buckets' #'accessProtect' #'removalSelector' #'reduceAfter' #'initialBucketSize' #'bucketSlotsGrown' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'protection' }
GbxLargeIdentityDictionary >> writeCritical: aBlock

	"The accessProtect semaphore is used for protection against
	 multiple threaded access to this instance. All writes are done
	 synchronously, and only after reads have finished."

	^accessProtect critical: aBlock

	"This can offer a performance boost when a series of
	 operations will be performed."

{ #category : #'protection' }
GbxLargeIdentityDictionary >> readCritical: aBlock
	"#readCritical: differs from #writeCritical: in that it may allow
	 Asynchronous reads so long as a write is not in progress
	 by another process.	 This can offer a performance boost
	 when a series of reads will be performed."

	^self useResurrectionAvoidance
	ifFalse: [ accessProtect critical: aBlock ]
	ifTrue:  [ accessProtect critical: [self finalizeCritical: aBlock] ]

{ #category : #'accessing' }
GbxLargeIdentityDictionary >> bucketSlotsGrown
	"This isn't a measure of the total items in buckets or the total number
	 of bucket slots. This is the total number of slots that all buckets have
	 grown."

	^bucketSlotsGrown

{ #category : #'accessing' }
GbxLargeIdentityDictionary >> initialBucketSize

	^initialBucketSize

{ #category : #'accessing' }
GbxLargeIdentityDictionary >> numElements: anObject
	^numElements := anObject

{ #category : #'accessing' }
GbxLargeIdentityDictionary >> numElements

	^numElements

{ #category : #'accessing' }
GbxLargeIdentityDictionary >> unmatchedPairs

	"Answer the number of key/value pairs where either
	 the key of the value is considered empty--but not both.
	 This is used for debugging only. Finalization temporarily
	 causes unmatched pairs."

	| count |
	count := super unmatchedPairs.
	self bucketsDo: [:b | count := count + b unmatchedPairs ].
	^count

{ #category : #'accessing' }
GbxLargeIdentityDictionary >> observedBucketSlotsAllocated
	"Answer the true number of collisions for the receiver.
	 Note: This number can become quickly out of date due to finalization."

	| count |
	count := 0.
	self bucketsDo: [:bucket | count := count + bucket tableSize].
	^count

{ #category : #'accessing' }
GbxLargeIdentityDictionary >> observedBucketSlotsGrown
	"Answer the true number of collisions for the receiver.
	 Note: This number can become quickly out of date due to finalization."

	| count |
	count := 0.
	self bucketsDo: [:bucket | count := count + bucket tableSize - initialBucketSize].
	^count

{ #category : #'accessing' }
GbxLargeIdentityDictionary >> primBuckets

	^buckets

{ #category : #'accessing' }
GbxLargeIdentityDictionary >> allUnmatched

	"This is used for debugging. It shows unmatched pairs
	 in a more inspectable form."

	| oc |
	oc := OrderedCollection new: self tableSize.
	1 to: self tableSize do: [:i |
		| aKey aValue |
		aKey := keys at: i.
		aValue := values at: i.
		(nil == aKey and: [nil == aValue]) ifFalse: [
			| aBucket bucketContents |
			bucketContents := nil == (aBucket := buckets at: i)
				ifTrue: [ nil ]
				ifFalse: [aBucket allUnmatched].
			oc add: (Array with: i with: aKey with: aValue with: bucketContents)
		].
	].
	^oc asArray

{ #category : #'accessing' }
GbxLargeIdentityDictionary >> at: aKey otherwise: otherwiseObject

	"Return the value that corresponds to aKey.  If no such key/value
	 pair exists, return otherwiseObject."

	^self readCritical: [ self basicAt: aKey otherwise: otherwiseObject ].

{ #category : #'accessing' }
GbxLargeIdentityDictionary >> sizeEstimate

	"Returns the number of key/value pairs in the receiver. Due to
	 finalization in weak arrays, numElements may be temporarily
	 larger than the actual number of pairs. Consider this value to
	 be an estimate but don't allow a negative number."

	^0 max: numElements

{ #category : #'accessing' }
GbxLargeIdentityDictionary >> bucketDistribution

	"Answer a bag populated with the sizes of all the buckets
	 in the receiver. For statistics only."

	| bag |
	bag := Bag new.
	self bucketsDo: [:bucket | bag add: bucket tableSaturation ].
	^bag

{ #category : #'accessing' }
GbxLargeIdentityDictionary >> weakness
	"Answer either nil,  #KEYS, or #VALUES."

	^weakness

{ #category : #'accessing' }
GbxLargeIdentityDictionary >> tableSaturation

	"Answer the number table slots that are populated with
	 anything--even if unbalanced due to finalization."

	| count bucket |
	count := 0.
	1 to: self tableSize do: [:i |
		(nil == (keys at: i) and: [nil == (values at: i)])
			ifFalse: [count := count + 1].
		nil == (bucket := buckets at: i)
			ifFalse: [count := count + bucket tableSaturation].
	].
	^count

{ #category : #'testing' }
GbxLargeIdentityDictionary >> basicHasValidSize
	"Answer boolean whether the value of numElements and
	 bucketSlotsGrown agrees with the number observed."

	| sizeStored sizeObserved storedBucketSlotsGrown observedBucketSlotsGrown inFinalization |
	self readCritical: 
			[sizeObserved := self sizeObserved.
			sizeStored := self numElements.
			observedBucketSlotsGrown := self observedBucketSlotsGrown.
			storedBucketSlotsGrown := self bucketSlotsGrown.
			inFinalization := self unmatchedPairs].
	sizeStored - inFinalization = sizeObserved ifFalse: [^false].
	storedBucketSlotsGrown = observedBucketSlotsGrown ifFalse: [^false].
	^true

{ #category : #'testing' }
GbxLargeIdentityDictionary >> hasWeakKeys

	^weakness == #KEYS

{ #category : #'testing' }
GbxLargeIdentityDictionary >> hasWeakValues

	^weakness == #VALUES

{ #category : #'initialization' }
GbxLargeIdentityDictionary >> reductionDenominator
	"Answer a number that will be used as the divisor for calculating
	 the number of bucket removals that must be done before #reduceBuckets
	 is sent. A higher value reduces buckets more frequently than a lower number."

	^12

{ #category : #'initialization' }
GbxLargeIdentityDictionary >> seekOptimalTableSize
	"Maintain an optimal size for the receiver. A smaller than optimal
	 size affects performance because of slow bucket access; however,
	 regrowth has a large immediate performance cost.

	Sender must hold my accessProtect."

	self rebuildTable: numElements * 2 mustRehash: false

{ #category : #'initialization' }
GbxLargeIdentityDictionary >> basicRebuildTable: proposedSize mustRehash: mustRehash 
	"Rebuilds the hash table by saving the current state, initializing and
	 changing the size of the table, and adding the key value pairs saved
	 back to the dictionary.

	If mustRehash is true, force a rebuild even if the new size 
	will be equal to the current size..

	Sender must hold my accessProtect"

	| holderStream newTableSize count |
	count := 0.
	newTableSize := self tableSizeFrom: (proposedSize max: self sizeEstimate).
	(mustRehash or: [newTableSize ~= tableSize]) ifFalse: [^self].
	initialBucketSize := 3 max: proposedSize // newTableSize.
	holderStream := ReadWriteStream on: (Array new: (self size + 50) * 2).
	self keysAndValuesDo: 
			[:aKey :aValue | 
			count := count + 1.
			holderStream
				nextPut: aKey;
				nextPut: aValue].
	self initializeTableSize: newTableSize.
	holderStream reset.
	count 
		timesRepeat: [self basicRegularAt: holderStream next put: holderStream next]

{ #category : #'initialization' }
GbxLargeIdentityDictionary >> accessProtector
	"Answer nil or a semaphore used to serialize access to
	 the receiver."

	^accessProtect

{ #category : #'initialization' }
GbxLargeIdentityDictionary >> selectedPrimes
	"Initialize selected prime numbers table.  This contains selected prime
	 numbers up to ~2^20.  In the interest of space and speed, it doesn't contain all
	 prime numbers within this range, but ones close to 2^(n/2) where n<40.
	The upper limit of 2^20 was chosen because 64-bit VW has 20-bit identity hash values. 
	When possible, the tableSize of
	 instances of this class will be selected from this list to improve
	 hashing characteristics."

	^#(43 61 89 127 181 257 367 521 739 1049 1481 2099 2963 4201 5927 8419 11863 16843 23741 33703 47491 67409 94993 134837 189989 269683 379979 539389 759959)

	"This computes the 'ideal' values that we want to pick primes close to:
	(11 to: 39) collect: [:e | 2**(e / 2.0)]
	"

	"Used to ensure numbers are primes (the hard way)."
	"	do: 
			[:prime | 
			2 to: (prime - 1 min: 2 ** 10)
				do: 
					[:int | 
					0 = (prime \\ int) 
						ifTrue: 
							[self gbsMessenger 
								error: '%1 is not prime because it is divisible by %2.'
								with: prime
								with: int]]]

		"

	"The following tests to see that each prime in the list is less than double the one two later,
	so that growing will consistently approximately double the size once it gets into the sequence.

| primes |
primes := GbxLargeIdentityDictionary new selectedPrimes.
1 to: primes size - 2
	do: 
		[:i | 
		| prime aBitMoreThanDoublePrime |
		prime := primes at: i.
		aBitMoreThanDoublePrime := primes at: i + 2.
		prime * 2 > aBitMoreThanDoublePrime 
			ifTrue: 
				[self gbsMessenger 
					error: '%1 is greater than half of %2'
					with: prime
					with: aBitMoreThanDoublePrime]]
"

{ #category : #'initialization' }
GbxLargeIdentityDictionary >> tableSizeFrom: aSize 
	"Return an integer such that it is >= to aSize, and either:
		 a) it is from our table of selected prime numbers, or
		 b) it is equal to the maximumTableSize"

	| bot top stab aPrime primes |
	primes := self selectedPrimes.
	top := primes size.
	aSize > (primes at: top) 
		ifTrue: 
			["It doesn't help to exceed hashing limits."

			^(primes at: top) min: self maximumTableSize].
	bot := 0.
	
	["Binary search for closest SelectedPrime that is >= aSize"

	stab := (top + bot) // 2.
	aPrime := primes at: stab.
	aSize <= aPrime ifTrue: [top := stab] ifFalse: [bot := stab].
	top - bot > 1] 
			whileTrue: [].
	^(primes at: top) min: self maximumTableSize

{ #category : #'initialization' }
GbxLargeIdentityDictionary >> initializeTableSize: size 
	"Initialize for capability of storing size key/value pairs

	Sender must hold my accessProtect."

	"self gbsMessenger
		comment: 'Resizing %1 containing %2 from %3 to %4.'
		with: self class
		with: numElements
		with: tableSize
		with: size.
	"

	[self hasCriticalAccess] gbxAssertEquals: true
		message: 'Critical access is required for structural cache changes.'.
	numElements := 0.
	bucketSlotsGrown := 0.
	super initializeTableSize: size.
	reduceAfter := (tableSize max: numElements) // self reductionDenominator.
	buckets isNil 
		ifFalse: [buckets do: [:b | b isNil ifFalse: [b owner: nil]]].
	buckets := Array new: size	"Must come after super init..."

{ #category : #'initialization' }
GbxLargeIdentityDictionary >> rebuildTable: proposedSize mustRehash: mustRehash 
	"Rebuild the hash table by saving the current state, initializing
	 and changing the size of the table, and adding the key value
	 pairs saved back to the hash dictionary. This must be executed
	 within the scope of a #writeCritical: block."

	"This indirection allows for platform specific overrides
	 of rebuildTable: while still allowing subclasses to
	 override the portable details of how to do so.

	Sender must hold my accessProtect"

	self gbsMessenger 
		statusTag: #rebuildTable
		message: 'GbxLargeDictionary (%1) rebuildTable: %2 rehashing: %3'
		with: self
		with: proposedSize
		with: mustRehash.
	self writeCritical: 
			[(GbsConfiguration current assertionChecks and: [mustRehash not]) 
				ifTrue: [self auditHashing].
			super rebuildTable: proposedSize mustRehash: mustRehash]

{ #category : #'initialization' }
GbxLargeIdentityDictionary >> changeBucketSlotGrowthBy: sizeChange

	bucketSlotsGrown := bucketSlotsGrown + sizeChange.

{ #category : #'initialization' }
GbxLargeIdentityDictionary >> deepCopy
	| copy |
	self readCritical: 
			[copy := (self shallowCopy)
						initializeTableSize: self tableSize;
						yourself.
			self 
				keysAndValuesDo: [:aKey :aValue | copy basicRegularAt: aKey copy put: aValue copy]].
	^copy

{ #category : #'initialization' }
GbxLargeIdentityDictionary >> initializeWeakness: aSymbolOrNil size: proposedSize 
	| newTableSize |
	newTableSize := self tableSizeFrom: proposedSize.
	initialBucketSize := 3 max: proposedSize // newTableSize.
	accessProtect := GbxRecursionLock forMutualExclusion.
	"It's not strictly necessary to do the following in a critical block,
	since no references to the new object have been handed out yet,
	but it's good form."
	self writeCritical: 
			[self
				weakness: aSymbolOrNil;
				initializeTableSize: newTableSize]

{ #category : #'initialization' }
GbxLargeIdentityDictionary >> recount

	"If the maintained count values are out of sync, then this will
	 return them to the correct values."

	accessProtect critical: [
		numElements := self tableSaturation.
		bucketSlotsGrown := self observedBucketSlotsGrown.
	].

{ #category : #'initialization' }
GbxLargeIdentityDictionary >> reduceAfter

	^reduceAfter

{ #category : #'enumeration' }
GbxLargeIdentityDictionary >> basicKeysAndValuesDo: twoArgBlock

	"For each key/value pair in the receiver, evaluate the two-argument
	 block aBlock with a key/value pair as the arguments."

	1 to: tableSize do: [ :tableIndex |
		| hashKey hashValue bucket |
		hashValue := self valueAt: tableIndex.
		hashKey := self keyAt: tableIndex.
		(hashKey == nil or: [ nil == hashValue ])
			ifFalse: [ twoArgBlock value: hashKey value: hashValue ].
		(bucket := buckets at: tableIndex) isNil
			ifFalse: [ bucket keysAndValuesDo: twoArgBlock ]
	].

{ #category : #'enumeration' }
GbxLargeIdentityDictionary >> keysAndValuesDo: twoArgBlock

	"For each key/value pair in the receiver, evaluate the two-argument
	 block aBlock with a key/value pair as the arguments."

	self readCritical: [self basicKeysAndValuesDo: twoArgBlock]

{ #category : #'enumeration' }
GbxLargeIdentityDictionary >> bucketsDo: aBlock
	"Evaluate aBlock for each bucket that has been defined. Keep
	 in mind that not all elements are stored in buckets, most are
	 stored in the keys and values collections."

	buckets do: [:bucket | nil == bucket ifFalse: [aBlock value: bucket]]

{ #category : #'key comparing' }
GbxLargeIdentityDictionary >> compare: anObject with: anotherObject

	"Key comparison is based on identity, not equality"

	^anObject == anotherObject

{ #category : #'key comparing' }
GbxLargeIdentityDictionary >> species

	^IdentityDictionary

{ #category : #'removing' }
GbxLargeIdentityDictionary >> primRemoveKeySafelyAt: index 
	
	[keys at: index put: nil.
	values at: index put: nil.
	self decrementNumElements] 
			valueUnpreemptively

{ #category : #'removing' }
GbxLargeIdentityDictionary >> checkReduceBuckets
	"Private. Unnecessary buckets are periodically removed to
	 reduce memory consumption and maintain performance.
	 This method can be sent at times when cleanup is safe
	 to do--it would not be safe to cleanup as part of GC finalization.

	Sender must hold my accessProtect. This is checked with an assertion."

	[self hasCriticalAccess] gbxAssert.
	tableSize > ((numElements max: 100) * 10) 
		ifTrue: [self rebuildTable: numElements * 2 mustRehash: false].
	reduceAfter > 0 ifFalse: [self basicReduceBuckets]

{ #category : #'removing' }
GbxLargeIdentityDictionary >> basicRemoveKey: aKey otherwise: otherwiseObject 
	"Removes the key/value pair with key aKey from the receiver and returns the value
	 If no key/value pair is present with key aKey, return otherwiseObject.

	Sender must hold my accessProtect."

	| index bucket hashKey |
	index := self hashForKey: aKey.
	hashKey := self keyAt: index.
	(self compare: aKey with: hashKey) 
		ifTrue: 
			[| aValue |
			aValue := self valueAt: index.
			self primRemoveKeySafelyAt: index.
			self removedKey: hashKey value: aValue.
			(bucket := buckets at: index) isNil ifFalse: [bucket checkNecessity: true].
			self checkReduceBuckets.
			^aValue].
	(bucket := buckets at: index) isNil 
		ifFalse: [^bucket removeKey: aKey otherwise: otherwiseObject].
	"Key not found"
	^otherwiseObject

{ #category : #'removing' }
GbxLargeIdentityDictionary >> removedKey: keyOrNil value: valueOrNil 
	"Note: VW finalization doesn't allow you to know the object that was
	 finalized. Refer to additional notes in #removalSelector:.
	Note that the finalization thread does NOT acquire my accessProtect before sending this message.
	Explicit removal paths do acquire accessProtect."

	self gbsMessenger 
		statusTag: #removedKey:value:
		message: '%1 removedKey: %2 value: %3'
		with: self
		with: keyOrNil identityHash
		with: valueOrNil identityHash.

	"Note: If both key and value are nil then the current Process is likely the finalization process,
	 and another Process is explicitly moving or removing the key/value pair."
	(nil == owner 
		or: [nil == removalSelector or: [nil == keyOrNil and: [nil == valueOrNil]]]) 
			ifFalse: 
				[removalSelector isSymbol 
					ifTrue: 
						[owner 
							perform: removalSelector
							with: keyOrNil
							with: valueOrNil]
					ifFalse: [removalSelector value: keyOrNil value: valueOrNil]]

{ #category : #'removing' }
GbxLargeIdentityDictionary >> removedKey: keyOrNil value: valueOrNil from: aBucket
	"Notification that oldKey was removed from aBucket."

	self removedKey: keyOrNil value: valueOrNil.
	reduceAfter := reduceAfter - 1.

{ #category : #'removing' }
GbxLargeIdentityDictionary >> basicReduceBuckets
	"Private. Done periodically to remove buckets that are no longer
	 necessary due to bucket size reductions. Performance
	 degrades as the number of buckets increases.

	Sender must hold my accessProtect."

	reduceAfter := (tableSize max: numElements) // self reductionDenominator.
	self bucketsDo: [:bucket | bucket checkNecessity]

{ #category : #'removing' }
GbxLargeIdentityDictionary >> removeKey: aKey otherwise: otherwiseObject
	"Removes the key/value pair with key aKey from the receiver and returns the value
	 If no key/value pair is present with key aKey, return otherwiseObject."

	^accessProtect critical: [ self basicRemoveKey: aKey otherwise: otherwiseObject ]

{ #category : #'removing' }
GbxLargeIdentityDictionary >> removeUnnecessaryBucket: aBucket 
	"Notice given from aBucket that it thinks it is no longer necessary
	 and would like to disassociate itself with the receiver. A bucket
	 is no longer necessary when it contains 0 or 1 key/value pairs. Ensure
	 that if one pair remains that it is preserved.

	Sender must hold my accessProtect"

	| bucketOffset assoc |
	[self hasCriticalAccess] gbxAssertEquals: true
		message: 'Critical access is required for structural cache changes.'.
	bucketOffset := aBucket tableOffset.
	(buckets size >= bucketOffset and: [(buckets at: bucketOffset) == aBucket]) 
		ifFalse: [^self].
	(nil == (keys at: bucketOffset) and: [nil == (values at: bucketOffset)]) 
		ifTrue: 
			[assoc := aBucket removeFirstPair.
			assoc isNil 
				ifFalse: 
					[keys at: bucketOffset put: assoc key.
					values at: bucketOffset put: assoc value]].
	aBucket tableSaturation > 0 ifTrue: [^self].
	self 
		changeBucketSlotGrowthBy: (aBucket tableSize - initialBucketSize) negated.
	buckets at: bucketOffset put: nil.
	aBucket breakDependencies.
	aBucket owner: nil

{ #category : #'removing' }
GbxLargeIdentityDictionary >> removalSelector: aSymbolOrTwoArgBlock
	"Set the two argument selector that will be sent to the owner with
	 removed key and value as arguments. VW doesn't allow you to
	 know the object finalized, so expect nil as one of the arguments.
	 Be careful not to resurrect a finalized object using VA."

	removalSelector := aSymbolOrTwoArgBlock.

{ #category : #'removing' }
GbxLargeIdentityDictionary >> decrementNumElements
	numElements := numElements - 1

{ #category : #'private - accessing' }
GbxLargeIdentityDictionary >> basicAt: aKey otherwise: otherwiseObject 
	"Return the value that corresponds to aKey.  If no such key/value
	 pair exists, return otherwiseObject.

	Sender must hold my accessProtect."

	| index hashKey bucket |
	nil == aKey ifTrue: [^otherwiseObject].
	index := self hashForKey: aKey.
	hashKey := keys at: index.
	(hashKey == nil or: [hashKey == 0]) 
		ifFalse: 
			[(self compare: aKey with: hashKey) 
				ifTrue: 
					[| hashValue |
					hashValue := values at: index.
					(hashValue == nil or: [hashValue == 0]) ifFalse: [^hashValue]
					"self unbalancedPairAt: index."]].
	(bucket := buckets at: index) == nil 
		ifFalse: [^bucket at: aKey otherwise: otherwiseObject].
	^otherwiseObject

{ #category : #'finalization' }
GbxLargeIdentityDictionary >> hasCriticalAccess
	"Answer whether the active process can access this dictionary right now"

	^accessProtect isActiveProcessInCriticalRegion

{ #category : #'private' }
GbxLargeIdentityDictionary >> weakness: aSymbol

	(#(nil KEYS VALUES) includes: aSymbol)
		ifFalse: [self gbsMessenger error: 'Invalid weakness setting'].
	(keys == nil and: [values == nil])
		ifFalse: [self gbsMessenger error: 'Improper use. Can only be set before initialization.'].
	weakness := aSymbol.

{ #category : #'inspecting' }
GbxLargeIdentityDictionary >> statistics

	"Returns a Dictionary containing statisitics that can be useful
	 in determining the performance of a hash dictionary.  The following
	 information is returned:

		TotalCollisionBuckets
			The number of collision buckets required to implement the
			hash dictionary.

	     AveragePairsPerBucket
			The average number of key/value pairs in each bucket.

	     LargestBucket
			The bucket having the most key/value pairs.  This bucket
			contains the most keys for which the hash function did not
			provide a good distribution over the range of values in the
			table.  "

	| bktCount pairCount maxBktSize |
	bktCount := 0.
	pairCount :=0.
	maxBktSize := 0.
	1 to: self tableSize do: [ :tableIndex |
		| hashKey collisionBkt |
		hashKey := self keyAt: tableIndex.
		collisionBkt := buckets at: tableIndex.
		(hashKey isNil and: [collisionBkt notNil]) ifTrue: [
			bktCount := bktCount + 1.
			pairCount := pairCount + collisionBkt sizeEstimate.
			(collisionBkt sizeEstimate > maxBktSize)
				ifTrue: [maxBktSize := collisionBkt sizeEstimate].
		].
	].
	^Dictionary new
		at: #TotalCollisionBuckets put: bktCount;
		at: #AveragePairsPerBucket put: (bktCount > 0 ifTrue: [pairCount // bktCount] ifFalse: [0]);
		at: #LargestBucket put: maxBktSize;
		at: #tableSize put: self tableSize;
		at: #TheDictionary put: self;
		yourself

{ #category : #'inspecting' }
GbxLargeIdentityDictionary >> auditHashing
	"Private. Items are added to the caches at certain index positions based on
	 a computed value. If the computed value for an object changes over time
	 then the object may considered missing from the cache even though it
	 is still there. This checks to see if any object hash values have changed
	 since being added."

	"
		| failure |
		failure :=	GBSM stObjectCache auditHashing.
		failure := failure | GBSM basicUnexportScheduler auditHashing.
		GBSM sessions do: [:ea | failure := failure | ea gsObjectCache auditHashing ].
		^failure
	"

	^self readCritical: 
			[| failure |
			failure := false.
			1 to: keys size
				do: 
					[:index | 
					| key properIndex cls |
					key := self keyAt: index.
					key == nil 
						ifFalse: 
							[properIndex := self hashForKey: key.
							properIndex = index 
								ifFalse: 
									[failure := true.
									self gbsMessenger 
										failure: 'Cache hash error: An instance of a %1 with identityHash %2 was stored in slot %3 instead of %4.'
										with: ((cls := key gbxBasicClass) == Metaclass 
												ifTrue: [key name , ' metaclass']
												ifFalse: [cls])
										with: key identityHash
										with: index
										with: properIndex]].
					(buckets at: index) isNil 
						ifFalse: [failure := (buckets at: index) auditHashing | failure]].
			failure]

{ #category : #'inspecting' }
GbxLargeIdentityDictionary >> gbxDebugPrintOn: aStream
	"Print debug information for the receiver. Use the
	 #printOn: if there would be a delay in printing."

	(accessProtect respondsTo: #critical:unlessBlocked:) ifTrue: [
		accessProtect
			critical: [ self basicDebugPrintOn: aStream ]
			unlessBlocked: [ super printOn: aStream ].
	] ifFalse: [ super printOn: aStream ].

{ #category : #'inspecting' }
GbxLargeIdentityDictionary >> basicDebugPrintOn: aStream 
	| localCount obsa obsg tsat tpne bc bcu unmp obs |
	super printOn: aStream.
	aStream
		cr;
		tab;
		nextPutAll: 'size: '.
	(tsat := self tableSaturation) printOn: aStream.
	(tpne := self numElements) = tsat 
		ifFalse: 
			[aStream nextPutAll: '	 ('.
			tpne printOn: aStream.
			aStream nextPutAll: ' estimated)'].
	aStream
		cr;
		tab;
		nextPutAll: 'owner: '.
	self owner printOn: aStream.
	aStream
		cr;
		tab;
		nextPutAll: 'accessProtect: '.
	accessProtect printOn: aStream.
	obs := self sizeObserved.
	unmp := self unmatchedPairs.
	(obs = self numElements and: [unmp = 0]) 
		ifFalse: 
			[aStream
				cr;
				tab;
				nextPutAll: 'matched pairs: '.
			obs printOn: aStream.
			aStream nextPutAll: '  ('.
			unmp printOn: aStream.
			aStream nextPutAll: '  unmatched)'].
	obsa := self observedBucketSlotsAllocated.
	aStream
		cr;
		tab;
		nextPutAll: 'local table size: '.
	self tableSize printOn: aStream.
	aStream
		tab;
		nextPutAll: ' ('.
	((super tableSaturation * 1000 / self tableSize) truncated / 10) asFloat 
		printOn: aStream.
	aStream nextPutAll: ' % saturation)'.
	aStream
		cr;
		tab;
		nextPutAll: 'total slots: '.
	self tableSize + obsa printOn: aStream.
	aStream
		tab;
		nextPutAll: ' ('.
	((tsat * 1000 / (obsa + self tableSize)) truncated / 10) asFloat 
		printOn: aStream.
	aStream nextPutAll: ' % saturation)'.
	aStream
		cr;
		tab;
		nextPutAll: 'bucketSlotsAllocated: '.
	obsa printOn: aStream.
	aStream
		cr;
		tab;
		nextPutAll: 'initialBucketSize: '.
	self initialBucketSize printOn: aStream.
	aStream
		cr;
		tab;
		nextPutAll: 'bucketSlotsGrown: '.
	(obsg := self observedBucketSlotsGrown) printOn: aStream.
	self bucketSlotsGrown = obsg 
		ifFalse: 
			[aStream nextPutAll: '	 ('.
			self bucketSlotsGrown printOn: aStream.
			aStream nextPutAll: ' estimated)'].
	tableSize < self maximumTableSize 
		ifTrue: 
			[aStream nextPutAll: '	 (resize after '.
			self maximumBucketSlotGrowth printOn: aStream.
			aStream nextPutAll: ')'].
	bc := bcu := 0.
	buckets do: 
			[:ea | 
			nil == ea 
				ifFalse: 
					[bc := bc + 1.
					ea isNecessary ifFalse: [bcu := bcu + 1]]].
	aStream
		cr;
		tab;
		nextPutAll: 'total buckets: '.
	bc printOn: aStream.
	bcu = 0 
		ifFalse: 
			[aStream
				tab;
				nextPutAll: ' ('.
			bcu printOn: aStream.
			aStream nextPutAll: ' unnecessary)'].
	aStream
		cr;
		tab;
		nextPutAll: 'remove unnecessary buckets after '.
	reduceAfter printOn: aStream.
	aStream nextPutAll: ' removals'.
	tsat = 0 ifTrue: [tsat := 0.00000000001].	"Avoids division by zero."
	aStream
		cr;
		tab;
		nextPutAll: 'distribution: '.
	aStream
		cr;
		tab;
		tab;
		nextPutAll: 'local: '.
	(localCount := super tableSaturation) printOn: aStream.
	aStream
		tab;
		nextPutAll: ' ('.
	((localCount * 1000 / tsat) truncated / 10) asFloat printOn: aStream.
	aStream nextPutAll: ' %)'.
	self bucketDistribution gbsValuesAndCountsDo: 
			[:bucketSize :count | 
			aStream
				cr;
				tab;
				tab.
			count printOn: aStream.
			aStream nextPutAll: ' buckets containing '.
			bucketSize printOn: aStream.
			aStream
				tab;
				nextPutAll: ' ('.
			((count * bucketSize * 1000 / tsat) truncated / 10) asFloat 
				printOn: aStream.
			aStream nextPutAll: ' %)']

{ #category : #'adding' }
GbxLargeIdentityDictionary >> maximumBucketSlotGrowth
	"Bucket growth (not including initial size) is monitored, and only
	 so much growth is permitted until the hash table is grown."

	^(tableSize // 99) * initialBucketSize

{ #category : #'adding' }
GbxLargeIdentityDictionary >> isGrowthRecommended
	"Sender must hold my accessProtect"

	^tableSize < self maximumTableSize 
		and: [bucketSlotsGrown > self maximumBucketSlotGrowth]

{ #category : #'adding' }
GbxLargeIdentityDictionary >> at: aKey put: aValue 
	"Stores the aKey/aValue pair in the hash dictionary.  Rebuilds the
	 hash table if the addition caused the number of collisions to
	 exceed the limit allowed."

	accessProtect critical: 
			[self basicRegularAt: aKey put: aValue.
			self isGrowthRecommended ifTrue: [self seekOptimalTableSize]].
	^aValue

{ #category : #'adding' }
GbxLargeIdentityDictionary >> basicRegularAt: aKey put: aValue 
	"Stores the aKey/value pair in the dictionary.

	Sender must hold my accessProtect"

	| index hashValue hashKey aBucket numAdded |
	(nil == aKey or: [nil == aValue]) 
		ifTrue: [^self gbsMessenger error: 'Attempt to store nil key or value.'].
	index := self hashForKey: aKey.

	"Try local table first"
	hashKey := self keyAt: index.
	hashValue := self valueAt: index.
	nil == hashValue == (nil == hashKey) 
		ifFalse: 
			[self unbalancedPairAt: index.
			hashKey := self keyAt: index.
			hashValue := self valueAt: index.
			nil == hashValue == (nil == hashKey) 
				ifFalse: [nil == hashKey ifTrue: [hashKey := #ToAvoidWhileGC]]].
	nil == hashKey 
		ifTrue: 
			["It's an empty slot, but can't assume key isn't already in a bucket."

			nil == (buckets at: index) 
				ifTrue: 
					[
					[numElements := numElements + 1.
					keys at: index put: aKey.
					values at: index put: aValue] 
							valueUnpreemptively.
					^self]]
		ifFalse: 
			[(self compare: aKey with: hashKey) 
				ifTrue: 
					["Key already exists"

					| replacement |
					replacement := self 
								replacing: hashValue
								with: aValue
								forKey: aKey.
					self 
						replaceAt: index
						key: aKey
						value: replacement.
					^self]].

	"Wouldn't fit in local table, put it in a bucket."
	nil == (aBucket := buckets at: index) 
		ifTrue: [aBucket := self newBucketAt: index].
	numAdded := aBucket at: aKey put: aValue.

	"Make sure the bucket wasn't finalized while adding."
	aBucket == (buckets at: index) 
		ifTrue: [numElements := numElements + numAdded]
		ifFalse: [self basicRegularAt: aKey put: aValue]

{ #category : #'adding' }
GbxLargeIdentityDictionary >> replacing: oldValue with: newValue forKey: aKey
	"Private. Notification that a value is being replaced. Answer
	 an object to use as the newValue."

	^newValue

{ #category : #'adding' }
GbxLargeIdentityDictionary >> newBucketAt: index 
	"Sender must hold my accessProtect"

	| aBucket |
	aBucket := self class bucketClass 
				new: self initialBucketSize
				owner: self
				atOffset: index.
	buckets at: index put: aBucket.
	^aBucket

{ #category : #'instance creation' }
GbxLargeIdentityDictionary class >> new: tableSize

	"Return a new instance with an initial table size that allows room to add key/value pairs before having to rebuild the tables"

	^self basicNew
		initializeWeakness: nil
		size: tableSize

{ #category : #'instance creation' }
GbxLargeIdentityDictionary class >> newWeakValues: tableSize

	"Return a new instance with an initial table size that allows room to add key/value pairs before having to rebuild the tables"

	^self basicNew
		initializeWeakness: #VALUES
		size: tableSize

{ #category : #'instance creation' }
GbxLargeIdentityDictionary class >> new

	"Return a new instance with a minimal initial table size."

	^self new: 3

{ #category : #'instance creation' }
GbxLargeIdentityDictionary class >> newWeakKeys: tableSize

	"Return a new instance with an initial table size that allows room to add key/value pairs before having to rebuild the tables"

	^self basicNew
		initializeWeakness: #KEYS
		size: tableSize

{ #category : #'components' }
GbxLargeIdentityDictionary class >> bucketClass

	^GbxLargeIdentityDictionaryBucket

