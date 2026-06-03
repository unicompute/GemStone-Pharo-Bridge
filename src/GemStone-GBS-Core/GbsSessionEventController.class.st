Class {
	#name : 'GbsSessionEventController',
	#superclass : 'Object',
	#instVars : [
		'session',
		'pollingActive',
		'pollingProcess',
		'pollingFrequency',
		'eventPriority',
		'lastPollingError',
		'pollingErrorCount'
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

{ #category : 'polling' }
GbsSessionEventController >> defaultProcessPriority [
	^ [ Processor userBackgroundPriority ]
		on: Error
		do: [
			[ Processor lowestPriority ]
				on: Error
				do: [ 30 ] ]
]

{ #category : 'initialization' }
GbsSessionEventController >> initialize [
	super initialize.
	pollingActive := false.
	pollingErrorCount := 0
]

{ #category : 'testing' }
GbsSessionEventController >> isPollingActive [
	^ pollingActive == true
]

{ #category : 'testing' }
GbsSessionEventController >> hasPollingProcess [
	^ pollingProcess notNil and: [
		[ pollingProcess isTerminated not ] on: Error do: [ false ] ]
]

{ #category : 'accessing' }
GbsSessionEventController >> lastPollingError [
	^ lastPollingError
]

{ #category : 'accessing' }
GbsSessionEventController >> pollingErrorCount [
	^ pollingErrorCount ifNil: [ 0 ]
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

{ #category : 'polling' }
GbsSessionEventController >> normalizedPollingFrequency [
	^ self pollingFrequency max: 1
]

{ #category : 'polling' }
GbsSessionEventController >> pollingDelay [
	^ Delay forMilliseconds: self normalizedPollingFrequency
]

{ #category : 'polling' }
GbsSessionEventController >> processPriority [
	| priority lower upper |
	priority := self eventPriority.
	priority isInteger ifFalse: [ ^ self defaultProcessPriority ].
	lower := [ Processor lowestPriority ] on: Error do: [ nil ].
	upper := [ Processor highestPriority ] on: Error do: [ nil ].
	(lower notNil and: [ priority < lower ]) ifTrue: [ ^ lower ].
	(upper notNil and: [ priority > upper ]) ifTrue: [ ^ upper ].
	^ priority
]

{ #category : 'polling' }
GbsSessionEventController >> handlePollingError: anError [
	lastPollingError := anError.
	pollingErrorCount := self pollingErrorCount + 1.
	((session respondsTo: #isLoggedIn) and: [ session isLoggedIn not ]) ifTrue: [
		pollingActive := false ].
	^ anError
]

{ #category : 'polling' }
GbsSessionEventController >> pollingLoop [
	[ pollingActive ] whileTrue: [
		self pollingDelay wait.
		pollingActive ifTrue: [
			[ self pollSignalsOnce ]
				on: Error
				do: [ :ex | self handlePollingError: ex ] ] ].
	^ self
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
	self startPollingProcess.
	^ self
]

{ #category : 'polling' }
GbsSessionEventController >> startPollingProcess [
	self hasPollingProcess ifTrue: [ ^ self ].
	pollingProcess := [
		[ self pollingLoop ] forkAt: self processPriority ]
			on: Error
			do: [
				[ self pollingLoop ] forkAt: self defaultProcessPriority ].
	[ pollingProcess name: 'GBS session event detector' ] on: Error do: [ ].
	^ self
]

{ #category : 'polling' }
GbsSessionEventController >> stopPolling [
	| process |
	pollingActive := false.
	process := pollingProcess.
	pollingProcess := nil.
	(process notNil and: [
		[ process ~~ Processor activeProcess ] on: Error do: [ true ] ]) ifTrue: [
			[ process terminate ] on: Error do: [ ] ].
	^ self
]
