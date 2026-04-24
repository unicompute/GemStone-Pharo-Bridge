Class {
	#name : 'CoreGbxFakeServiceForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'currentContext',
		'currentReceiverOopValue'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> currentContext [
	^ currentContext
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> currentContext: aContext [
	currentContext := aContext
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> currentReceiverOop [
	^ currentReceiverOopValue
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> currentReceiverOop: anObject [
	currentReceiverOopValue := anObject
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> selectedMethodClassName [
	^ currentContext
		ifNil: [ nil ]
		ifNotNil: [
			(currentContext respondsTo: #methodClassOrUnknown)
				ifTrue: [ currentContext methodClassOrUnknown ]
				ifFalse: [ nil ] ]
]

{ #category : 'accessing' }
CoreGbxFakeServiceForRemoteDebugger >> selectedMethodSelector [
	^ currentContext
		ifNil: [ nil ]
		ifNotNil: [
			(currentContext respondsTo: #selectorOrUnknown)
				ifTrue: [ currentContext selectorOrUnknown ]
				ifFalse: [ nil ] ]
]
