Class {
	#name : 'GbxMemoryLogger',
	#superclass : 'GbxLogger',
	#instVars : [
		'messages',
		'maxMessages'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxMemoryLogger class >> new [
	^ super new
		initialize;
		yourself
]

{ #category : 'instance creation' }
GbxMemoryLogger class >> maxMessages: anInteger [
	^ self new
		maxMessages: anInteger;
		yourself
]

{ #category : 'accessing' }
GbxMemoryLogger >> clear [
	"Clear all logged messages"
	messages := OrderedCollection new.
	logCount := 0.
]

{ #category : 'logging' }
GbxMemoryLogger >> log: aString [
	"Log a message to memory"
	| timestamp message |
	
	messages ifNil: [ messages := OrderedCollection new ].
	
	timestamp := DateAndTime now asString.
	message := { timestamp. aString }.
	
	messages add: message.
	logCount := logCount + 1.
	
	"Trim if needed"
	messages size > maxMessages ifTrue: [
		messages removeFirst: messages size - maxMessages.
	].
]

{ #category : 'accessing' }
GbxMemoryLogger >> maxMessages [
	^ maxMessages ifNil: [ 1000 ]
]

{ #category : 'accessing' }
GbxMemoryLogger >> maxMessages: anInteger [
	maxMessages := anInteger
]

{ #category : 'accessing' }
GbxMemoryLogger >> messages [
	^ messages ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxMemoryLogger >> messagesAsText [
	"Return all messages as formatted text"
	| stream |
	
	stream := WriteStream on: String new.
	
	messages ifNotNil: [
		messages do: [ :msg |
			stream
				nextPutAll: msg first;
				nextPutAll: ' ';
				nextPutAll: msg second;
				cr.
		].
	].
	
	^ stream contents
]

{ #category : 'accessing' }
GbxMemoryLogger >> recentMessages: count [
	"Get the most recent N messages"
	| startIndex |
	
	messages ifNil: [ ^ #() ].
	
	startIndex := messages size - count + 1.
	startIndex < 1 ifTrue: [ startIndex := 1 ].
	
	^ messages copyFrom: startIndex to: messages size.
]
