Class {
	#name : 'GbsSessionTransactionCoordinator',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsSessionTransactionCoordinator class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'accessing' }
GbsSessionTransactionCoordinator >> session [
	^ session
]

{ #category : 'accessing' }
GbsSessionTransactionCoordinator >> session: aSession [
	session := aSession
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> abortTransaction [
	| result |
	session isLoggedIn ifFalse: [ GbsError signal: 'Not logged in.' ].

	result := session gciAbort.
	((result = 1) or: [ result = true ]) ifFalse: [
		"Some local stones report a falsey GCI abort result even though the
		abort succeeds. Fall back to an explicit Smalltalk abortTransaction
		before treating the connection as broken."
		[ session evaluateSystemSelector: #abortTransaction withArguments: #() ]
			on: Error
			do: [ GbsError signal: 'Failed to abort transaction.' ] ].
	self drainPendingAbortError.
	self resetClientStateAfterSuccessfulTransactionBoundary: #abort.
	^ true
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> drainPendingAbortError [
	(session respondsTo: #checkForError) ifFalse: [ ^ self ].
	[ session checkForError ]
		on: Error
		do: [ :ex | nil ].
	^ self
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> resetClientStateAfterSuccessfulTransaction [
	^ self resetClientStateAfterSuccessfulTransactionBoundary: #commit
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> resetClientStateAfterSuccessfulTransactionBoundary: reasonSymbol [
	GbsSessionManager invalidateStaleTypedWrapperClassesForSession: session.
	GbsSessionManager clearTypedWrapperFreshnessCacheForSession: session.
	session materializer clearRemoteClassNameCache.
	session invalidateRepositoryRoots.
	GbsMaterializedObjectDirtyTracker resetAfterTransactionForSession: session reason: reasonSymbol.
	session resetMaterializedObjectCache.
	^ session
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> prepareClientStateBeforeCommit [
	^ GbsSessionLifecycleManager prepareForCommitInSession: session
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> needsCommit [
	^ session evaluateSystemSelector: #needsCommit withArguments: #()
]

{ #category : 'locking' }
GbsSessionTransactionCoordinator >> readLock: anObject [
	session executeSystemSelector: #readLock: withArguments: { anObject }.
	^ session
]

{ #category : 'locking' }
GbsSessionTransactionCoordinator >> writeLock: anObject [
	session executeSystemSelector: #writeLock: withArguments: { anObject }.
	^ session
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> commitTransaction [
	| result |
	session isLoggedIn ifFalse: [ GbsError signal: 'Not logged in.' ].

	self prepareClientStateBeforeCommit.
	result := session gciCommit.
	result = 1 ifTrue: [
		self resetClientStateAfterSuccessfulTransactionBoundary: #commit ].
	^ result = 1
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> commitTransactionOrSignalConflict [
	self commitTransaction ifTrue: [ ^ true ].
	self signalConflict: 'GemStone commit conflict.'
]

{ #category : 'private' }
GbsSessionTransactionCoordinator >> capturedTransactionConflicts [
	"Fetch the structured conflict report for the last failed commit. The server clears its conflict sets at
	the start of the next commit, so this must be read before any subsequent commit. Guarded so a fetch
	failure never masks the original conflict."
	(session respondsTo: #transactionConflicts) ifFalse: [ ^ Dictionary new ].
	^ [ session transactionConflicts ] on: Error do: [ Dictionary new ]
]

{ #category : 'private' }
GbsSessionTransactionCoordinator >> signalConflict: aMessage [
	"Capture the structured conflict report (before any abort, which the caller must defer) and signal a
	GbsCommitConflictError carrying it."
	^ GbsCommitConflictError new
		conflicts: self capturedTransactionConflicts;
		signal: aMessage
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> commitTransactionWithRetryCount: aRetryCount [
	| retries attempts |
	retries := (aRetryCount ifNil: [ 0 ] ifNotNil: [ aRetryCount asInteger ]) max: 0.
	attempts := retries + 1.
	1 to: attempts do: [ :attempt |
		self commitTransaction ifTrue: [ ^ true ].
		"On the final attempt, capture the conflict report before any abort clears it."
		attempt = attempts
			ifTrue: [ ^ self signalConflict: 'GemStone commit conflict after ', attempts printString, ' attempts.' ]
			ifFalse: [ self abortTransaction ] ]
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> withCommitRetryCount: aRetryCount do: aBlock [
	| retries attempts result |
	retries := (aRetryCount ifNil: [ 0 ] ifNotNil: [ aRetryCount asInteger ]) max: 0.
	attempts := retries + 1.
	1 to: attempts do: [ :attempt |
		result := aBlock value.
		self commitTransaction ifTrue: [ ^ result ].
		attempt = attempts
			ifTrue: [ ^ self signalConflict: 'GemStone commit conflict after ', attempts printString, ' attempts.' ]
			ifFalse: [ self abortTransaction ] ]
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> withGemStoneTransactionDo: aBlock [
	^ self withGemStoneTransactionRetryCount: 0 do: aBlock
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> withGemStoneTransactionRetryCount: aRetryCount do: aBlock [
	| retries attempts result handledConflict |
	retries := (aRetryCount ifNil: [ 0 ] ifNotNil: [ aRetryCount asInteger ]) max: 0.
	attempts := retries + 1.
	1 to: attempts do: [ :attempt |
		handledConflict := false.
		[
			[
				result := aBlock value.
				self commitTransactionOrSignalConflict.
				^ result
			] on: GbsCommitConflictError do: [ :ex |
				handledConflict := true.
				self abortTransaction.
				attempt = attempts
					ifTrue: [ ex pass ] ]
		] on: Error do: [ :ex |
			handledConflict ifFalse: [
				[ self abortTransaction ] on: Error do: [ :abortEx | ] ].
			ex pass ] ].
	self signalConflict: 'GemStone commit conflict after ', attempts printString, ' attempts.'
]
