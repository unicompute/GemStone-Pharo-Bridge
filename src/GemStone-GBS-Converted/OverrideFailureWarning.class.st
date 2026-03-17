Class {
	#name : 'OverrideFailureWarning',
	#superclass : 'Warning',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private - actions' }
OverrideFailureWarning >> defaultAction
[

	Transcript cr; nextPutAll: self description.
	^self gbsMessenger warn: self description.
]

