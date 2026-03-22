Class {
	#name : 'GbxEventDetectorTool',
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
GbxEventDetectorTool class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'events' }
GbxEventDetectorTool >> addHandler: aBlock forEvent: eventName [
	"Add an event handler"
	eventHandlers ifNil: [ eventHandlers := Dictionary new ].
	
	(eventHandlers at: eventName ifAbsentPut: [ OrderedCollection new ])
		add: aBlock.
]

{ #category : 'events' }
GbxEventDetectorTool >> detectEvents [
	"Start detecting events"
	isDetecting := true.
	
	[ isDetecting ] whileTrue: [
		self pollForEvents.
		(Delay forMilliseconds: 100) wait.
	] forkAt: Processor backgroundPriority.
]

{ #category : 'accessing' }
GbxEventDetectorTool >> eventCount [
	^ eventCount ifNil: [ 0 ]
]

{ #category : 'events' }
GbxEventDetectorTool >> fireEvent: eventName withData: data [
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
GbxEventDetectorTool >> initialize [
	super initialize.
	eventHandlers := Dictionary new.
	isDetecting := false.
	eventCount := 0.
]

{ #category : 'accessing' }
GbxEventDetectorTool >> isDetecting [
	^ isDetecting ifNil: [ false ]
]

{ #category : 'events' }
GbxEventDetectorTool >> pollForEvents [
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
GbxEventDetectorTool >> session [
	^ session
]

{ #category : 'accessing' }
GbxEventDetectorTool >> session: aSession [
	session := aSession
]

{ #category : 'events' }
GbxEventDetectorTool >> stopDetecting [
	"Stop detecting events"
	isDetecting := false.
]
