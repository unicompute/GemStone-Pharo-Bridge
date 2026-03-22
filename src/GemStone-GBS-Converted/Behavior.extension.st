Extension { #name : 'Behavior' }

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior class >> instancesAreUnique [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior class >> newFromGSObjectReport: report inSession: session [
	^ session smalltalkClassFor: (report objId asGSObjectInSession: session)
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> asForwarder [
	^ self gbsAsUncachedForwarder
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> canUnstubInPlaceFromReport: report stubSize: stubSize [
	| newObjSize |
	newObjSize := self instSize.
	self isVariable ifTrue: [
		newObjSize := newObjSize + (self gbxIndexableSizeFromReport: report) ].
	^ newObjSize = stubSize
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> faultPolicy [
	^ #immediate
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbsByteSwizzleStride [
	^ 0
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxBindingFor: varNameSymbol [
	^ Smalltalk globals
		associationAt: (varNameSymbol isString ifTrue: [ varNameSymbol asSymbol ] ifFalse: [ varNameSymbol ])
		ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxBindingFor: varNameSymbol in: namespaceName [
	| namespace normalizedKey resolvedNamespaceName |
	normalizedKey := varNameSymbol isString
		ifTrue: [ varNameSymbol asSymbol ]
		ifFalse: [ varNameSymbol ].
	resolvedNamespaceName := namespaceName isString
		ifTrue: [ namespaceName asSymbol ]
		ifFalse: [ namespaceName ].
	namespace := resolvedNamespaceName isSymbol
		ifTrue: [ Smalltalk globals at: resolvedNamespaceName ifAbsent: [ Smalltalk globals ] ]
		ifFalse: [
			resolvedNamespaceName inject: Smalltalk globals into: [ :ns :each |
				| key |
				key := each isString ifTrue: [ each asSymbol ] ifFalse: [ each ].
				(ns respondsTo: #at:ifAbsent:)
					ifTrue: [ ns at: key ifAbsent: [ ns ] ]
					ifFalse: [ ns ] ] ].
	^ (namespace respondsTo: #associationAt:ifAbsent:)
		ifTrue: [ namespace associationAt: normalizedKey ifAbsent: [ nil ] ]
		ifFalse: [ nil ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxCanBeArgForUnsynchronizedOperationInSession: session [
	^ super gbxCanBeArgForUnsynchronizedOperationInSession: session
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxCanBeStubbed [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxDeepCopyCycles: cycles [
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxIgnoreFutureChanges [
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxIndexableSizeFromReport: report [
	^ report idxSize
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxIsMeta [
	^ self isMeta
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxIsModifiable [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxIsThisLastReport: report [
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxResolve: varNameSymbol [
	| varAssoc |
	varAssoc := self gbxBindingFor: varNameSymbol.
	^ varAssoc ifNil: [ nil ] ifNotNil: [ varAssoc value ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxResolve: varNameSymbol in: namespaceName [
	| varAssoc |
	varAssoc := self gbxBindingFor: varNameSymbol in: namespaceName.
	^ varAssoc ifNil: [ nil ] ifNotNil: [ varAssoc value ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxShouldMournEarly [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxTrapFutureChanges [
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gbxUpdateAsForwarder: aBoolean fromDelegate: aGSObject [
	aBoolean
		ifTrue: [
			| fwd |
			(self respondsTo: #removeFromSystem) ifTrue: [ self removeFromSystem ].
			self gbxAssertImmutable.
			self gbxIsImmutable: true.
			fwd := GbsForwarder new.
			self gbxBecome: fwd ]
		ifFalse: [ self gbxUpdateFromDelegate: aGSObject ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> gsObjImpl [
	self isBits
		ifTrue: [ ^ 1 ].
	^ 0
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> instancesAreForwarders [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> putInGSSession: aGbsSession [
	^ self asGSObjectInSession: aGbsSession
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Behavior >> stubYourself [
]
