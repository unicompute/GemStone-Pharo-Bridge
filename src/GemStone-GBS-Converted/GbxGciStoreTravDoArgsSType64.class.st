Class {
	#name : 'GbxGciStoreTravDoArgsSType64',
	#superclass : 'GbxGciStoreTravDoArgsSType',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64 >> alteredNumPairs
[
	"There are never any altered symbols in GS64."

	^0
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64 >> alteredNumPairs: anInteger
[
	"There are never any altered symbols in GS64."
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64 >> alteredSymbolBuf
[
	"There are never any altered symbols in GS64."

	^nil
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64 >> alteredSymbolBuf: aPointer
[
	"There are never any altered symbols in GS64."
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64 >> doPerform
[
	"0 == ExecuteStr, 1 == Perform, 2 == ExecuteBlock, 3 == no execution, 4 == ContinueWith."

	^self uint32At: 1
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64 >> doPerform: aNum
[
	"0 == ExecuteStr, 1 == Perform, 2 == ExecuteBlock, 3 == no execution, 4 == ContinueWith."

	self uint32At: 1 put: aNum
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64 >> execBlockArgs
[
	^self oopAt: 57
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64 >> execBlockArgs: anObject
[
	self oopAt: 57 put: anObject
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64 >> execBlockNumArgs
[
	^self uint32At: 65
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64 >> execBlockNumArgs: anInteger
[
	self uint32At: 65 put: anInteger
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64 >> process
[
	^self oopAt: 17
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64 >> process: anInteger
[
	self oopAt: 17 put: anInteger
]

{ #category : 'private - printing' }
GbxGciStoreTravDoArgsSType64 >> printStructEndOn: aStream indent: indent 
[
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
]

{ #category : 'private - printing' }
GbxGciStoreTravDoArgsSType64 >> printCArgsOn: aStream indent: indent 
[
	aStream nextPutAll: 'process = '.
	self process printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'replaceTopOfStackWith = '.
	self replaceTopOfStackWith printOn: aStream.
	aStream crtab: indent
]

{ #category : 'initialize-release' }
GbxGciStoreTravDoArgsSType64 >> initialize
[
	"Set things appropriately for initial allocation."

	super initialize.
	self
		execBlockArgs: 0;
		execBlockNumArgs: 0.
	^self
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64 >> replaceTopOfStackWith
[
	^self oopAt: 25
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64 >> replaceTopOfStackWith: anInteger
[
	self oopAt: 25 put: anInteger
]
