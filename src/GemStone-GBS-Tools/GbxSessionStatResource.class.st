Class {
	#name : 'GbxSessionStatResource',
	#superclass : 'GbxStatResource',
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
GbxSessionStatResource class >> on: aSession [
	^ self new
		session: aSession;
		resourceType: #session;
		yourself
]

{ #category : 'accessing' }
GbxSessionStatResource >> abortCount [
	^ abortCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxSessionStatResource >> collectStats [
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
GbxSessionStatResource >> commitCount [
	^ commitCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxSessionStatResource >> initialize [
	super initialize.
	name := 'Session'.
	self addStat: (GbxStat named: 'sessionId').
	self addStat: (GbxStat named: 'loginTime').
	self addStat: (GbxStat named: 'rpcCount').
	self addStat: (GbxStat named: 'commitCount').
	self addStat: (GbxStat named: 'abortCount').
]

{ #category : 'accessing' }
GbxSessionStatResource >> loginTime [
	^ loginTime
]

{ #category : 'accessing' }
GbxSessionStatResource >> rpcCount [
	^ rpcCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxSessionStatResource >> session [
	^ session
]

{ #category : 'accessing' }
GbxSessionStatResource >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxSessionStatResource >> sessionId [
	^ sessionId
]

{ #category : 'accessing' }
GbxSessionStatResource >> summary [
	"Return a summary string of session stats"
	^ 'Session ', sessionId, ': ', rpcCount asString, ' RPCs, ',
	  commitCount asString, ' commits, ',
	  abortCount asString, ' aborts'
]
