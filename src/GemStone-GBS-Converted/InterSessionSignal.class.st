"
Raised on the client when the session receives a GsInterSessionSignal from another GemStone session.
Carries the decoded signal triple -- the sending session's serial number, the signal number, and the
signal message -- mirroring VisualWorks GsInterSessionSignal accessors so handlers can read the signal
without re-fetching the server-side signal proxy.
"
Class {
	#name : 'InterSessionSignal',
	#superclass : 'Notification',
	#instVars : [
		'signalNumber',
		'sentMessage',
		'sendingSessionSerial'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
InterSessionSignal class >> signalNumber: aSignalNumber message: aMessage sendingSessionSerial: aSerial [
	^ self new
		signalNumber: aSignalNumber;
		sentMessage: aMessage;
		sendingSessionSerial: aSerial;
		yourself
]

{ #category : 'accessing' }
InterSessionSignal >> messageText [
	"Answer the signal message. Falls back to the standard exception messageText when no decoded message
	is present (for example a signal received with only raw error text)."
	^ sentMessage ifNil: [ super messageText ]
]

{ #category : 'accessing' }
InterSessionSignal >> sendingSessionSerial [
	^ sendingSessionSerial
]

{ #category : 'accessing' }
InterSessionSignal >> sendingSessionSerial: anInteger [
	sendingSessionSerial := anInteger
]

{ #category : 'accessing' }
InterSessionSignal >> sentMessage [
	^ sentMessage
]

{ #category : 'accessing' }
InterSessionSignal >> sentMessage: aString [
	sentMessage := aString
]

{ #category : 'accessing' }
InterSessionSignal >> signalNumber [
	^ signalNumber
]

{ #category : 'accessing' }
InterSessionSignal >> signalNumber: anInteger [
	signalNumber := anInteger
]
