Class {
	#name : 'GbxGciStoreTravDoArgsSType64',
	#superclass : 'GbxGciStoreTravDoArgsSType',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private - printing' }
GbxGciStoreTravDoArgsSType64 >> printStructEndOn: aStream indent: indent 
	aStream nextPutAll: 'alteredTheOops = '.
	self alteredTheOops printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'alteredNumOops = '.
	self alteredNumOops printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'alteredCompleted = '.
	self alteredCompleted printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'execBlock_args = '.
	self execBlockArgs printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'execBlock_numArgs = '.
	self execBlockNumArgs printOn: aStream.
	aStream crtab: indent

{ #category : 'private - printing' }
GbxGciStoreTravDoArgsSType64 >> printCArgsOn: aStream indent: indent 
	aStream nextPutAll: 'process = '.
	self process printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'replaceTopOfStackWith = '.
	self replaceTopOfStackWith printOn: aStream.
	aStream crtab: indent

{ #category : 'initialize-release' }
GbxGciStoreTravDoArgsSType64 >> initialize
	"Set things appropriately for initial allocation."

	super initialize.
	self
		execBlockArgs: 0;
		execBlockNumArgs: 0.
	^self

