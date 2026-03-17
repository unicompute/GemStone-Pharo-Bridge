Class {
	#name : 'GbxStructure',
	#superclass : 'Object',
	#instVars : [
		'data'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'printing' }
GbxStructure >> printOn: aStream
[
	"Print a representation of the structure on <aStream>.  Use of indent is to allow
	for formatted printing of nested structures."

	self printOn: aStream indent: 1
]

{ #category : 'printing' }
GbxStructure >> printOn: aStream indent: anInteger
[

	self subclassResponsibility
]

