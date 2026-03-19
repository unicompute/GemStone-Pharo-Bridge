Class {
	#name : 'GbxLongHolderType',
	#superclass : 'GbxStructure',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private' }
GbxLongHolderType >> content
[
	^self uint64At: 1
]

{ #category : 'private' }
GbxLongHolderType >> content: aLong
[
	self uint64At: 1 put: aLong
]

{ #category : 'printing' }
GbxLongHolderType >> printOn: aStream indent: indent
[
	aStream tab: indent - 1.
	aStream nextPutAll: self class name , ' holding ' , self content asInteger printString.
]
