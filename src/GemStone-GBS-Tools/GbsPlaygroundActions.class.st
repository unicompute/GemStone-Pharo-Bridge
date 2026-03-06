Class {
	#name : 'GbsPlaygroundActions',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'helpers' }
GbsPlaygroundActions class >> activeSessionOrInform [
	| session |
	session := GbsSessionParameters currentSession.
	session ifNil: [
		UIManager default inform: 'No Session - please login to GemStone first'.
		^ nil
	].
	^ session
]

{ #category : 'helpers' }
GbsPlaygroundActions class >> selectedCodeFrom: aPlaygroundPresenter [
	| code textPresenter |
	code := [ aPlaygroundPresenter selectedTextOrLine ] on: Error do: [ '' ].
	(code isString and: [ code isEmpty ]) ifTrue: [
		textPresenter := [ aPlaygroundPresenter text ] on: Error do: [ nil ].
		code := (textPresenter notNil and: [ textPresenter respondsTo: #text ])
			ifTrue: [ [ textPresenter text asString ] on: Error do: [ '' ] ]
			ifFalse: [ '' ]
	].
	^ code asString copyReplaceAll: String cr with: String lf
]

{ #category : 'helpers' }
GbsPlaygroundActions class >> appendPrintedResult: resultString in: aPlaygroundPresenter [
	| textPresenter currentText |
	textPresenter := [ aPlaygroundPresenter text ] on: Error do: [ nil ].
	textPresenter ifNil: [
		UIManager default inform: resultString asString.
		^ self
	].
	currentText := (textPresenter respondsTo: #text)
		ifTrue: [ [ textPresenter text asString ] on: Error do: [ '' ] ]
		ifFalse: [ '' ].
	(textPresenter respondsTo: #text:)
		ifTrue: [ textPresenter text: currentText, ' " ', resultString asString, ' "' ]
		ifFalse: [ UIManager default inform: resultString asString ].
]

{ #category : 'actions' }
GbsPlaygroundActions class >> gsDoItIn: aPlaygroundPresenter [
	^ self gsEvaluateIn: aPlaygroundPresenter debugOnError: true
]

{ #category : 'actions' }
GbsPlaygroundActions class >> gsDebugItIn: aPlaygroundPresenter [
	^ self gsEvaluateIn: aPlaygroundPresenter debugOnError: true
]

{ #category : 'actions' }
GbsPlaygroundActions class >> gsEvaluateIn: aPlaygroundPresenter debugOnError: debugOnError [
	| code activeSession result processOop exceptionCandidate serverCandidate hasRemoteMetadata currentUsable exceptionUsable |
	code := self selectedCodeFrom: aPlaygroundPresenter.
	code ifEmpty: [ ^ self ].

	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ self ].

	[
		result := activeSession execute: code.
		GbsRemoteTranscript drainSessionLogsToWindowsAndLocal: activeSession.
		^ result
	] on: GbsError do: [ :ex |
		serverCandidate := (ex respondsTo: #serverProcessOop)
			ifTrue: [ ex serverProcessOop ]
			ifFalse: [ nil ].
		processOop := serverCandidate.
		(processOop isNil or: [ processOop = 0 or: [ processOop = 20 ] ]) ifTrue: [
			processOop := (ex respondsTo: #tag)
				ifTrue: [ ex tag ]
				ifFalse: [ 20 ]
		].
		(processOop isNumber not) ifTrue: [ processOop := 20 ].
		(processOop isNil or: [ processOop = 0 or: [ processOop = 20 ] ]) ifTrue: [
			processOop := (ex respondsTo: #exceptionOop)
				ifTrue: [ ex exceptionOop ]
				ifFalse: [ 20 ]
		].
		(processOop isNumber not) ifTrue: [ processOop := 20 ].
		processOop := processOop ifNil: [ 20 ].
		processOop := (processOop = 0) ifTrue: [ 20 ] ifFalse: [ processOop ].

		exceptionCandidate := (ex respondsTo: #exceptionOop)
			ifTrue: [ ex exceptionOop ]
			ifFalse: [ nil ].
		hasRemoteMetadata := ((serverCandidate isNumber and: [ serverCandidate > 20 ])
			or: [ exceptionCandidate isNumber and: [ exceptionCandidate > 20 ] ]).
		currentUsable := hasRemoteMetadata.
		exceptionUsable := false.
		(currentUsable not and: [ exceptionCandidate isNumber and: [ exceptionCandidate > 20 ] ]) ifTrue: [
			processOop := exceptionCandidate.
			currentUsable := true.
			exceptionUsable := true
		].

		(debugOnError
			and: [ (processOop isNumber and: [ processOop > 20 ]) and: [ hasRemoteMetadata ] ])
			ifTrue: [
				self openRemoteDebuggerOn: ex messageText processOop: processOop session: activeSession
			]
			ifFalse: [
				UIManager default inform: 'GemStone Error: ', ex messageText
			].
	]
]

{ #category : 'actions' }
GbsPlaygroundActions class >> gsInspectItIn: aPlaygroundPresenter [
	| code activeSession oop |
	code := self selectedCodeFrom: aPlaygroundPresenter.
	code ifEmpty: [ ^ self ].
	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ self ].

	oop := activeSession serverInterface apiGciExecuteStr: code context: 20 env: 0.
	((oop isNumber) and: [ oop > 20 ])
		ifTrue: [ GbsInspector inspect: oop session: activeSession ]
		ifFalse: [ UIManager default inform: 'Result is nil or execution failed.' ].
]

{ #category : 'actions' }
GbsPlaygroundActions class >> gsPrintItIn: aPlaygroundPresenter [
	| code printScript activeSession resultString |
	code := self selectedCodeFrom: aPlaygroundPresenter.
	code ifEmpty: [ ^ self ].
	printScript := '[ ', code, ' ] value printString'.
	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ self ].
	resultString := activeSession executeAndFetch: printScript.
	self appendPrintedResult: resultString in: aPlaygroundPresenter.
	GbsRemoteTranscript drainSessionLogsToWindowsAndLocal: activeSession.
]

{ #category : 'actions' }
GbsPlaygroundActions class >> gsFileItInIn: aPlaygroundPresenter [
	| code activeSession |
	code := self selectedCodeFrom: aPlaygroundPresenter.
	code ifEmpty: [ ^ self ].
	activeSession := self activeSessionOrInform.
	activeSession ifNil: [ ^ self ].
	[ activeSession execute: code.
	  GbsRemoteTranscript drainSessionLogsToWindowsAndLocal: activeSession.
	  UIManager default inform: 'GemStone file-in executed.' ]
		on: Error
		do: [ :ex | UIManager default inform: 'GS-File it in failed: ', ex messageText ].
]

{ #category : 'helpers' }
GbsPlaygroundActions class >> openRemoteDebuggerOn: errorString processOop: processOop session: aSession [
	| errorText safeProcessOop |
	errorText := errorString ifNil: [ 'Unknown Error' ] ifNotNil: [ :es | es asString ].
	safeProcessOop := processOop ifNil: [ 20 ].
	((safeProcessOop isNumber not) or: [ safeProcessOop <= 20 ]) ifTrue: [
		^ UIManager default inform: 'GemStone Error: ', errorText
	].
	[
		GbsRemoteDebugger
			openOn: errorText
			process: safeProcessOop
			session: aSession
	] on: Error do: [ :ex |
		UIManager default inform: 'Error opening debugger: ', ex messageText
	].
]
