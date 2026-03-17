Class {
	#name : 'GbxGciStoreTravDoArgsSType64v31',
	#superclass : 'GbxGciStoreTravDoArgsSType64v3',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private - printing' }
GbxGciStoreTravDoArgsSType64v31 >> printEArgsOn: aStream indent: indent
[

	aStream nextPutAll: 'contextObject = '.
	self contextObject printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'sourceClass = '.
	self sourceClass printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'symbolList = '.
	self symbolList printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'sourceSize = '.
	self sourceSize printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'source = '.
	self source printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'args = '.
	self execBlockArgs printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'numArgs = '.
	self execBlockNumArgs printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'environmentId = '.
	self eEnvironmentId printOn: aStream.
	aStream crtab: indent
]

{ #category : 'private - printing' }
GbxGciStoreTravDoArgsSType64v31 >> printPArgsOn: aStream indent: indent 
[
	aStream nextPutAll: 'receiver = '.
	self receiver printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'selector = '.
	self selector printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'args = '.
	self args printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'numArgs = '.
	self numArgs printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'environmentId = '.
	self pEnvironmentId printOn: aStream.
	aStream crtab: indent
]

{ #category : 'printing' }
GbxGciStoreTravDoArgsSType64v31 >> printOn: aStream indent: indent
[

	aStream tab: indent - 1.
	aStream nextPutAll: self class name , ' with:'.
	aStream crtab: indent.
	aStream nextPutAll: 'doPerform = '.
	self doPerform printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'doFlags = '.
	self doFlags printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'alteredNumOops = '.
	self alteredNumOops printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'alteredCompleted = '.
	self alteredCompleted printOn: aStream.
	aStream crtab: indent.
	self printPecArgsOn: aStream indent: indent.
	aStream nextPutAll: 'storeTravBuff = '.
	self storeTravBuff printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'alteredTheOops = '.
	self alteredTheOops printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'storeTravFlags = '.
	self storeTravFlags printOn: aStream
]

