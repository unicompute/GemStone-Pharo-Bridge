Class {
	#name : 'GbxGciErrSType64v3',
	#superclass : 'GbxGciErrSType',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxGciErrSType64v3 >> asGbsErrorForSession: aGbsSession
[

	| exceptionOop gbsError |
	gbsError := super asGbsErrorForSession: aGbsSession.
	exceptionOop := GbxDelegate oopValue: self exceptionObj session: aGbsSession.
	gbsError
		exceptionOop: exceptionOop;
		reason: self reason.
	^gbsError
]

{ #category : 'accessing' }
GbxGciErrSType64v3 >> argsOffset
[
	
	^25
]

{ #category : 'accessing' }
GbxGciErrSType64v3 >> exceptionObj
[
	^self oopAt: 17
]

{ #category : 'accessing' }
GbxGciErrSType64v3 >> reason
[
	^self cStringAt: 1139
]
