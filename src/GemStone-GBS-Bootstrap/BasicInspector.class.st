Class {
	#name : 'BasicInspector',
	#superclass : 'Object',
	#instVars : [
		'object',
		'fixedFields',
		'undoHistory',
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'testing' }
BasicInspector >> gbxIsGbsInspector
[
	"VisualWorks compatibility stub"
	^true
]

{ #category : 'accessing' }
BasicInspector >> tabLabel
[
	"VisualWorks compatibility stub"
	^'Inspector'
]

{ #category : 'accessing' }
BasicInspector >> addAddAndRemoveItemsTo: aMenu
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
BasicInspector >> createInsertionUndo: anObject before: index
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
BasicInspector >> derivedFields
[
	"VisualWorks compatibility stub"
	^#()
]

{ #category : 'accessing' }
BasicInspector >> dynamicInstVarFields
[
	"VisualWorks compatibility stub"
	^#()
]

{ #category : 'accessing' }
BasicInspector >> gbxCacheInterval: anInteger
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
BasicInspector >> gbxCachedRanges
[
	"VisualWorks compatibility stub"
	^#()
]

{ #category : 'accessing' }
BasicInspector >> initialize: anObject
[
	object := anObject.
	fixedFields := Array new.
	undoHistory := OrderedCollection new
]

{ #category : 'accessing' }
BasicInspector >> namedFields
[
	"VisualWorks compatibility stub"
	^#()
]

{ #category : 'accessing' }
BasicInspector >> partAt: index
[
	"VisualWorks compatibility stub"
	^nil
]

{ #category : 'accessing' }
BasicInspector >> partCount
[
	"VisualWorks compatibility stub"
	^0
]

{ #category : 'accessing' }
BasicInspector >> refresh
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
BasicInspector >> object
[
	^object
]

{ #category : 'accessing' }
BasicInspector >> object: anObject
[
	object := anObject
]

{ #category : 'accessing' }
BasicInspector >> protectedVariableNames
[
	^#()
]

{ #category : 'accessing' }
BasicInspector >> refreshSelfAttribute
[
	"VisualWorks compatibility stub"
]

{ #category : 'accessing' }
BasicInspector >> remotePrintStringFor: anObject
[
	"VisualWorks compatibility stub"
	^''
]

{ #category : 'accessing' }
BasicInspector >> selfAttribute
[
	"VisualWorks compatibility stub"
	^nil
]

{ #category : 'accessing' }
BasicInspector >> session
[
	^session
]

{ #category : 'accessing' }
BasicInspector >> session: anObject
[
	session := anObject
]
