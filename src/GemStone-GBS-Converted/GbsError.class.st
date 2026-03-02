Class {
	#name : 'GbsError',
	#superclass : 'Error',
	#instVars : [
		'gemStoneExceptionProxy'
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
