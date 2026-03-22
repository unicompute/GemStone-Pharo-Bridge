Class {
	#name : 'GbxStoreTraversalTool',
	#superclass : 'GbxTraversal',
	#instVars : [
		'session',
		'cache',
		'bufferSize',
		'objectsStored',
		'dirtyObjects',
		'storeBlock'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxStoreTraversalTool class >> on: aSession cache: aCache [
	^ self new
		session: aSession;
		cache: aCache;
		yourself
]

{ #category : 'traversal' }
GbxStoreTraversalTool >> storeObject: anObject [
	"Store an object to GemStone"
	| oop |
	
	"Check if already cached"
	oop := cache oopForProxy: anObject.
	oop ifNotNil: [ ^ oop ].
	
	"Unswizzle the object"
	self unswizzleObject: anObject.
	
	"Store to server"
	oop := self storeBufferToServer.
	
	"Cache the result"
	cache atOop: oop put: anObject.
	
	objectsStored := objectsStored + 1.
	^ oop.
]

{ #category : 'traversal' }
GbxStoreTraversalTool >> storeObjects: objectArray [
	"Store multiple objects to GemStone"
	| oops |
	
	oops := Array new: objectArray size.
	objectArray keysAndValuesDo: [ :i :obj |
		oops at: i put: (self storeObject: obj).
	].
	
	^ oops.
]

{ #category : 'unswizzling' }
GbxStoreTraversalTool >> unswizzleObject: anObject [
	"Unswizzle an object to raw bytes"
	
	anObject isArray ifTrue: [ ^ self unswizzleArray: anObject ].
	anObject isOrderedCollection ifTrue: [ ^ self unswizzleCollection: anObject ].
	anObject isDictionary ifTrue: [ ^ self unswizzleDictionary: anObject ].
	anObject isSet ifTrue: [ ^ self unswizzleSet: anObject ].
	anObject isString ifTrue: [ ^ self unswizzleString: anObject ].
	anObject isSymbol ifTrue: [ ^ self unswizzleSymbol: anObject ].
	
	^ self unswizzleProxy: anObject.
]

{ #category : 'unswizzling' }
GbxStoreTraversalTool >> unswizzleArray: anArray [
	"Unswizzle an array"
	| size |
	
	size := anArray size.
	self allocateBufferForSize: size * 8 + 16.
	
	"Write size"
	buffer uint64At: 1 put: size.
	
	"Write elements"
	1 to: size do: [ :i |
		| elem oop |
		elem := anArray at: i.
		oop := self getOopFor: elem.
		buffer uint64At: (i * 8 + 8) put: oop.
	].
]

{ #category : 'unswizzling' }
GbxStoreTraversalTool >> unswizzleCollection: aCollection [
	"Unswizzle a collection"
	| size |
	
	size := aCollection size.
	self allocateBufferForSize: size * 8 + 16.
	
	"Write size"
	buffer uint64At: 1 put: size.
	
	"Write elements"
	1 to: size do: [ :i |
		| elem oop |
		elem := aCollection at: i.
		oop := self getOopFor: elem.
		buffer uint64At: (i * 8 + 8) put: oop.
	].
]

{ #category : 'unswizzling' }
GbxStoreTraversalTool >> unswizzleDictionary: aDictionary [
	"Unswizzle a dictionary"
	| count offset |
	
	count := aDictionary size.
	self allocateBufferForSize: count * 16 + 16.
	
	"Write count"
	buffer uint64At: 1 put: count.
	
	offset := 16.
	aDictionary keysAndValuesDo: [ :key :value |
		| keyOop valueOop |
		keyOop := self getOopFor: key.
		valueOop := self getOopFor: value.
		
		buffer uint64At: offset put: keyOop.
		buffer uint64At: offset + 8 put: valueOop.
		
		offset := offset + 16.
	].
]

{ #category : 'unswizzling' }
GbxStoreTraversalTool >> unswizzleSet: aSet [
	"Unswizzle a set"
	| size offset |
	
	size := aSet size.
	self allocateBufferForSize: size * 8 + 16.
	
	"Write size"
	buffer uint64At: 1 put: size.
	
	offset := 16.
	aSet do: [ :elem |
		| elemOop |
		elemOop := self getOopFor: elem.
		buffer uint64At: offset put: elemOop.
		offset := offset + 8.
	].
]

{ #category : 'unswizzling' }
GbxStoreTraversalTool >> unswizzleString: aString [
	"Unswizzle a string"
	| size |
	
	size := aString size.
	self allocateBufferForSize: size + 16.
	
	"Write size"
	buffer uint64At: 1 put: size.
	
	"Write characters"
	1 to: size do: [ :i |
		buffer unsignedByteAt: i + 8 put: (aString at: i) asInteger.
	].
]

{ #category : 'unswizzling' }
GbxStoreTraversalTool >> unswizzleSymbol: aSymbol [
	"Unswizzle a symbol"
	self unswizzleString: aSymbol asString.
]

{ #category : 'unswizzling' }
GbxStoreTraversalTool >> unswizzleProxy: aProxy [
	"Unswizzle a proxy"
	| oop |
	
	oop := cache oopForProxy: aProxy.
	oop ifNil: [
		oop := aProxy oop.
	].
	
	self allocateBufferForSize: 16.
	buffer uint64At: 1 put: oop.
]

{ #category : 'storage' }
GbxStoreTraversalTool >> storeBufferToServer [
	"Store buffer contents to server"
	| oop |
	
	session ifNil: [ ^ nil ].
	
	"Create new OOP"
	oop := session serverInterface apiGciNewOop.
	
	"Store bytes"
	session serverInterface
		apiGciStoreBytes: oop
		startIndex: 1
		bytes: buffer
		numBytes: bufferSize.
	
	"Mark as dirty"
	dirtyObjects add: oop.
	
	^ oop.
]

{ #category : 'utilities' }
GbxStoreTraversalTool >> allocateBufferForSize: size [
	"Allocate buffer for given size"
	
	buffer ifNotNil: [ buffer free ].
	bufferSize := size.
	buffer := ExternalAddress allocate: bufferSize.
]

{ #category : 'utilities' }
GbxStoreTraversalTool >> getOopFor: anObject [
	"Get OOP for an object"
	| oop |
	
	"Check if it's already an OOP"
	anObject isInteger ifTrue: [ ^ anObject ].
	
	"Check cache"
	oop := cache oopForProxy: anObject.
	oop ifNotNil: [ ^ oop ].
	
	"Check if it's a proxy"
	(anObject respondsTo: #oop) ifTrue: [
		oop := anObject oop.
		oop ifNotNil: [ ^ oop ].
	].
	
	"Need to store it first"
	^ self storeObject: anObject.
]

{ #category : 'initialization' }
GbxStoreTraversalTool >> initialize [
	super initialize.
	cache := GbxBasicCacheTool new.
	dirtyObjects := OrderedCollection new.
	objectsStored := 0.
	storeBlock := [ :obj | self unswizzleObject: obj ].
]

{ #category : 'accessing' }
GbxStoreTraversalTool >> cache [
	^ cache
]

{ #category : 'accessing' }
GbxStoreTraversalTool >> cache: aCache [
	cache := aCache
]

{ #category : 'accessing' }
GbxStoreTraversalTool >> dirtyObjects [
	^ dirtyObjects
]

{ #category : 'accessing' }
GbxStoreTraversalTool >> objectsStored [
	^ objectsStored
]

{ #category : 'accessing' }
GbxStoreTraversalTool >> session [
	^ session
]

{ #category : 'accessing' }
GbxStoreTraversalTool >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxStoreTraversalTool >> storeBlock [
	^ storeBlock
]

{ #category : 'accessing' }
GbxStoreTraversalTool >> storeBlock: aBlock [
	storeBlock := aBlock
]
