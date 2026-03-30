Class {
	#name : 'OverrideFailureWarning',
	#superclass : 'Warning',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
OverrideFailureWarning class >> raiseSignal: aString [
	^ self signal: aString
]

{ #category : 'private - actions' }
OverrideFailureWarning >> defaultAction [
	Transcript
		cr;
		show: self messageText.
	^ self resume
]
