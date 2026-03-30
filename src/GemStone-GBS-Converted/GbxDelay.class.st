Class {
	#name : 'GbxDelay',
	#superclass : 'Object',
	#instVars : [
		'delay',
		'disregarded'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxDelay class >> forMilliseconds: anInteger [
	^ self new
		initializeForMilliseconds: anInteger;
		yourself
]

{ #category : 'instance creation' }
GbxDelay class >> forSeconds: anInteger [
	^ self forMilliseconds: anInteger * 1000
]

{ #category : 'private' }
GbxDelay >> gbxDisregard [
	disregarded := true
]

{ #category : 'initialization' }
GbxDelay >> initializeForMilliseconds: anInteger [
	delay := Delay forMilliseconds: (anInteger max: 0).
	disregarded := false
]

{ #category : 'waiting' }
GbxDelay >> wait [
	disregarded ifTrue: [ ^ self ].
	delay wait
]
