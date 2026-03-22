Class {
	#name : 'GbxWaitingEventDetectorTool',
	#superclass : 'GbxEventDetectorTool',
	#instVars : [
		'eventQueue',
		'waitForEvents',
		'timeout',
		'signalSocket'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxWaitingEventDetectorTool class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'instance creation' }
GbxWaitingEventDetectorTool class >> on: aSession timeout: milliseconds [
	^ self new
		session: aSession;
		timeout: milliseconds;
		yourself
]

{ #category : 'events' }
GbxWaitingEventDetectorTool >> detectEvents [
	"Start waiting for events"
	isDetecting := true.
	eventQueue := SharedQueue new.
	
	[ isDetecting ] whileTrue: [
		self waitForEvent.
	] forkAt: Processor backgroundPriority.
]

{ #category : 'events' }
GbxWaitingEventDetectorTool >> fireEvent: eventName withData: data [
	"Fire an event with data"
	super fireEvent: eventName withData: data.
	
	eventQueue ifNotNil: [
		eventQueue nextPut: { eventName. data }.
	].
]

{ #category : 'initialization' }
GbxWaitingEventDetectorTool >> initialize [
	super initialize.
	waitForEvents := true.
	timeout := 5000. "5 seconds default"
]

{ #category : 'events' }
GbxWaitingEventDetectorTool >> nextEvent [
	"Get next event (blocking)"
	^ eventQueue next
]

{ #category : 'events' }
GbxWaitingEventDetectorTool >> nextEventIfAvailable [
	"Get next event if available (non-blocking)"
	^ eventQueue nextAvailable
]

{ #category : 'events' }
GbxWaitingEventDetectorTool >> nextEventWithTimeout [
	"Get next event with timeout"
	| deadline |
	
	deadline := DateAndTime now + (Duration milliseconds: timeout).
	
	[ DateAndTime now < deadline ] whileTrue: [
		| event |
		event := eventQueue nextAvailable.
		event ifNotNil: [ ^ event ].
		(Delay forMilliseconds: 100) wait.
	].
	
	^ nil
]

{ #category : 'accessing' }
GbxWaitingEventDetectorTool >> timeout [
	^ timeout
]

{ #category : 'accessing' }
GbxWaitingEventDetectorTool >> timeout: anInteger [
	timeout := anInteger
]

{ #category : 'events' }
GbxWaitingEventDetectorTool >> waitForEvent [
	"Wait for an event to occur"
	| script result |
	
	session ifNil: [ ^ self ].
	
	script := '[
		| event |
		event := nil.
		"Wait for signal or break"
		[ 
			System signalSemaphore ifNotNil: [ :sig |
				event := { #signal. sig }
			].
		] on: Error do: [ nil ].
		event
	] value'.
	
	result := session executeAndFetch: script.
	result ifNotNil: [
		self fireEvent: result first withData: result second.
	].
]
