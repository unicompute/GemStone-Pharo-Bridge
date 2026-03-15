Class {
	#name : 'GbxStatMonitor',
	#superclass : 'Object',
	#instVars : [
		'session',
		'stats',
		'descriptors',
		'interval',
		'isMonitoring',
		'lastUpdate'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxStatMonitor class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'initialization' }
GbxStatMonitor >> initialize [
	super initialize.
	stats := Dictionary new.
	descriptors := OrderedCollection new.
	interval := 5000. "5 seconds default"
	isMonitoring := false.
]

{ #category : 'accessing' }
GbxStatMonitor >> addStat: aStat [
	"Add a stat to monitor"
	stats at: aStat name put: aStat.
]

{ #category : 'accessing' }
GbxStatMonitor >> addStatNamed: aString description: desc category: cat [
	"Add a new stat by name"
	| stat descriptor |
	
	stat := GbxStat named: aString.
	descriptor := GbxStatDescriptor
		named: aString
		description: desc
		category: cat.
	
	stats at: aString put: stat.
	descriptors add: descriptor.
	^ stat
]

{ #category : 'accessing' }
GbxStatMonitor >> descriptors [
	^ descriptors
]

{ #category : 'monitoring' }
GbxStatMonitor >> fetchStatsFromServer [
	"Fetch statistics from GemStone server"
	| script result |
	
	session ifNil: [ ^ self ].
	
	script := '[
		| stream |
		stream := WriteStream on: String new.
		stream
			nextPutAll: System vmGcCount asString; nextPutAll: ''|'';
			nextPutAll: System vmGcTime asString; nextPutAll: ''|'';
			nextPutAll: System objectCount asString; nextPutAll: ''|'';
			nextPutAll: System pageFaults asString.
		stream contents
	] value'.
	
	result := session executeAndFetch: script.
	self parseStats: result.
]

{ #category : 'accessing' }
GbxStatMonitor >> interval [
	^ interval
]

{ #category : 'accessing' }
GbxStatMonitor >> interval: aNumber [
	interval := aNumber
]

{ #category : 'accessing' }
GbxStatMonitor >> isMonitoring [
	^ isMonitoring
]

{ #category : 'accessing' }
GbxStatMonitor >> lastUpdate [
	^ lastUpdate
]

{ #category : 'parsing' }
GbxStatMonitor >> parseStats: aString [
	"Parse stats string from server"
	| parts |
	
	aString ifNil: [ ^ self ].
	
	parts := aString splitOn: $|.
	parts size >= 4 ifTrue: [
		self updateStat: 'vmGcCount' value: (parts first asInteger).
		self updateStat: 'vmGcTime' value: (parts second asInteger).
		self updateStat: 'objectCount' value: (parts third asInteger).
		self updateStat: 'pageFaults' value: (parts fourth asInteger).
	].
	
	lastUpdate := DateAndTime now.
]

{ #category : 'accessing' }
GbxStatMonitor >> session [
	^ session
]

{ #category : 'accessing' }
GbxStatMonitor >> session: aSession [
	session := aSession
]

{ #category : 'monitoring' }
GbxStatMonitor >> startMonitoring [
	"Start monitoring statistics"
	isMonitoring := true.
	self fetchStatsFromServer.
	
	[ isMonitoring ] whileTrue: [
		(Delay forMilliseconds: interval) wait.
		isMonitoring ifTrue: [
			self fetchStatsFromServer.
		].
	] forkAt: Processor backgroundPriority.
]

{ #category : 'monitoring' }
GbxStatMonitor >> stopMonitoring [
	"Stop monitoring statistics"
	isMonitoring := false.
]

{ #category : 'accessing' }
GbxStatMonitor >> statAt: aString [
	^ stats at: aString ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbxStatMonitor >> stats [
	^ stats
]

{ #category : 'updating' }
GbxStatMonitor >> updateStat: aString value: aNumber [
	"Update a stat value"
	| stat |
	
	stat := stats at: aString ifAbsent: [
		| newStat |
		newStat := GbxStat named: aString.
		stats at: aString put: newStat.
		newStat
	].
	
	stat updateValue: aNumber.
]
