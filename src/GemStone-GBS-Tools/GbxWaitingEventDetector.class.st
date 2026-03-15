Class {
	#name : 'GbxWaitingEventDetector',
	#superclass : 'GbxEventDetector',
	#instVars : [
		'eventQueue',
		'waitForEvents',
		'timeout'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxWaitingEventDetector class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'instance creation' }
GbxWaitingEventDetector class >> on: aSession timeout: milliseconds [
	^ self new
		session: aSession;
		timeout: milliseconds;
		yourself
]

{ #category : 'events' }
GbxWaitingEventDetector >> detectEvents [
	"Start waiting for events"
	isDetecting := true.
	eventQueue := SharedQueue new.
	
	[ isDetecting ] whileTrue: [
		self waitForEvent.
	] forkAt: Processor backgroundPriority.
]

{ #category : 'events' }
GbxWaitingEventDetector >> fireEvent: eventName withData: data [
	"Fire an event with data"
	super fireEvent: eventName withData: data.
	
	eventQueue ifNotNil: [
		eventQueue nextPut: { eventName. data }.
	].
]

{ #category : 'initialization' }
GbxWaitingEventDetector >> initialize [
	super initialize.
	waitForEvents := true.
	timeout := 5000. "5 seconds default"
]

{ #category : 'events' }
GbxWaitingEventDetector >> nextEvent [
	"Get next event (blocking)"
	^ eventQueue next
]

{ #category : 'events' }
GbxWaitingEventDetector >> nextEventIfAvailable [
	"Get next event if available (non-blocking)"
	^ eventQueue nextAvailable
]

{ #category : 'events' }
GbxWaitingEventDetector >> nextEventWithTimeout [
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
GbxWaitingEventDetector >> timeout [
	^ timeout
]

{ #category : 'accessing' }
GbxWaitingEventDetector >> timeout: anInteger [
	timeout := anInteger
]

{ #category : 'events' }
GbxWaitingEventDetector >> waitForEvent [
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
