Class {
	#name : 'InformDialog',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'ui' }
InformDialog class >> inform: aString [
	UIManager default inform: aString
]
