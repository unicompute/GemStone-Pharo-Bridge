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
		'Instance',
		'StatMonitorPriority'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'initialize-release' }
GbxStatMonitor class >> initialize [
	StatMonitorPriority := Processor userInterruptPriority
]

{ #category : 'instance creation' }
GbxStatMonitor class >> instance [
	Instance ifNil: [ Instance := self basicNew initialize ].
	^ Instance
]

{ #category : 'instance creation' }
GbxStatMonitor class >> new [
	^ self instance
]

{ #category : 'configuring' }
GbxStatMonitor class >> statMonitorPriority [
	StatMonitorPriority ifNil: [ self initialize ].
	^ StatMonitorPriority
]

{ #category : 'configuring' }
GbxStatMonitor class >> statMonitorPriority: priorityInteger [
	StatMonitorPriority := priorityInteger
]

{ #category : 'accessing' }
GbxStatMonitor >> addStatResource: statResource [
	archiver ifNil: [ ^ self ].
	archiver addStatResource: statResource
]

{ #category : 'accessing' }
GbxStatMonitor >> archiverClass [
	^ GbxStatArchiver
]

{ #category : 'accessing' }
GbxStatMonitor >> cacheSampleIntervalMultiplier [
	^ cacheSampleIntervalMultiplier
]

{ #category : 'accessing' }
GbxStatMonitor >> cacheSampleIntervalMultiplier: anInteger [
	cacheSampleIntervalMultiplier := anInteger max: 1
]

{ #category : 'utilities' }
GbxStatMonitor >> handlingErrorsDo: aBlock [
	^ aBlock
		on: Exception
		do: [ :ex |
			Transcript
				cr;
				show: 'Stats disabled after getting: ', ex messageText.
			self setState: #shutdown ]
]

{ #category : 'initialization' }
GbxStatMonitor >> initialize [
	super initialize.
	stateChangeProtect := Semaphore forMutualExclusion.
	process := nil.
	state := #stopped.
	sampleInterval := 2000.
	cacheSampleIntervalMultiplier := 5.
	nextResumption := nil.
	delay := nil.
	^ self
]

{ #category : 'testing' }
GbxStatMonitor >> isProcessRunning [
	^ state = #running and: [ process notNil and: [ process isTerminated not ] ]
]

{ #category : 'monitor process loop' }
GbxStatMonitor >> monitorLoop [
	| iteration |

	iteration := 0.
	nextResumption := Time millisecondClockValue.
	[ state = #running and: [ Processor activeProcess == process ] ] whileTrue: [
		iteration := iteration + 1.
		self handlingErrorsDo: [ self sampleAndArchive: iteration ].
		state = #running ifTrue: [
			nextResumption := Time millisecondClockValue + sampleInterval.
			delay := Delay forMilliseconds: sampleInterval.
			[ delay wait ] ensure: [ delay := nil ] ] ].
	nextResumption := nil.
	stateChangeProtect critical: [
		process := nil.
		self setState: #stopped ].
	archiver ifNotNil: [ archiver close ].
	archiver := nil
]

{ #category : 'accessing' }
GbxStatMonitor >> processName [
	^ 'GBS Stat Monitor - sample rate ', sampleInterval printString, ' milliseconds'
]

{ #category : 'accessing' }
GbxStatMonitor >> removeStatResource: statResource [
	(archiver isNil or: [ statResource isNil or: [ statResource instanceId isNil ] ])
		ifTrue: [ ^ self ].
	archiver removeStatResource: statResource
]

{ #category : 'sampling and archiving' }
GbxStatMonitor >> sampleAndArchive: iteration [
	| sampleTime |

	sampleTime := 0.
	archiver isNil ifTrue: [ ^ sampleTime ].
	(iteration \\ cacheSampleIntervalMultiplier) = 0 ifTrue: [
		sampleTime := self sampleCacheStats ].
	sampleTime := sampleTime + self sampleAndArchiveMainStats.
	^ sampleTime
]

{ #category : 'sampling and archiving' }
GbxStatMonitor >> sampleAndArchiveMainStats [
	| sampleTime |

	sampleTime := Time millisecondClockValue.
	archiver writeSampleHeaderAndSample.
	sampleTime := (Time millisecondClockValue - sampleTime) * 1000.
	GBSM statResource incMainStatSampleTime: sampleTime.
	^ sampleTime
]

{ #category : 'sampling and archiving' }
GbxStatMonitor >> sampleCacheStats [
	| sampleTime clientMap |

	sampleTime := Time millisecondClockValue.
	clientMap := GBSM clientMap.
	(clientMap notNil and: [ clientMap respondsTo: #inventoryCache ])
		ifTrue: [ clientMap inventoryCache ].
	sampleTime := (Time millisecondClockValue - sampleTime) * 1000.
	GBSM statResource incCacheStatSampleTime: sampleTime.
	^ sampleTime
]

{ #category : 'accessing' }
GbxStatMonitor >> sampleInterval [
	^ sampleInterval
]

{ #category : 'accessing' }
GbxStatMonitor >> sampleInterval: milliseconds [
	sampleInterval := milliseconds max: 1.
	process ifNotNil: [ process name: self processName ]
]

{ #category : 'accessing' }
GbxStatMonitor >> setState: newState [
	state := newState
]

{ #category : 'monitor process loop' }
GbxStatMonitor >> startProcess [
	self isProcessRunning ifTrue: [ ^ self ].
	stateChangeProtect critical: [
		archiver ifNotNil: [ archiver close ].
		archiver := self archiverClass new.
		self setState: #running.
		process := [ self monitorLoop ] newProcess.
		process
			name: self processName;
			priority: self class statMonitorPriority;
			resume ]
]

{ #category : 'monitor process loop' }
GbxStatMonitor >> stopProcess [
	| currentProcess |

	stateChangeProtect critical: [
		currentProcess := process.
		currentProcess ifNil: [ ^ self ].
		self setState: #shutdown ].
	currentProcess == Processor activeProcess
		ifFalse: [ currentProcess terminate ].
	stateChangeProtect critical: [
		process := nil.
		self setState: #stopped ].
	archiver ifNotNil: [ archiver close ].
	archiver := nil
]
