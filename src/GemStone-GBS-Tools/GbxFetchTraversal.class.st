Class {
	#name : 'GbxFetchTraversal',
	#superclass : 'GbxTraversal',
	#instVars : [
		'session',
		'cache',
		'clampSpec',
		'level',
		'bufferSize',
		'objectsFetched',
		'swizzleBlock'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxFetchTraversal class >> on: aSession cache: aCache [
	^ self new
		session: aSession;
		cache: aCache;
		yourself
]

{ #category : 'traversal' }
GbxFetchTraversal >> fetchObjectAtOop: anOop [
	"Fetch and swizzle a single object"
	| proxy |
	
	"Check cache first"
	proxy := cache proxyForOop: anOop.
	proxy ifNotNil: [ ^ proxy ].
	
	"Fetch from server"
	self fetchRawDataForOop: anOop.
	
	"Swizzle the data"
	^ self swizzleBuffer.
]

{ #category : 'traversal' }
GbxFetchTraversal >> fetchObjectsAtOops: oopArray [
	"Fetch and swizzle multiple objects"
	| results |
	
	results := Array new: oopArray size.
	oopArray keysAndValuesDo: [ :i :oop |
		results at: i put: (self fetchObjectAtOop: oop).
	].
	
	^ results.
]

{ #category : 'fetching' }
GbxFetchTraversal >> fetchRawDataForOop: anOop [
	"Fetch raw data for an OOP from server"
	| size classOop |
	
	session ifNil: [ ^ nil ].
	
	"Get object size"
	size := session serverInterface apiGciFetchSize: anOop.
	
	"Get object class"
	classOop := session serverInterface apiGciFetchClass: anOop.
	
	"Allocate buffer"
	bufferSize := size + 64. "Extra space for header"
	buffer := ExternalAddress allocate: bufferSize.
	
	"Fetch bytes"
	session serverInterface
		apiGciFetchBytes: anOop
		startIndex: 1
		buffer: buffer
		maxSize: size.
	
	objectsFetched := objectsFetched + 1.
]

{ #category : 'initialization' }
GbxFetchTraversal >> initialize [
	super initialize.
	cache := GbxBasicCache new.
	level := 3. "Default replication level"
	objectsFetched := 0.
	swizzleBlock := [ :oop :data | self defaultSwizzleForOop: oop data: data ].
]

{ #category : 'swizzling' }
GbxFetchTraversal >> defaultSwizzleForOop: anOop data: data [
	"Default swizzling logic"
	| className proxy |
	
	"Read class name from data"
	className := self readClassNameFromBuffer.
	
	"Create appropriate proxy"
	proxy := self createProxyForClass: className oop: anOop.
	
	"Cache the proxy"
	cache atOop: anOop put: proxy.
	
	^ proxy.
]

{ #category : 'swizzling' }
GbxFetchTraversal >> createProxyForClass: className oop: anOop [
	"Create a proxy for a specific class"
	
	className = 'Array' ifTrue: [ ^ self createArrayProxyForOop: anOop ].
	className = 'OrderedCollection' ifTrue: [ ^ self createCollectionProxyForOop: anOop ].
	className = 'Dictionary' ifTrue: [ ^ self createDictionaryProxyForOop: anOop ].
	className = 'Set' ifTrue: [ ^ self createSetProxyForOop: anOop ].
	className = 'String' ifTrue: [ ^ self createStringProxyForOop: anOop ].
	className = 'Symbol' ifTrue: [ ^ self createSymbolProxyForOop: anOop ].
	
	^ GbsProxy new
		oop: anOop;
		session: session;
		className: className;
		yourself.
]

{ #category : 'swizzling' }
GbxFetchTraversal >> createArrayProxyForOop: anOop [
	"Create an array proxy"
	| size array i elemOop |
	
	size := self readSizeFromBuffer.
	array := Array new: size.
	
	1 to: size do: [ :i |
		elemOop := self readOopAtOffset: (i * 8).
		array at: i put: (self fetchObjectAtOop: elemOop).
	].
	
	^ array.
]

{ #category : 'swizzling' }
GbxFetchTraversal >> createCollectionProxyForOop: anOop [
	"Create a collection proxy"
	| size collection i elemOop |
	
	size := self readSizeFromBuffer.
	collection := OrderedCollection new: size.
	
	1 to: size do: [ :i |
		elemOop := self readOopAtOffset: (i * 8).
		collection add: (self fetchObjectAtOop: elemOop).
	].
	
	^ collection.
]

{ #category : 'swizzling' }
GbxFetchTraversal >> createDictionaryProxyForOop: anOop [
	"Create a dictionary proxy"
	| dict keyOop valueOop |
	
	dict := Dictionary new.
	
	[ self hasMoreEntries ] whileTrue: [
		keyOop := self readNextOop.
		valueOop := self readNextOop.
		
		dict
			at: (self fetchObjectAtOop: keyOop)
			put: (self fetchObjectAtOop: valueOop).
	].
	
	^ dict.
]

{ #category : 'swizzling' }
GbxFetchTraversal >> createSetProxyForOop: anOop [
	"Create a set proxy"
	| size set i elemOop |
	
	size := self readSizeFromBuffer.
	set := IdentitySet new: size.
	
	1 to: size do: [ :i |
		elemOop := self readOopAtOffset: (i * 8).
		set add: (self fetchObjectAtOop: elemOop).
	].
	
	^ set.
]

{ #category : 'swizzling' }
GbxFetchTraversal >> createStringProxyForOop: anOop [
	"Create a string proxy"
	| size string |
	
	size := self readSizeFromBuffer.
	string := String new: size.
	
	1 to: size do: [ :i |
		string at: i put: (self readByteAtOffset: i).
	].
	
	^ string.
]

{ #category : 'swizzling' }
GbxFetchTraversal >> createSymbolProxyForOop: anOop [
	"Create a symbol proxy"
	| string |
	
	string := self createStringProxyForOop: anOop.
	^ string asSymbol.
]

{ #category : 'reading' }
GbxFetchTraversal >> readClassNameFromBuffer [
	"Read class name from buffer"
	| className |
	
	className := buffer getString.
	^ className.
]

{ #category : 'reading' }
GbxFetchTraversal >> readSizeFromBuffer [
	"Read size from buffer"
	^ buffer uint64At: 1.
]

{ #category : 'reading' }
GbxFetchTraversal >> readOopAtOffset: offset [
	"Read an OOP at a specific offset"
	^ buffer uint64At: offset.
]

{ #category : 'reading' }
GbxFetchTraversal >> readByteAtOffset: offset [
	"Read a byte at a specific offset"
	^ buffer unsignedByteAt: offset.
]

{ #category : 'reading' }
GbxFetchTraversal >> readNextOop [
	"Read next OOP from buffer (sequential)"
	| oop |
	
	oop := buffer uint64At: buffer currentPosition.
	buffer currentPosition: buffer currentPosition + 8.
	^ oop.
]

{ #category : 'testing' }
GbxFetchTraversal >> hasMoreEntries [
	"Check if there are more entries to read"
	^ buffer currentPosition < bufferSize.
]

{ #category : 'accessing' }
GbxFetchTraversal >> cache [
	^ cache
]

{ #category : 'accessing' }
GbxFetchTraversal >> cache: aCache [
	cache := aCache
]

{ #category : 'accessing' }
GbxFetchTraversal >> clampSpec [
	^ clampSpec
]

{ #category : 'accessing' }
GbxFetchTraversal >> clampSpec: aSpec [
	clampSpec := aSpec
]

{ #category : 'accessing' }
GbxFetchTraversal >> level [
	^ level
]

{ #category : 'accessing' }
GbxFetchTraversal >> level: anInteger [
	level := anInteger
]

{ #category : 'accessing' }
GbxFetchTraversal >> objectsFetched [
	^ objectsFetched
]

{ #category : 'accessing' }
GbxFetchTraversal >> session [
	^ session
]

{ #category : 'accessing' }
GbxFetchTraversal >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxFetchTraversal >> swizzleBlock [
	^ swizzleBlock
]

{ #category : 'accessing' }
GbxFetchTraversal >> swizzleBlock: aBlock [
	swizzleBlock := aBlock
]

{ #category : 'swizzling' }
GbxFetchTraversal >> swizzleBuffer [
	"Swizzle the entire buffer"
	^ swizzleBlock value: nil value: buffer.
]
