Class {
	#name : 'GbxWaitingEventDetector',
	#superclass : 'GbxEventDetector',
	#instVars : [
		'signalSocket'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private' }
GbxWaitingEventDetector >> newRunningProcess
[
	"Start a new process that does readWait's on the GCI's out-of-band socket."

	| eventWaitBlock |
	eventWaitBlock :=
			[runningProtect critical:
					[[
					[[self pollForCurrentSignals.
					signalSocket readWaitWithTimeoutMs: self readWaitTimeout]
						on: GbsWSAEventSelect
						do:
							[:ex |
							"Ignore stale socket notifications during teardown."
							]]
						on: Error
						do:
							[:ex |
							session eventDetectorErrorHandler isNil
								ifTrue: [ex pass]
								ifFalse: [session eventDetectorErrorHandler value: ex]]]
							repeat]].
	process := eventWaitBlock
				gbxNewProcessNamed: 'GBS EventDetector for ' , session printString.
	process priority: session configuration eventPriority.
	process resume
]

{ #category : 'public' }
GbxWaitingEventDetector >> start
[
	self setupSignalSocket.
	super start
]

{ #category : 'public' }
GbxWaitingEventDetector >> stop
[
	super stop.
	self teardownSignalSocket
]

{ #category : 'private' }
GbxWaitingEventDetector >> notQuiteInfinity
[
	^600000
]

{ #category : 'private' }
GbxWaitingEventDetector >> teardownSignalSocket
[
	callSequencer isNil
		ifFalse: [
			callSequencer shutdownSocket: signalSocket
				withHandle: callSequencer getSignalHandle ].
	signalSocket := nil
]

{ #category : 'private' }
GbxWaitingEventDetector >> readWaitTimeout
[
	^session configuration backupPolling
		ifTrue: [session configuration eventPollingFrequency]
		ifFalse: [self notQuiteInfinity]
]

{ #category : 'private' }
GbxWaitingEventDetector >> setupSignalSocket
[
	signalSocket := callSequencer socketAccessorOn: callSequencer getSignalHandle
]
