Class {
	#name : 'GbsLoginSequencingSession',
	#superclass : 'GbsSession',
	#instVars : [
		'postLoginCalled',
		'finishPostLoginCalled',
		'scheduleFinishPostLoginCalled'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'private - session management' }
GbsLoginSequencingSession >> basicLoginLinked: linked [
	sessionId := 1.
	^ true
]

{ #category : 'private - session management' }
GbsLoginSequencingSession >> basicX509Login [
	sessionId := 1.
	^ true
]

{ #category : 'testing' }
GbsLoginSequencingSession >> finishPostLoginCalled [
	^ finishPostLoginCalled = true
]

{ #category : 'private - session management' }
GbsLoginSequencingSession >> finishPostLogin [
	finishPostLoginCalled := true.
	^ self
]

{ #category : 'testing' }
GbsLoginSequencingSession >> postLoginCalled [
	^ postLoginCalled = true
]

{ #category : 'private - session management' }
GbsLoginSequencingSession >> postLogin [
	postLoginCalled := true.
	^ self
]

{ #category : 'testing' }
GbsLoginSequencingSession >> scheduleFinishPostLoginCalled [
	^ scheduleFinishPostLoginCalled = true
]

{ #category : 'private - session management' }
GbsLoginSequencingSession >> scheduleFinishPostLogin [
	scheduleFinishPostLoginCalled := true.
	^ self
]

{ #category : 'private - session management' }
GbsLoginSequencingSession >> sessionCriticalNoSessionCheck: aBlock [
	^ aBlock value
]
