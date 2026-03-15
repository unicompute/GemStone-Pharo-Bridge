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
GbsError >> gemStoneExceptionProxy [

	^ gemStoneExceptionProxy
]

{ #category : 'accessing' }
GbsError >> gemStoneExceptionProxy: anObject [

	gemStoneExceptionProxy := anObject
]

{ #category : 'accessing' }
GbsError >> serverProcessOop [

	^ serverProcessOop
]

{ #category : 'accessing' }
GbsError >> serverProcessOop: anObject [

	serverProcessOop := anObject
]

{ #category : 'accessing' }
GbsError >> exceptionOop [

	^ exceptionOop
]

{ #category : 'accessing' }
GbsError >> exceptionOop: anObject [

	exceptionOop := anObject
]

{ #category : 'testing' }
GbsError >> gbxIsGSError [

	^ true
]

{ #category : 'accessing' }
GbsError >> gbxGsDebuggerSession [

	^ self session
]

{ #category : 'accessing' }
GbsError >> serverProcess [

	^ serverProcessOop
]

{ #category : 'accessing' }
GbsError >> session [

	(gemStoneExceptionProxy notNil and: [ gemStoneExceptionProxy respondsTo: #session ]) ifTrue: [
		^ [ gemStoneExceptionProxy session ] on: Error do: [ nil ]
	].
	^ nil
]
