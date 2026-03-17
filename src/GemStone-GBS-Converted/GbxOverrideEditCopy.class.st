Class {
	#name : #'GbxOverrideEditCopy',
	#superclass : #'GbxOverrideEditWithCount',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'applying' }
GbxOverrideEditCopy >> applyFrom: inputStream to: outputStream

	outputStream nextPutAll: (inputStream next: count)

