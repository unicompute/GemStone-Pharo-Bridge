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
Object >> changed: anAspect [
	^ self changed: anAspect with: nil
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> changed: anAspect with: anObject [
	| dependents |
	dependents := (self respondsTo: #myDependents)
		ifTrue: [ self myDependents ]
		ifFalse: [
			(self respondsTo: #dependents)
				ifTrue: [ self dependents ]
				ifFalse: [ nil ] ].
	dependents ifNil: [ ^ self ].
	dependents do: [ :each |
		(each respondsTo: #update:with:from:)
			ifTrue: [
				[ each update: anAspect with: anObject from: self ]
					on: Error
					do: [ ] ]
			ifFalse: [
				(each respondsTo: #update:from:)
					ifTrue: [
						[ each update: anAspect from: self ]
							on: Error
							do: [ ] ]
					ifFalse: [
						(each respondsTo: #update:)
							ifTrue: [
								[ each update: anAspect ]
									on: Error
									do: [ ] ] ] ] ].
	^ self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> asGSObject [
	| remoteObject |
	remoteObject := self gbxDelegate.
	^ remoteObject isNil
		ifTrue: [ self asGSObjectInSession: GbsSessionManager current currentSession ]
		ifFalse: [ remoteObject forAnySingleSession ]
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> asGSObjectInSession: aGbsSession [
	| delegate |
	delegate := aGbsSession cacheAtST: self.
	delegate isNil
		ifTrue: [
			aGbsSession sessionCritical: [
				delegate := aGbsSession cacheAtST: self.
				delegate isNil
					ifTrue: [ delegate := self newGSObjectMappingInSession: aGbsSession ] ] ].
	^ delegate forSession: aGbsSession
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
Object >> gbxDelegate [
	^ GbsSessionManager current delegateForClientObject: self
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxFixMe [
	"A send of gbxFixMe indicates code that still needs work."
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsImmutable [
	(self respondsTo: #isReadOnlyObject)
		ifTrue: [ ^ self isReadOnlyObject ].
	(self respondsTo: #isImmediateObject)
		ifTrue: [ ^ self isImmediateObject ].
	(self respondsTo: #isImmutable)
		ifTrue: [ ^ self isImmutable ].
	^ false
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsImmutable: aBoolean [
	| wasImmutable |
	wasImmutable := self gbxIsImmutable.
	((self respondsTo: #isImmediateObject) and: [ self isImmediateObject ])
		ifTrue: [ ^ wasImmutable ].
	(self respondsTo: #isReadOnlyObject:)
		ifTrue: [
			self isReadOnlyObject: aBoolean.
			^ wasImmutable ].
	aBoolean
		ifTrue: [
			(self respondsTo: #beReadOnlyObject)
				ifTrue: [
					self beReadOnlyObject.
					^ wasImmutable ] ]
		ifFalse: [
			(self respondsTo: #beWritableObject)
				ifTrue: [
					self beWritableObject.
					^ wasImmutable ] ].
	(self respondsTo: #isImmutable:)
		ifTrue: [
			self isImmutable: aBoolean.
			^ wasImmutable ].
	^ wasImmutable
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsimmutable [
	^ self gbxIsImmutable
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> gbxIsimmutable: aBoolean [
	^ self gbxIsImmutable: aBoolean
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

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> newGSObjectMappingInSession: aGbsSession [
	| aDelegate |
	aDelegate := aGbsSession getFreeOop.
	aGbsSession connectClient: self toServer: aDelegate.
	aDelegate markStDirty: self.
	^ aDelegate
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> putInGS [
	^ self putInGSSession: GbsSessionManager current currentSession
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> putInGSSession: aGbsSession [
	| proxy |
	proxy := self asGSObjectInSession: aGbsSession.
	proxy isStDirty ifTrue: [ aGbsSession flushDirtyToGS ].
	^ proxy
]

{ #category : '*GemStone-GBS-Converted-compatibility' }
Object >> putInGSSession: aSession toLevel: level [
	GbsConfiguration
		deprecated: 'Object>>putInGSSession:toLevel: deprecated January, 2008. Use #putInGSSession instead, or even better, use normal replication mechanisms and avoid forcing objects to the server in separate network round trips.'.
	^ self putInGSSession: aSession
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
