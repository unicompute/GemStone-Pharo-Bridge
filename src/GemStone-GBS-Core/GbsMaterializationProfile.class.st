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
		^ aSession
			materializeSequenceableCollectionOop: anOop
			using: [ :items | items asOrderedCollection ]
			withProfile: (self nestedProfileForDepth: anInteger)
			depth: anInteger
			seen: seenOops ].
	className = 'SortedCollection' ifTrue: [
		^ aSession
			materializeSequenceableCollectionOop: anOop
			using: [ :items | items asSortedCollection ]
			withProfile: (self nestedProfileForDepth: anInteger)
			depth: anInteger
			seen: seenOops ].
	className = 'Bag' ifTrue: [
		^ aSession
			materializeSequenceableCollectionOop: anOop
			using: [ :items | | bag |
				bag := Bag new.
				items do: [ :each | bag add: each ].
				bag ]
			withProfile: (self nestedProfileForDepth: anInteger)
			depth: anInteger
			seen: seenOops ].
	className = 'Set' ifTrue: [
		^ aSession
			materializeSequenceableCollectionOop: anOop
			using: [ :items | items asSet ]
			withProfile: (self nestedProfileForDepth: anInteger)
			depth: anInteger
			seen: seenOops ].
	className = 'IdentitySet' ifTrue: [
		^ aSession
			materializeSequenceableCollectionOop: anOop
			using: [ :items | | set |
				set := IdentitySet new.
				items do: [ :each | set add: each ].
				set ]
			withProfile: (self nestedProfileForDepth: anInteger)
			depth: anInteger
			seen: seenOops ].
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
GbsMaterializationProfile >> materializeOop: anOop inSession: aSession depth: anInteger seen: seenOops [
	| className |
	(aSession isImmediateOop: anOop) ifTrue: [ ^ aSession resultFor: anOop ].
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
