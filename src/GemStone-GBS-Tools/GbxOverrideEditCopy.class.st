Class {
	#name : 'GbxOverrideEditCopy',
	#superclass : 'GbxOverrideEditWithCount',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'applying' }
GbxOverrideEditCopy >> applyFrom: inputStream to: outputStream
[
	outputStream nextPutAll: (inputStream next: count)
]

