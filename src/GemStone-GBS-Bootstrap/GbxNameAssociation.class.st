Class {
	#name : 'GbxNameAssociation',
	#superclass : 'Association',
	#instVars : [
		'gsName',
		'environment',
		'category',
		'usage',
		'dirty',
		'immutable'
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'instance creation' }
GbxNameAssociation class >> newWithValuesFrom: aVariableBinding andGsName: aSymbol
[
	^ self
		newWithValuesFrom: aVariableBinding
		andGsName: aSymbol
		environment:
			((aVariableBinding respondsTo: #environment)
				ifTrue: [ aVariableBinding environment ]
				ifFalse: [ Smalltalk globals ])
]

{ #category : 'instance creation' }
GbxNameAssociation class >> newWithValuesFrom: aVariableBinding andGsName: aSymbol environment: anEnvironment
[
	| nameAssociation |
	nameAssociation := self key: aVariableBinding key value: aVariableBinding value.
	nameAssociation
		gsName: aSymbol;
		environment: anEnvironment;
		category:
			((aVariableBinding respondsTo: #category)
				ifTrue: [ aVariableBinding category ]
				ifFalse: [ nil ]);
		usage:
			((aVariableBinding respondsTo: #usage)
				ifTrue: [ aVariableBinding usage ]
				ifFalse: [ nil ]);
		isImmutable:
			((aVariableBinding respondsTo: #isImmutable)
				ifTrue: [ aVariableBinding isImmutable ]
				ifFalse: [ false ]);
		markNotDirty.
	^ nameAssociation
]

{ #category : 'accessing' }
GbxNameAssociation >> gsName
[
	^ gsName
]

{ #category : 'accessing' }
GbxNameAssociation >> gsName: anObject
[
	gsName := anObject
]

{ #category : 'accessing' }
GbxNameAssociation >> environment
[
	^ environment ifNil: [ Smalltalk globals ]
]

{ #category : 'accessing' }
GbxNameAssociation >> environment: anObject
[
	environment := anObject
]

{ #category : 'accessing' }
GbxNameAssociation >> category
[
	^ category
]

{ #category : 'accessing' }
GbxNameAssociation >> category: anObject
[
	category := anObject
]

{ #category : 'accessing' }
GbxNameAssociation >> usage
[
	^ usage
]

{ #category : 'accessing' }
GbxNameAssociation >> usage: anObject
[
	usage := anObject
]

{ #category : 'accessing' }
GbxNameAssociation >> isImmutable
[
	^ immutable == true
]

{ #category : 'accessing' }
GbxNameAssociation >> isImmutable: aBoolean
[
	immutable := aBoolean == true
]

{ #category : 'accessing' }
GbxNameAssociation >> value
[
	^ (self environment respondsTo: #at:ifAbsent:)
		ifTrue: [ self environment at: self key ifAbsent: [ super value ] ]
		ifFalse: [ super value ]
]

{ #category : 'accessing' }
GbxNameAssociation >> value: newValue
[
	self markDirty.
	(self environment respondsTo: #at:put:)
		ifTrue: [ self environment at: self key put: newValue ].
	^ super value: newValue
]

{ #category : 'accessing' }
GbxNameAssociation >> noDirtyValue: newValue
[
	(self environment respondsTo: #at:put:)
		ifTrue: [ self environment at: self key put: newValue ].
	^ super value: newValue
]

{ #category : 'accessing' }
GbxNameAssociation >> markDirty
[
	dirty := true
]

{ #category : 'accessing' }
GbxNameAssociation >> markNotDirty
[
	dirty := false
]

{ #category : 'accessing' }
GbxNameAssociation >> dirty
[
	^ dirty == true
]

{ #category : 'replication support' }
GbxNameAssociation >> namedValues
[
	| clone |
	clone := self shallowCopy.
	clone instVarAt: 1 put: gsName.
	^ clone
]

{ #category : 'replication support' }
GbxNameAssociation >> faultPolicy
[
	^ #immediate
]

{ #category : 'replication support' }
GbxNameAssociation >> namedValueAt: index put: aValue
[
	index = 1
		ifTrue: [
			gsName := aValue.
			self key ifNil: [ self instVarAt: 1 put: aValue ] ]
		ifFalse: [ self error: 'Unsupported named slot index' ]
]

{ #category : 'printing' }
GbxNameAssociation >> printOn: aStream
[
	aStream
		print: self key;
		nextPutAll: '->';
		print: self value
]
