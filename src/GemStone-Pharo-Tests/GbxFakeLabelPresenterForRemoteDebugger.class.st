Class {
	#name : 'GbxFakeLabelPresenterForRemoteDebugger',
	#superclass : 'Object',
	#instVars : [
		'label'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbxFakeLabelPresenterForRemoteDebugger >> label [
	^ label ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxFakeLabelPresenterForRemoteDebugger >> label: aString [
	label := aString
]
