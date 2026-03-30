Class {
	#name : 'GbxOverrideEditCopy',
	#superclass : 'GbxOverrideEditWithCount',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'applying' }
GbxOverrideEditCopy >> applyFrom: inputStream to: outputStream [
	outputStream nextPutAll: (inputStream next: count)
]
