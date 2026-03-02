"
Block and Context cases for CannotReturn need to signal a dedicated exception.
(see subclasses and the related testcases)
"
Class {
	#name : 'CannotReturn',
	#superclass : 'Error',
	#instVars : [
		'result'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
CannotReturn >> isResumable [

	^true
]

{ #category : 'accessing' }
CannotReturn >> result [

	^result
]

{ #category : 'accessing' }
CannotReturn >> result: r [

	result := r
]
