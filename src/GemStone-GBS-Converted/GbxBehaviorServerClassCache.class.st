Class {
	#name : 'GbxBehaviorServerClassCache',
	#superclass : 'Object',
	#instVars : [
		'className',
		'classMethodCache',
		'instanceMethodCache',
		'serverCache',
		'classDelegate'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxBehaviorServerClassCache class >> on: aSymbol forServerCache: aServerCache [
	^ self new
		className: aSymbol;
		classDelegate: (aServerCache behaviorForClassNamed: aSymbol);
		serverCache: aServerCache;
		initializeCaches;
		yourself
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> classDelegate: aBehavior [
	classDelegate := aBehavior
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> classMethodCache [
	^ classMethodCache ifNil: [ classMethodCache := Dictionary new ]
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> classMethodTextsFor: selectors [
	^ self methodTextsFor: selectors in: classDelegate class
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> className [
	^ className
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> className: aSymbol [
	className := aSymbol asSymbol
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> classProtocolForSelector: aSelector [
	^ self protocolForSelector: aSelector inCache: self classMethodCache
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> classProtocols [
	^ self classMethodCache keys asSortedCollection asArray
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> classSelectors [
	| selectors |
	selectors := SortedCollection new.
	self classMethodCache valuesDo: [ :each | selectors addAll: each ].
	^ selectors asArray
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> currentBehavior [
	^ serverCache isAtInstanceSide
		ifTrue: [ self instanceMethodCache copy ]
		ifFalse: [ self classMethodCache copy ]
]

{ #category : 'initialization' }
GbxBehaviorServerClassCache >> initializeCaches [
	instanceMethodCache := self protocolCacheFor: classDelegate.
	classMethodCache := self protocolCacheFor: classDelegate class
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> instanceMethodCache [
	^ instanceMethodCache ifNil: [ instanceMethodCache := Dictionary new ]
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> instanceMethodTextsFor: selectors [
	^ self methodTextsFor: selectors in: classDelegate
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> instanceProtocolForSelector: aSelector [
	^ self protocolForSelector: aSelector inCache: self instanceMethodCache
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> instanceProtocols [
	^ self instanceMethodCache keys asSortedCollection asArray
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> instanceSelectors [
	| selectors |
	selectors := SortedCollection new.
	self instanceMethodCache valuesDo: [ :each | selectors addAll: each ].
	^ selectors asArray
]

{ #category : 'private' }
GbxBehaviorServerClassCache >> methodTextsFor: selectors in: aBehavior [
	aBehavior ifNil: [ ^ #() ].
	^ selectors collect: [ :selector |
		| compiledMethod |
		compiledMethod := aBehavior compiledMethodAt: selector ifAbsent: [ nil ].
		compiledMethod
			ifNil: [ selector asString ]
			ifNotNil: [
				(compiledMethod respondsTo: #sourceCode)
					ifTrue: [ compiledMethod sourceCode ifNil: [ selector asString ] ]
					ifFalse: [ compiledMethod printString ] ] ]
]

{ #category : 'private' }
GbxBehaviorServerClassCache >> protocolCacheFor: aBehavior [
	| cache |
	cache := Dictionary new.
	aBehavior ifNil: [ ^ cache ].
	aBehavior selectors do: [ :selector |
		| category |
		category := (aBehavior respondsTo: #protocolOfSelector:)
			ifTrue: [ aBehavior protocolOfSelector: selector ]
			ifFalse: [ [ aBehavior organization categoryOfElement: selector ] on: Error do: [ 'as yet unclassified' ] ].
		category ifNil: [ category := 'as yet unclassified' ].
		(category respondsTo: #name) ifTrue: [ category := category name ].
		category := category asString.
		(cache at: category ifAbsentPut: [ OrderedCollection new ]) add: selector ].
	cache keysAndValuesDo: [ :key :selectors |
		cache at: key put: selectors asSortedCollection asArray ].
	^ cache
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> protocolForSelector: aSelectorDisplay [
	| selector |
	selector := (aSelectorDisplay respondsTo: #selector)
		ifTrue: [ aSelectorDisplay selector ]
		ifFalse: [ aSelectorDisplay ].
	^ serverCache isAtInstanceSide
		ifTrue: [ self instanceProtocolForSelector: selector ]
		ifFalse: [ self classProtocolForSelector: selector ]
]

{ #category : 'private' }
GbxBehaviorServerClassCache >> protocolForSelector: aSelector inCache: aDictionary [
	aDictionary keysAndValuesDo: [ :category :selectors |
		(selectors includes: aSelector) ifTrue: [ ^ category ] ].
	^ nil
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> serverCache: aCache [
	serverCache := aCache
]
