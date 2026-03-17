Class {
	#name : 'GbxGciStoreTravDoArgsSType32',
	#superclass : 'GbxGciStoreTravDoArgsSType',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'initialize-release' }
GbxGciStoreTravDoArgsSType32 >> initialize
	"Set things appropriately for initial allocation."

	super initialize.
	self
		alteredSymbolBuf: 0;
		alteredNumPairs: 0.
	^self

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType32 >> doPerform
	"0 - ExecuteStr
	1 - Perform"
	^data memberAt: #doPerform

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType32 >> alteredSymbolBuf
	^data memberAt: #alteredSymbolBuf

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType32 >> alteredSymbolBuf: aPointer 
	data memberAt: #alteredSymbolBuf put: aPointer

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType32 >> alteredNumPairs
	^data memberAt: #alteredNumPairs

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType32 >> alteredNumPairs: anInteger 
	data memberAt: #alteredNumPairs put: anInteger

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType32 >> doPerform: aNum
	"0 - ExecuteStr
	1 - Perform"
	data memberAt: #doPerform put: aNum

{ #category : 'private - printing' }
GbxGciStoreTravDoArgsSType32 >> printStructEndOn: aStream indent: indent 
	aStream nextPutAll: 'alteredTheOops = '.
	self alteredTheOops printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'alteredNumOops = '.
	self alteredNumOops printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'alteredSymbolBuf = '.
	self alteredSymbolBuf printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'alteredNumPairs = '.
	self alteredNumPairs printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'alteredCompleted = '.
	self alteredCompleted printOn: aStream.
	aStream crtab: indent

{ #category : 'private - printing' }
GbxGciStoreTravDoArgsSType32 >> printCArgsOn: aStream indent: indent 
	aStream 
		nextPutAll: 'ERROR, someone is asking for continue args of a 32-bit struct, which cannot have continue args.'.
	aStream crtab: indent

