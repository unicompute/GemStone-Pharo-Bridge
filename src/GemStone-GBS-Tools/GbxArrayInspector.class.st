Class {
	#name : 'GbxArrayInspector',
	#superclass : 'ArrayInspector',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'private' }
GbxArrayInspector >> privateRemoveAtIndices: anIntegerCollection 
	"GBS: remove in reverse order so as not to disturb the indexing"

	anIntegerCollection asSortedCollection 
		reverseDo: [:anIndex | object delegate remotePerform: #removeAtIndex: with: anIndex asGSObject]

{ #category : 'private' }
GbxArrayInspector >> rememberUndo: ignored

	"GemStone undo not supported"

{ #category : 'private' }
GbxArrayInspector >> privateMoveAllAtIndices: aCollection beforeIndex: anIndex
	"Reposition elements at indices listed in aCollection so that they are all 
	located at indices {anIndex, anIndex+1, ...}. The size of the resulting collection 
	is the same as that of the original."

	| insertionPoint delegates |
	aCollection asSortedCollection reverseDo: 
			[:each |
			object delegate remotePerform: #removeAtIndex: with: each asGSObject].
	insertionPoint := anIndex - aCollection size max: 1.
	delegates := aCollection collect: 
					[:each |
					| del |
					del := (object cachedElements at: each) valueDelegate.
					(del isKindOf: GemStone.Gbs.GbxInspectionWrapper)
						ifTrue: [del delegate]
						ifFalse: [del]].
	object delegate
		remotePerform: #addAll:beforeIndex:
		with: delegates
		with: insertionPoint asGSObject.
	^insertionPoint to: insertionPoint + aCollection size - 1

{ #category : 'private' }
GbxArrayInspector >> refresh
	"refresh the remote array values, then refresh the gui"

	object refreshArray.
	super refresh

{ #category : 'private' }
GbxArrayInspector >> pickSingleObjectIn: partCollection ifCancelled: aBlock
	"return the delegate, not the value (which is a wrapper)"

	| labels objects objectsCopy |
	partCollection size = 1 ifTrue: [^partCollection first basicValueDelegate].
	labels := OrderedCollection new.
	objects := OrderedCollection new.
	partCollection do: 
			[:part |
			labels add: ('<1s>: <2s>' expandMacrosWith: part displayString
						with: (self session unsynchronizedEvaluate: 'self printString'
								context: part basicValueDelegate)).
			objects add: part basicValueDelegate].
	objectsCopy := objects copy.
	labels add: (#All1pAsAnArray << #dialogs >> 'All <1p> as an Array'
				expandMacrosWith: partCollection size).
	objects add: (object session evaluate: 'Array withAll: self'
				context: (objectsCopy asGSObjectInSession: self session)).
	labels
		add: (#All1pAsAnOC << #dialogs >> 'All <1p> as an OrderedCollection'
				expandMacrosWith: partCollection size).
	objects add: (object session evaluate: 'OrderedCollection withAll: self'
				context: objectsCopy asGSObject).
	labels add: (#All1pAsASet << #dialogs >> 'All <1p> as a Set'
				expandMacrosWith: partCollection size).
	objects add: (object session evaluate: 'Set withAll: self'
				context: objectsCopy asGSObject).
	^self gbsMessenger
		choose: #UseWhichOfTheseObjectsQ << #dialogs
				>> 'Use which of these objects?'
		fromList: labels
		values: objects
		lines: 8
		cancel: aBlock

{ #category : 'private' }
GbxArrayInspector >> selectIndices: indexCollection 
	| selections |
	selections := indexCollection 
				collect: [:idx | self fieldListHolder list at: idx].
	self selectAll: selections

{ #category : 'decomposing' }
GbxArrayInspector >> partCount
	^object cachedElements size

{ #category : 'actions' }
GbxArrayInspector >> add

	| expression newValue |
	self gbxFixMe.	"gemstone undo's not supported yet"
	expression := self gbsMessenger
				request: 'Add new element (context is inspector''s GemStone delegate):'.
	expression isEmpty ifTrue: [^self].
	newValue := object session
				evaluate: expression
				context: object delegate.
	object delegate
				remotePerform: #add:
				with: newValue.
	object resetObjectSize.
	self
		refresh;
		select: (self partAt: (object delegate performOnGsServer: #size))

{ #category : 'actions' }
GbxArrayInspector >> gbxCacheInterval: anInterval 
	object cacheArrayInterval: anInterval

{ #category : 'actions-drag/drop' }
GbxArrayInspector >> drop: partCollection at: aPart 
	aPart 
		value: (self pickSingleObjectIn: partCollection ifCancelled: [^self]).
	self refresh.
	self select: aPart

{ #category : 'initialize-release' }
GbxArrayInspector >> partAt: anInteger 
	^object cachedElements at: anInteger

{ #category : 'initialize-release' }
GbxArrayInspector >> initialize: anObject
	
	undoHistory := OrderedCollection new.
	object := anObject.
	object refreshArray.
	super refresh.
	self session: anObject delegate noCheckSession.

{ #category : 'testing' }
GbxArrayInspector class >> gbxIsGbsInspector
	^true

{ #category : 'accessing' }
GbxArrayInspector class >> tabLabel

	^self gbxTabLabel: 'GS Elements'

