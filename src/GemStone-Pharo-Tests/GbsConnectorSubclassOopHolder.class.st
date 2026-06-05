"
A minimal object that answers #oop, used by GbsConnectorSubclassTest to verify GbsFastConnector resolves a
server OOP from any object answering #oop.
"
Class {
	#name : 'GbsConnectorSubclassOopHolder',
	#superclass : 'Object',
	#instVars : [
		'oop'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'accessing' }
GbsConnectorSubclassOopHolder >> oop [
	^ oop
]

{ #category : 'accessing' }
GbsConnectorSubclassOopHolder >> oop: anInteger [
	oop := anInteger
]
