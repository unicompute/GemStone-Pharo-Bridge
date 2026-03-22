Class {
	#name : 'GbxEventDetector',
	#superclass : 'Object',
	#instVars : [
		'callSequencer',
		'process',
		'runningProtect',
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'initialize-release' }
GbxEventDetector >> initialize
[
	runningProtect := GbxSemaphore forMutualExclusion.
	^self
]

{ #category : 'accessing' }
GbxEventDetector >> session: aSession 
[
	session := aSession.
	callSequencer := session serverInterface callSequencer.
	^self
]

{ #category : 'public' }
GbxEventDetector >> start
[
	"By design, each instance is good for only one start/stop cycle, 
	so we can assume a fresh instance here

	We capture the eventDetectorThread so the tools can make
	more intelligent decisions about waiting for the session semaphore"

	self newRunningProcess.
	session sessionProtect eventDetectorThread: process
]

{ #category : 'public' }
GbxEventDetector >> stop
[
	"By design, each instance is good for only one start/stop cycle,
	so we can assume a running process here."
	"Start and stop should be sent only from the same GbxCInterface, 
	while holding its accessProtect"

	process isNil ifTrue: [^self].	"process could be nil legitimately if session terminated in wrong spot on login"
	process terminate.
	"The semaphore will be signaled when the process has 
			             actually unwound from its critical section. Wait for it."
	runningProtect wait.
	process := nil.
	session sessionProtect eventDetectorThread: nil
]

{ #category : 'private' }
GbxEventDetector >> process
[
	^process
]

{ #category : 'private' }
GbxEventDetector >> newRunningProcess
[
	^self subclassResponsibility
]

{ #category : 'private' }
GbxEventDetector >> pollForCurrentSignals
[

	| result |
	
	[result := [session pollForSignalDeferFatalErrors: true]
				on: GbsGemStoneError
				do: 
					[:ex |
					"If there's a fatal error, the event detector thread should shut down.
					 We can't rely on catching GbsFataError's as not all fatal errors have client class mappings.
					 We *know* the polling uses a deprecated method. If we catch a Deprecated, just resume.
					 On Pharo, a fresh login can also race into an object-does-not-exist
					 poll result before the session is fully settled; treat that as no event."
					ex originator number // 1000 = 4
						ifTrue: [Processor activeProcess terminate]
						ifFalse: [ex originator number = 2746
							ifTrue: [ex resume]
							ifFalse: [ex originator number = 2101
								ifTrue: [ex return: session]
								ifFalse: [ex pass]]]].
	result ~~ session]
			whileTrue: []
]

{ #category : 'instance creation' }
GbxEventDetector class >> session: aSession
[
	"Answer a new instance of the appropriate concrete subclass"

	| class |
	class := aSession isLinked ifTrue: [GbxPollingEventDetector] ifFalse: [GbxWaitingEventDetector].
	^class privSession: aSession
]

{ #category : 'private-instance creation' }
GbxEventDetector class >> privSession: aSession 
[
	^self new session: aSession
]

{ #category : 'private-instance creation' }
GbxEventDetector class >> new
[
	^super new initialize
]
