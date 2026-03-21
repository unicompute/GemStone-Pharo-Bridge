Class {
	#name : 'GbsSessionSupportFakeCandidate',
	#superclass : 'Object',
	#instVars : [
		'liveSession',
		'sessionId'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbsSessionSupportFakeCandidate >> liveSession [
	^ liveSession
]

{ #category : 'accessing' }
GbsSessionSupportFakeCandidate >> liveSession: anObject [
	liveSession := anObject
]

{ #category : 'accessing' }
GbsSessionSupportFakeCandidate >> sessionId [
	^ sessionId
]

{ #category : 'accessing' }
GbsSessionSupportFakeCandidate >> sessionId: anObject [
	sessionId := anObject
]
