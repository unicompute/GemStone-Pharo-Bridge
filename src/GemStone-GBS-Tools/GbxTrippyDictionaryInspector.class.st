Class {
	#name : 'GbxTrippyDictionaryInspector',
	#superclass : 'DictionaryInspector',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'testing' }
GbxTrippyDictionaryInspector class >> gbxIsGbsInspector [

	^true
]

{ #category : 'accessing' }
GbxTrippyDictionaryInspector class >> tabLabel [


	^self gbxTabLabel: 'GS Elements'
]

{ #category : 'testing' }
GbxTrippyDictionaryInspector class >> testing [

	^true
]

{ #category : 'actions' }
GbxTrippyDictionaryInspector >> add [

	| newKey del |
	self gbxFixMe.	"gemstone undo's not supported yet"
	newKey := self requestNewKey.
	newKey isNil ifTrue: [^self].
	del := object delegate.
	del 
		remotePerform: #at:put:
		with: newKey asGSObject
		with: del session oopNil.
	self refresh
]

{ #category : 'private' }
GbxTrippyDictionaryInspector >> createInsertionUndo: partCollection before: anIndex [ 

	"undos not implemented in GemStone inspectors yet"

	self gbxFixMe
]

{ #category : 'building collections' }
GbxTrippyDictionaryInspector >> gbxCacheInterval: anInterval [ 

	object cacheDictionaryInterval: anInterval
]

{ #category : 'accessing' }
GbxTrippyDictionaryInspector >> gbxDriverPartAt: anIndex [ 

	^object cache isSorted 
		ifTrue: [super gbxDriverPartAt: anIndex]
		ifFalse: [GbxKeyedDummyElement new key: anIndex]
]

{ #category : 'initialize-release' }
GbxTrippyDictionaryInspector >> initialize: anObject [

	
	super initialize: anObject.
	self session: anObject delegate noCheckSession
]

{ #category : 'private' }
GbxTrippyDictionaryInspector >> pickSingleObjectIn: partCollection ifCancelled: aBlock [

	"return the delegate, not the value (which is a wrapper)"
	
	| labels objects objectsCopy |
	partCollection size = 1 ifTrue: [^partCollection first basicValueDelegate].
	labels := OrderedCollection new.
	objects := OrderedCollection new.
	partCollection
		do:
			[:part | 
			labels
				add:
					('<1s>: <2s>'
						expandMacrosWith: part displayString
						with:
							(self session
								unsynchronizedEvaluate: 'self printString'
								context: part basicValueDelegate)).
			objects add: part basicValueDelegate].
	objectsCopy := objects copy.
	labels
		add:
			(#All1pAsAnArray << #dialogs >> 'All <1p> as an Array'
				expandMacrosWith: partCollection size).
	objects
		add:
			(object session
				evaluate: 'Array withAll: self'
				context: objectsCopy asGSObject).
	labels
		add:
			(#All1pAsAnOC << #dialogs >> 'All <1p> as an OrderedCollection'
				expandMacrosWith: partCollection size).
	objects
		add:
			(object session
				evaluate: 'OrderedCollection withAll: self'
				context: objectsCopy asGSObject).
	labels
		add:
			(#All1pAsASet << #dialogs >> 'All <1p> as a Set'
				expandMacrosWith: partCollection size).
	objects
		add:
			(object session
				evaluate: 'Set withAll: self'
				context: objectsCopy asGSObject).
	^self gbsMessenger
		choose:
			#UseWhichOfTheseObjectsQ << #dialogs >> 'Use which of these objects?'
		fromList: labels
		values: objects
		lines: 8
		cancel: aBlock
]

{ #category : 'private' }
GbxTrippyDictionaryInspector >> refresh [

	"Dictionary inspectors in GemStone want to use basic super super behavior"

	| originalSelections |
	linearizedParts := object refreshDictionary.
	originalSelections := self selections.
	driver := self driverClass for: self.
	driver refresh.
	self selectAll: originalSelections
]

{ #category : 'actions' }
GbxTrippyDictionaryInspector >> removeSelected [

	"GBS: make sure we refresh the collection afterwards"

	self gbxFixMe.	"gemstone undo's not supported yet"
	self selections 
		do: [:each | object delegate remotePerform: #removeKey: with: each keyDelegate].
	self refresh
]

{ #category : 'private' }
GbxTrippyDictionaryInspector >> requestNewKey [

	"Answer a new key to add to the dictionary.  nil is
	a 'no answer' value since it is not a valid dictionary key.

	GBS: compile the resultant expression with the context of the delegate"

	| expression |
	expression := self gbsMessenger
				request: 'Add new key (context is inspector''s GemStone delegate):'.
	expression isEmpty ifTrue: [^nil].
	^object session evaluate: expression context: object delegate
]

{ #category : 'accessing' }
GbxTrippyDictionaryInspector >> selection [

	"override the super implementation so we can create our own derived attribute with a cached printString"

	| selection |
	self hasSingleSelection 
		ifFalse: 
			[self error: #errSingleSelectionRequired << #dialogs 
						>> 'single selection required'].
	selection := self fieldListHolder selections asArray first.
	^self valueOrKeyHolder value = #value 
		ifTrue: [selection]
		ifFalse: 
			[GbxDerivedAttribute 
				label: (#key1s << #dialogs >> 'key <1s>' 
						expandMacrosWith: selection displayString)
				value: selection key
				printString: selection displayString]
]

{ #category : 'accessing' }
GbxTrippyDictionaryInspector >> selections [

	"override the super implementation so we can create our own derived attributes with a cached printString"

	| selections indices list |
	indices := self fieldListHolder selectionIndexes asSortedCollection.
	list := self fieldListHolder list.
	selections := (indices collect: [:each | list at: each]) asArray.
	^self valueOrKeyHolder value = #value 
		ifTrue: [selections]
		ifFalse: 
			[selections collect: 
					[:each | 
					GbxDerivedAttribute 
						label: (#key1s << #dialogs >> 'key <1s>' 
								expandMacrosWith: each displayString)
						value: each key
						printString: each displayString]]
]
