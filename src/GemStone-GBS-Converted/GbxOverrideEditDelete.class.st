Class {
	#name : 'GbxOverrideEditDelete',
	#superclass : 'GbxOverrideEditWithCount',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'applying' }
GbxOverrideEditDelete >> applyFrom: inputStream to: outputStream [
	inputStream skip: count
]
