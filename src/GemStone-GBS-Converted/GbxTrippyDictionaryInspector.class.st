Class {
	#name : 'GbxTrippyDictionaryInspector',
	#superclass : 'GbxDictionaryInspector',
	#instVars : [
		'object',
		'fieldList',
		'selectionIndexes',
		'valueOrKey',
		'newKeyBlock'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
GbxTrippyDictionaryInspector class >> gbxIsGbsInspector [
	^ true
]

{ #category : 'accessing' }
GbxTrippyDictionaryInspector class >> tabLabel [
	^ 'GS Dictionary'
]

{ #category : 'actions' }
GbxTrippyDictionaryInspector >> add [
	| key |
	key := self requestNewKey.
	key ifNil: [ ^ self ].
	(object respondsTo: #at:put:)
		ifTrue: [ object at: key put: nil ].
	self refresh
]

{ #category : 'accessing' }
GbxTrippyDictionaryInspector >> fieldList: aCollection [
	fieldList := aCollection asArray
]

{ #category : 'private' }
GbxTrippyDictionaryInspector >> gbxDriverPartAt: anIndex [
	((object respondsTo: #cache) and: [ object cache respondsTo: #isSorted ])
		ifTrue: [ object cache isSorted ifTrue: [ ^ fieldList at: anIndex ] ].
	^ GbxKeyedDummyElement new
		key: anIndex;
		yourself
]

{ #category : 'initialization' }
GbxTrippyDictionaryInspector >> initialize: anObject [
	object := anObject.
	fieldList := #().
	selectionIndexes := #().
	valueOrKey := #value.
	^ self
]

{ #category : 'accessing' }
GbxTrippyDictionaryInspector >> object [
	^ object
]

{ #category : 'actions' }
GbxTrippyDictionaryInspector >> refresh [
	(object respondsTo: #refreshDictionary)
		ifTrue: [ object refreshDictionary ].
	(object respondsTo: #fieldList)
		ifTrue: [ fieldList := object fieldList asArray ]
]

{ #category : 'actions' }
GbxTrippyDictionaryInspector >> removeSelected [
	self selections do: [ :each |
		(object respondsTo: #removeKey:ifAbsent:)
			ifTrue: [ object removeKey: each key ifAbsent: [ ] ] ].
	self refresh
]

{ #category : 'actions' }
GbxTrippyDictionaryInspector >> requestNewKey [
	^ newKeyBlock ifNil: [ nil ] ifNotNil: [ newKeyBlock value ]
]

{ #category : 'actions' }
GbxTrippyDictionaryInspector >> requestNewKeyBlock: aBlock [
	newKeyBlock := aBlock
]

{ #category : 'selection' }
GbxTrippyDictionaryInspector >> selection [
	| selected |
	selectionIndexes size = 1 ifFalse: [ self error: 'single selection required' ].
	selected := fieldList at: selectionIndexes first.
	^ valueOrKey = #value
		ifTrue: [ selected ]
		ifFalse: [
			GbxDerivedAttribute
				label: 'key ', selected displayString
				value: selected key
				printString: selected displayString ]
]

{ #category : 'selection' }
GbxTrippyDictionaryInspector >> selectionIndexes: aCollection [
	selectionIndexes := aCollection asArray
]

{ #category : 'selection' }
GbxTrippyDictionaryInspector >> selections [
	| selections |
	selections := selectionIndexes collect: [ :each | fieldList at: each ].
	^ valueOrKey = #value
		ifTrue: [ selections asArray ]
		ifFalse: [
			selections collect: [ :each |
				GbxDerivedAttribute
					label: 'key ', each displayString
					value: each key
					printString: each displayString ] ]
]

{ #category : 'selection' }
GbxTrippyDictionaryInspector >> valueOrKey: aSymbol [
	valueOrKey := aSymbol
]
