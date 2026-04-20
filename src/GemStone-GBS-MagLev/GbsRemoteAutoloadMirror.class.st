Class {
	#name : 'GbsRemoteAutoloadMirror',
	#superclass : 'Object',
	#instVars : [
		'namespaceMirror',
		'metadata'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRemoteAutoloadMirror class >> on: aNamespaceMirror metadata: anArray [
	^ self new
		namespaceMirror: aNamespaceMirror;
		metadata: anArray;
		yourself
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> autoloadFile [
	^ self metadataAt: 2 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> currentAutoloadFile [
	^ self autoloadFile
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> constantMirror [
	^ [ namespaceMirror
		constantMirrorAt: self name
		ifAbsent: [ nil ] ]
		on: Error
		do: [ :ex | nil ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> cachedConstantMirror [
	^ [ namespaceMirror
		cachedConstantMirrorAt: self name
		ifAbsent: [ nil ] ]
		on: Error
		do: [ :ex | nil ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> displayName [
	^ self name
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> effectiveAutoloadFile [
	^ self autoloadFile
		ifNil: [ self persistentAutoloadFile ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> hasPersistentRegistration [
	^ self metadataAt: 7 ifAbsent: [ self persistentAutoloadFile notNil ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> hasCurrentRegistration [
	^ self autoloadFile notNil
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> hasRecoverableRegistration [
	^ self hasCurrentRegistration not
		and: [ self effectiveAutoloadFile notNil ]
]

{ #category : 'testing' }
GbsRemoteAutoloadMirror >> hasFailedRegistration [
	(self isLoaded or: [ self isLoading ]) ifTrue: [ ^ false ].
	^ self hasCurrentRegistration not
		and: [ self hasRecoverableRegistration or: [ self isTransientCached ] ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> canResetRegistration [
	^ self hasCurrentRegistration
		or: [ self isTransientCached ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> canRetryRegistration [
	^ self effectiveAutoloadFile notNil
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> failureStateLabel [
	self isLoaded ifTrue: [ ^ 'Healthy' ].
	self isLoading ifTrue: [ ^ 'Loading' ].
	self hasCurrentRegistration ifTrue: [ ^ 'Awaiting First Load' ].
	self hasRecoverableRegistration ifTrue: [ ^ 'Persistent Recovery Required' ].
	self isTransientCached ifTrue: [ ^ 'Transient Cache Reset Required' ].
	^ 'Missing'
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> failureDetail [
	^ self metadataAt: 8 ifAbsent: [
		self hasCurrentRegistration ifTrue: [
			^ 'Current registration is ready to load.' ].
		self isTransientCached ifTrue: [
			self hasPersistentRegistration
				ifTrue: [ ^ 'Transient cache must be reset before persistent recovery.' ].
			^ 'Transient cache must be reset before retry.' ].
		self hasRecoverableRegistration ifTrue: [
			^ 'Persistent registration can be recovered.' ].
		^ 'No recoverable autoload registration was found.' ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> failure [
	^ GbsRemoteAutoloadFailure on: self
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> failureBacktraceText [
	^ self metadataAt: 15 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> failureException [
	^ self failure exceptionObject
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> failureBacktraceEntries [
	^ self failureException backtraceEntries
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> failureExceptionOop [
	^ self metadataAt: 14 ifAbsent: [ nil ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> failureMessage [
	^ self metadataAt: 11 ifAbsent: [
		self isLoading ifTrue: [ ^ 'Autoload is currently loading.' ].
		self isLoaded ifTrue: [ ^ 'Autoload load completed successfully.' ].
		self hasCurrentRegistration ifTrue: [ ^ 'No previous autoload failure is recorded for the current registration.' ].
		self isTransientCached ifTrue: [
			self hasPersistentRegistration
				ifTrue: [ ^ 'A transient cache entry remains from a failed or interrupted autoload attempt.' ].
			^ 'A transient cache entry remains and must be reset before retry.' ].
		self hasRecoverableRegistration ifTrue: [
			^ 'Retry will rebuild the transient autoload state from the persistent registration.' ].
		^ 'No autoload failure metadata is available.' ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> failureSourceLabel [
	^ self metadataAt: 10 ifAbsent: [
		self hasCurrentRegistration ifTrue: [ ^ 'Current Registration' ].
		(self isTransientCached and: [ self hasPersistentRegistration ]) ifTrue: [
			^ 'Transient Cache + Persistent Registration' ].
		self isTransientCached ifTrue: [ ^ 'Transient Cache' ].
		self hasPersistentRegistration ifTrue: [ ^ 'Persistent Registration' ].
		^ 'Missing' ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> isLoaded [
	^ self rawState == true
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> isLoading [
	^ self rawState isNil
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> isTransientCached [
	^ self metadataAt: 6 ifAbsent: [ false ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> lastAttemptedFile [
	^ self metadataAt: 12 ifAbsent: [
		self currentAutoloadFile
			ifNil: [ self persistentAutoloadFile ] ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> oop [
	^ self metadataAt: 4 ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbsRemoteAutoloadMirror >> metadata [
	^ metadata ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsRemoteAutoloadMirror >> metadata: anArray [
	metadata := anArray ifNil: [ #() ] ifNotNil: [ anArray asArray ]
]

{ #category : 'private' }
GbsRemoteAutoloadMirror >> metadataAt: anIndex ifAbsent: aBlock [
	^ self metadata at: anIndex ifAbsent: aBlock
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> name [
	^ self metadataAt: 1 ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbsRemoteAutoloadMirror >> namespaceMirror [
	^ namespaceMirror
]

{ #category : 'accessing' }
GbsRemoteAutoloadMirror >> namespaceMirror: aNamespaceMirror [
	namespaceMirror := aNamespaceMirror
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> persistentAutoloadFile [
	^ self metadataAt: 5 ifAbsent: [ nil ]
]

{ #category : 'printing' }
GbsRemoteAutoloadMirror >> printOn: aStream [
	super printOn: aStream.
	self name ifNotNil: [
		aStream
			nextPutAll: '(';
			nextPutAll: self name asString.
		self autoloadFile ifNotNil: [
			aStream
				nextPutAll: ' -> ';
				nextPutAll: self autoloadFile asString ].
		aStream
			nextPutAll: ' ';
			nextPutAll: self stateLabel asString;
			nextPut: $) ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> proxy [
	| oopValue |
	oopValue := self oop.
	oopValue ifNil: [ ^ nil ].
	^ self session objectForOop: oopValue
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> rawState [
	^ self metadataAt: 3 ifAbsent: [ false ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> registrationStateLabel [
	(self isTransientCached and: [ self hasPersistentRegistration ]) ifTrue: [
		^ 'Transient+Persistent' ].
	self isTransientCached ifTrue: [ ^ 'Transient' ].
	self hasPersistentRegistration ifTrue: [ ^ 'Persistent' ].
	^ 'Current'
]

{ #category : 'actions' }
GbsRemoteAutoloadMirror >> recoverRegistration [
	^ namespaceMirror recoverAutoload: self name
]

{ #category : 'actions' }
GbsRemoteAutoloadMirror >> resetRegistration [
	^ namespaceMirror resetAutoload: self name
]

{ #category : 'actions' }
GbsRemoteAutoloadMirror >> retryRegistration [
	^ self retryRegistrationUsingSourceKind: self retrySourceKind
]

{ #category : 'actions' }
GbsRemoteAutoloadMirror >> retryRegistrationUsingSourceKind: aString [
	aString ifNil: [ ^ namespaceMirror retryAutoload: self name ].
	^ namespaceMirror
		retryAutoload: self name
		usingSourceKind: aString asString
]

{ #category : 'actions' }
GbsRemoteAutoloadMirror >> retryRegistrationUsingPersistentSource [
	^ self retryRegistrationUsingSourceKind: 'persistent'
]

{ #category : 'actions' }
GbsRemoteAutoloadMirror >> retryRegistrationUsingTransientSource [
	^ self retryRegistrationUsingSourceKind: 'transient-reset'
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> recoveryStateLabel [
	self hasCurrentRegistration ifTrue: [ ^ 'Current' ].
	self hasRecoverableRegistration ifTrue: [ ^ 'Recoverable' ].
	^ 'Missing'
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> retryStateLabel [
	self canRetryRegistration ifFalse: [ ^ 'Unavailable' ].
	self hasCurrentRegistration ifTrue: [ ^ 'Current' ].
	self hasRecoverableRegistration ifTrue: [ ^ 'Recoverable' ].
	self isTransientCached ifTrue: [ ^ 'Reset Then Retry' ].
	^ 'Unavailable'
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> retryDetailLabel [
	^ self metadataAt: 9 ifAbsent: [
		self hasCurrentRegistration ifTrue: [ ^ 'Retry current registration.' ].
		(self isTransientCached and: [ self hasPersistentRegistration ]) ifTrue: [
			^ 'Reset transient cache, then recover persistent registration.' ].
		self isTransientCached ifTrue: [ ^ 'Reset transient cache before retry.' ].
		self hasRecoverableRegistration ifTrue: [ ^ 'Recover persistent registration before retry.' ].
		^ 'Retry unavailable.' ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> retrySourceKind [
	^ self metadataAt: 13 ifAbsent: [
		self hasCurrentRegistration ifTrue: [ ^ 'current' ].
		(self isTransientCached and: [ self hasPersistentRegistration ]) ifTrue: [ ^ 'persistent-after-reset' ].
		self isTransientCached ifTrue: [ ^ 'transient-reset' ].
		self hasRecoverableRegistration ifTrue: [ ^ 'persistent' ].
		^ 'missing' ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> retrySourceChoices [
	self canRetryRegistration ifFalse: [ ^ #() ].
	self hasCurrentRegistration ifTrue: [ ^ #('current') ].
	(self isTransientCached and: [ self hasPersistentRegistration ]) ifTrue: [
		^ #('transient-reset' 'persistent-after-reset') ].
	self isTransientCached ifTrue: [ ^ #('transient-reset') ].
	self hasRecoverableRegistration ifTrue: [ ^ #('persistent') ].
	^ { self retrySourceKind } asArray
]

{ #category : 'accessing' }
GbsRemoteAutoloadMirror >> session [
	^ namespaceMirror session
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> stateLabel [
	self isLoaded ifTrue: [ ^ 'Loaded' ].
	self isLoading ifTrue: [ ^ 'Loading' ].
	^ 'Pending'
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> targetDisplayName [
	| constantMirror |
	self isLoaded ifFalse: [ ^ nil ].
	constantMirror := self cachedConstantMirror.
	constantMirror ifNil: [ ^ nil ].
	^ [ constantMirror targetDisplayName ]
		on: Error
		do: [ :ex | nil ]
]

{ #category : 'querying' }
GbsRemoteAutoloadMirror >> valueClassName [
	| constantMirror |
	self isLoaded ifFalse: [ ^ nil ].
	constantMirror := self cachedConstantMirror.
	constantMirror ifNil: [ ^ nil ].
	^ [ constantMirror valueClassName ]
		on: Error
		do: [ :ex | nil ]
]
