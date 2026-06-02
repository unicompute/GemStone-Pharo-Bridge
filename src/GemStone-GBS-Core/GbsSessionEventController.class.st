Class {
	#name : 'GbsSessionEventController',
	#superclass : 'Object',
	#instVars : [
		'session',
		'pollingActive',
		'pollingProcess',
		'pollingFrequency',
		'eventPriority'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsSessionEventController class >> forSession: aSession [
	^ (aSession class weakRegistryNamed: #GbsSessionEventControllers)
		at: aSession
		ifAbsentPut: [
			self new
				session: aSession;
				yourself ]
]

{ #category : 'testing' }
GbsSessionEventController class >> isPollingActiveForSession: aSession [
	^ ((aSession class weakRegistryNamed: #GbsSessionEventControllers)
		at: aSession
		ifAbsent: [ nil ])
			ifNil: [ false ]
			ifNotNil: [ :controller | controller isPollingActive ]
]

{ #category : 'lifecycle' }
GbsSessionEventController class >> resetForSession: aSession [
	| controller |
	controller := (aSession class weakRegistryNamed: #GbsSessionEventControllers)
		removeKey: aSession
		ifAbsent: [ nil ].
	controller ifNotNil: [ controller stopPolling ].
	^ aSession
]

{ #category : 'accessing' }
GbsSessionEventController >> eventPriority [
	^ eventPriority ifNil: [ 3 ]
]

{ #category : 'accessing' }
GbsSessionEventController >> eventPriority: anInteger [
	eventPriority := anInteger
]

{ #category : 'initialization' }
GbsSessionEventController >> initialize [
	super initialize.
	pollingActive := false
]

{ #category : 'testing' }
GbsSessionEventController >> isPollingActive [
	^ pollingActive == true
]

{ #category : 'polling' }
GbsSessionEventController >> handlePositivePollResult: signalResult [
	| handled |
	signalResult = 4 ifTrue: [ ^ TransactionBacklog signal ].
	handled := self pollGemStoneErrorIfPresent.
	handled ifNotNil: [ ^ handled ].
	signalResult = 1 ifTrue: [ ^ AlmostOutOfMemory signal ].
	^ signalResult
]

{ #category : 'polling' }
GbsSessionEventController >> handlePollResult: signalResult [
	signalResult ifNil: [ ^ nil ].
	signalResult == false ifTrue: [ ^ nil ].
	signalResult == true ifTrue: [ ^ self handlePositivePollResult: 1 ].
	(signalResult = 0) ifTrue: [ ^ nil ].
	(signalResult respondsTo: #>) ifFalse: [ ^ signalResult ].
	(signalResult > 0) ifTrue: [
		^ self handlePositivePollResult: signalResult ].
	^ signalResult
]

{ #category : 'polling' }
GbsSessionEventController >> pollOnce [
	self isPollingActive ifFalse: [ ^ nil ].
	^ self pollSignalsOnce
]

{ #category : 'polling' }
GbsSessionEventController >> pollGemStoneErrorIfPresent [
	(session respondsTo: #checkForError) ifFalse: [ ^ nil ].
	^ session checkForError
]

{ #category : 'polling' }
GbsSessionEventController >> pollSignalsOnce [
	((session respondsTo: #isLoggedIn) and: [ session isLoggedIn not ]) ifTrue: [ ^ nil ].
	^ self handlePollResult: session gciPollForSignal
]

{ #category : 'accessing' }
GbsSessionEventController >> pollingFrequency [
	^ pollingFrequency ifNil: [ 300 ]
]

{ #category : 'accessing' }
GbsSessionEventController >> pollingFrequency: milliseconds [
	pollingFrequency := milliseconds
]

{ #category : 'accessing' }
GbsSessionEventController >> session [
	^ session
]

{ #category : 'accessing' }
GbsSessionEventController >> session: aSession [
	session := aSession
]

{ #category : 'polling' }
GbsSessionEventController >> startIfEnabledFromPolicy [
	| policy |
	policy := [ GbsReplicationPolicy forSession: session ] on: Error do: [ nil ].
	policy ifNil: [ ^ self ].
	self pollingFrequency: policy eventPollingFrequency.
	self eventPriority: policy eventPriority.
	(policy asyncSignalPollingEnabled == true)
		ifTrue: [ self startPolling ]
		ifFalse: [ self stopPolling ].
	^ self
]

{ #category : 'polling' }
GbsSessionEventController >> startPolling [
	pollingActive := true.
	^ self
]

{ #category : 'polling' }
GbsSessionEventController >> stopPolling [
	pollingActive := false.
	pollingProcess ifNotNil: [
		[ pollingProcess terminate ] on: Error do: [ ].
		pollingProcess := nil ].
	^ self
]
