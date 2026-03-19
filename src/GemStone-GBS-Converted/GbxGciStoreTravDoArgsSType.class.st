Class {
	#name : 'GbxGciStoreTravDoArgsSType',
	#superclass : 'GbxStructure',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'initialize-release' }
GbxGciStoreTravDoArgsSType >> initialize
[
	"Set things appropriately for initial allocation."

	self
		alteredTheOops: 0;
		alteredNumOops: 0
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> alteredNumOops
[
	^self uint32At: 9
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> alteredNumOops: anInteger
[
	self uint32At: 9 put: anInteger
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> alteredCompleted
[
	^self boolAt: 13
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> storeTravFlags
[
	^self uint32At: 89
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> storeTravFlags: aLong
[
	self uint32At: 89 put: aLong
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> alteredTheOops
[
	^self oopAt: 81
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> alteredTheOops: aPointer
[
	self oopAt: 81 put: aPointer
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> alteredSymbolBuf
[
	^self subclassResponsibility
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> storeTravBuff
[
	^self oopAt: 73
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> storeTravBuff: aPointer
[
	self oopAt: 73 put: aPointer
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> doFlags
[
	^self uint32At: 5
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> doFlags: aLong
[
	self uint32At: 5 put: aLong
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> alteredNumPairs
[
	^self subclassResponsibility
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> args
[
	^self oopAt: 57
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> args: aPointer
[
	self oopAt: 57 put: aPointer
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> contextObject
[
	^self oopAt: 17
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> contextObject: anOop
[
	self oopAt: 17 put: anOop
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> numArgs
[
	^self uint32At: 65
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> numArgs: anInteger
[
	self uint32At: 65 put: anInteger
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> receiver
[
	^self oopAt: 17
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> receiver: anOop
[
	self oopAt: 17 put: anOop
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> selector
[
	^self oopAt: 49
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> selector: aPointer
[
	self oopAt: 49 put: aPointer
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> source
[
	^self oopAt: 49
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> source: aPointer
[
	self oopAt: 49 put: aPointer
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> sourceClass
[
	^self oopAt: 25
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> sourceClass: anOop
[
	self oopAt: 25 put: anOop
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> sourceSize
[
	^self uint64At: 41
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> sourceSize: aSize
[
	self uint64At: 41 put: aSize
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> symbolList
[
	^self oopAt: 33
]

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType >> symbolList: anOop
[
	self oopAt: 33 put: anOop
]

{ #category : 'printing' }
GbxGciStoreTravDoArgsSType >> printOn: aStream indent: indent 
[
	aStream tab: indent - 1.
	aStream nextPutAll: self class name , ' with:'.
	aStream crtab: indent.
	aStream nextPutAll: 'storeTravBuff = '.
	self storeTravBuff printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'storeTravFlags = '.
	self storeTravFlags printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'doPerform = '.
	self doPerform printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'doFlags = '.
	self doFlags printOn: aStream.
	aStream crtab: indent.
	self printPecArgsOn: aStream indent: indent.
	self printStructEndOn: aStream indent: indent
]

{ #category : 'private - printing' }
GbxGciStoreTravDoArgsSType >> printStructEndOn: aStream indent: indent 
[
	^self subclassResponsibility
]

{ #category : 'private - printing' }
GbxGciStoreTravDoArgsSType >> printPArgsOn: aStream indent: indent 
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
	aStream crtab: indent
]

{ #category : 'private - printing' }
GbxGciStoreTravDoArgsSType >> printPecArgsOn: aStream indent: indent 
[
	"Union members used when doPerform=
	0 -- e_args  (ExecuteStr)
	1 -- p_args  (Perform)
	2 -- e_args  (ExecuteBlock)
	3 -- p_args 	(no execution, only receiver is used, to indicate the object to traverse)
	4 -- c_args  (ContinueWith)"

	| doPerform |
	doPerform := self doPerform.
	(doPerform == 1 or: [doPerform == 3]) 
		ifTrue: [self printPArgsOn: aStream indent: indent].
	(doPerform == 0 or: [doPerform == 2]) 
		ifTrue: [self printEArgsOn: aStream indent: indent].
	doPerform == 4 ifTrue: [self printCArgsOn: aStream indent: indent]
]

{ #category : 'private - printing' }
GbxGciStoreTravDoArgsSType >> printCArgsOn: aStream indent: indent 
[
	self subclassResponsibility
]

{ #category : 'private - printing' }
GbxGciStoreTravDoArgsSType >> printEArgsOn: aStream indent: indent 
[
	aStream nextPutAll: 'source = '.
	self source printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'sourceSize = '.
	self sourceSize printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'sourceClass = '.
	self sourceClass printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'contextObject = '.
	self contextObject printOn: aStream.
	aStream crtab: indent.
	aStream nextPutAll: 'symbolList = '.
	self symbolList printOn: aStream.
	aStream crtab: indent
]
