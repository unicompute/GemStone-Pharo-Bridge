Class {
	#name : 'GbxSetInspector',
	#superclass : 'SetInspector',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'private' }
GbxSetInspector >> refresh
[
	"gemstone wants super super behavior"

	| originalSelections |
	linearized := GBSM showBusyWhile: [object refreshSet].
	originalSelections := self selections.
	driver := self driverClass for: self.
	driver refresh.
	self selectAll: originalSelections
]

{ #category : 'actions' }
GbxSetInspector >> removeSelected
[

	self gbxFixMe.	"gemstone undo's not supported yet"
	object delegate remotePerform: #removeAll:
		with: (self selections collect: [:each | each value delegate]).
	self refresh
]

{ #category : 'actions' }
GbxSetInspector >> add
[

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
	self refresh
]

{ #category : 'actions' }
GbxSetInspector >> gbxCacheInterval: anInterval
[
	object cacheSetInterval: anInterval
]

{ #category : 'initialize-release' }
GbxSetInspector >> initialize: anObject
[
	super initialize: anObject.
	linearized := GBSM showBusyWhile: [anObject refreshSet]
]

{ #category : 'testing' }
GbxSetInspector class >> gbxIsGbsInspector
[
	^true
]

{ #category : 'accessing' }
GbxSetInspector class >> tabLabel
[

	^self gbxTabLabel: 'GS Elements'
]

