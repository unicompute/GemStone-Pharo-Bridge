Class {
	#name : 'GbxBasicCache',
	#superclass : 'GbxCollectionCache',
	#instVars : [
		'oopToProxy',
		'proxyToOop',
		'session',
		'hitCount',
		'missCount',
		'proxyCount',
		'maxProxies',
		'weakRegistry'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxBasicCache class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'instance creation' }
GbxBasicCache class >> on: aSession maxProxies: anInteger [
	^ self new
		session: aSession;
		maxProxies: anInteger;
		yourself
]

{ #category : 'cache management' }
GbxBasicCache >> atOop: anOop ifAbsent: aBlock [
	"Get proxy for an OOP, or evaluate block if not cached"
	| proxy |
	
	anOop <= 20 ifTrue: [ ^ aBlock value ]. "Special oops (nil, true, false, etc)"
	
	proxy := oopToProxy at: anOop ifAbsent: nil.
	proxy ifNotNil: [
		hitCount := hitCount + 1.
		^ proxy
	].
	
	missCount := missCount + 1.
	^ aBlock value
]

{ #category : 'cache management' }
GbxBasicCache >> atOop: anOop put: aProxy [
	"Cache a proxy for an OOP"
	
	anOop <= 20 ifTrue: [ ^ aProxy ]. "Don't cache special oops"
	
	"Check if already cached"
	(oopToProxy includesKey: anOop) ifTrue: [
		^ oopToProxy at: anOop
	].
	
	"Evict if needed"
	proxyCount >= maxProxies ifTrue: [
		self evictOldest.
	].
	
	"Add to cache"
	oopToProxy at: anOop put: aProxy.
	proxyToOop at: aProxy put: anOop.
	proxyCount := proxyCount + 1.
	
	"Register for finalization"
	self registerForFinalization: aProxy.
	
	^ aProxy
]

{ #category : 'cache management' }
GbxBasicCache >> clear [
	"Clear the cache"
	oopToProxy := IdentityDictionary new.
	proxyToOop := IdentityDictionary new.
	proxyCount := 0.
	hitCount := 0.
	missCount := 0.
]

{ #category : 'cache management' }
GbxBasicCache >> evictOldest [
	"Evict oldest entry (simple LRU)"
	| oldestOop oldestProxy |
	
	oopToProxy isEmpty ifTrue: [ ^ ].
	
	"Get first entry (oldest in dictionary)"
	oldestOop := oopToProxy keys first.
	oldestProxy := oopToProxy at: oldestOop.
	
	oopToProxy removeKey: oldestOop.
	proxyToOop removeKey: oldestProxy ifAbsent: [ ].
	proxyCount := proxyCount - 1.
]

{ #category : 'cache management' }
GbxBasicCache >> evictProxy: aProxy [
	"Evict a specific proxy from cache"
	| oop |
	
	oop := proxyToOop at: aProxy ifAbsent: [ nil ].
	oop ifNotNil: [
		oopToProxy removeKey: oop ifAbsent: [ ].
		proxyToOop removeKey: aProxy ifAbsent: [ ].
		proxyCount := proxyCount - 1.
	].
]

{ #category : 'accessing' }
GbxBasicCache >> hitCount [
	^ hitCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxBasicCache >> hitRatio [
	| total |
	total := hitCount + missCount.
	total = 0 ifTrue: [ ^ 1.0 ].
	^ hitCount / total
]

{ #category : 'initialization' }
GbxBasicCache >> initialize [
	super initialize.
	oopToProxy := IdentityDictionary new.
	proxyToOop := IdentityDictionary new.
	hitCount := 0.
	missCount := 0.
	proxyCount := 0.
	maxProxies := 10000.
	weakRegistry := WeakValueDictionary new.
]

{ #category : 'accessing' }
GbxBasicCache >> maxProxies [
	^ maxProxies
]

{ #category : 'accessing' }
GbxBasicCache >> maxProxies: anInteger [
	maxProxies := anInteger
]

{ #category : 'accessing' }
GbxBasicCache >> missCount [
	^ missCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
GbxBasicCache >> oopForProxy: aProxy [
	"Get OOP for a proxy"
	^ proxyToOop at: aProxy ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbxBasicCache >> oopToProxy [
	^ oopToProxy
]

{ #category : 'accessing' }
GbxBasicCache >> proxyCount [
	^ proxyCount
]

{ #category : 'accessing' }
GbxBasicCache >> proxyForOop: anOop [
	"Get proxy for an OOP"
	^ oopToProxy at: anOop ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GbxBasicCache >> proxyToOop [
	^ proxyToOop
]

{ #category : 'finalization' }
GbxBasicCache >> registerForFinalization: aProxy [
	"Register a proxy for finalization"
	weakRegistry at: aProxy put: [ :proxy |
		self evictProxy: proxy.
	].
]

{ #category : 'accessing' }
GbxBasicCache >> session [
	^ session
]

{ #category : 'accessing' }
GbxBasicCache >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbxBasicCache >> size [
	^ proxyCount
]

{ #category : 'cache management' }
GbxBasicCache >> swizzleOop: anOop [
	"Swizzle an OOP to a proxy or cached object"
	^ self atOop: anOop ifAbsent: [
		"Create new proxy"
		| proxy |
		proxy := GbsProxy new
			oop: anOop;
			session: session;
			yourself.
		self atOop: anOop put: proxy.
		proxy
	].
]

{ #category : 'cache management' }
GbxBasicCache >> unswizzleProxy: aProxy [
	"Unswizzle a proxy back to OOP"
	| oop |
	
	oop := self oopForProxy: aProxy.
	oop ifNotNil: [
		self evictProxy: aProxy.
	].
	
	^ oop
]
