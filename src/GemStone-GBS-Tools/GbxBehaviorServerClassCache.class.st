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
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> serverCache: anObject
[
	serverCache := anObject
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> instanceMethodCache
[
	"lazily cache the instance category names and selectors from the server"

	instanceMethodCache isNil 
		ifTrue: 
			[instanceMethodCache := serverCache session 
						evaluate: ' | gbxDict | 
		gbxDict := Dictionary new. 
		self categoryNames do:[:cat |
			gbxDict at: cat put: (self selectorsIn: cat)].
		gbxDict'
						context: classDelegate].
	^instanceMethodCache
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> className
[
	^className
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> classMethodCache
[
	"lazily cache the class category names and selectors from the server"

	classMethodCache isNil
		ifTrue: 
			[classMethodCache := serverCache session
						unsynchronizedEvaluate: ' | gbxDict | 
		gbxDict := Dictionary new. 
		self categoryNames do:[:cat |
			gbxDict at: cat put: (self selectorsIn: cat)].
		gbxDict'
						context: classDelegate remoteClass].
	^classMethodCache
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> classDelegate: anObject
[
	classDelegate := anObject
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> className: aString
[
	className := aString
]

{ #category : 'accessing' }
GbxBehaviorServerClassCache >> currentBehavior
[
	^serverCache isAtInstanceSide 
		ifTrue: [self instanceMethodCache]
		ifFalse: [self classMethodCache]
]

{ #category : 'protocols' }
GbxBehaviorServerClassCache >> classProtocols
[
	^self classMethodCache keys
]

{ #category : 'protocols' }
GbxBehaviorServerClassCache >> instanceProtocols
[
	^self instanceMethodCache keys
]

{ #category : 'protocols' }
GbxBehaviorServerClassCache >> protocolForSelector: aSelectorDisplay
[
	^serverCache isAtInstanceSide 
		ifTrue: [self instanceProtocolForSelector: aSelectorDisplay selector]
		ifFalse: [self classProtocolForSelector: aSelectorDisplay selector]
]

{ #category : 'protocols' }
GbxBehaviorServerClassCache >> instanceProtocolForSelector: aSelector
[
	instanceMethodCache keysAndValuesDo: 
			[:categoryName :selectorArray | 
			selectorArray do: [:sel | sel = aSelector ifTrue: [^categoryName]]]
]

{ #category : 'protocols' }
GbxBehaviorServerClassCache >> classProtocolForSelector: aSelector
[
	classMethodCache keysAndValuesDo: 
			[:categoryName :selectorArray | 
			selectorArray do: [:sel | sel = aSelector ifTrue: [^categoryName]]]
]

{ #category : 'methods' }
GbxBehaviorServerClassCache >> instanceSelectors
[
	| instanceSelectors |
	instanceSelectors := SortedCollection new.
	self instanceMethodCache 
		keysAndValuesDo: [:protocolName :selectors | instanceSelectors addAll: selectors].
	^instanceSelectors
]

{ #category : 'methods' }
GbxBehaviorServerClassCache >> classSelectors
[
	| classSelectors |
	classSelectors := SortedCollection new.
	self classMethodCache 
		keysAndValuesDo: [:protocolName :selectors | classSelectors addAll: selectors].
	^classSelectors
]

{ #category : 'methods' }
GbxBehaviorServerClassCache >> classMethodTextsFor: selectors
[
	^serverCache session 
		evaluate: '
		| gbxSourceCodes |
		gbxSourceCodes := Array new.
		self do:[:selector | 
		gbxSourceCodes add: (' 
				, classDelegate remoteClassName 
					, '  sourceCodeAt: selector)].
		gbxSourceCodes'
		context: selectors asGSObject
]

{ #category : 'methods' }
GbxBehaviorServerClassCache >> instanceMethodTextsFor: selectors
[
	^serverCache session 
		evaluate: '
		| gbxSourceCodes |
		gbxSourceCodes := Array new.
		self do:[:selector | 
		gbxSourceCodes add: (' 
				, className asString , '  sourceCodeAt: selector)].
		gbxSourceCodes'
		context: selectors asGSObject
]

{ #category : 'instance creation' }
GbxBehaviorServerClassCache class >> on: aSymbol forServerCache: aGbxBehaviorServerCache
[
	| inst |
	inst := self new.
	inst className: aSymbol.
	inst classDelegate: (aSymbol == aGbxBehaviorServerCache theClassName 
				ifTrue: [aGbxBehaviorServerCache inspector theClass]
				ifFalse: [aGbxBehaviorServerCache session unsynchronizedExecute: aSymbol asString]).
	inst serverCache: aGbxBehaviorServerCache.
	^inst
]

