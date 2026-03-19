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

{ #category : 'instance creation' }
GbxStructure class >> address: anAddress
[
	| obj |
	obj := self basicNew.
	obj setData: anAddress.
	^obj
]

{ #category : 'instance creation' }
GbxStructure class >> allocate
[
	| obj |
	obj := self basicNew.
	obj allocateData.
	^obj
]

{ #category : 'accessing' }
GbxStructure class >> fixedSize
[
	self == GbxLongHolderType ifTrue: [^8].
	(self inheritsFrom: GbxGciErrSType) ifTrue: [^2168].
	(self inheritsFrom: GbxGciStoreTravDoArgsSType) ifTrue: [^96].
	self == GbxGciClampedTravArgsSType ifTrue: [^40].
	self == GbxX509LoginArg ifTrue: [^80].
	self error: 'Unknown structure size for ' , self name
]

{ #category : 'initialize-release' }
GbxStructure >> allocateData
[
	| size |
	size := self class fixedSize.
	data := ExternalAddress allocate: size.
	data autoRelease.
	1 to: size do: [:index | data byteAt: index put: 0]
]

{ #category : 'accessing' }
GbxStructure >> asAddress
[
	^data
]

{ #category : 'private' }
GbxStructure >> addressValueOf: anObject
[
	anObject ifNil: [^0].
	^anObject isInteger
		ifTrue: [anObject]
		ifFalse: [anObject asInteger]
]

{ #category : 'private' }
GbxStructure >> allocateCStringFrom: aString
[
	| cString bytes string |
	string := aString ifNil: [''].
	string := string isSymbol
		ifTrue: [string asString]
		ifFalse: [string].
	bytes := string utf8Encoded.
	cString := ExternalAddress allocate: bytes size + 1.
	cString autoRelease.
	1 to: bytes size do: [:index | cString byteAt: index put: (bytes at: index)].
	cString byteAt: bytes size + 1 put: 0.
	^cString
]

{ #category : 'private' }
GbxStructure >> boolAt: byteOffset
[
	^(self uint32At: byteOffset) ~~ 0
]

{ #category : 'private' }
GbxStructure >> boolAt: byteOffset put: aBoolean
[
	self uint32At: byteOffset put: (aBoolean ifTrue: [1] ifFalse: [0])
]

{ #category : 'private' }
GbxStructure >> cStringAt: byteOffset
[
	^(data + byteOffset - 1) readString
]

{ #category : 'accessing' }
GbxStructure >> data
[
	^data
]

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

{ #category : 'private' }
GbxStructure >> oopAt: byteOffset
[
	^data unsignedLongLongAt: byteOffset
]

{ #category : 'private' }
GbxStructure >> oopAt: byteOffset put: anObject
[
	data unsignedLongLongAt: byteOffset put: (self addressValueOf: anObject)
]

{ #category : 'initialize-release' }
GbxStructure >> setData: anAddress
[
	data := anAddress
]

{ #category : 'private' }
GbxStructure >> uint16At: byteOffset
[
	^data unsignedShortAt: byteOffset
]

{ #category : 'private' }
GbxStructure >> uint16At: byteOffset put: anInteger
[
	data unsignedShortAt: byteOffset put: anInteger
]

{ #category : 'private' }
GbxStructure >> uint32At: byteOffset
[
	^data unsignedLongAt: byteOffset
]

{ #category : 'private' }
GbxStructure >> uint32At: byteOffset put: anInteger
[
	data unsignedLongAt: byteOffset put: anInteger
]

{ #category : 'private' }
GbxStructure >> uint64At: byteOffset
[
	^data unsignedLongLongAt: byteOffset
]

{ #category : 'private' }
GbxStructure >> uint64At: byteOffset put: anInteger
[
	data unsignedLongLongAt: byteOffset put: anInteger
]
