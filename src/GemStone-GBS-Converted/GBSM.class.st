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
    CurrentSession ifNotNil: [ ^ CurrentSession ].
    ^ GbsSessionParameters currentSession
]

{ #category : 'accessing' }
GBSM class >> currentSession: aSession [
    CurrentSession := aSession.
    (GbsSessionParameters currentSession == aSession)
        ifFalse: [ GbsSessionParameters currentSession: aSession ]
]

{ #category : 'cleanup' }
GBSM class >> reset [
    CurrentSession := nil
]
