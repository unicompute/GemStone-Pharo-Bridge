Class {
	#name : 'GbxClientObjDictionaryBucket',
	#superclass : 'Object',
	#instVars : [
		'freeHead',
		'highwater',
		'keys',
		'needFinalization',
		'owner',
		'ownerIndex',
		'size'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'growing' }
GbxClientObjDictionaryBucket >> makeRoom
	"I need to make room for another pair. If I can make room by finalizing, I need to do so.
	If no room is to be made by finalizing, I need to replace myself with a larger bucket."

	"The sender must hold my owner's writeProtect."

	self finalizeIfNeeded.
	freeHead == nil ifTrue: [self grow]

{ #category : 'accessing' }
GbxClientObjDictionaryBucket >> delegateAtClient: key 
	"Answer the value for a key, if present. If not present, answer nil."

	"Reads do not have to be protected by a semaphore. So after finding the value we need to re-check the key
	in case another thread removed the key between our finding the key and getting the value -- the value could
	belong to a different key in that case. We don't move keys, so if it's not the same, it's been removed."

	| index value |
	highwater == 0 ifTrue: [^nil].	"The prim search fails if told to stop at 0."
	"Send prim message directly for performance"
	index := keys 
				indexOf: key
				replaceWith: key
				startingAt: 1
				stoppingAt: highwater.
	^index == 0 
		ifTrue: [nil]
		ifFalse: 
			[value := self basicAt: index.
			(keys at: index) == key ifTrue: [value] ifFalse: [nil]]

{ #category : 'accessing' }
GbxClientObjDictionaryBucket >> clearForSession: aSession 
	"aSession is logging out. Remove any values that are for the given session. 
	If the only value for any key is for aSession, remove that key as well."

	"Sender must hold my owner's writeProtect"

	| valueForSession key |
	highwater to: 1
		by: -1
		do: 
			[:index | 
			| value newValue |
			value := self basicAt: index.
			value == nil 
				ifFalse: 
					[(valueForSession := value forSession: aSession) == nil 
						ifFalse: 
							[valueForSession setDeadSession.
							"Don't remove key or value if the key is a proxy."
							(key := keys at: index) gbxIsProxy 
								ifFalse: 
									[value isReadOnlyObject ifFalse: [key gbxIgnoreFutureChanges].
									newValue := value notForSession: aSession.
									self basicAt: index put: newValue.
									newValue == nil 
										ifTrue: 
											["Remove the key. Ensure that this operation can't be interrupted."

											[] ensure: 
													[keys at: index put: freeHead.
													freeHead := index.
													size := size - 1]]]]]]

{ #category : 'accessing' }
GbxClientObjDictionaryBucket >> atNewClient: clientObject putDelegate: delegate 
	"Similar to #at:put: in an IdentityDictionary, but the key is known by the sender to be not currently present, so I can skip looking to see if it's already there."

	"Answer false if I have no obvious room, true if I added the pair."

	"The sender must hold my owner's writeProtect."

	| index |
	index := freeHead.
	index == nil ifTrue: [^false].
	"This method must be interruptable at any point and not leave the bucket in an invalid state.
	Thus, we use an ensure: block. This doesn't help in VW7.5 and earlier, which doesn't complete
	interrupted ensure: blocks, but should protect against corruption in VW7.6 and later."
	[] ensure: 
			[freeHead := keys at: freeHead.
			self basicAt: index put: delegate.
			keys at: index put: clientObject.
			index > highwater ifTrue: [highwater := index].
			size := size + 1].
	delegate isReadOnlyObject: clientObject isImmutable.
	"isImmutable is vw-specific. This is executed frequently enough that gbxIsImmutable is noticeably slower."
	delegate isStDirty ifFalse: [clientObject gbxTrapFutureChanges].
	^true

{ #category : 'accessing' }
GbxClientObjDictionaryBucket >> atClient: key putDelegate: value 
	"Similar to #at:put: in an IdentityDictionary, We don't know whether the key is already present, so we have to look"

	"Answer false if I have no obvious room, true if I added the pair."

	"The sender must hold my owner's writeProtect."

	| index existingDelegate |
	index := highwater == 0 
				ifTrue: [0]
				ifFalse: 
					["Send this message directly for performance"

					keys 
						indexOf: key
						replaceWith: key
						startingAt: 1
						stoppingAt: highwater].
	index == 0 ifTrue: [^self atNewClient: key putDelegate: value].
	"Key found, add delegate to the existing list."
	existingDelegate := self basicAt: index.
	self basicAt: index
		put: (existingDelegate connectingDelegate: value withClient: key).
	^true

{ #category : 'accessing' }
GbxClientObjDictionaryBucket >> removeStub: key 
	"A special-purpose message for when we're about to do a one-way become on the key,
	which will almost certainly move it out of this bucket.
	Remove the key-value pair (which I must contain) and answer the current value.
	The key is known to exist in the cache, is known to be a stub, and is known to have
	one delegate as its value (since stubs cannot be shared between sessions)."

	"The sender must hold my owner's writeProtect."

	| index delegate |
	index := keys 
				indexOf: key
				replaceWith: key
				startingAt: 1
				stoppingAt: highwater.
	"Known to exist, so highwater cannot be 0, and index should be valid here."
	delegate := self basicAt: index.
	"Remove the entry. Protect against interruption by unwind with ensure:."
	[] ensure: 
			[self basicAt: index put: nil.
			keys at: index put: freeHead.
			freeHead := index.
			size := size - 1].
	^delegate

{ #category : 'accessing' }
GbxClientObjDictionaryBucket >> removeClient: key forSession: aSession
	"Remove the key"
	"The sender must hold my owner's writeProtect."

	| index |
	highwater == 0 ifTrue: [^self].
	index := keys
				indexOf: key
				replaceWith: key
				startingAt: 1
				stoppingAt: highwater.
	index == 0 ifTrue: [^nil	"key not found"].
	self removeClientAtIndex: index forSession: aSession

{ #category : 'queries' }
GbxClientObjDictionaryBucket >> capacity
	"Answer how many key-value pairs I can hold."

	^keys size

{ #category : 'queries' }
GbxClientObjDictionaryBucket >> size
	"Answer how many key-value pairs I currently hold.
	This may be overstated, since the count will include any keys that have been garbage collected
	but not yet finalized."

	^size

{ #category : 'utility' }
GbxClientObjDictionaryBucket >> auditHashing
	| cls |
	keys do: 
			[:key | 
			(key gbxBasicClass == SmallInteger or: [key == nil]) 
				ifFalse: 
					[key identityHash = ownerIndex 
						ifFalse: 
							[self gbsMessenger 
								failure: 'Cache hash error: An instance of a %1 with identityHash %2 was stored in bucket  %3'
								with: ((cls := key gbxBasicClass) == Metaclass 
										ifTrue: [key name , ' metaclass']
										ifFalse: [cls])
								with: key identityHash
								with: ownerIndex]]]

{ #category : 'finalization' }
GbxClientObjDictionaryBucket >> finalize
	"Recover space from all keys that have been garbage collected"

	"Sender must hold my owner's write protect."

	| index |
	highwater == 0 ifTrue: [^nil].	"Highwater shouldn't be zero if we need finalizing, but..."
	"Search from end to beginning, so lower indexes will be reused first."
	index := highwater.
	"For integrity, must ensure: to protect against stack unwind."
	[] ensure: 
			[
			[index := keys 
						indexOf: 0
						replaceWith: freeHead
						startingAt: index
						stoppingAt: 1.
			index == 0] 
					whileFalse: 
						[freeHead := index.
						self basicAt: index put: nil.
						size := size - 1]].
	self postFinalize

{ #category : 'finalization' }
GbxClientObjDictionaryBucket >> needFinalization
	needFinalization := true.
	owner needFinalization

{ #category : 'finalization' }
GbxClientObjDictionaryBucket >> postFinalize
	"See whether I'm now small enough that I should compact or shrink"

	"Sender must hold my owner's write protect."

	self gbxFixMe	"Needs to be written."

{ #category : 'finalization' }
GbxClientObjDictionaryBucket >> finalizeIfNeeded
	"Reset needFinalization before finalization in case high-priority finalizer thread notifies 
	us we need finalization during finalization. We will sometimes finalize when we don't need to, 
	but will never fail to finalize when we should. Exception: If the Process is terminated or otherwise
	unwound after needFinalization is reset but before finalization finishes, unfinalized entries may
	persist in the bucket until more GC happens or the bucket grows. This level of inaccuracy is
	probably not worth the effort to prevent."

	needFinalization 
		ifTrue: 
			[needFinalization := false.
			self finalize]

{ #category : 'finalization' }
GbxClientObjDictionaryBucket >> update: anAspectSymbol with: aParameter from: aSender 
	"If I'm being told that I need finalization, record that fact."

	(aSender == keys and: [anAspectSymbol = #ElementExpired]) 
		ifTrue: [self needFinalization]

{ #category : 'private' }
GbxClientObjDictionaryBucket >> removeClientAtIndex: index forSession: aSession
	"Sender must ensure that there is actually an entry at index."
	"The sender must hold my owner's writeProtect."

	| value newValue key |
	value := self basicAt: index.
	(value forSession: aSession) == nil
		ifFalse: 
			[key := keys at: index.
			newValue := value notForSession: aSession.
			self basicAt: index put: newValue.
			newValue == nil
				ifTrue: 
					["Remove the key"
					value isReadOnlyObject ifFalse: [key gbxIgnoreFutureChanges].
					"Ensure that this bit cannot be interrupted by unwind, to avoid
							corrupting the bucket."
					[] ensure: 
							[keys at: index put: freeHead.
							freeHead := index.
							size := size - 1]]]

{ #category : 'private' }
GbxClientObjDictionaryBucket >> threadFreeChain
	"Initialize the free chain. Assumes I'm empty, will obliterate any keys present."

	1 to: keys size - 1 do: [:i | keys at: i put: i + 1].
	keys at: keys size put: nil.	"Terminate the chain"
	freeHead := 1

{ #category : 'private' }
GbxClientObjDictionaryBucket >> grow
	"Copy my live elements to another larger bucket, then tell my owner to replace me with that bucket."

	"The sender must hold my owner's writeProtect."

	| newBucket |
	newBucket := self class 
				new: self capacity * 2
				owner: owner
				index: ownerIndex.
	1 to: highwater
		do: [:i | newBucket atNewClient: (keys at: i) putDelegateOrList: (self basicAt: i)].
	"Keys may get GC'ed while copying. Could check at each iteration, but safest
	and reasonably fast is to always tell the new bucket it needs to finalize."
	newBucket needFinalization.
	owner replaceBucketAt: ownerIndex with: newBucket

{ #category : 'private' }
GbxClientObjDictionaryBucket >> atNewClient: clientObject putDelegateOrList: delegateOrList 
	"Private. Used ONLY when growing to move everything associated with one client 
	object from an old bucket to a new bucket. The receiver MUST already be large enough to hold the new object.
	The client object is known by the sender to be not currently present, so I can skip looking to see if it's already there.
	The client object may also be 0 if the client object has been GCed but not yet finalized. That's OK, the new bucket
	will be finalized after we're done copying into it."

	"The sender must hold my owner's writeProtect."

	| index |
	index := freeHead.
	index == nil 
		ifTrue: 
			[self gbsMessenger error: 'Bucket out of room while growing or shrinking'].
	freeHead := keys at: freeHead.
	self basicAt: index put: delegateOrList.
	keys at: index put: clientObject.
	index > highwater ifTrue: [highwater := index].
	size := size + 1.

{ #category : 'initialize-release' }
GbxClientObjDictionaryBucket >> initializeOwner: dictionary index: index 
	"Initialization is not protected against Process termination. The only window where this could cause a problem
	is during the first login after GBS is loaded into an image. We assume that was completed correctly.

	The other time to initialize a bucket is during growth. If initialization fails, the bucket is not yet part of the parent,
	and so does not matter."

	owner := dictionary.
	ownerIndex := index.
	highwater := 0.
	size := 0.
	keys := WeakArray new: self basicSize.
	keys addDependent: self.
	needFinalization := false.
	self threadFreeChain

{ #category : 'stack dumping' }
GbxClientObjDictionaryBucket >> keysDo: aBlock
	"Used in gathering cache inventory stats. Not necessarily a consistent view."

	keys do: 
			[:key |
			(key gbxBasicClass == SmallInteger or: [key == nil])
				ifFalse: [aBlock value: key]]

{ #category : 'stack dumping' }
GbxClientObjDictionaryBucket >> keysAndValuesDo: aBlock 
	"this should only be used to dump out the clientMap"

	| key |
	1 to: keys size
		do: 
			[:i | 
			key := keys at: i.
			(key gbxBasicClass == SmallInteger or: [key == nil]) 
				ifFalse: [aBlock value: key value: (self basicAt: i)]]

{ #category : 'instance creation' }
GbxClientObjDictionaryBucket class >> new: size owner: dictionary index: index 
	| inst |
	inst := self basicNew: size.
	inst initializeOwner: dictionary index: index.
	^inst

