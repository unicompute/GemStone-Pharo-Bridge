Class {
	#name : 'GbxObjectMemoryStat',
	#superclass : 'GbxStatResource',
	#instVars : [
		'session',
		'objectCount',
		'byteCount',
		'oopCount',
		'percentFull'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxObjectMemoryStat class >> on: aSession [
	^ self new
		session: aSession;
		resourceType: #objectMemory;
		yourself
]

{ #category : 'accessing' }
GbxObjectMemoryStat >> byteCount [
	^ byteCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxObjectMemoryStat >> collectStats [
	"Collect object memory statistics from GemStone"
	| script result parts |
	
	session ifNil: [ ^ self ].
	
	script := '[
		| stream |
		stream := WriteStream on: String new.
		stream
			nextPutAll: System objectCount asString; nextPutAll: ''|'';
			nextPutAll: System byteCount asString; nextPutAll: ''|'';
			nextPutAll: System oopCount asString; nextPutAll: ''|'';
			nextPutAll: System percentFull asString.
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	parts := result splitOn: $|.
	parts size >= 4 ifTrue: [
		objectCount := parts first asInteger.
		byteCount := parts second asInteger.
		oopCount := parts third asInteger.
		percentFull := parts fourth asInteger.
		
		self updateStat: 'objectCount' value: objectCount.
		self updateStat: 'byteCount' value: byteCount.
		self updateStat: 'oopCount' value: oopCount.
		self updateStat: 'percentFull' value: percentFull.
	].
]

{ #category : 'accessing' }
GbxObjectMemoryStat >> initialize [
	super initialize.
	name := 'Object Memory'.
	self addStat: (GbxStat named: 'objectCount').
	self addStat: (GbxStat named: 'byteCount').
	self addStat: (GbxStat named: 'oopCount').
	self addStat: (GbxStat named: 'percentFull').
]

{ #category : 'accessing' }
GbxObjectMemoryStat >> objectCount [
	^ objectCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxObjectMemoryStat >> oopCount [
	^ oopCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxObjectMemoryStat >> percentFull [
	^ percentFull ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxObjectMemoryStat >> session [
	^ session
]

{ #category : 'accessing' }
GbxObjectMemoryStat >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxObjectMemoryStat >> summary [
	"Return a summary string of object memory stats"
	^ 'Object Memory: ', objectCount asString, ' objects, ',
	  byteCount asString, ' bytes, ',
	  oopCount asString, ' oops (', percentFull asString, '% full)'
]
