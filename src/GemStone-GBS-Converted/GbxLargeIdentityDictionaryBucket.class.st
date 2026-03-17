Class {
	#name : 'GbxLargeIdentityDictionaryBucket',
	#superclass : 'GbxLargeIdentityKeyedCollection',
	#instVars : [
		'tableOffset',
		'checkNecessity'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxLargeIdentityDictionaryBucket >> accessProtector
	"Answer the semaphore that controls access to the
	 receiver. A bucket uses the semaphore of the bucket owner."

	| myOwner |
	^(myOwner := owner) isNil
		ifTrue: [nil]
		ifFalse: [myOwner accessProtector].

{ #category : 'accessing' }
GbxLargeIdentityDictionaryBucket >> removeFirstPair
	"Returns an association containing the last remaining key/value pair, or nil if I have
	 no elements. This is executed as part of bucket removal.

	Sender must hold my owner's accessProtect"

	1 to: tableSize
		do: 
			[:index | 
			| aKey aValue |
			aValue := self valueAt: index.
			aKey := self keyAt: index.
			(nil == aKey or: [nil == aValue]) 
				ifFalse: 
					[keys at: index put: nil.
					values at: index put: nil.
					^Association key: aKey value: aValue]].
	^nil

{ #category : 'accessing' }
GbxLargeIdentityDictionaryBucket >> tableOffset
	"Answer the index position that the receiver can be found
	 within the dictionary for the bucket."

	^tableOffset

{ #category : 'key comparing' }
GbxLargeIdentityDictionaryBucket >> compare: anObject with: anotherObject

	"Key comparison is based on equality"

	^anObject == anotherObject

{ #category : 'initialization' }
GbxLargeIdentityDictionaryBucket >> initializeSize: initialSize owner: aWeakDictionary atOffset: offset

	"Initialize myself with enough growing room to hold numOfKeyValuePairs"

	owner := aWeakDictionary.
	tableOffset := offset.
	self initializeTableSize: initialSize.

{ #category : 'initialization' }
GbxLargeIdentityDictionaryBucket >> basicRebuildTable: newSize mustRehash: rehashingBool 
	"Rebuilds the hash table by saving the current state, initializing and
	 changing the size of the table, and adding the key value pairs saved
	 back to the dictionary.

	Sender must hold my accessProtect."

	| oldSize oldKeys oldValues |
	oldSize := tableSize.
	oldKeys := keys.
	oldValues := values.
	self initializeTableSize: newSize.
	self finalizeCritical: 
			[keys 
				replaceFrom: 1
				to: oldSize
				with: oldKeys.
			values 
				replaceFrom: 1
				to: oldSize
				with: oldValues]

{ #category : 'initialization' }
GbxLargeIdentityDictionaryBucket >> initializeTableSize: newTableSize
	"Initialize for capability of storing size key/value pairs"

	| oldSize |
	checkNecessity := false.
	oldSize := tableSize isNil ifTrue: [newTableSize] ifFalse: [tableSize].
	super initializeTableSize: newTableSize.
	owner changeBucketSlotGrowthBy: tableSize - oldSize.

{ #category : 'initialization' }
GbxLargeIdentityDictionaryBucket >> rehash
	"It is very likely that an item's new hash value wouldn't include it
	 in the bucket, so we need to rehash the bucket through the owner."

	owner rehash

{ #category : 'private' }
GbxLargeIdentityDictionaryBucket >> isNecessary
	"Answer boolean whether the bucket is necessary, but don't
	 do anything if it isn't necessary. This is useful for gathering
	 statistics."

	| sat |
	owner isNil ifTrue: [^false].
	checkNecessity ifFalse: [^true].
	sat :=self tableSaturation.
	sat = 0 ifTrue: [^false].
	sat > 1 ifTrue: [^true].
	"sat = 1"
	^nil ~~ (owner keyAt: tableOffset) and: [nil ~~ (owner valueAt: tableOffset)]

{ #category : 'private' }
GbxLargeIdentityDictionaryBucket >> writeCritical: aBlock
	"We remember the owner in case it is nilled by another process
	 between #isNil and #writeCritical:."

	| ownerWas |
	^(ownerWas := owner) isNil
		ifTrue: [ aBlock value ]
		ifFalse: [ ownerWas writeCritical: aBlock ]

{ #category : 'private' }
GbxLargeIdentityDictionaryBucket >> checkNecessity: aBool

	checkNecessity := aBool.

{ #category : 'private' }
GbxLargeIdentityDictionaryBucket >> auditHashing
	"Private. Items are added to the caches at certain index positions based on
	 a computed value. If the computed value for an object changes over time
	 then the object may considered missing from the cache even though it
	 is still there. This checks to see if any object hash values have changed
	 since being added."

	| failure |
	failure := false.
	1 to: keys size do: [:index |
		| key properIndex |
		key := self keyAt: index.
		key == nil ifFalse: [
			properIndex := owner hashForKey: key.
			properIndex = tableOffset ifFalse: [
				| cls |
				failure := true.
				self gbsMessenger
					failure: 'Cache hash error: An instance of a %1 with identityHash %2 was stored in bucket slot %3 instead of %4.'
					with: ((cls := key gbxBasicClass) == Metaclass ifTrue: [key name, ' metaclass'] ifFalse: [cls])
					with: key identityHash
					with: tableOffset
					with: properIndex.
			].
		].
	].
	^failure

{ #category : 'private' }
GbxLargeIdentityDictionaryBucket >> checkNecessity
	"Sender must hold my owner's accessProtect"

	checkNecessity ifFalse: [^self].
	self tableSaturation > 1 ifTrue: [^self].
	owner isNil ifTrue: [^self].
	owner removeUnnecessaryBucket: self

{ #category : 'private' }
GbxLargeIdentityDictionaryBucket >> basicAt: aKey replacement: newValue 
	"Private. This does a low-level unprotected replacement of a
	 value. Use with care. Ignore replacement if key doesn't
	 exist--due to finalization.

	Sender must hold my owner's accessProtect."

	| index |
	(index := self indexOf: aKey) == nil 
		ifFalse: [values at: index put: newValue]

{ #category : 'testing' }
GbxLargeIdentityDictionaryBucket >> hasWeakValues

	^owner hasWeakValues

{ #category : 'testing' }
GbxLargeIdentityDictionaryBucket >> valueClass

	^owner valueClass

{ #category : 'testing' }
GbxLargeIdentityDictionaryBucket >> keyClass

	^owner keyClass

{ #category : 'testing' }
GbxLargeIdentityDictionaryBucket >> hasWeakKeys

	^owner hasWeakKeys

{ #category : 'removing' }
GbxLargeIdentityDictionaryBucket >> removedKey: keyOrNil value: valueOrNil
	"Inform GemStone that there is no longer a reference to anOop in the GSI cache.
	 Great care must be taken here to avoid a nil owner because this is sent
	 by finalization which is allowed to operate concurrently."

	| ownerWas |
	checkNecessity := true.
	nil == (ownerWas := owner)
		ifFalse: [ownerWas removedKey: keyOrNil value: valueOrNil from: self].

{ #category : 'removing' }
GbxLargeIdentityDictionaryBucket >> primRemoveKeySafelyAt: index 
	
	[keys at: index put: nil.
	values at: index put: nil.
	owner isNil ifFalse: [owner decrementNumElements]] 
			valueUnpreemptively

{ #category : 'removing' }
GbxLargeIdentityDictionaryBucket >> basicClearForSession: aSession 
	"Private. Sender must hold my accessProtect. 
	Remove all entries with values that are delegates in aGSSession.  If a
	 key is associated with more than one delegate value (via a GSObjectList),
	 only the delegate associated with aGSSession is removed from that list,
	 and the key remains in the dictionary.  Invalidate the session id of all
	 delegates for aGSSession."

	| observed |
	observed := super basicClearForSession: aSession.
	checkNecessity := observed < 2.
	^observed

{ #category : 'removing' }
GbxLargeIdentityDictionaryBucket >> removeKey: aKey otherwise: otherwiseObject 
	"Removes the key/value pair with key aKey from the receiver and returns the value
	 If no key/value pair is present with key aKey, return otherwiseObject.

	Sender must hold my accessProtect."

	| keyIndex aValue |
	(keyIndex := self indexOf: aKey) == nil ifTrue: [^otherwiseObject].
	aValue := self valueAt: keyIndex.
	self primRemoveKeySafelyAt: keyIndex.
	self removedKey: aKey value: aValue.
	owner checkReduceBuckets.
	^aValue

{ #category : 'finalization' }
GbxLargeIdentityDictionaryBucket >> weakness
	"Answer either nil,  #KEYS, or #VALUES."

	^owner weakness

{ #category : 'adding' }
GbxLargeIdentityDictionaryBucket >> at: aKey put: aValue 
	"Stores the aKey/aValue pair in the receiver.  Returns the number of elements
	 actually added to the 'size' of the receiver, 0 or 1.  If the key already exists, the
	 value of existsPutBlock, with the old value as its argument, is the new value to
	 be put."

	"Sender must hold my owner's accessProtect."

	| insertIndex replacement |
	0 > (insertIndex := self indexFor: aKey) 
		ifTrue: 
			[insertIndex := insertIndex negated.
			keys at: insertIndex put: aKey.
			values at: insertIndex put: aValue.
			^1].
	replacement := owner 
				replacing: (values at: insertIndex)
				with: aValue
				forKey: aKey.
	self 
		replaceAt: insertIndex
		key: aKey
		value: replacement.
	^0

{ #category : 'instance creation' }
GbxLargeIdentityDictionaryBucket class >> new: numberOfKeyValuePairs owner: aCacheDictionary atOffset: offset

	"Return a new instance with enough growing room for numberOfKeyValuePairs"
	^self new
		initializeSize: numberOfKeyValuePairs
		owner: aCacheDictionary
		atOffset: offset

