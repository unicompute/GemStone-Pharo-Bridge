Class {
	#name : 'GbxRuntimeOverrideSpec',
	#superclass : 'GbxAbstractOverrideSpec',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> bagAddWithOccurrencesOverrideSource [
	^ 'add: newObject withOccurrences: anInteger
	"Add newObject anInteger times to the receiver. Answer newObject."

	contents at: newObject put: (contents at: newObject ifAbsent: [ 0 ]) + anInteger.
	self gbxConsiderModified.
	^ newObject'
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> bagAddWithOccurrencesSource [
	^ (Bag >> #add:withOccurrences:) sourceCode asString
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> bagRemoveIfAbsentOverrideSource [
	^ 'remove: oldObject ifAbsent: exceptionBlock
	"Remove oldObject from the receiver''s elements. If several of the
	elements are equal to oldObject, only one is removed. If no element is
	equal to oldObject, answer the result of evaluating anExceptionBlock.
	Otherwise, answer the argument, oldObject."

	| count |
	count := contents at: oldObject ifAbsent: [ ^ exceptionBlock value ].
	count = 1
		ifTrue: [ contents removeKey: oldObject ]
		ifFalse: [ contents at: oldObject put: count - 1 ].
	self gbxConsiderModified.
	^ oldObject'
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> bagRemoveIfAbsentSource [
	^ (Bag >> #remove:ifAbsent:) sourceCode asString
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> bagRemoveKeyIfAbsentOverrideSource [
	^ 'removeKey: oldObject ifAbsent: exceptionBlock
	"Remove oldObject''s entry (e.g., the object and all its occurrences) from the receiver''s elements.
	If no element is equal to oldObject, answer the result of evaluating anExceptionBlock.
	Otherwise, answer the argument, oldObject."

	contents at: oldObject ifAbsent: [ ^ exceptionBlock value ].
	contents removeKey: oldObject.
	self gbxConsiderModified.
	^ oldObject'
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> bagRemoveKeyIfAbsentSource [
	^ (Bag >> #removeKey:ifAbsent:) sourceCode asString
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> identityDictionaryAtPutOverrideSource [
	^ 'at: key put: anObject
	"Set the value at key to be anObject. If key is not found, create a
	new entry for key and set its value to anObject. Answer anObject."

	| index assoc |
	index := self findElementOrNil: key.
	assoc := array at: index.
	assoc
		ifNil: [ self atNewIndex: index put: (Association key: key value: anObject) ]
		ifNotNil: [
			assoc value: anObject.
			self gbxConsiderModified ].
	^ anObject'
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> identityDictionaryAtPutSource [
	^ (Dictionary >> #at:put:) sourceCode asString
]

{ #category : 'accessing' }
GbxRuntimeOverrideSpec class >> overridesPackageName [
	^ 'GbsRuntimeOverrides'
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> spec832 [
	<version: '8.3.2'>
	^ self spec93
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> spec911 [
	<version: '9.1.1'>
	^ self spec93
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> spec921 [
	<version: '9.2.1'>
	^ self spec93
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> spec93 [
	<version: '9.3'>
	^ GbxOverrideSet
		destinationPackageName: self overridesPackageName
		classOverrides: #()
		variableOverrides: #()
		methodOverrides: (OrderedCollection new
				add: (GbxMethodOverride
							behavior: Bag
							selector: #add:withOccurrences:
							from: self bagAddWithOccurrencesSource
							to: self bagAddWithOccurrencesOverrideSource);
				add: (GbxMethodOverride
							behavior: Bag
							selector: #remove:ifAbsent:
							from: self bagRemoveIfAbsentSource
							to: self bagRemoveIfAbsentOverrideSource);
				add: (GbxMethodOverride
							behavior: Bag
							selector: #removeKey:ifAbsent:
							from: self bagRemoveKeyIfAbsentSource
							to: self bagRemoveKeyIfAbsentOverrideSource);
				add: (GbxMethodOverride
							behavior: IdentityDictionary
							selector: #at:put:
							from: self identityDictionaryAtPutSource
							to: self identityDictionaryAtPutOverrideSource);
				yourself)
]
