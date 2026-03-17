Class {
	#name : 'GbxTextEditorInspector',
	#superclass : 'TextEditorInspector',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbxTextEditorInspector >> documentHolder
	"vw8x support"

	^textHolder

{ #category : 'actions' }
GbxTextEditorInspector >> refresh
	self textHolder value: object refreshText

{ #category : 'actions' }
GbxTextEditorInspector >> textAccepted: aController

	| newDelegate |
	newDelegate := self session
				executeBlock: '[:obj :string |
					obj class withAll: string]'
				withArguments: (Array with: self object delegate
						with: aController text asString)
				context: nil.	"server text editor pane only up for CharacterCollection subclasses"
	self session
		executeBlock: '[:new :old |
		old become: new]'
		withArguments: (Array with: self object delegate with: newDelegate)
		context: nil.
	self object delegate become: newDelegate.
	self container visit object: newDelegate owner: self container visit.
	container isNil
		ifTrue: 
			[self container navigator updateShellsInspectedObject	"get default container"]
		ifFalse: [container updateShellsInspectedObject]

{ #category : 'initialize-release' }
GbxTextEditorInspector >> initialize: anObject
	
	self session: anObject delegate noCheckSession.
	super initialize: anObject

{ #category : 'testing' }
GbxTextEditorInspector class >> gbxIsGbsInspector
	^true

{ #category : 'accessing' }
GbxTextEditorInspector class >> tabLabel

	^self gbxTabLabel: 'GS Text'

