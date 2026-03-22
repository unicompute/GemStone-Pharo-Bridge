Class {
	#name : 'GbxBehaviorServerCache',
	#superclass : 'Object',
	#instVars : [
		'classNames',
		'classCaches',
		'inspector'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbxBehaviorServerCache >> inspector: anObject
[
	inspector := anObject
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> isAtInstanceSide
[
	^inspector isAtInstanceSide
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> inspector
[
	^inspector
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> classNames: anObject 
[
	classNames := anObject.
	self initialize
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> classNames
[
	^classNames
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> theClassName
[
	^classNames last
]

{ #category : 'accessing' }
GbxBehaviorServerCache >> session
[
	^inspector session
]

{ #category : 'protocols' }
GbxBehaviorServerCache >> currentProtocolsFor: className 
[
	"return the instance or class side protocols for the given className"

	| classCache |
	classCache := classCaches at: className.
	^inspector isAtInstanceSide 
		ifTrue: [classCache instanceProtocols]
		ifFalse: [classCache classProtocols]
]

{ #category : 'protocols' }
GbxBehaviorServerCache >> protocolForSelector: aSelector 
[
	| classCache |
	classCache := classCaches at: self theClassName.
	^classCache protocolForSelector: aSelector
]

{ #category : 'protocols' }
GbxBehaviorServerCache >> protocolExists: aSymbol 
[
	"check the object's class for an existing protocol"

	^(self currentProtocolsFor: self theClassName) includes: aSymbol
]

{ #category : 'protocols' }
GbxBehaviorServerCache >> currentBehaviorFor: className 
[
	"return a dictionary of protocols and selectors"

	^(classCaches at: className) currentBehavior
]

{ #category : 'methods' }
GbxBehaviorServerCache >> classesReferencedFrom: aSelectorDisplay 
[
	| literals context |
	context := self isAtInstanceSide 
				ifTrue: [self session resolveSymbol: aSelectorDisplay className]
				ifFalse: 
					[(self session resolveSymbol: aSelectorDisplay className) remoteClass].
	literals := self session 
				evaluate: '| gbxLiterals | 
				gbxLiterals := Set new.
				(self compiledMethodAt: ' 
						, aSelectorDisplay selector printString 
							, ') literals do:[:each | 
				each isBehavior 
					ifTrue:[gbxLiterals add: each name]
					ifFalse:[
						((each isKindOf: Association) and: [each value isBehavior]) 
							ifTrue: [gbxLiterals add: each key]]].
				gbxLiterals'
				context: context.
	^literals asSortedCollection: [:a :b | a < b]
]

{ #category : 'methods' }
GbxBehaviorServerCache >> currentMethodsTextFor: selectorDictionary 
[
	"return a collection of strings representing the method context given a dictionary of classNames to selectors"

	| strings cache |
	strings := OrderedCollection new.
	selectorDictionary keysAndValuesDo: 
			[:className :selectors | 
			cache := classCaches at: className.
			self isAtInstanceSide 
				ifTrue: [strings addAll: (cache instanceMethodTextsFor: selectors)]
				ifFalse: [strings addAll: (cache classMethodTextsFor: selectors)]].
	^strings
]

{ #category : 'methods' }
GbxBehaviorServerCache >> currentSelectorsFor: className protocol: protocolName 
[
	"return the instance or class selectors for a given protocol name"

	| classCache |
	classCache := classCaches at: className.
	^inspector isAtInstanceSide 
		ifTrue: [classCache instanceMethodCache at: protocolName]
		ifFalse: [classCache classMethodCache at: protocolName]
]

{ #category : 'methods' }
GbxBehaviorServerCache >> allMethodSymbolsFor: aSelectorDisplay 
[
	| context |
	context := self isAtInstanceSide 
				ifTrue: [self session resolveSymbol: aSelectorDisplay className]
				ifFalse: 
					[(self session resolveSymbol: aSelectorDisplay className) remoteClass].
	^inspector session 
		evaluate: '(self compiledMethodAt: ' 
				, aSelectorDisplay selector printString , ') _selectorPool'
		context: context
]

{ #category : 'methods' }
GbxBehaviorServerCache >> currentSelectorsFor: className 
[
	"return the instance or class selectors for the class name"

	| classCache |
	classCache := classCaches at: className.
	^inspector isAtInstanceSide 
		ifTrue: [classCache instanceSelectors]
		ifFalse: [classCache classSelectors]
]

{ #category : 'initialize-release' }
GbxBehaviorServerCache >> initialize
[
	classCaches := Dictionary new.
	classNames ifNil: [ ^ self ].
	classNames do: 
			[:className | 
			classCaches at: className
				put: (GbxBehaviorServerClassCache on: className forServerCache: self)]
]

{ #category : 'initialize-release' }
GbxBehaviorServerCache class >> on: aCollection inspector: aGbxBehaviorInspector 
[
	| inst |
	inst := self new.
	inst
		inspector: aGbxBehaviorInspector;
		classNames: aCollection;
		initialize.
	^inst
]
