Class {
	#name : 'GbxLogger',
	#superclass : 'Object',
	#instVars : [
		'filename'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxLogger >> filename
[

	^filename
]

{ #category : 'initialize-release' }
GbxLogger >> initializeWithFileName: aString
[

	filename := aString
]

{ #category : 'instance creation' }
GbxLogger class >> usingFileNamed: aString
[

	^(self new)
		initializeWithFileName: aString;
		yourself
]

