Class {
	#name : 'GbsSessionLoginCoordinator',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsSessionLoginCoordinator class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'error handling' }
GbsSessionLoginCoordinator >> interpretErrorMessage: aString errorNumber: anErrorNumber [
	| errorMsgLower originalMsg |
	originalMsg := aString isString
		ifTrue: [ aString ]
		ifFalse: [
			[ aString asString ]
				on: Error
				do: [ 'Unknown error' ] ].
	errorMsgLower := originalMsg asLowercase.
	(errorMsgLower includesSubstring: 'connection refused') ifTrue: [
		^ 'Cannot connect to GemStone netldi daemon.

The netldi is not running or not accessible.

To fix this, start netldi on the GemStone server:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
	(errorMsgLower includesSubstring: 'no such') ifTrue: [
		((errorMsgLower includesSubstring: 'stn')
			or: [ errorMsgLower includesSubstring: 'stone' ]) ifTrue: [
			^ 'Cannot find the GemStone stone.

Please check that the stone exists and netldi is running.

To start the stone and netldi:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ] ].
	(errorMsgLower includesSubstring: 'netldi') ifTrue: [
		^ 'GemStone netldi daemon is not running or not accessible.

To fix this, start netldi on the GemStone server:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
	(errorMsgLower includesSubstring: 'gemnetobject') ifTrue: [
		^ 'Cannot connect to gemnetobject service.

Please ensure the GemStone service is running.

To start netldi:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
	(errorMsgLower includesSubstring: 'login') ifTrue: [
		((errorMsgLower includesSubstring: 'fail')
			or: [ (errorMsgLower includesSubstring: 'denied')
			or: [ errorMsgLower includesSubstring: 'disabled' ] ]) ifTrue: [
			^ 'GemStone login failed.

Please check your username and password, or verify that logins are enabled.

Original error: ', originalMsg ] ].
	(errorMsgLower includesSubstring: 'shutdown') ifTrue: [
		^ 'GemStone is shutting down.

Please wait for it to fully stop and restart it.

To restart:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
	(errorMsgLower includesSubstring: 'timeout') ifTrue: [
		^ 'Connection to GemStone timed out.

Please check network connectivity and that netldi is running.

To start netldi:
  startnetldi -a <stone_name> -g <username>

Original error: ', originalMsg ].
	(anErrorNumber notNil and: [ anErrorNumber ~= 0 ]) ifTrue: [
		^ 'GemStone error ', anErrorNumber asString, ': ', originalMsg ].
	originalMsg isEmpty ifTrue: [
		^ 'Login failed. Please check your GemStone connection parameters.

Common issues:
- netldi is not running - start with: startnetldi -a <stone_name> -g <username>
- Stone name is incorrect
- Network connectivity issues' ].
	^ originalMsg
]

{ #category : 'login' }
GbsSessionLoginCoordinator >> loginStone: stoneName user: username password: password [
	| initSuccess loginSuccess errorStruct interpretedError |
	self resetSessionStateForLoginAttempt.
	initSuccess := session gciInit.
	initSuccess ifFalse: [ ^ GbsError signal: 'Failed to initialize GemStone GCI library.' ].
	loginSuccess := session
		gciLoginStone: stoneName
		hostUser: ''
		hostPass: ''
		gsUser: username
		gsPass: password.
	loginSuccess ifFalse: [
		errorStruct := GciError new.
		(session gciErr: errorStruct) ifTrue: [
			Transcript show: '[GemStone Login Error]'; cr.
			Transcript show: '  Stone: ', stoneName; cr.
			Transcript show: '  User: ', username; cr.
			Transcript
				show: '  Error Number: ';
				show: ([ errorStruct number printString ] on: Exception do: [ 'n/a' ]);
				cr.
			Transcript
				show: '  Error Message: ';
				show: ([ errorStruct message ] on: Exception do: [ 'Unknown login failure' ]);
				cr.
			interpretedError := session interpretLoginError: errorStruct.
			Transcript show: '  Interpreted: ', interpretedError; cr; cr.
			session signalError: errorStruct.
			^ GbsError signal: interpretedError ].
		^ GbsError signal: 'Unknown login failure. Please check your GemStone connection parameters.' ].
	session isLoggedIn: true
]

{ #category : 'login' }
GbsSessionLoginCoordinator >> resetSessionStateForLoginAttempt [
	session isLoggedIn: false.
	session sessionOop: nil.
	session sessionId: nil.
	(session respondsTo: #clearProxyCache) ifTrue: [ session clearProxyCache ].
	(session respondsTo: #clearNamedObjectCache) ifTrue: [ session clearNamedObjectCache ].
	(session respondsTo: #materializer) ifTrue: [
		[ session materializer clearRemoteClassNameCache ]
			on: Error
			do: [ ] ]
]

{ #category : 'accessing' }
GbsSessionLoginCoordinator >> session [
	^ session
]

{ #category : 'accessing' }
GbsSessionLoginCoordinator >> session: aSession [
	session := aSession
]
