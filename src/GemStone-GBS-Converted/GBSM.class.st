Class {
	#name : 'GBSM',
	#superclass : 'Object',
	#classInstVars : [
		'CurrentSession'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GBSM class >> currentSession [
    ^ CurrentSession
]

{ #category : 'accessing' }
GBSM class >> currentSession: aSession [
    CurrentSession := aSession
]

{ #category : 'cleanup' }
GBSM class >> reset [
    CurrentSession := nil
]
