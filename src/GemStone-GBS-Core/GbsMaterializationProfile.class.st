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
	(self shouldMaterializeCollectionClassNamed: className depth: anInteger) ifTrue: [
		seenOops add: anOop.
		^ self
			materializeCollectionClassNamed: className
			oop: anOop
			inSession: aSession
			depth: anInteger
			seen: seenOops ].
	(self
		shouldMaterializeMappedClassNamed: className
		inSession: aSession
		depth: anInteger) ifTrue: [
		^ aSession materializer
			materializeMappedObjectOop: anOop
			className: className
			withProfile: self
			depth: anInteger
			seen: seenOops ].
	^ aSession proxyForOop: anOop serverClassName: className
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
GbsMaterializationProfile >> materializationClassNamed: className [
	className ifNil: [ ^ nil ].
	^ Smalltalk globals
		at: className asSymbol
		ifAbsent: [ nil ]
]

{ #category : 'materialization' }
GbsMaterializationProfile >> nestedProfileForDepth: anInteger [
	^ self
]

{ #category : 'materialization' }
GbsMaterializationProfile >> nestedProfileForIndexedPartOfClassNamed: className inSession: aSession depth: anInteger [
	| class scheme |
	class := self materializationClassNamed: className.
	class ifNil: [ ^ self nestedProfileForDepth: anInteger ].
	scheme := self replicationSchemeInSession: aSession.
	((scheme notNil and: [
		scheme respondsTo: #shouldProxyIndexedInstvarsOfClass: ]) and: [
		scheme shouldProxyIndexedInstvarsOfClass: class ]) ifTrue: [
		^ GbsProxyOnlyMaterializationProfile new ].
	^ self nestedProfileForDepth: anInteger
]

{ #category : 'materialization' }
GbsMaterializationProfile >> nestedProfileForNamedSlot: slotIndex ofClassNamed: className inSession: aSession depth: anInteger [
	| class scheme |
	class := self materializationClassNamed: className.
	class ifNil: [ ^ self nestedProfileForDepth: anInteger ].
	scheme := self replicationSchemeInSession: aSession.
	((scheme notNil and: [
		scheme respondsTo: #shouldProxyNamedSlot:ofClass: ]) and: [
		scheme shouldProxyNamedSlot: slotIndex ofClass: class ]) ifTrue: [
		^ GbsProxyOnlyMaterializationProfile new ].
	^ self nestedProfileForDepth: anInteger
]

{ #category : 'materialization' }
GbsMaterializationProfile >> replicationSchemeInSession: aSession [
	| manager |
	manager := [ GbxClampManager forSession: aSession ] on: Error do: [ nil ].
	manager ifNil: [ ^ nil ].
	^ [ manager currentReplicationScheme ] on: Error do: [ nil ]
]

{ #category : 'materialization' }
GbsMaterializationProfile >> shouldMaterializeCollectionClassNamed: className depth: anInteger [
	^ false
]

{ #category : 'materialization' }
GbsMaterializationProfile >> shouldMaterializeMappedClassNamed: className inSession: aSession [
	^ false
]

{ #category : 'materialization' }
GbsMaterializationProfile >> shouldMaterializeMappedClassNamed: className inSession: aSession depth: anInteger [
	^ self shouldMaterializeMappedClassNamed: className inSession: aSession
]

{ #category : 'materialization' }
GbsMaterializationProfile >> shouldMaterializeScalarClassNamed: className [
	^ #('String' 'DoubleByteString' 'Symbol' 'DoubleByteSymbol' 'DateTime' 'ByteArray')
		includes: className
]
