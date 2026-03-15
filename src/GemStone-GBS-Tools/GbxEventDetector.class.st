Class {
	#name : 'GbxEventDetector',
	#superclass : 'Object',
	#instVars : [
		'session',
		'eventHandlers',
		'isDetecting',
		'eventCount'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxEventDetector class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'events' }
GbxEventDetector >> addHandler: aBlock forEvent: eventName [
	"Add an event handler"
	eventHandlers ifNil: [ eventHandlers := Dictionary new ].
	
	(eventHandlers at: eventName ifAbsentPut: [ OrderedCollection new ])
		add: aBlock.
]

{ #category : 'events' }
GbxEventDetector >> detectEvents [
	"Start detecting events"
	isDetecting := true.
	
	[ isDetecting ] whileTrue: [
		self pollForEvents.
		(Delay forMilliseconds: 100) wait.
	] forkAt: Processor backgroundPriority.
]

{ #category : 'accessing' }
GbxEventDetector >> eventCount [
	^ eventCount ifNil: [ 0 ]
]

{ #category : 'events' }
GbxEventDetector >> fireEvent: eventName withData: data [
	"Fire an event with data"
	| handlers |
	
	handlers := eventHandlers at: eventName ifAbsent: [ nil ].
	handlers ifNotNil: [
		handlers do: [ :handler |
			[ handler value: data ] on: Error do: [ ].
		].
	].
	
	eventCount := eventCount + 1.
]

{ #category : 'initialization' }
GbxEventDetector >> initialize [
	super initialize.
	eventHandlers := Dictionary new.
	isDetecting := false.
	eventCount := 0.
]

{ #category : 'accessing' }
GbxEventDetector >> isDetecting [
	^ isDetecting ifNil: [ false ]
]

{ #category : 'events' }
GbxEventDetector >> pollForEvents [
	"Poll for events from GemStone"
	| script result |
	
	session ifNil: [ ^ self ].
	
	script := '[
		| events |
		events := OrderedCollection new.
		"Check for signals, breaks, etc."
		System signalSemaphore ifNotNil: [ :sig |
			events add: { #signal. sig }
		].
		events
	] value'.
	
	result := session executeAndFetch: script.
	result ifNotNil: [
		result do: [ :event |
			self fireEvent: event first withData: event second.
		].
	].
]

{ #category : 'accessing' }
GbxEventDetector >> session [
	^ session
]

{ #category : 'accessing' }
GbxEventDetector >> session: aSession [
	session := aSession
]

{ #category : 'events' }
GbxEventDetector >> stopDetecting [
	"Stop detecting events"
	isDetecting := false.
]
