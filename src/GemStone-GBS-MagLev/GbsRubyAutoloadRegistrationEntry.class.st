Class {
	#name : 'GbsRubyAutoloadRegistrationEntry',
	#superclass : 'GbsRubyRuntimeEntry',
	#instVars : [
		'autoloadMirror'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRubyAutoloadRegistrationEntry class >> on: anAutoloadMirror [
	^ self new
		autoloadMirror: anAutoloadMirror;
		kind: #autoloadRegistration;
		value: anAutoloadMirror effectiveAutoloadFile;
		persistent: anAutoloadMirror hasPersistentRegistration;
		yourself
]

{ #category : 'accessing' }
GbsRubyAutoloadRegistrationEntry >> autoloadFile [
	^ self effectiveAutoloadFile
]

{ #category : 'accessing' }
GbsRubyAutoloadRegistrationEntry >> autoloadMirror [
	^ autoloadMirror
]

{ #category : 'accessing' }
GbsRubyAutoloadRegistrationEntry >> autoloadMirror: anAutoloadMirror [
	autoloadMirror := anAutoloadMirror
]

{ #category : 'printing' }
GbsRubyAutoloadRegistrationEntry >> displayString [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: self name asString;
			nextPutAll: ' -> ';
			nextPutAll: (self autoloadFile ifNil: [ '(none)' ]) asString;
			nextPutAll: ' [';
			nextPutAll: self stateLabel asString;
			nextPut: $].
		self registrationStateLabel = 'Current' ifFalse: [
			stream
				nextPutAll: ' {';
				nextPutAll: self registrationStateLabel asString;
				nextPut: $} ].
		(self failureStateLabel = 'Healthy' or: [ self failureStateLabel = 'Loading' ]) ifFalse: [
			stream
				nextPutAll: ' <';
				nextPutAll: self failureStateLabel asString;
				nextPut: $>.
			self failureDetail ifNotNil: [
				stream
					nextPutAll: ' -- ';
					nextPutAll: self failureDetail asString ].
			(self failureMessage notNil
				and: [ self failureMessage ~= self failureDetail ]) ifTrue: [
				stream
					nextPutAll: ' (';
					nextPutAll: self failureMessage asString;
					nextPut: $) ] ] ]
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> currentAutoloadFile [
	^ autoloadMirror currentAutoloadFile
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> effectiveAutoloadFile [
	^ autoloadMirror effectiveAutoloadFile
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> hasPersistentRegistration [
	^ autoloadMirror hasPersistentRegistration
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> hasCurrentRegistration [
	^ autoloadMirror hasCurrentRegistration
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> hasRecoverableRegistration [
	^ autoloadMirror hasRecoverableRegistration
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> canResetRegistration [
	^ autoloadMirror canResetRegistration
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> canRetryRegistration [
	^ autoloadMirror canRetryRegistration
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> failureStateLabel [
	^ autoloadMirror failureStateLabel
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> failureDetail [
	^ autoloadMirror failureDetail
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> failure [
	^ autoloadMirror failure
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> failureBacktraceText [
	^ autoloadMirror failureBacktraceText
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> failureException [
	^ autoloadMirror failureException
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> failureBacktraceEntries [
	^ autoloadMirror failureException backtraceEntries
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> failureMessage [
	^ autoloadMirror failureMessage
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> failureSourceLabel [
	^ autoloadMirror failureSourceLabel
]

{ #category : 'testing' }
GbsRubyAutoloadRegistrationEntry >> isLoaded [
	^ autoloadMirror isLoaded
]

{ #category : 'testing' }
GbsRubyAutoloadRegistrationEntry >> isLoading [
	^ autoloadMirror isLoading
]

{ #category : 'testing' }
GbsRubyAutoloadRegistrationEntry >> isTransientCached [
	^ autoloadMirror isTransientCached
]

{ #category : 'testing' }
GbsRubyAutoloadRegistrationEntry >> hasFailedRegistration [
	^ autoloadMirror hasFailedRegistration
]

{ #category : 'testing' }
GbsRubyAutoloadRegistrationEntry >> isRubySource [
	^ (self extension ifNil: [ '' ]) asLowercase = 'rb'
]

{ #category : 'accessing' }
GbsRubyAutoloadRegistrationEntry >> name [
	^ autoloadMirror name
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> lastAttemptedFile [
	^ autoloadMirror lastAttemptedFile
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> extension [
	| fileName |
	fileName := self effectiveAutoloadFile.
	fileName ifNil: [ ^ nil ].
	(fileName asString includes: $.) ifFalse: [ ^ nil ].
	^ fileName asString copyAfterLast: $.
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> pathComponents [
	| fileName |
	fileName := self effectiveAutoloadFile.
	fileName ifNil: [ ^ #() ].
	^ (fileName asString findTokens: '/') asArray
]

{ #category : 'accessing' }
GbsRubyAutoloadRegistrationEntry >> persistentAutoloadFile [
	^ autoloadMirror persistentAutoloadFile
]

{ #category : 'accessing' }
GbsRubyAutoloadRegistrationEntry >> registrationStateLabel [
	^ autoloadMirror registrationStateLabel
]

{ #category : 'accessing' }
GbsRubyAutoloadRegistrationEntry >> recoveryStateLabel [
	^ autoloadMirror recoveryStateLabel
]

{ #category : 'actions' }
GbsRubyAutoloadRegistrationEntry >> recoverAction [
	^ GbsRubyRuntimeProvenanceAction
		action: #recoverAutoload
		sourceEntry: self
		targetPath: self name
]

{ #category : 'actions' }
GbsRubyAutoloadRegistrationEntry >> recoverRegistration [
	^ autoloadMirror recoverRegistration
]

{ #category : 'actions' }
GbsRubyAutoloadRegistrationEntry >> resetRegistration [
	^ autoloadMirror resetRegistration
]

{ #category : 'actions' }
GbsRubyAutoloadRegistrationEntry >> resetAction [
	^ GbsRubyRuntimeProvenanceAction
		action: #resetAutoload
		sourceEntry: self
		targetPath: self name
]

{ #category : 'actions' }
GbsRubyAutoloadRegistrationEntry >> retryRegistration [
	^ autoloadMirror retryRegistration
]

{ #category : 'actions' }
GbsRubyAutoloadRegistrationEntry >> retryAction [
	^ GbsRubyRuntimeProvenanceAction
		action: #retryAutoload
		sourceEntry: self
		targetPath: self name
]

{ #category : 'accessing' }
GbsRubyAutoloadRegistrationEntry >> retryStateLabel [
	^ autoloadMirror retryStateLabel
]

{ #category : 'accessing' }
GbsRubyAutoloadRegistrationEntry >> retryDetailLabel [
	^ autoloadMirror retryDetailLabel
]

{ #category : 'accessing' }
GbsRubyAutoloadRegistrationEntry >> retrySourceKind [
	^ autoloadMirror retrySourceKind
]

{ #category : 'accessing' }
GbsRubyAutoloadRegistrationEntry >> retrySourceChoices [
	^ autoloadMirror retrySourceChoices
]

{ #category : 'actions' }
GbsRubyAutoloadRegistrationEntry >> retryActions [
	^ (self retrySourceChoices ifEmpty: [ { nil } ]) collect: [ :each |
		self retryActionForSourceKind: each ]
]

{ #category : 'accessing' }
GbsRubyAutoloadRegistrationEntry >> provenanceLabel [
	^ self registrationStateLabel
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> provenanceLinks [
	^ { GbsRubyRuntimeProvenanceLink
		source: self name asString
		target: (self autoloadFile ifNil: [ '(none)' ])
		kind: #autoloadRegistration
		entry: self }
]

{ #category : 'querying' }
GbsRubyAutoloadRegistrationEntry >> provenanceActionsUsing: aRuntimeFacade [
	| actions |
	actions := OrderedCollection new.
	self hasRecoverableRegistration ifTrue: [
		actions add: self recoverAction ].
	self canResetRegistration ifTrue: [
		actions add: self resetAction ].
	self canRetryRegistration ifTrue: [
		(self retrySourceChoices ifEmpty: [ { nil } ]) do: [ :each |
			actions add: (self retryActionForSourceKind: each) ] ].
	^ actions asArray
]

{ #category : 'accessing' }
GbsRubyAutoloadRegistrationEntry >> stateLabel [
	^ autoloadMirror stateLabel
]

{ #category : 'accessing' }
GbsRubyAutoloadRegistrationEntry >> targetDisplayName [
	^ autoloadMirror targetDisplayName
]

{ #category : 'actions' }
GbsRubyAutoloadRegistrationEntry >> retryActionForSourceKind: aString [
	^ GbsRubyRuntimeProvenanceAction
		retryAction: #retryAutoload
		sourceEntry: self
		targetPath: self name
		sourceKind: aString
]

{ #category : 'actions' }
GbsRubyAutoloadRegistrationEntry >> retryRegistrationUsingSourceKind: aString [
	^ autoloadMirror retryRegistrationUsingSourceKind: aString
]
