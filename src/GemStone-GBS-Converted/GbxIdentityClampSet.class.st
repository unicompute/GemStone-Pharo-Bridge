Class {
	#name : #'GbxIdentityClampSet',
	#superclass : #'IdentitySet',
	#instVars : [ #'needFinalization' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'replication support' }
GbxIdentityClampSet >> gbxCanBeStubbed
	"really don't want to stub this; it's an internal part of the session."

	^false

{ #category : #'GemStone extensions' }
GbxIdentityClampSet >> faultPolicy
	"This object is an internal part of the session and must never be stubbed."

	^#immediate

{ #category : #'accessing' }
GbxIdentityClampSet >> removeIfPresent: anObject

	self remove: anObject ifAbsent: [^nil].
	self markDirty

{ #category : #'private' }
GbxIdentityClampSet >> species
	"Collect and Select aren't normally sent to me, but respond reasonably if it happens in debugging"

	^IdentitySet

{ #category : #'private' }
GbxIdentityClampSet >> fixCollisionsFrom: start
	"Adapted from Pharo WeakSet >> fixCollisionsFrom:"
	
	"The element at start has been removed and replaced by tombstone.
	This method moves forward from there, relocating any entries
	that had been placed below due to collisions with this one."

	"Things are complicated here by the fact that before we hit a nil there may be other 0 tombstones, 
	which definitely won't be in the right place, since the right place for those is to be gone.
	Nil them out but don't stop looking for misplaced non-nil non-zero entries."
	
	| element index |
	index := start.
	[ (element := self basicAt: (index := index \\ self basicSize + 1)) == nil ] whileFalse: [
		element == 0
			ifTrue: [ "This object is gone"
				self basicAt: index put: nil.
				tally := tally - 1 ]
			ifFalse: [
				| newIndex |
				(newIndex := self findElementOrNil: element) = index ifFalse: [
					self 
						basicAt: newIndex put: element;
						basicAt: index put: nil ] ] ]

{ #category : #'finalization' }
GbxIdentityClampSet >> mourn
	"This is sent from the VW finalization thread. Just note that we need finalization, 
	and the session will finalize us at the next server round trip.
	Because instances of GbxIdentityClampSet are replicated, if autoMarkDirty is
	on we may well be immutable at the time we receive this.
	We don't want to mark dirty (for one, our session may be in the process
	of logging out, and we can't afford the error in an early-mourning container)
	so do the mourn while mutable. Can't let another thread modify us while mutable,
	though, so do it as a critical section."

	
	[| wasImmutable |
	wasImmutable := self gbxIsImmutable: false.
	needFinalization := true.
	self gbxIsImmutable: wasImmutable]
			valueUnpreemptively

{ #category : #'finalization' }
GbxIdentityClampSet >> indexOf: oldValue replaceWith: newValue startingAt: startIndex stoppingAt: stopIndex
	"Searches the specified portion of the receiver for the first reference 
	to oldValue, replacing that reference with newValue, and answers
	the 1-based index at which the oldValue was found. Zero is returned if
	the oldValue cannot be found. The search is restricted to and inclusive
	of the specified start and stop indices. The primitive fails if the start and
	stop indices are not SmallIntegers or if either is out of range."
	<primitive: 422>

	self primitiveFailed

{ #category : #'finalization' }
GbxIdentityClampSet >> finalize
	"Clean up any tombstones, and mark myself dirty."
	"Sender must hold my session's sessionProtect."

	| size tombstoneIndex startTally |
	startTally := tally.
	size := self basicSize.
	tombstoneIndex := self
				indexOf: 0
				replaceWith: nil
				startingAt: 1
				stoppingAt: size.
	[tombstoneIndex ~~ 0] whileTrue: 
			[tally := tally - 1.
			self fixCollisionsFrom: tombstoneIndex.
			tombstoneIndex := self
						indexOf: 0
						replaceWith: nil
						startingAt: tombstoneIndex
						stoppingAt: size].
	tally = startTally
		ifFalse: 
			["Now dirty"
			self markDirty].
	needFinalization := false

{ #category : #'finalization' }
GbxIdentityClampSet >> beStrongAndFinalized

	self whileMutableDo: 
			[self
				isWeakContainer: false;
				finalizeIfNeeded]

{ #category : #'finalization' }
GbxIdentityClampSet >> beWeak
	"Sender must hold my session's protect"

	self whileMutableDo: [self isWeakContainer: true]

{ #category : #'finalization' }
GbxIdentityClampSet >> finalizeIfNeeded
	"Sender must hold my session's sessionProtect."

	needFinalization ifTrue: [self finalize]

{ #category : #'initialize-release' }
GbxIdentityClampSet >> release
	"My session is logging out. If I'm currently immutable and the finalization thread happens to send mourn after this, I don't want to 
	run into trouble trying to mark myself dirty in a logged-out session."

	self gbxIsImmutable: false

{ #category : #'initialize-release' }
GbxIdentityClampSet >> initialize

	super initialize.
	needFinalization := false

{ #category : #'initialize-release' }
GbxIdentityClampSet >> initializeForSession: sess

	needFinalization := false

{ #category : #'adding' }
GbxIdentityClampSet >> add: anObject

	super add: anObject.
	self markDirty

{ #category : #'private' }
GbxIdentityClampSet class >> gbxShouldMournEarly
	"GBS private. Answer true if my instances implement #mourn in a trivial manner that cannot block or error, 
	and it is important that all of them be mourned before any normal mourning is done."

	^true

{ #category : #'instance creation' }
GbxIdentityClampSet class >> new: initialCapacity

	| inst |
	inst := super new: initialCapacity.
	inst initialize.
	^inst

