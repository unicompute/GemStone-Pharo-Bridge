Class {
	#name : 'BindingReference',
	#superclass : 'Object',
	#instVars : [
		'pathString',
		'environment',
		'simpleName'
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'instance creation' }
BindingReference class >> pathString: aString
[
	^ self new pathString: aString
]

{ #category : 'instance creation' }
BindingReference class >> simpleName: aSymbol in: anEnvironment
[
	^ self new
		environment: anEnvironment;
		simpleName: aSymbol;
		yourself
]

{ #category : 'accessing' }
BindingReference >> pathString: aString
[
	pathString := aString asString.
	^ self
]

{ #category : 'accessing' }
BindingReference >> environment
[
	^ environment ifNil: [ environment := self resolvedEnvironment ]
]

{ #category : 'accessing' }
BindingReference >> environment: anObject
[
	environment := anObject.
	^ self
]

{ #category : 'accessing' }
BindingReference >> simpleName
[
	^ simpleName ifNil: [ simpleName := self parsedSegments last asSymbol ]
]

{ #category : 'accessing' }
BindingReference >> simpleName: aSymbol
[
	simpleName := aSymbol asSymbol.
	^ self
]

{ #category : 'accessing' }
BindingReference >> bindingOrNil
[
	| bindingEnvironment assoc |
	bindingEnvironment := self environment.
	bindingEnvironment ifNil: [ ^ nil ].

	assoc := (bindingEnvironment respondsTo: #associationAt:ifAbsent:)
		ifTrue: [ bindingEnvironment associationAt: self simpleName ifAbsent: [ nil ] ]
		ifFalse: [ nil ].
	assoc ifNil: [ ^ nil ].

	^ GbxNameAssociation
		newWithValuesFrom: assoc
		andGsName: self simpleName
		environment: bindingEnvironment
]

{ #category : 'accessing' }
BindingReference >> valueOrDo: aBlock
[
	| binding |
	binding := self bindingOrNil.
	^ binding
		ifNil: [ aBlock value ]
		ifNotNil: [ binding value ]
]

{ #category : 'private' }
BindingReference >> parsedSegments
[
	^ pathString
		ifNil: [ Array with: self simpleName ]
		ifNotNil: [ pathString findTokens: '.' ]
]

{ #category : 'private' }
BindingReference >> resolvedEnvironment
[
	| current |
	current := Smalltalk globals.
	self parsedSegments allButLast do: [ :each |
		| symbol assoc next |
		symbol := each asSymbol.
		(#(Root Smalltalk) includes: symbol)
			ifFalse: [
				(current respondsTo: #associationAt:ifAbsent:)
					ifTrue: [
						assoc := current associationAt: symbol ifAbsent: [ ^ nil ].
						next := assoc value ]
					ifFalse: [
						(current isBehavior and: [ current classPool notNil ])
							ifTrue: [
								assoc := current classPool associationAt: symbol ifAbsent: [ ^ nil ].
								next := assoc value ]
							ifFalse: [ ^ nil ] ].
				current := next ] ].

	(current isBehavior and: [ self parsedSegments size > 1 ])
		ifTrue: [ ^ current classPool ].
	(current respondsTo: #associationAt:ifAbsent:)
		ifTrue: [ ^ current ].
	^ nil
]
