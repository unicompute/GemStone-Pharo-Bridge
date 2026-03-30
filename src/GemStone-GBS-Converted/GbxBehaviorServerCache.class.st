Class {
	#name : 'GbxBehaviorServerCache',
	#superclass : 'Object',
	#instVars : [
		'classNames',
		'classCaches',
		'inspector'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxBehaviorServerCache class >> on: aCollection inspector: anInspector [
	^ self new
		inspector: anInspector;
		classNames: aCollection;
		initialize;
		yourself
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> behaviorForClassNamed: aSymbol [
	| resolved |
	inspector ifNotNil: [
		((inspector respondsTo: #theClassName) and: [ inspector theClassName asSymbol = aSymbol ])
			ifTrue: [
				(inspector respondsTo: #theClass)
					ifTrue: [ ^ inspector theClass ] ] ].
	resolved := Smalltalk globals at: aSymbol ifAbsent: [ nil ].
	^ resolved
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> classNames [
	^ classNames ifNil: [ #() ]
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> classNames: aCollection [
	classNames := aCollection collect: [ :each | each asSymbol ]
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> classesReferencedFrom: sourceText [
	| tokens |
	sourceText ifNil: [ ^ #() ].
	tokens := sourceText substrings.
	^ (tokens
		select: [ :each | (Smalltalk globals includesKey: each asSymbol) ])
			collect: [ :each | each asSymbol ]
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> currentBehaviorFor: classNameSymbol [
	^ (classCaches at: classNameSymbol asSymbol) currentBehavior
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> currentMethodsTextFor: selectorDictionary [
	| strings |
	strings := OrderedCollection new.
	selectorDictionary keysAndValuesDo: [ :classNameSymbol :selectors |
		| cache |
		cache := classCaches at: classNameSymbol asSymbol.
		self isAtInstanceSide
			ifTrue: [ strings addAll: (cache instanceMethodTextsFor: selectors) ]
			ifFalse: [ strings addAll: (cache classMethodTextsFor: selectors) ] ].
	^ strings asArray
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> currentProtocolsFor: classNameSymbol [
	| cache |
	cache := classCaches at: classNameSymbol asSymbol.
	^ self isAtInstanceSide
		ifTrue: [ cache instanceProtocols ]
		ifFalse: [ cache classProtocols ]
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> currentSelectorsFor: classNameSymbol [
	| cache |
	cache := classCaches at: classNameSymbol asSymbol.
	^ self isAtInstanceSide
		ifTrue: [ cache instanceSelectors ]
		ifFalse: [ cache classSelectors ]
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> currentSelectorsFor: classNameSymbol protocol: protocolName [
	| cache dictionary |
	cache := classCaches at: classNameSymbol asSymbol.
	dictionary := self isAtInstanceSide
		ifTrue: [ cache instanceMethodCache ]
		ifFalse: [ cache classMethodCache ].
	^ dictionary at: protocolName asString ifAbsent: [ #() ]
]

{ #category : 'initialization' }
GbxBehaviorServerCache >> initialize [
	super initialize.
	classCaches := Dictionary new.
	self classNames do: [ :each |
		classCaches at: each put: (GbxBehaviorServerClassCache on: each forServerCache: self) ]
]

{ #category : 'testing' }
GbxBehaviorServerCache >> isAtInstanceSide [
	^ inspector isNil
		ifTrue: [ true ]
		ifFalse: [
			(inspector respondsTo: #isAtInstanceSide)
				ifTrue: [ inspector isAtInstanceSide ]
				ifFalse: [ true ] ]
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> inspector [
	^ inspector
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> inspector: anObject [
	inspector := anObject
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> protocolExists: aSelector [
	^ (self protocolForSelector: aSelector) notNil
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> protocolForSelector: aSelector [
	| cache |
	cache := classCaches at: self theClassName ifAbsent: [ ^ nil ].
	^ cache protocolForSelector: aSelector
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> session [
	^ inspector ifNil: [ nil ] ifNotNil: [
		(inspector respondsTo: #session)
			ifTrue: [ inspector session ]
			ifFalse: [ nil ] ]
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> theClassName [
	inspector ifNotNil: [
		(inspector respondsTo: #theClassName)
			ifTrue: [ ^ inspector theClassName asSymbol ] ].
	^ self classNames ifEmpty: [ nil ] ifNotEmpty: [ self classNames first ]
]
