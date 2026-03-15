Class {
	#name : 'GbxPollingEventDetector',
	#superclass : 'GbxEventDetector',
	#instVars : [
		'pollInterval',
		'lastPollTime'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxPollingEventDetector class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'instance creation' }
GbxPollingEventDetector class >> on: aSession interval: milliseconds [
	^ self new
		session: aSession;
		pollInterval: milliseconds;
		yourself
]

{ #category : 'events' }
GbxPollingEventDetector >> detectEvents [
	"Start polling for events"
	isDetecting := true.
	
	[ isDetecting ] whileTrue: [
		self pollForEvents.
		lastPollTime := DateAndTime now.
		(Delay forMilliseconds: pollInterval) wait.
	] forkAt: Processor backgroundPriority.
]

{ #category : 'initialization' }
GbxPollingEventDetector >> initialize [
	super initialize.
	pollInterval := 500. "500ms default"
]

{ #category : 'accessing' }
GbxPollingEventDetector >> lastPollTime [
	^ lastPollTime
]

{ #category : 'accessing' }
GbxPollingEventDetector >> pollInterval [
	^ pollInterval
]

{ #category : 'accessing' }
GbxPollingEventDetector >> pollInterval: anInteger [
	pollInterval := anInteger
]

{ #category : 'events' }
GbxPollingEventDetector >> pollForEvents [
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
