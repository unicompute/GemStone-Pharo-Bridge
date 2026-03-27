Class {
	#name : 'GbxOverrideEditDelete',
	#superclass : 'GbxOverrideEditWithCount',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'applying' }
GbxOverrideEditDelete >> applyFrom: inputStream to: outputStream
[
	inputStream skip: count
]

