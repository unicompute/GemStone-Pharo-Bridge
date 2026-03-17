Class {
	#name : #'GbxLongHolderType',
	#superclass : #'GbxStructure',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'printing' }
GbxLongHolderType >> printOn: aStream indent: indent
	aStream tab: indent - 1.
	aStream nextPutAll: self class name , ' holding ' , self content asInteger printString.

