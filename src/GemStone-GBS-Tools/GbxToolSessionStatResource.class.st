Class {
	#name : 'GbxToolSessionStatResource',
	#superclass : 'GbxToolStatResource',
	#instVars : [
		'session',
		'sessionId',
		'loginTime',
		'rpcCount',
		'commitCount',
		'abortCount'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxToolSessionStatResource class >> on: aSession [
	^ self new
		session: aSession;
		resourceType: #session;
		yourself
]

{ #category : 'accessing' }
GbxToolSessionStatResource >> abortCount [
	^ abortCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxToolSessionStatResource >> collectStats [
	"Collect session statistics from GemStone"
	| script result parts |
	
	session ifNil: [ ^ self ].
	
	script := '[
		| stream sess |
		sess := GsCurrentSession current.
		stream := WriteStream on: String new.
		stream
			nextPutAll: sess sessionId asString; nextPutAll: ''|'';
			nextPutAll: sess loginTime asString; nextPutAll: ''|'';
			nextPutAll: sess rpcCount asString; nextPutAll: ''|'';
			nextPutAll: sess commitCount asString; nextPutAll: ''|'';
			nextPutAll: sess abortCount asString.
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	parts := result splitOn: $|.
	parts size >= 5 ifTrue: [
		sessionId := parts first.
		loginTime := parts second.
		rpcCount := parts third asInteger.
		commitCount := parts fourth asInteger.
		abortCount := parts fifth asInteger.
		
		self updateStat: 'sessionId' value: sessionId.
		self updateStat: 'loginTime' value: loginTime.
		self updateStat: 'rpcCount' value: rpcCount.
		self updateStat: 'commitCount' value: commitCount.
		self updateStat: 'abortCount' value: abortCount.
	].
]

{ #category : 'accessing' }
GbxToolSessionStatResource >> commitCount [
	^ commitCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxToolSessionStatResource >> initialize [
	super initialize.
	name := 'Session'.
	self addStat: (GbxToolStat named: 'sessionId').
	self addStat: (GbxToolStat named: 'loginTime').
	self addStat: (GbxToolStat named: 'rpcCount').
	self addStat: (GbxToolStat named: 'commitCount').
	self addStat: (GbxToolStat named: 'abortCount').
]

{ #category : 'accessing' }
GbxToolSessionStatResource >> loginTime [
	^ loginTime
]

{ #category : 'accessing' }
GbxToolSessionStatResource >> rpcCount [
	^ rpcCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxToolSessionStatResource >> session [
	^ session
]

{ #category : 'accessing' }
GbxToolSessionStatResource >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxToolSessionStatResource >> sessionId [
	^ sessionId
]

{ #category : 'accessing' }
GbxToolSessionStatResource >> summary [
	"Return a summary string of session stats"
	^ 'Session ', sessionId, ': ', rpcCount asString, ' RPCs, ',
	  commitCount asString, ' commits, ',
	  abortCount asString, ' aborts'
]
