Class {
	#name : 'GbxToolStatMonitor',
	#superclass : 'Object',
	#instVars : [
		'session',
		'stats'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxToolStatMonitor class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'opening' }
GbxToolStatMonitor class >> open [
	"Open the stat monitor tool"
	self inform: 'Stat Monitor not fully implemented in this version. Statistics are collected on the GemStone server side.'
]

{ #category : 'opening' }
GbxToolStatMonitor class >> openOn: aSession [
	"Open the stat monitor tool on a session"
	| tool |
	tool := self on: aSession.
	^ GbxToolStatMonitorPresenter openOn: tool
]

{ #category : 'actions' }
GbxToolStatMonitor >> refresh [
	"Refresh statistics from server"
	| script result |
	
	session ifNil: [ ^ self ].
	
	script := '[
		| stats |
		stats := Dictionary new.
		stats at: ''status'' put: ''Stats collection not available in this version''.
		stats
	] value'.
	
	result := session executeAndFetch: script.
	stats := result
]

{ #category : 'accessing' }
GbxToolStatMonitor >> session [
	^ session
]

{ #category : 'accessing' }
GbxToolStatMonitor >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxToolStatMonitor >> stats [
	^ stats ifNil: [ stats := Dictionary new ]
]
