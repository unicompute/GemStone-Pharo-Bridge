Extension { #name : 'GbsSessionParameters' }

{ #category : '*GemStone-GBS-Core' }
GbsSessionParameters >> ensureCleanString: aString [
	| source |
	aString ifNil: [ ^ '' ].
	source := aString asString.
	^ (String streamContents: [ :stream |
		source do: [ :each |
			each codePoint = 0 ifFalse: [ stream nextPut: each ] ] ])
		trimBoth
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionParameters >> fetchTranscriptLogs [
	"Ask the server interface to fetch the active Transcript logs"
	^ GbsServerInterface uniqueInstance
		executeAndPrint: '[
		| fetched log text |
		fetched := (Transcript respondsTo: #fetchAndClear)
			ifTrue: [ [ Transcript fetchAndClear ] on: Error do: [ nil ] ]
			ifFalse: [ nil ].
		fetched ifNotNil: [ ^ fetched ifNil: [ '''' ] ].
		log := UserGlobals at: #PharoTranscriptLog ifAbsent: [ OrderedCollection new ].
		text := String streamContents: [ :stream |
			log do: [ :each |
				stream nextPutAll: each asString.
				stream cr ] ].
		UserGlobals at: #PharoTranscriptLog put: OrderedCollection new.
		text
	] value'
		inSession: self sessionId
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionParameters >> handleLoginError: interface [
	"Handle login failure with specific error messages for netldi and connection issues"
	| errorMessage rawErrMsg errNum hasError buffer |
	buffer := ExternalAddress allocate: 2168.
	[
		hasError := interface apiGciErr: buffer.
		(hasError = 1 or: [ hasError == true ]) ifTrue: [
			errNum := buffer signedLongAt: 5.
			rawErrMsg := self ensureCleanString: (self readErrorMessageFrom: buffer) ] ]
		ensure: [ buffer free ].
	Transcript show: '[GemStone Login Error]'; cr.
	Transcript show: '  Stone: ', self gemStoneName; cr.
	Transcript show: '  User: ', self username; cr.
	Transcript show: '  Error Number: ', (errNum ifNil: [ 'nil' ]) printString; cr.
	Transcript
		show: '  Raw Message: ';
		show: ((rawErrMsg isNil or: [ rawErrMsg isEmpty ])
			ifTrue: [ '(empty)' ]
			ifFalse: [ rawErrMsg ]);
		cr.
	errorMessage := self interpretErrorMessage: rawErrMsg errorNumber: errNum.
	Transcript show: '  Interpreted: '; show: (errorMessage copyReplaceAll: String cr with: ' | '); cr; cr.
	self error: errorMessage
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionParameters >> invalidCredentialsErrorMessage: originalMsg [
	| message |
	message := self ensureCleanString: originalMsg.
	message isEmpty ifTrue: [
		message := 'Login failed: the userId/password combination is invalid or expired.' ].
	^ 'GemStone login failed.

Please check your username and password, or verify that logins are enabled.

Original error: ', message
]

{ #category : '*GemStone-GBS-Core' }
GbsSessionParameters >> interpretErrorMessage: aString errorNumber: anErrorNumber [
	"Interpret error messages and provide user-friendly explanations for common issues"
	| errorMsgLower originalMsg |
	originalMsg := aString
		ifNil: [ '' ]
		ifNotNil: [
			[
				(aString isKindOf: ByteArray)
					ifTrue: [ self convertBytesToString: aString ]
					ifFalse: [ aString asString ] ]
				on: Error
				do: [ '' ] ].
	originalMsg := self ensureCleanString: originalMsg.
	anErrorNumber = 4051 ifTrue: [
		^ self invalidCredentialsErrorMessage: originalMsg ].
	originalMsg isEmpty ifTrue: [
		^ self netldiErrorMessage ].
	errorMsgLower := originalMsg asLowercase.
	(errorMsgLower includesSubstring: 'connection refused') ifTrue: [
		^ 'Cannot connect to GemStone netldi daemon.

The netldi is not running or not accessible.

To fix this, start netldi on the GemStone server:
  startnetldi -a ', self gemStoneName, '

Original error: ', originalMsg ].
	(errorMsgLower includesSubstring: 'no such') ifTrue: [
		((errorMsgLower includesSubstring: 'stn')
			or: [ errorMsgLower includesSubstring: 'stone' ]) ifTrue: [
			^ 'Cannot find the GemStone stone "', self gemStoneName, '".

Please check that the stone exists and netldi is running.

To start the stone and netldi:
  startnetldi -a ', self gemStoneName, '

Original error: ', originalMsg ] ].
	(errorMsgLower includesSubstring: 'netldi') ifTrue: [
		^ 'GemStone netldi daemon is not running or not accessible.

To fix this, start netldi on the GemStone server:
  startnetldi -a ', self gemStoneName, '

Original error: ', originalMsg ].
	(errorMsgLower includesSubstring: 'gemnetobject') ifTrue: [
		^ 'Cannot connect to gemnetobject service.

Please ensure the GemStone service is running.

To start netldi:
  startnetldi -a ', self gemStoneName, '

Original error: ', originalMsg ].
	(errorMsgLower includesSubstring: 'login') ifTrue: [
		((errorMsgLower includesSubstring: 'fail')
			or: [ (errorMsgLower includesSubstring: 'denied')
			or: [ errorMsgLower includesSubstring: 'disabled' ] ]) ifTrue: [
			^ self invalidCredentialsErrorMessage: originalMsg ] ].
	((errorMsgLower includesSubstring: 'invalid password')
		or: [ (errorMsgLower includesSubstring: 'invalid or expired')
		or: [ errorMsgLower includesSubstring: 'userid/password combination' ] ]) ifTrue: [
		^ self invalidCredentialsErrorMessage: originalMsg ].
	(errorMsgLower includesSubstring: 'shutdown') ifTrue: [
		^ 'GemStone is shutting down.

Please wait for it to fully stop and restart it:
  startnetldi -a ', self gemStoneName, '

Original error: ', originalMsg ].
	(errorMsgLower includesSubstring: 'timeout') ifTrue: [
		^ 'Connection to GemStone timed out.

Please check network connectivity and that netldi is running.

To start netldi:
  startnetldi -a ', self gemStoneName, '

Original error: ', originalMsg ].
	(anErrorNumber notNil and: [ anErrorNumber ~= 0 ]) ifTrue: [
		^ 'GemStone error ', anErrorNumber asString, ': ', originalMsg ].
	originalMsg isEmpty ifTrue: [
		^ self netldiErrorMessage ].
	^ originalMsg
]
