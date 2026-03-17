Class {
	#name : 'GbxGciClampedTravArgsSType',
	#superclass : 'GbxStructure',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'printing' }
GbxGciClampedTravArgsSType >> printOn: aStream indent: indent 
	| travBuffSize |
	aStream tab: indent - 1.
	aStream nextPutAll: self class name , ' with:'.
	aStream crtab: indent.
	aStream nextPutAll: 'clampSpec = ' , self clampSpec printString.
	aStream crtab: indent.
	aStream nextPutAll: 'travBuff = ' , self travBuff asInteger printString.
	aStream crtab: indent.
	"64-bit version has no travBuffSize; skip it if not present."
	
	[travBuffSize := self travBuffSize.
	aStream nextPutAll: 'travBuffSize = ' , travBuffSize printString.
	aStream crtab: indent] 
			on: MemberNotFoundError
			do: [:ex | ex return].
	aStream nextPutAll: 'level = ' , self level printString.
	aStream crtab: indent.
	aStream nextPutAll: 'retrievalFlags = ' , self retrievalFlags printString.
	aStream crtab: indent.
	aStream nextPutAll: 'resultOop = ' , self resultOop printString

