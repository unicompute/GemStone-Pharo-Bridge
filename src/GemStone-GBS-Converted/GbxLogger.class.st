Class {
	#name : 'GbxLogger',
	#superclass : 'Object',
	#instVars : [
		'filename'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxLogger >> filename [
	^ filename
]

{ #category : 'accessing' }
GbxLogger >> filename: aString [
	filename := aString
]

{ #category : 'initialize-release' }
GbxLogger >> initializeWithFileName: aString [
	filename := aString
]
