Class {
	#name : 'GbsSessionSupportFakeLiveSession',
	#superclass : 'Object',
	#instVars : [
		'sessionId',
		'loggedIn',
		'parameters'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'execution' }
GbsSessionSupportFakeLiveSession >> execute: aString [
	^ true
]

{ #category : 'execution' }
GbsSessionSupportFakeLiveSession >> executeAndFetch: aString [
	^ ''
]

{ #category : 'testing' }
GbsSessionSupportFakeLiveSession >> hasValidSessionId [
	^ sessionId notNil and: [ sessionId ~= 0 ]
]

{ #category : 'testing' }
GbsSessionSupportFakeLiveSession >> isConnected [
	^ self isLoggedIn
]

{ #category : 'testing' }
GbsSessionSupportFakeLiveSession >> isLoggedIn [
	^ loggedIn == true
]

{ #category : 'testing' }
GbsSessionSupportFakeLiveSession >> isLoggedIn: aBoolean [
	loggedIn := aBoolean
]

{ #category : 'accessing' }
GbsSessionSupportFakeLiveSession >> parameters [
	^ parameters
]

{ #category : 'accessing' }
GbsSessionSupportFakeLiveSession >> parameters: anObject [
	parameters := anObject
]

{ #category : 'accessing' }
GbsSessionSupportFakeLiveSession >> sessionId [
	^ sessionId
]

{ #category : 'accessing' }
GbsSessionSupportFakeLiveSession >> sessionId: anObject [
	sessionId := anObject
]
