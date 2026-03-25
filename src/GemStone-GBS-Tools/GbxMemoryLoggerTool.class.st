Class {
	#name : 'GbxMemoryLoggerTool',
	#superclass : 'GbxLoggerTool',
	#instVars : [
		'messages',
		'maxMessages'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxMemoryLoggerTool class >> maxMessages: anInteger [
	^ self new
		maxMessages: anInteger;
		yourself
]

{ #category : 'instance creation' }
GbxMemoryLoggerTool class >> new [
	^ super new
		initialize;
		yourself
]

{ #category : 'accessing' }
GbxMemoryLoggerTool >> clear [
	"Clear all logged messages"
	messages := OrderedCollection new.
	logCount := 0.
]

{ #category : 'initialization' }
GbxMemoryLoggerTool >> initialize [
	super initialize.
	messages := OrderedCollection new.
	maxMessages := 1000.
]

{ #category : 'logging' }
GbxMemoryLoggerTool >> log: aString [
	"Log a message to memory"
	| timestamp message |
	
	messages ifNil: [ messages := OrderedCollection new ].
	
	timestamp := DateAndTime now asString.
	message := { timestamp. aString }.
	
	messages add: message.
	logCount := logCount + 1.
	
	"Trim if needed"
	messages size > self maxMessages ifTrue: [
		messages removeFirst: messages size - self maxMessages.
	].
]

{ #category : 'accessing' }
GbxMemoryLoggerTool >> maxMessages [
	^ maxMessages ifNil: [ 1000 ]
]

{ #category : 'accessing' }
GbxMemoryLoggerTool >> maxMessages: anInteger [
	maxMessages := anInteger
]

{ #category : 'accessing' }
GbxMemoryLoggerTool >> messages [
	^ messages ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxMemoryLoggerTool >> messagesAsText [
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
GbxMemoryLoggerTool >> recentMessages: count [
	"Get the most recent N messages"
	| startIndex |
	
	messages ifNil: [ ^ #() ].
	
	startIndex := messages size - count + 1.
	startIndex < 1 ifTrue: [ startIndex := 1 ].
	
	^ messages copyFrom: startIndex to: messages size.
]
