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

	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: newObject noModError: nil ].
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
	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: oldObject noModError: nil ].
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
	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: oldObject noModError: nil ].
	contents removeKey: oldObject.
	self gbxConsiderModified.
	^ oldObject'
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> bagRemoveKeyIfAbsentSource [
	^ (Bag >> #removeKey:ifAbsent:) sourceCode asString
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> dictionaryAtPutOverrideSource [
	^ 'at: key put: anObject
	"Set the value at key to be anObject.  If key is not found, create a
	new entry for key and set is value to anObject. Answer anObject."

	| index assoc |
	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: key noModError: nil ].
	index := self findElementOrNil: key.
	assoc := array at: index.
	assoc
		ifNil: [ self atNewIndex: index put: (Association key: key value: anObject) ]
		ifNotNil: [ assoc value: anObject ].
	self gbxConsiderModified.
	^ anObject'
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> dictionaryAtPutSource [
	^ (Dictionary >> #at:put:) sourceCode asString
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> orderedCollectionAddOverrideSource [
	^ 'add: newObject
	"Add a new object at the end of the collection, and returns the object itself"
	"((OrderedCollection new add: 42; yourself) add: 43; yourself) asArray >>> #(42 43)"

	"Add returns the object itself"
	"(OrderedCollection new add: 42) >>> 42"

	"You may want to use yourself to return the collection itself"
	"(OrderedCollection new add: 42; yourself) class >>> OrderedCollection"
	"(OrderedCollection new add: 42; yourself) size >>> 1"
	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: newObject noModError: nil ].
	self addLast: newObject.
	self gbxConsiderModified.
	^ newObject'
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> orderedCollectionAddSource [
	^ (OrderedCollection >> #add:) sourceCode asString
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> orderedCollectionRemoveIfAbsentOverrideSource [
	^ 'remove: oldObject ifAbsent: absentBlock

	| index |
	index := firstIndex.
	[ index <= lastIndex ]
		whileTrue: [
			oldObject = (array at: index)
				ifTrue: [
					(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
						self gbsEnsureMutationAllowedAt: oldObject noModError: nil ].
					self removeIndex: index.
					self gbxConsiderModified.
					^ oldObject ]
				ifFalse: [ index := index + 1 ] ].
	^ absentBlock value'
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> orderedCollectionRemoveIfAbsentSource [
	^ (OrderedCollection >> #remove:ifAbsent:) sourceCode asString
]

{ #category : 'accessing' }
GbxRuntimeOverrideSpec class >> overridesPackageName [
	^ 'GbsRuntimeOverrides'
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> setAddOverrideSource [
	^ 'add: newObject
	"Include newObject as one of the receiver''s elements, but only if
	not already present. Answer newObject."

	| index |
	index := self scanFor: newObject.
	(array at: index)
		ifNil: [
			(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
				self gbsEnsureMutationAllowedAt: newObject noModError: nil ].
			self atNewIndex: index put: newObject asCollectionElement.
			self gbxConsiderModified ].
	^ newObject'
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> setAddSource [
	^ (Set >> #add:) sourceCode asString
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> setRemoveIfAbsentOverrideSource [
	^ 'remove: oldObject ifAbsent: aBlock

	| index |
	index := self findElementOrNil: oldObject.
	(array at: index) ifNil: [ ^ aBlock value ].
	(self respondsTo: #gbsEnsureMutationAllowedAt:noModError:) ifTrue: [
		self gbsEnsureMutationAllowedAt: oldObject noModError: nil ].
	array at: index put: nil.
	tally := tally - 1.
	self fixCollisionsFrom: index.
	self gbxConsiderModified.
	^ oldObject'
]

{ #category : 'generated' }
GbxRuntimeOverrideSpec class >> setRemoveIfAbsentSource [
	^ (Set >> #remove:ifAbsent:) sourceCode asString
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
							behavior: Dictionary
							selector: #at:put:
							from: self dictionaryAtPutSource
							to: self dictionaryAtPutOverrideSource);
				add: (GbxMethodOverride
							behavior: OrderedCollection
							selector: #add:
							from: self orderedCollectionAddSource
							to: self orderedCollectionAddOverrideSource);
				add: (GbxMethodOverride
							behavior: OrderedCollection
							selector: #remove:ifAbsent:
							from: self orderedCollectionRemoveIfAbsentSource
							to: self orderedCollectionRemoveIfAbsentOverrideSource);
				add: (GbxMethodOverride
							behavior: Set
							selector: #add:
							from: self setAddSource
							to: self setAddOverrideSource);
				add: (GbxMethodOverride
							behavior: Set
							selector: #remove:ifAbsent:
							from: self setRemoveIfAbsentSource
							to: self setRemoveIfAbsentOverrideSource);
				yourself)
]
