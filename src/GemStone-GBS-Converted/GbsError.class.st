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
