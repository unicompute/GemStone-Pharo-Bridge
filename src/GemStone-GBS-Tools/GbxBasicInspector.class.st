Class {
	#name : 'GbxBasicInspector',
	#superclass : 'BasicInspector',
	#instVars : [
		'selfAttribute',
		'namedFields'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'menu management' }
GbxBasicInspector >> addAddAndRemoveItemsTo: aMenu 
[
	"Not supported for GemStone server classes"
]

{ #category : 'accessing' }
GbxBasicInspector >> selfAttribute
[

	selfAttribute isNil
		ifTrue: 
			[selfAttribute := GbxDerivedAttribute
						label: 'self'
						value: self object delegate
						printString: (self remotePrintStringFor: self object delegate)].
	^selfAttribute
]

{ #category : 'accessing' }
GbxBasicInspector >> gbxCachedRanges
[
	"return our collection of interval indices which were cached"

	^self object basicCache cachedRanges
]

{ #category : 'accessing' }
GbxBasicInspector >> dynamicInstVarFields
[

	
	[| dynamicInstVars |
	dynamicInstVars := OrderedCollection new.
	self object delegate session
		sessionCritical: 
			[(self object delegate
				unsynchronizedPerformOnGsServer: #dynamicInstanceVariables) do: 
						[:varName |
						| attr instVarDelegate |
						attr := GbxDynamicInstVarAttribute
									label: #varName << #gbs >> ('dynamic: ' , varName asString)
									value: (instVarDelegate := self object delegate session
													unsynchronizedExecuteBlock: '[:obj :var | obj dynamicInstVarAt: var]'
													withArguments: (Array with: self object delegate with: varName)
													context: nil)
									printString: (self remotePrintStringFor: instVarDelegate)
									object: self object.
						dynamicInstVars add: attr]]
		unlessBlocked: [^OrderedCollection new]
		retryFor: 500.
	^dynamicInstVars asArray]
			on: MessageNotUnderstood
			do: [:ex | ^Array with: 'error getting dynamic inst vars']
]

{ #category : 'accessing' }
GbxBasicInspector >> remotePrintStringFor: delegate
[

	^self object session
		unsynchronizedEvaluate: '
										 | gbxWriteStream gbxObject gbxClass |
										gbxObject := self. '
				, GbxInspectionWrapperWithSession enhancedRemotePrintString
					, '
										gbxWriteStream contents'
		context: delegate
]

{ #category : 'private' }
GbxBasicInspector >> refreshSelfAttribute
[
	selfAttribute := nil.
	self selfAttribute
]

{ #category : 'private' }
GbxBasicInspector >> derivedFields
[

	^
	[self object remoteClassName = 'GsNMethod'
		ifTrue: 
			[Array with: (GbxDerivedAttribute
						label: #sourceCode << #gbs >> 'sourceCode'
						valueBlock: [(self object delegate performOnGsServer: #sourceString) copy])]
		ifFalse: [object inspectorClientExtraAttributes]]
			on: MessageNotUnderstood
			do: [:ex | ex return: Array new]
]

{ #category : 'private' }
GbxBasicInspector >> createInsertionUndo: partCollection before: anIndex 
[
	"undos not implemented in GemStone inspectors yet"

	self gbxFixMe
]

{ #category : 'private' }
GbxBasicInspector >> namedFields
[
	namedFields isNil ifTrue:[
		namedFields := self object basicNamedVariablesProtectedBy: self protectedVariableNames].
	^namedFields
]

{ #category : 'private' }
GbxBasicInspector >> refresh
[
	self refreshSelfAttribute.
	object basicCache ifNotNil: [object refreshBasicArray].
	namedFields := nil. 
	fixedFields := nil.
	super refresh.
]

{ #category : 'actions' }
GbxBasicInspector >> gbxCacheInterval: anInterval 
[
	"adjust for the fixed fields in the basic display"

	self object basicCache cacheArrayInterval: (anInterval 
				setFrom: anInterval first - fixedFields size
				to: anInterval last - fixedFields size
				by: anInterval increment)
]

{ #category : 'initialize-release' }
GbxBasicInspector >> initialize: anObject
[
	
	object := anObject.
	self object basicCache: (GbxBasicCacheTool on: self object delegate).
	self refresh.
	undoHistory := OrderedCollection new.
	self session: anObject delegate noCheckSession
]

{ #category : 'decomposing' }
GbxBasicInspector >> partCount
[
	^fixedFields size + self object basicCache elements size
]

{ #category : 'decomposing' }
GbxBasicInspector >> partAt: anInteger 
[
	anInteger <= fixedFields size ifTrue: [^fixedFields at: anInteger].
	^self object basicCache elements at: anInteger - fixedFields size
]

{ #category : 'testing' }
GbxBasicInspector class >> gbxIsGbsInspector
[
	^true
]

{ #category : 'private - inspecting' }
GbxBasicInspector class >> tabLabel
[

	^self gbxTabLabel: 'GS Basic'
]
