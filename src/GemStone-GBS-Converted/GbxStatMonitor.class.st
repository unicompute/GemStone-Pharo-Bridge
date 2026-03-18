Class {
	#name : 'GbxStatMonitor',
	#superclass : 'Object',
	#instVars : [
		'process',
		'state',
		'stateChangeProtect',
		'nextResumption',
		'delay',
		'archiver',
		'sampleInterval',
		'cacheSampleIntervalMultiplier'
	],
	#classVars : [
		'StatMonitorPriority'
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'utilities' }
GbxStatMonitor >> handlingErrorsDo: aBlock 
[
	"Evaluate aBlock.  If any error occurs (usually caused by stat archive file removal),
	 handle it gracefully, notify or log the error, and turn off stats."

	^aBlock
		on: Exception
		do: 
			[:ex | 
			| msg |
			GBSM statsEnabled: false.
			msg := 'Stats disabled after getting: ' , ex messageText.
			"Drop priority - otherwise, if we're returning from snapshot, the Transcript breaks"
			Processor activeProcess priority: Processor userSchedulingPriority - 1.
			GbsConfiguration current confirm 
				ifTrue: [self gbsMessenger warn: msg]
				ifFalse: [self gbsMessenger comment: msg]]
]

{ #category : 'accessing' }
GbxStatMonitor >> addStatResource: statResource 
[
	archiver isNil ifFalse: [ archiver addStatResource: statResource ]
]

{ #category : 'accessing' }
GbxStatMonitor >> sampleInterval
[
	"Return the interval in milliseconds between two stat samples"

	^sampleInterval
]

{ #category : 'accessing' }
GbxStatMonitor >> setState: newState 
[
	"Uncomment extra debugging to find a problem"

	"| m oldState pnm |
	m := self gbsMessenger.
	oldState := state.
	pnm := Processor activeProcess name.
	pnm isNil ifTrue: [ pnm := Processor activeProcess printString ].
	pnm := pnm, ': ', Processor activeProcess hash printString.
	Transcript cr; show: 'From ', oldState, ' to ', newState, ' by ', pnm.
	(newState == #stopped) ifTrue: [ m assert: (oldState == nil or: [oldState == #shutdown]) failure: 'state changing from %1 to #stopped' with: oldState ].
	(newState == #starting) ifTrue: [ m assert: oldState == #stopped failure: 'state changing from %1 to #starting' with: oldState ].
	(newState == #running) ifTrue: [ m assert: oldState == #starting failure: 'state changing from %1 to #running' with: oldState ].
	(newState == #shutdown) ifTrue: [ m assert: oldState == #running failure: 'state changing from %1 to #shutdown' with: oldState ].
	m assert: oldState == state failure: 'state changed from %1 to %2' with: oldState with: state."

	state := newState
]

{ #category : 'accessing' }
GbxStatMonitor >> removeStatResource: statResource 
[
	"if the instanceId is nil, then that means we haven't yet completed our login and
	the stat resource is being removed. Presumably this means that the login
	was curtailed and we don't need to record anything about this session"

	(archiver isNil or: [statResource instanceId isNil]) 
		ifFalse: [^archiver removeStatResource: statResource]
]

{ #category : 'accessing' }
GbxStatMonitor >> processName
[

	^'GBS Stat Monitor - sample rate ', sampleInterval printString, ' milliseconds'
]

{ #category : 'accessing' }
GbxStatMonitor >> cacheSampleIntervalMultiplier: anInteger 
[
	"This value times sampleInterval is the interval between two cache stat samples.  For example, a
	 cacheSampleIntervalMultiplier of 1 means cache stats will be sampled every time stats are
	 sampled.  A value of 5 means cache stats will be sampled every 5th time.  Cache stats are
	 more expensive to sample than other stats, as they iterate over the gsObjectCache."

	cacheSampleIntervalMultiplier := anInteger
]

{ #category : 'accessing' }
GbxStatMonitor >> isProcessRunning
[

	^state == #running and: [ process notNil and: [ process isTerminated not ]]
]

{ #category : 'accessing' }
GbxStatMonitor >> cacheSampleIntervalMultiplier
[
	"This value times sampleInterval is the interval between two cache stat samples.  For example, a
	 cacheSampleIntervalMultiplier of 1 means cache stats will be sampled every time stats are
	 sampled.  A value of 5 means cache stats will be sampled every 5th time.  Cache stats are
	 more expensive to sample than other stats, as they iterate over the gsObjectCache."

	^cacheSampleIntervalMultiplier
]

{ #category : 'accessing' }
GbxStatMonitor >> archiverClass
[

	^GbxStatArchiver
]

{ #category : 'accessing' }
GbxStatMonitor >> sampleInterval: milliseconds 
[
	"Set the interval between samples in milliseconds"

	sampleInterval := milliseconds.
	process isNil ifFalse: [process name: self processName]
]

{ #category : 'sampling and archiving' }
GbxStatMonitor >> sampleAndArchive: iteration
[
	"This method is executed to perform a single statistics snapshot and archive it.  Return
	 the time in microseconds spent sampling."

	| sampleTime |
	sampleTime := 0.
	archiver isNil ifFalse: [
		(iteration \\ cacheSampleIntervalMultiplier) == 0 ifTrue: [ 
			sampleTime := self sampleCacheStats. ].
		sampleTime := sampleTime + self sampleAndArchiveMainStats.
		].
	^sampleTime
]

{ #category : 'monitor process loop' }
GbxStatMonitor >> startProcess
[
	"GbxStatMonitor instance startProcess"
	"GbxStatMonitor instance stopProcess"

	(process notNil and: [process isTerminated not and: [state == #running]])
		ifTrue: [^self].
	stateChangeProtect critical: 
			[| handoff |
			archiver := self archiverClass new.
			self setState: #starting.
			handoff := Semaphore new.
			process := 
					[self setState: #running.
					handoff signal.
					self monitorLoop]
							newProcess.
			process name: self processName.
			process priority: self class statMonitorPriority.
			process resume.
			handoff wait]
]

{ #category : 'monitor process loop' }
GbxStatMonitor >> stopProcess
[
	"GbxStatMonitor instance startProcess"
	"GbxStatMonitor instance stopProcess"

	| d |
	stateChangeProtect critical: 
			[(process notNil and: [process isTerminated])
				ifTrue: 
					[self setState: #stopped.
					process := nil.
					archiver close].
			process isNil ifFalse: [self setState: #shutdown]].
	"Signal the current delay semaphore to speed up the shutdown"
	(d := delay) isNil ifFalse: [d gbxDisregard].

	"We never send #stopProcess from the monitor process, but I guess this guard doesn't hurt."
	process == Processor activeProcess
		ifFalse: 
			["Wait for the monitor process to complete (unless we *are* the monitor process)"
			[state = #stopped] whileFalse: [(GbxDelay forMilliseconds: 20) wait]]
]

{ #category : 'monitor process loop' }
GbxStatMonitor >> monitorLoop
[
	"This is the loop executed by the GBS Statistics Monitor process.  Use startProcess."

	| i |
	nextResumption := Time millisecondClockValue.
	i := 0.
	[state = #running and: [Processor activeProcess == process]] whileTrue: 
			[| sampleMs |
			i := i + 1.
			self handlingErrorsDo: 
					[sampleMs := (self sampleAndArchive: i) // 1000.
					nextResumption := nextResumption + sampleInterval.
					"Fix for bug 33038 - stat sampling should delay at least as long as it runs"
					nextResumption := nextResumption 
								max: Time millisecondClockValue + sampleMs.
					delay := GbxDelay untilMilliseconds: nextResumption.
					delay wait.
					delay := nil]].
	nextResumption := nil.
	stateChangeProtect critical: 
			[self setState: #stopped.
			process := nil].
	archiver isNil ifFalse: [archiver close].
	archiver := nil
]

{ #category : 'initialize-release' }
GbxStatMonitor >> sampleAndArchiveMainStats
[
	"This method is executed to perform a single manager/session statistics snapshot and archive it.  
	 Return the time in microseconds spent sampling."

	| sampleTime |
	sampleTime := Time gbxClock.
	archiver writeSampleHeaderAndSample.
	sampleTime := Time gbxClock - sampleTime.
	GBSM statResource incMainStatSampleTime: sampleTime.
	^sampleTime
]

{ #category : 'initialize-release' }
GbxStatMonitor >> sampleCacheStats
[
	"This method is executed to perform a single cache statistics snapshot and archive it"

	| sampleTime |
	sampleTime := Time gbxClock.
	"take inventory of the cache"
	GBSM clientMap inventoryCache.
	sampleTime := Time gbxClock - sampleTime.
	GBSM statResource incCacheStatSampleTime: sampleTime.
	^sampleTime
]

{ #category : 'initialize-release' }
GbxStatMonitor >> initialize
[

	"GbxStatMonitor instance initialize"

	stateChangeProtect := Semaphore forMutualExclusion.
	process := nil.
	state := #stopped.
	sampleInterval := 2000.
	cacheSampleIntervalMultiplier := 5. "Every 5th sample will gather cache statistics"
	nextResumption := nil.
	delay := nil
]

{ #category : 'class initialization' }
GbxStatMonitor class >> initialize
[
	"By default, the stat monitor process runs at a higher priority than applications,
	 to get a better chance at each stat collection representing a stable 'snapshot' 
	 in time"

	StatMonitorPriority := Processor userInterruptPriority
]

{ #category : 'configuring' }
GbxStatMonitor class >> statMonitorPriority
[
	"The priority at which the stat monitor process runs."

	^StatMonitorPriority
]

{ #category : 'configuring' }
GbxStatMonitor class >> statMonitorPriority: priorityInteger 
[
	"Assign the stat monitor process priority to be priorityInteger, which must
	 be a valid priority defined by the ProcessorScheduler class.  The next
	 time the stat monitor process is started, it will run at this priority."

	StatMonitorPriority := priorityInteger
]

{ #category : 'instance creation' }
GbxStatMonitor class >> new
[

	"Disallowed.  Use instance to get the sole instance."

	^self shouldNotImplement
]

{ #category : 'instance creation' }
GbxStatMonitor class >> instance
[

	"Returns the sole instance of GbxStatMonitor"
	Instance isNil ifTrue: [ Instance := self basicNew initialize ].
	^Instance
]

