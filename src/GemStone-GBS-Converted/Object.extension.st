Extension { #name : 'Object' }

{ #category : '*GemStone-GBS-Converted-messenger' }
Object >> cstMessenger [
	^ CstMessageDispatcher singleton
]

{ #category : '*GemStone-GBS-Converted-messenger' }
Object >> cstArgumentPrintOn: aStream [
	self printOn: aStream
]

{ #category : '*GemStone-GBS-Converted-messenger' }
Object >> gbsMessenger [
	^ GbxMessageDispatcher singleton
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> changeRequest: anAspect [
	| dependents |
	dependents := (self respondsTo: #myDependents)
		ifTrue: [ self myDependents ]
		ifFalse: [
			(self respondsTo: #dependents)
				ifTrue: [ self dependents ]
				ifFalse: [ nil ] ].
	dependents ifNil: [ ^ true ].
	dependents do: [ :each |
		(each respondsTo: #updateRequest:)
			ifTrue: [
				([ each updateRequest: anAspect ] on: Error do: [ true ])
					ifFalse: [ ^ false ] ] ].
	^ true
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxResolve: varNameSymbol [
	^ self class gbxResolve: varNameSymbol
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxResolve: varNameSymbol in: namespaceName [
	^ self class gbxResolve: varNameSymbol in: namespaceName
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxBindingFor: varNameSymbol [
	^ self class gbxBindingFor: varNameSymbol
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxBindingFor: varNameSymbol in: namespaceName [
	^ self class gbxBindingFor: varNameSymbol in: namespaceName
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxFixMe [
	"A send of gbxFixMe indicates code that still needs work."
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsGSError [
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxAsCString [
	(self isKindOf: Symbol) ifTrue: [ ^ self asString ].
	^ self
]

{ #category : '*GemStone-GBS-Converted-messenger' }
Object class >> gbsMessenger [
	^ GbxMessageDispatcher singleton
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object class >> gbxResolve: varNameSymbol [
	| varAssoc |
	varAssoc := self gbxBindingFor: varNameSymbol.
	^ varAssoc
		ifNil: [ nil ]
		ifNotNil: [ varAssoc value ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object class >> gbxResolve: varNameSymbol in: namespaceName [
	| varAssoc |
	varAssoc := self gbxBindingFor: varNameSymbol in: namespaceName.
	^ varAssoc
		ifNil: [ nil ]
		ifNotNil: [ varAssoc value ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object class >> gbxBindingFor: varNameSymbol [
	^ Smalltalk globals associationAt: varNameSymbol ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object class >> gbxBindingFor: varNameSymbol in: namespaceName [
	^ self gbxBindingFor: varNameSymbol
]
