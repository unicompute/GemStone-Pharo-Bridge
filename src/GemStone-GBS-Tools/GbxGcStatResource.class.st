Class {
	#name : 'GbxGcStatResource',
	#superclass : 'GbxToolStatResource',
	#instVars : [
		'session',
		'gcCount',
		'gcTime',
		'lastGcTime',
		'objectsScavenged',
		'objectsTenured'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxGcStatResource class >> on: aSession [
	^ self new
		session: aSession;
		resourceType: #garbageCollection;
		yourself
]

{ #category : 'accessing' }
GbxGcStatResource >> collectStats [
	"Collect GC statistics from GemStone"
	| script result parts |
	
	session ifNil: [ ^ self ].
	
	script := '[
		| stream |
		stream := WriteStream on: String new.
		stream
			nextPutAll: System vmGcCount asString; nextPutAll: ''|'';
			nextPutAll: System vmGcTime asString; nextPutAll: ''|'';
			nextPutAll: System lastGcTime asString; nextPutAll: ''|'';
			nextPutAll: System objectsScavenged asString; nextPutAll: ''|'';
			nextPutAll: System objectsTenured asString.
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	parts := result splitOn: $|.
	parts size >= 5 ifTrue: [
		gcCount := parts first asInteger.
		gcTime := parts second asInteger.
		lastGcTime := parts third asInteger.
		objectsScavenged := parts fourth asInteger.
		objectsTenured := parts fifth asInteger.
		
		self updateStat: 'gcCount' value: gcCount.
		self updateStat: 'gcTime' value: gcTime.
		self updateStat: 'lastGcTime' value: lastGcTime.
		self updateStat: 'objectsScavenged' value: objectsScavenged.
		self updateStat: 'objectsTenured' value: objectsTenured.
	].
]

{ #category : 'accessing' }
GbxGcStatResource >> gcCount [
	^ gcCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxGcStatResource >> gcTime [
	^ gcTime ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxGcStatResource >> initialize [
	super initialize.
	name := 'Garbage Collection'.
	self addStat: (GbxToolStat named: 'gcCount').
	self addStat: (GbxToolStat named: 'gcTime').
	self addStat: (GbxToolStat named: 'lastGcTime').
	self addStat: (GbxToolStat named: 'objectsScavenged').
	self addStat: (GbxToolStat named: 'objectsTenured').
]

{ #category : 'accessing' }
GbxGcStatResource >> lastGcTime [
	^ lastGcTime ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxGcStatResource >> objectsScavenged [
	^ objectsScavenged ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxGcStatResource >> objectsTenured [
	^ objectsTenured ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxGcStatResource >> session [
	^ session
]

{ #category : 'accessing' }
GbxGcStatResource >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxGcStatResource >> summary [
	"Return a summary string of GC stats"
	^ 'GC: ', gcCount asString, ' collections, ',
	  gcTime asString, ' ms total, ',
	  objectsScavenged asString, ' scavenged, ',
	  objectsTenured asString, ' tenured'
]
