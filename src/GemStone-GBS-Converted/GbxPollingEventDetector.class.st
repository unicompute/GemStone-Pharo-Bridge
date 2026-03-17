Class {
	#name : 'GbxPollingEventDetector',
	#superclass : 'GbxEventDetector',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'public' }
GbxPollingEventDetector >> newRunningProcess
	"Create a Smalltalk process to poll for GemStone asynchronous events.
	The polling frequency (in milliseconds) can be modified by sending
	GbsConfiguration current eventPollingFrequency: milliseconds"
	"We'll prevent the polling when:
	1- GBS is in the middle of some replication
	2- Processor is in 'switch disabled' mode (there is a VA callback in action!)

	All in the name of not interrupting some GS interaction"

	| eventPollerBlock |
	eventPollerBlock :=
			[runningProtect critical: 
					[
					[[self pollForCurrentSignals] on: Error
						do: 
							[:ex |
							session eventDetectorErrorHandler isNil
								ifTrue: [ex pass]
								ifFalse: [session eventDetectorErrorHandler value: ex]].
					(GbxDelay forMilliseconds: GbsConfiguration current eventPollingFrequency)
						wait]
							repeat]].
	process := eventPollerBlock
				gbxNewProcessNamed: 'GbsEventPollerForSession' , session printString.
	process priority: session configuration eventPriority.
	process resume

