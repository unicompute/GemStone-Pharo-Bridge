Class {
	#name : 'ConfirmDialog',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'ui' }
ConfirmDialog class >> confirm: aString [
	^ UIManager default confirm: aString
]
