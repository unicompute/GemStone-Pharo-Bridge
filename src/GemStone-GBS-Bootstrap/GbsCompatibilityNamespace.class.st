Class {
	#name : 'GbsCompatibilityNamespace',
	#superclass : 'Object',
	#instVars : [
		'bindings'
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'initialization' }
GbsCompatibilityNamespace >> initialize
[
	super initialize.
	bindings := Dictionary new
]

{ #category : 'private' }
GbsCompatibilityNamespace >> normalizeKey: aKey
[
	^ aKey isString
		ifTrue: [ aKey asSymbol ]
		ifFalse: [ aKey ]
]

{ #category : 'accessing' }
GbsCompatibilityNamespace >> at: aKey
[
	^ self at: aKey ifAbsent: [ self error: 'Unknown binding: ', aKey asString ]
]

{ #category : 'accessing' }
GbsCompatibilityNamespace >> at: aKey ifAbsent: aBlock
[
	^ bindings at: (self normalizeKey: aKey) ifAbsent: aBlock
]

{ #category : 'accessing' }
GbsCompatibilityNamespace >> at: aKey put: aValue
[
	^ bindings at: (self normalizeKey: aKey) put: aValue
]

{ #category : 'accessing' }
GbsCompatibilityNamespace >> associationAt: aKey ifAbsent: aBlock
[
	^ bindings associationAt: (self normalizeKey: aKey) ifAbsent: aBlock
]

{ #category : 'enumerating' }
GbsCompatibilityNamespace >> bindingsDo: aBlock
[
	bindings associationsDo: aBlock
]

{ #category : 'enumerating' }
GbsCompatibilityNamespace >> keysAndValuesDo: aBlock
[
	bindings keysAndValuesDo: aBlock
]

{ #category : 'testing' }
GbsCompatibilityNamespace >> includesKey: aKey
[
	^ bindings includesKey: (self normalizeKey: aKey)
]

{ #category : 'message handling' }
GbsCompatibilityNamespace >> doesNotUnderstand: aMessage
[
	(aMessage arguments isEmpty and: [ self includesKey: aMessage selector ])
		ifTrue: [ ^ self at: aMessage selector ].
	^ super doesNotUnderstand: aMessage
]
