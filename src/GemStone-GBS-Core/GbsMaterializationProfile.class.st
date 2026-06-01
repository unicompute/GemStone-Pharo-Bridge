Class {
	#name : 'GbsMaterializationProfile',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'materialization' }
GbsMaterializationProfile >> materializeCollectionClassNamed: className oop: anOop inSession: aSession depth: anInteger seen: seenOops [
	className = 'Array' ifTrue: [
		^ aSession
			materializeArrayOop: anOop
			withProfile: (self nestedProfileForDepth: anInteger)
			depth: anInteger
			seen: seenOops ].
	className = 'OrderedCollection' ifTrue: [
		^ self materializeSequenceableCollectionClassNamed: className oop: anOop inSession: aSession depth: anInteger seen: seenOops ].
	className = 'SortedCollection' ifTrue: [
		^ self materializeSequenceableCollectionClassNamed: className oop: anOop inSession: aSession depth: anInteger seen: seenOops ].
	className = 'Bag' ifTrue: [
		^ self materializeSequenceableCollectionClassNamed: className oop: anOop inSession: aSession depth: anInteger seen: seenOops ].
	className = 'Set' ifTrue: [
		^ self materializeSequenceableCollectionClassNamed: className oop: anOop inSession: aSession depth: anInteger seen: seenOops ].
	className = 'IdentitySet' ifTrue: [
		^ self materializeSequenceableCollectionClassNamed: className oop: anOop inSession: aSession depth: anInteger seen: seenOops ].
	className = 'Dictionary' ifTrue: [
		^ aSession
			materializeDictionaryOop: anOop
			identityKeys: false
			withProfile: (self nestedProfileForDepth: anInteger)
			depth: anInteger
			seen: seenOops ].
	className = 'IdentityDictionary' ifTrue: [
		^ aSession
			materializeDictionaryOop: anOop
			identityKeys: true
			withProfile: (self nestedProfileForDepth: anInteger)
			depth: anInteger
			seen: seenOops ].
	className = 'Association' ifTrue: [
		^ aSession
			materializeAssociationOop: anOop
			withProfile: (self nestedProfileForDepth: anInteger)
			depth: anInteger
			seen: seenOops ].
	^ aSession proxyForOop: anOop serverClassName: className
]

{ #category : 'materialization' }
GbsMaterializationProfile >> materializeSequenceableCollectionClassNamed: className oop: anOop inSession: aSession depth: anInteger seen: seenOops [
	^ (aSession materializer
		materializeSequenceableCollectionOops: { anOop }
		classNames: (Dictionary new
			at: anOop put: className;
			yourself)
		withProfile: (self nestedProfileForDepth: anInteger)
		depth: anInteger
		seen: seenOops)
			at: anOop
]

{ #category : 'materialization' }
GbsMaterializationProfile >> materializeOop: anOop inSession: aSession depth: anInteger seen: seenOops [
	| className |
	(aSession isImmediateOop: anOop) ifTrue: [ ^ aSession resultFor: anOop ].
	aSession materializedObjectForOop: anOop ifPresent: [ :object | ^ object ].
	(seenOops includes: anOop) ifTrue: [ ^ aSession proxyForOop: anOop ].
	className := aSession remoteClassNameForOop: anOop.
	(self shouldMaterializeScalarClassNamed: className) ifTrue: [
		^ self materializeScalarClassNamed: className oop: anOop inSession: aSession ].
	(self shouldMaterializeCollectionClassNamed: className depth: anInteger) ifFalse: [
		^ aSession proxyForOop: anOop serverClassName: className ].
	seenOops add: anOop.
	^ self
		materializeCollectionClassNamed: className
		oop: anOop
		inSession: aSession
		depth: anInteger
		seen: seenOops
]

{ #category : 'materialization' }
GbsMaterializationProfile >> materializeScalarClassNamed: className oop: anOop inSession: aSession [
	(className = 'String' or: [ className = 'DoubleByteString' ]) ifTrue: [
		^ aSession remoteStringValueForOop: anOop ].
	(className = 'Symbol' or: [ className = 'DoubleByteSymbol' ]) ifTrue: [
		^ (aSession remoteStringValueForOop: anOop) asSymbol ].
	className = 'DateTime' ifTrue: [
		^ DateAndTime readFrom: (aSession remoteStringValueForOop: anOop) readStream ].
	className = 'ByteArray' ifTrue: [
		^ aSession
			materializeByteArrayOop: anOop
			withProfile: GbsProxyOnlyMaterializationProfile new
			depth: 0
			seen: IdentitySet new ].
	^ aSession proxyForOop: anOop serverClassName: className
]

{ #category : 'materialization' }
GbsMaterializationProfile >> nestedProfileForDepth: anInteger [
	^ self
]

{ #category : 'materialization' }
GbsMaterializationProfile >> shouldMaterializeCollectionClassNamed: className depth: anInteger [
	^ false
]

{ #category : 'materialization' }
GbsMaterializationProfile >> shouldMaterializeScalarClassNamed: className [
	^ #('String' 'DoubleByteString' 'Symbol' 'DoubleByteSymbol' 'DateTime' 'ByteArray')
		includes: className
]
