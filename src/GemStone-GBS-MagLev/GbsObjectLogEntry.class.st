Class {
	#name : 'GbsObjectLogEntry',
	#superclass : 'Object',
	#instVars : [
		'index',
		'priority',
		'label',
		'pid',
		'timestamp',
		'tag',
		'tagged',
		'objectOop',
		'objectDisplayString',
		'session'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsObjectLogEntry class >> index: anIndex priority: aPriority label: aLabel pid: aPid timestamp: aTimestamp tag: aTag tagged: aBoolean objectOop: anOop objectDisplayString: anObjectDisplayString session: aSession [
	^ self new
		index: anIndex;
		priority: aPriority;
		label: aLabel;
		pid: aPid;
		timestamp: aTimestamp;
		tag: aTag;
		tagged: aBoolean;
		objectOop: anOop;
		objectDisplayString: anObjectDisplayString;
		session: aSession;
		yourself
]

{ #category : 'querying' }
GbsObjectLogEntry >> displayString [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: self priorityLabel;
			nextPutAll: ' #';
			nextPutAll: self index printString;
			nextPutAll: ' ';
			nextPutAll: self label.
		self hasObject ifTrue: [
			stream
				nextPutAll: ' -> ';
				nextPutAll: self objectDisplayString ] ]
]

{ #category : 'querying' }
GbsObjectLogEntry >> detailText [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'ObjectLog Entry #';
			nextPutAll: self index printString;
			cr; cr;
			nextPutAll: 'Priority: ';
			nextPutAll: self priorityLabel;
			cr;
			nextPutAll: 'Label: ';
			nextPutAll: self label.
		self timestamp ifNotNil: [
			stream
				cr;
				nextPutAll: 'Timestamp: ';
				nextPutAll: self timestamp asString ].
		self pid ifNotNil: [
			stream
				cr;
				nextPutAll: 'Pid: ';
				nextPutAll: self pid printString ].
		self tagged ifTrue: [
			stream
				cr;
				nextPutAll: 'Tag: ';
				nextPutAll: self tag ].
		self hasObject ifTrue: [
			stream
				cr;
				nextPutAll: 'Object: ';
				nextPutAll: self objectDisplayString.
			self objectOop ifNotNil: [
				stream
					nextPutAll: ' (oop ';
					nextPutAll: self objectOop printString;
					nextPut: $) ] ] ]
]

{ #category : 'querying' }
GbsObjectLogEntry >> hasObject [
	^ objectOop notNil
]

{ #category : 'accessing' }
GbsObjectLogEntry >> index [
	^ index ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbsObjectLogEntry >> index: anInteger [
	index := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger asInteger ]
]

{ #category : 'accessing' }
GbsObjectLogEntry >> label [
	^ label ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsObjectLogEntry >> label: aString [
	label := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'querying' }
GbsObjectLogEntry >> object [
	| proxy |
	self hasObject ifFalse: [ ^ nil ].
	session ifNil: [ ^ nil ].
	proxy := session objectForOop: self objectOop.
	^ session materializeMaglevRuntimeValue: proxy
]

{ #category : 'accessing' }
GbsObjectLogEntry >> objectDisplayString [
	^ objectDisplayString ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsObjectLogEntry >> objectDisplayString: aString [
	objectDisplayString := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsObjectLogEntry >> objectOop [
	^ objectOop
]

{ #category : 'accessing' }
GbsObjectLogEntry >> objectOop: anInteger [
	objectOop := anInteger
]

{ #category : 'accessing' }
GbsObjectLogEntry >> pid [
	^ pid
]

{ #category : 'accessing' }
GbsObjectLogEntry >> pid: anInteger [
	pid := anInteger
]

{ #category : 'accessing' }
GbsObjectLogEntry >> priority [
	^ priority ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbsObjectLogEntry >> priority: anInteger [
	priority := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger asInteger ]
]

{ #category : 'querying' }
GbsObjectLogEntry >> priorityLabel [
	^ {
		1 -> 'FATAL'.
		2 -> 'ERROR'.
		3 -> 'WARN'.
		4 -> 'INFO'.
		5 -> 'DEBUG'.
		6 -> 'TRACE' }
		asDictionary
		at: self priority
		ifAbsent: [ self priority printString ]
]

{ #category : 'printing' }
GbsObjectLogEntry >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self displayString;
		nextPut: $)
]

{ #category : 'accessing' }
GbsObjectLogEntry >> session [
	^ session
]

{ #category : 'accessing' }
GbsObjectLogEntry >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbsObjectLogEntry >> tag [
	^ tag ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsObjectLogEntry >> tag: aString [
	tag := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsObjectLogEntry >> tagged [
	^ tagged == true
]

{ #category : 'accessing' }
GbsObjectLogEntry >> tagged: aBoolean [
	tagged := aBoolean == true
]

{ #category : 'accessing' }
GbsObjectLogEntry >> timestamp [
	^ timestamp
]

{ #category : 'accessing' }
GbsObjectLogEntry >> timestamp: anObject [
	timestamp := anObject
]
