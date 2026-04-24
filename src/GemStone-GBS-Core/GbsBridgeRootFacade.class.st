Class {
	#name : 'GbsBridgeRootFacade',
	#superclass : 'GbsSymbolDictionaryFacade',
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsBridgeRootFacade class >> on: aSession [
	^ self new
		session: aSession;
		yourself
]

{ #category : 'accessing' }
GbsBridgeRootFacade >> name [
	^ 'BridgeRoot'
]

{ #category : 'printing' }
GbsBridgeRootFacade >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: '(BridgeRoot)'
]

{ #category : 'private' }
GbsBridgeRootFacade >> aliasRootKeys [
	^ #()
]

{ #category : 'private' }
GbsBridgeRootFacade >> rootKey [
	^ #GbsBridgeRoot
]

{ #category : 'private' }
GbsBridgeRootFacade >> rootScript [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '[:association :primaryKey :aliasKeys | | userGlobals root |
	userGlobals := association
		ifNil: [ nil ]
		ifNotNil: [ (association respondsTo: #value)
			ifTrue: [ association value ]
			ifFalse: [ association ] ].
	userGlobals ifNil: [ nil ] ifNotNil: [
		root := userGlobals
			at: primaryKey
			ifAbsent: [
				| existing |
				existing := nil.
				aliasKeys do: [ :each |
					existing ifNil: [
						existing := userGlobals at: each ifAbsent: [ nil ] ] ].
				existing ifNil: [ Dictionary new ] ifNotNil: [ existing ] ].
		userGlobals at: primaryKey put: root.
		aliasKeys do: [ :each | userGlobals at: each put: root ].
		root ] ]
	value: (GsSession currentSession resolveSymbol: #UserGlobals)
	value: ';
			nextPutAll: (session marshalArgumentToScript: self rootKey);
			nextPutAll: '
	value: ';
			nextPutAll: (session marshalArgumentToScript: self aliasRootKeys) ]
]
