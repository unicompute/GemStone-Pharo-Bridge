Class {
	#name : 'GbsError',
	#superclass : 'Error',
	#instVars : [
		'gemStoneExceptionProxy',
		'serverProcessOop',
		'exceptionOop'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbsError >> exceptionOop [

	^ exceptionOop
]

{ #category : 'accessing' }
GbsError >> exceptionOop: anObject [

	exceptionOop := anObject
]

{ #category : 'debugging' }
GbsError >> debuggerMetadata [
	| metadata |
	metadata := Dictionary new.
	metadata
		at: #messageText put: self messageText;
		at: #serverProcessOop put: serverProcessOop;
		at: #processOop put: serverProcessOop;
		at: #exceptionOop put: exceptionOop;
		at: #tag put: self tag;
		at: #exceptionClass put: self gemStoneExceptionClassName;
		at: #selector put: self gemStoneExceptionSelector;
		at: #source put: self gemStoneExceptionSource;
		at: #stackDigest put: self gemStoneExceptionStackDigest;
		at: #dirtyTransaction put: self gemStoneSessionNeedsCommit.
	gemStoneExceptionProxy ifNotNil: [
		(gemStoneExceptionProxy respondsTo: #oop)
			ifTrue: [
				metadata
					at: #gemStoneExceptionOop
					put: ([ gemStoneExceptionProxy oop ] on: Error do: [ nil ]) ] ].
	^ metadata
]

{ #category : 'debugging' }
GbsError >> debuggerMetadataString [
	| metadata |
	metadata := self debuggerMetadata.
	^ String streamContents: [ :stream |
		#(messageText processOop serverProcessOop exceptionOop exceptionClass selector source stackDigest dirtyTransaction tag gemStoneExceptionOop)
			do: [ :key |
				(metadata includesKey: key) ifTrue: [
					stream
						nextPutAll: key asString;
						nextPutAll: '=';
						nextPutAll: (metadata at: key) printString;
						space ] ] ]
]

{ #category : 'debugging' }
GbsError >> debuggerMetadataValueFor: selectorSymbol [
	gemStoneExceptionProxy ifNil: [ ^ nil ].
	(gemStoneExceptionProxy respondsTo: selectorSymbol) ifFalse: [ ^ nil ].
	^ [ gemStoneExceptionProxy perform: selectorSymbol ] on: Error do: [ nil ]
]

{ #category : 'debugging' }
GbsError >> firstDebuggerMetadataValueForAny: selectorSymbols [
	selectorSymbols do: [ :selectorSymbol |
		| value |
		value := self debuggerMetadataValueFor: selectorSymbol.
		value ifNotNil: [ ^ value ] ].
	^ nil
]

{ #category : 'debugging' }
GbsError >> gemStoneExceptionClassName [
	| session oop |
	gemStoneExceptionProxy ifNil: [ ^ nil ].
	session := (gemStoneExceptionProxy respondsTo: #session)
		ifTrue: [ [ gemStoneExceptionProxy session ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	oop := (gemStoneExceptionProxy respondsTo: #oop)
		ifTrue: [ [ gemStoneExceptionProxy oop ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	(session notNil and: [ oop notNil and: [ session respondsTo: #remoteClassNameForOop: ] ])
		ifTrue: [ ^ [ session remoteClassNameForOop: oop ] on: Error do: [ nil ] ].
	^ [ gemStoneExceptionProxy class name asString ] on: Error do: [ nil ]
]

{ #category : 'debugging' }
GbsError >> gemStoneExceptionSelector [
	| value |
	value := self firstDebuggerMetadataValueForAny: #(selector selectorOrUnknown signalerSelector).
	value ifNil: [ ^ nil ].
	^ [ value asString ] on: Error do: [ nil ]
]

{ #category : 'debugging' }
GbsError >> gemStoneExceptionSource [
	| value |
	value := self firstDebuggerMetadataValueForAny: #(sourceString sourceCode signalerSource).
	value ifNil: [ ^ nil ].
	^ [ value asString ] on: Error do: [ nil ]
]

{ #category : 'debugging' }
GbsError >> gemStoneExceptionStackDigest [
	| value text |
	value := self firstDebuggerMetadataValueForAny: #(backtraceText stackReport stackString).
	value ifNil: [ ^ nil ].
	text := [ value asString ] on: Error do: [ nil ].
	text ifNil: [ ^ nil ].
	^ text size asString, ':', (text copyFrom: 1 to: (text size min: 120))
]

{ #category : 'accessing' }
GbsError >> gemStoneExceptionProxy [

	^ gemStoneExceptionProxy
]

{ #category : 'accessing' }
GbsError >> gemStoneExceptionProxy: anObject [

	gemStoneExceptionProxy := anObject
]

{ #category : 'debugging' }
GbsError >> gemStoneSessionNeedsCommit [
	| session |
	gemStoneExceptionProxy ifNil: [ ^ nil ].
	session := (gemStoneExceptionProxy respondsTo: #session)
		ifTrue: [ [ gemStoneExceptionProxy session ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	(session notNil and: [ session respondsTo: #needsCommit ])
		ifFalse: [ ^ nil ].
	^ [ session needsCommit ] on: Error do: [ nil ]
]

{ #category : 'accessing' }
GbsError >> serverProcessOop [

	^ serverProcessOop
]

{ #category : 'accessing' }
GbsError >> serverProcessOop: anObject [

	serverProcessOop := anObject
]
