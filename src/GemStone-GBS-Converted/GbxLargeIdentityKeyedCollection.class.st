Class {
	#name : 'GbxLargeIdentityKeyedCollection',
	#superclass : 'Object',
	#instVars : [
		'keys',
		'values',
		'owner',
		'tableSize'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> species

	"For VisualAge inspectors"
	^Dictionary

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> allUnmatched

	"This is used for debugging. It shows unmatched pairs
	 in a more inspectable form."

	| oc |
	oc := OrderedCollection new: self tableSize.
	1 to: self tableSize do: [:i |
		| aKey aValue |
		aKey := keys at: i.
		aValue := values at: i.
		(nil == aKey and: [nil == aValue])
			ifFalse: [oc add: (Array with: i with: aKey with: aValue)].
	].
	^oc asArray

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> owner

	^owner

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> size

	"Returns the number of key/value pairs in the receiver. Due to
	 finalization in weak arrays, numElements may be temporarily
	 larger than the actual number of pairs. Consider this value to
	 be an estimate."

	^self sizeEstimate

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> at: aKey otherwise: alternateValue
	^self subclassResponsibility

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> keys

	"Returns a collection containing the receiver's keys."

	| aCollection |

	aCollection := OrderedCollection new: self sizeEstimate.
	self keysDo: [ :each | aCollection add: each ].
	^aCollection

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> at: aKey ifAbsent: missingBlock

	"For compatibility with Dictionaries.
	 Should use #at:otherwise: instead."

	| answer |
	^NotCachedToken == (answer := self at: aKey otherwise: NotCachedToken)
		ifTrue: [missingBlock value]
		ifFalse: [ answer ].

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> tableSize
	"Could use either keys or values because they are both initialized
	 to the same size."

	^tableSize

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> sizeEstimate

	"Answer the number of key/value pairs where either
	 the key or the value is not nil. Unmatched pairs are
	 included in this count."

	^self tableSaturation

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> sizeObserved
	"Answer the true number of complete key/value pairs for the receiver.
	 Note: This number can become quickly out of date due to finalization."

	| count |
	count := 0.
	self keysDo: [:key | count := count + 1 ].
	^count

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> at: aKey

 	"Returns the value that corresponds to aKey."

	^self at: aKey ifAbsent: [self gbsMessenger error: 'Key not found' ]

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> values

	"Returns a collection containing the receiver's values."

	| answer |
	answer := OrderedCollection new: self sizeEstimate.
	self do: [ :each | answer add: each ].
	^answer

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> detect: aBlock ifNone: exceptionBlock
	"Evaluate aBlock with each of the receiver's elements as the argument.
	Answer the first element for which aBlock evaluates to true."

	self do: [:each | (aBlock value: each) ifTrue: [^each]].
	^exceptionBlock value

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> tableSaturation

	"Answer the number table slots that are populated with
	 anything--even if unbalanced due to finalization."

	| count |
	count := 0.
	1 to: self tableSize do: [:i |
		(nil == (keys at: i) and: [nil == (values at: i)])
			ifFalse: [count := count + 1].
	].
	^count

{ #category : 'accessing' }
GbxLargeIdentityKeyedCollection >> unmatchedPairs

	"Answer the number of key/value pairs where either
	 the key of the value is considered empty--but not both.
	 This is used for debugging only. Finalization temporarily
	 causes unmatched pairs."

	| count |
	count := 0.
	1 to: self tableSize do: [:i |
		(nil == (self keyAt: i)) == (nil == (self valueAt: i))
			ifFalse: [count := count + 1].
	].
	^count

{ #category : 'enumeration' }
GbxLargeIdentityKeyedCollection >> do: oneArgBlock
	"For each key/value pair in the receiver, evaluates the
	 one-argument block aBlock with the value as the argument."

	self keysAndValuesDo: [:key :value | oneArgBlock value: value ].

{ #category : 'enumeration' }
GbxLargeIdentityKeyedCollection >> associationsDo: aBlock

	"Iteratively evaluate the one argument aBlock using each
	 Association element of the receiver.

	 Fail if aBlock is not a one-argument Block
	 Fail if aBlock's body does not expect an Association as a parameter."

	self keysAndValuesDo: [:key :value |
		aBlock value: (Association key: key value: value)]

{ #category : 'enumeration' }
GbxLargeIdentityKeyedCollection >> keysAndValuesDo: twoArgBlock

	"For each key/value pair in the receiver, evaluate the two-argument
	 block aBlock with a key/value pair as the arguments."

	1 to: tableSize do: [ :tableIndex |
		| hashKey hashValue |
		hashValue := self valueAt: tableIndex.
		hashKey := self keyAt: tableIndex.
		(hashKey == nil or: [ nil == hashValue ])
		ifFalse: [ twoArgBlock value: hashKey value: hashValue ].
	].

{ #category : 'enumeration' }
GbxLargeIdentityKeyedCollection >> keysDo: oneArgBlock

	"For each key/value pair in the receiver, evaluates the
	 one-argument block aBlock with the key as the argument."

	self keysAndValuesDo: [:key :value | oneArgBlock value: key ].

{ #category : 'initialization' }
GbxLargeIdentityKeyedCollection >> valueClass

	nil == values ifFalse: [^values class].
	self hasWeakValues ifFalse: [^Array].
	^self weakArrayClass

{ #category : 'initialization' }
GbxLargeIdentityKeyedCollection >> rebuildTable: proposedSize mustRehash: mustRehash 
	"Rebuild the hash table by saving the current state, initializing
	 and changing the size of the table, and adding the key value
	 pairs saved back to the hash dictionary. If mustRehash is true, 
	do this even if the new table size will be equal to the old table size"

	"This indirection allows for platform specific overrides
	 of rebuildTable: while still allowing subclasses to
	 override the portable details of how to do so.

	Sender must hold my accessProtect."

	self gbsMessenger 
		statusTag: #rebuildTable
		message: 'GbxLargeKeyedCollection (%1) rebuildTable: %2 rehashing: %3'
		with: self
		with: proposedSize
		with: mustRehash.
	self basicRebuildTable: proposedSize mustRehash: mustRehash

{ #category : 'initialization' }
GbxLargeIdentityKeyedCollection >> owner: anObject

	owner := anObject

{ #category : 'initialization' }
GbxLargeIdentityKeyedCollection >> keyClass
	nil == keys ifFalse: [^keys class].
	self hasWeakKeys ifFalse: [^GbxArray].
	^self weakArrayClass

{ #category : 'initialization' }
GbxLargeIdentityKeyedCollection >> initializeTableSize: newTableSize 
	"Initialize for capability of storing size key/value pairs"

	| oldKeys oldValues |
	oldKeys := keys.
	oldValues := values.
	keys := self keyClass new: newTableSize.
	values := self valueClass new: newTableSize.
	tableSize := newTableSize.

	"We need to break the dependencies among the old buckets and
	the receiver.  If we don't, WeakArrays in the old buckets might
	try to finalize."
	self hasWeakKeys 
		ifTrue: 
			[keys addDependent: self.
			nil == oldKeys ifFalse: [oldKeys removeDependent: self]].
	self hasWeakValues 
		ifTrue: 
			[values addDependent: self.
			nil == oldValues ifFalse: [oldValues removeDependent: self]]

{ #category : 'initialization' }
GbxLargeIdentityKeyedCollection >> breakDependencies

	"Remove dependencies (disabling finalization)"

	self hasWeakKeys ifTrue: [ keys removeDependent: self ].
	self hasWeakValues ifTrue: [ values removeDependent: self ].

{ #category : 'initialization' }
GbxLargeIdentityKeyedCollection >> weakArrayClass
	"Answer a dialect specific class that has the protocol of
	 an Array, but has weak references to elements."

	^self class weakArrayClass

{ #category : 'initialization' }
GbxLargeIdentityKeyedCollection >> basicRebuildTable: newSize mustRehash: rehashingBool
	"Rebuilds the hash table by saving the current state, initializing and
	 changing the size of the table, and adding the key value pairs saved
	 back to the dictionary."

	self subclassResponsibility

{ #category : 'testing' }
GbxLargeIdentityKeyedCollection >> hasWeakKeys
	^self subclassResponsibility

{ #category : 'testing' }
GbxLargeIdentityKeyedCollection >> isEmpty

	"Returns true if there are no key/value pairs in the receiver.
	Otherwise, returns false."

	^1 > self sizeEstimate

{ #category : 'testing' }
GbxLargeIdentityKeyedCollection >> includesKey: aKey

	"Returns true if the receiver contains a key that is equal to aKey, otherwise returns false"

	^NotCachedToken ~~ (self at: aKey otherwise: NotCachedToken)

{ #category : 'testing' }
GbxLargeIdentityKeyedCollection >> hasWeakValues
	^self subclassResponsibility

{ #category : 'testing' }
GbxLargeIdentityKeyedCollection >> includes: anObject

	self do: [:each | each = anObject ifTrue: [^true]].
	^false

{ #category : 'testing' }
GbxLargeIdentityKeyedCollection >> notEmpty

	^self isEmpty not

{ #category : 'finalization' }
GbxLargeIdentityKeyedCollection >> encourageFinalization
	"VisualAge appears to only finalize WeakArray elements
	 after a GC (VW finalizes a little at a time as desired). This method
	 attempts to get the job done faster. This method doesn't always
	 clean everything up the first time in VA; it will complete early if the VA
	 finalizationQueue didn't include any objects we are interested in.
	 This can take several seconds to run, so use with care."

	| extraPasses startSize lastSize |
	extraPasses := 4.
	startSize := lastSize := self sizeEstimate.
	self encourageFinalizationWhile: [
		lastSize := self sizeEstimate.
		extraPasses := extraPasses - 1.
		(startSize - lastSize) > 0 ifTrue: [extraPasses := 3].
		startSize := lastSize.
		extraPasses > 0
	].

{ #category : 'finalization' }
GbxLargeIdentityKeyedCollection >> useResurrectionAvoidance
	"Answer true if it is possible for the VM in use to gain
	 a reference to an object that is queued for finalization. Answer
	 false for VW because items in weak arrays become 0 while
	 queued for finalization. Answer true for VA (only when
	 #hasWeakValues) to flush the finalization queue. Resurrection
	 avoidance isn't necessary for weak keys because we can
	 assume you have a strong reference to the key already."

	^false

{ #category : 'finalization' }
GbxLargeIdentityKeyedCollection >> dirtyDisable: aKey forValue: aValue
	"This is only useful for dialects that have immutability support."

	aValue isReadOnlyObject not ifTrue: [ aKey gbxIgnoreFutureChanges ].

{ #category : 'finalization' }
GbxLargeIdentityKeyedCollection >> encourageFinalizationWhile: aBlock 
	"VisualAge VM appears to only finalize WeakArray elements
	 after a GC (VW finalizes a little at a time as desired). This method
	 attempts to get the job done faster. This method doesn't always
	 clean everything up the first time in VA; it will complete early if the VA
	 finalizationQueue didn't include any objects we are interested in.
	 This can take several seconds to run, so use with care."

	
	[self basicEncourageFinalization.
	GbsConfiguration isVisualAgeImage 
		ifTrue: [[Processor finalizeCycle] whileTrue: []]
		ifFalse: 
			[(GbxDelay forMilliseconds: 50) wait.
			Processor yield].
	aBlock value] 
			whileTrue: []

	"The GC, delay, and yield are all required. One missing, and nothing will
	 be finalized. A 50ms delay seems to give the best performance."

{ #category : 'removing' }
GbxLargeIdentityKeyedCollection >> removeKey: anObject

	^self removeKey: anObject ifAbsent: [self gbsMessenger error: 'Key not found']

{ #category : 'removing' }
GbxLargeIdentityKeyedCollection >> removedKey: keyOrNil value: valueOrNil

	self subclassResponsibility.

{ #category : 'removing' }
GbxLargeIdentityKeyedCollection >> removeKey: aKey ifAbsent: missingBlock

	"For compatibility with Dictionaries.
	 Should use #at:otherwise: instead."

	| answer |
	^NotCachedToken == (answer := self removeKey: aKey otherwise: NotCachedToken)
		ifTrue: [missingBlock value]
		ifFalse: [ answer ].

{ #category : 'removing' }
GbxLargeIdentityKeyedCollection >> basicClearForSession: session 
	"Private. 
	Remove all entries with values that are delegates in session.  If a
	 key is associated with more than one delegate value (via a GbxObjectList),
	 only the delegate associated with session is removed from that list,
	 and the key remains in the dictionary.  Invalidate the session id of all
	 delegate for session. This is only used by ST-->GS dictionaries,
	 but is implemented in a common superclass.

	Sender must hold my accessProtect."

	| aValue aKey observed |
	observed := 0.
	1 to: tableSize
		do: 
			[:index | 
			"This is a key/value pair"

			aValue := self valueAt: index.
			aKey := self keyAt: index.
			(aKey == nil or: [nil == aValue]) 
				ifFalse: 
					[| valueForSession newValue |
					nil == (valueForSession := aValue forSession: session) 
						ifFalse: [valueForSession setDeadSession].
					nil == (newValue := aValue notForSession: session) 
						ifTrue: 
							["This key is associated with one delegate, from session.
							 Disable auto-mark-dirty and remove the entry unless aKey
							 is a proxy. If it was a proxy then leave for GC cleanup."

							aKey gbxIsProxy 
								ifTrue: [observed := observed + 1]
								ifFalse: 
									[self dirtyDisable: aKey forValue: aValue.
									self primRemoveKeySafelyAt: index.
									self removedKey: aKey value: aValue]]
						ifFalse: 
							["This key is still associated with delegates from other session(s)."

							values at: index put: newValue.
							observed := observed + 1]]].
	^observed

{ #category : 'removing' }
GbxLargeIdentityKeyedCollection >> removeKey: aKey otherwise: alternateObject 
	^self subclassResponsibility

{ #category : 'key comparison' }
GbxLargeIdentityKeyedCollection >> hashForKey: aKey 
	"Return the hashed index into the receiver derived from aKey,
	based on its identity hash."

	^aKey identityHash \\ tableSize + 1

{ #category : 'key comparison' }
GbxLargeIdentityKeyedCollection >> compare: anObject with: anotherObject

	"Key comparison is based on equality"

	^anObject = anotherObject

{ #category : 'printing' }
GbxLargeIdentityKeyedCollection >> printOn: aStream

	aStream nextPutAll: 'a '.
	self class printOn: aStream.
	aStream nextPutAll: ' (id '.
	self identityHash printOn: aStream.
	aStream nextPutAll: ') with '.
	self sizeEstimate printOn: aStream.
	aStream nextPutAll: ' elements'

{ #category : 'converting' }
GbxLargeIdentityKeyedCollection >> asDictionary
	"Answer a dictionary populated with all items of the receiver."

	| answer |
	answer := self species new: self sizeEstimate.
	self keysAndValuesDo: [:key :value | answer at: key put: value ].
	^answer

{ #category : 'adding' }
GbxLargeIdentityKeyedCollection >> addAll: aDictionary

	"Store aDictionary values in the receiver at
	 the dictionary keys.

	 Answer aDictionary."

	aDictionary keysAndValuesDo: [:key :value |
		self at: key put: value].
	^aDictionary

{ #category : 'adding' }
GbxLargeIdentityKeyedCollection >> add: anAssociation

	"Adds the key/value pair found in the association"

	self at: anAssociation key put: anAssociation value.
	^anAssociation

{ #category : 'adding' }
GbxLargeIdentityKeyedCollection >> replaceAt: index key: aKey value: aValue
	"Private. VA overrides this method to do some finalization protection
	 while replacing data."

	keys at: index put: aKey.
	values at: index put: aValue.

