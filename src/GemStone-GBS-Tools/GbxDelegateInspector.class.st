Class {
	#name : 'GbxDelegateInspector',
	#superclass : 'GbxBasicInspector',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'initialize-release' }
GbxDelegateInspector >> initialize: anObject
	
	object := anObject.
	self refresh.
	undoHistory := OrderedCollection new.
	self session: anObject delegate noCheckSession

{ #category : 'accessing' }
GbxDelegateInspector >> object
	^object delegate

{ #category : 'decomposing' }
GbxDelegateInspector >> partCount
	^fixedFields size

{ #category : 'private - inspecting' }
GbxDelegateInspector >> derivedFields
	^[object delegateInspectorExtraAttributes] 
		on: MessageNotUnderstood
		do: [:ex | ex return: Array new]

{ #category : 'private - inspecting' }
GbxDelegateInspector >> selfAttribute
	^GbxDerivedAttribute 
		label: 'self'
		value: object delegate
		printString: object delegatePrintString

{ #category : 'private' }
GbxDelegateInspector >> doItReceiver
	"Answer the object that should be informed of the result of evaluating a
	text selection."

	"GBS: the local object which represents our self context should be the delegate on the GS Delegate tab."

	^object delegate

{ #category : 'private' }
GbxDelegateInspector >> namedFields
	| protected |
	protected := self protectedVariableNames.
	^self object class allInstVarNames collect: 
			[:each | 
			| part |
			part := Tools.Trippy.NamedVariable of: self object named: each.
			(protected includes: each) ifTrue: [part beProtected].
			part]

{ #category : 'private' }
GbxDelegateInspector class >> tabLabel

	^self gbxTabLabel: 'GS Delegate'

