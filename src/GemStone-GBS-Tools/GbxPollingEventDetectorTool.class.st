Class {
	#name : 'GbxPollingEventDetectorTool',
	#superclass : 'GbxEventDetectorTool',
	#instVars : [
		'pollInterval',
		'lastPollTime'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxPollingEventDetectorTool class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'instance creation' }
GbxPollingEventDetectorTool class >> on: aSession interval: milliseconds [
	^ self new
		session: aSession;
		pollInterval: milliseconds;
		yourself
]

{ #category : 'events' }
GbxPollingEventDetectorTool >> detectEvents [
	"Start polling for events"
	isDetecting := true.
	
	[ isDetecting ] whileTrue: [
		self pollForEvents.
		lastPollTime := DateAndTime now.
		(Delay forMilliseconds: pollInterval) wait.
	] forkAt: Processor backgroundPriority.
]

{ #category : 'initialization' }
GbxPollingEventDetectorTool >> initialize [
	super initialize.
	pollInterval := 500. "500ms default"
]

{ #category : 'accessing' }
GbxPollingEventDetectorTool >> lastPollTime [
	^ lastPollTime
]

{ #category : 'accessing' }
GbxPollingEventDetectorTool >> pollInterval [
	^ pollInterval
]

{ #category : 'accessing' }
GbxPollingEventDetectorTool >> pollInterval: anInteger [
	pollInterval := anInteger
]

{ #category : 'events' }
GbxPollingEventDetectorTool >> pollForEvents [
	"Poll for events from GemStone"
	| script result |
	
	session ifNil: [ ^ self ].
	
	script := '[
		| events |
		events := OrderedCollection new.
		"Check for signals"
		[ System signalSemaphore ] on: Error do: [ nil ].
		events
	] value'.
	
	result := session executeAndFetch: script.
	result ifNotNil: [
		result do: [ :event |
			self fireEvent: event first withData: event second.
		].
	].
]
