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
	GbsSessionManager invalidateStaleTypedWrapperClassesForSession: session.
	session materializer clearRemoteClassNameCache.
	session invalidateRepositoryRoots.
	^ true
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

	result := session gciCommit.
	result = 1 ifTrue: [
		GbsSessionManager invalidateStaleTypedWrapperClassesForSession: session.
		session materializer clearRemoteClassNameCache.
		session invalidateRepositoryRoots ].
	^ result = 1
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> commitTransactionOrSignalConflict [
	self commitTransaction ifTrue: [ ^ true ].
	GbsCommitConflictError signal: 'GemStone commit conflict.'
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> commitTransactionWithRetryCount: aRetryCount [
	| retries attempts |
	retries := (aRetryCount ifNil: [ 0 ] ifNotNil: [ aRetryCount asInteger ]) max: 0.
	attempts := retries + 1.
	1 to: attempts do: [ :attempt |
		self commitTransaction ifTrue: [ ^ true ].
		attempt < attempts ifTrue: [ self abortTransaction ] ].
	GbsCommitConflictError
		signal: 'GemStone commit conflict after ', attempts printString, ' attempts.'
]

{ #category : 'transactions' }
GbsSessionTransactionCoordinator >> withCommitRetryCount: aRetryCount do: aBlock [
	| retries attempts result |
	retries := (aRetryCount ifNil: [ 0 ] ifNotNil: [ aRetryCount asInteger ]) max: 0.
	attempts := retries + 1.
	1 to: attempts do: [ :attempt |
		result := aBlock value.
		self commitTransaction ifTrue: [ ^ result ].
		attempt < attempts ifTrue: [ self abortTransaction ] ].
	GbsCommitConflictError
		signal: 'GemStone commit conflict after ', attempts printString, ' attempts.'
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
	GbsCommitConflictError
		signal: 'GemStone commit conflict after ', attempts printString, ' attempts.'
]
