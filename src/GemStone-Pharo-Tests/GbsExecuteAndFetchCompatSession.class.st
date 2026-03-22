Class {
	#name : 'GbsExecuteAndFetchCompatSession',
	#superclass : 'GbsSession',
	#instVars : [
		'lastContext',
		'lastSource',
		'nextValue'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbsExecuteAndFetchCompatSession >> lastContext [
	^ lastContext
]

{ #category : 'accessing' }
GbsExecuteAndFetchCompatSession >> lastSource [
	^ lastSource
]

{ #category : 'accessing' }
GbsExecuteAndFetchCompatSession >> nextValue: anObject [
	nextValue := anObject
]

{ #category : 'private - execution' }
GbsExecuteAndFetchCompatSession >> unsynchronizedEvaluate: sourceString [
	lastSource := sourceString.
	lastContext := nil.
	^ nextValue
]

{ #category : 'private - execution' }
GbsExecuteAndFetchCompatSession >> unsynchronizedEvaluate: sourceString context: contextDelegate [
	lastSource := sourceString.
	lastContext := contextDelegate.
	^ nextValue
]
