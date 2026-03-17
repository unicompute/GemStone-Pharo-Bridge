Class {
	#name : #'GbxAddClassDialog',
	#superclass : #'GbxApplicationModel',
	#instVars : [ #'newClassName' #'superClassName' #'newInstVars' #'newClassVars' #'dictionary' #'modifiable' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Tools'
}

{ #category : #'initialize - release' }
GbxAddClassDialog >> setupEventHandlingUsing: bldr

	| superWidget newWidget |
	superWidget := (bldr componentAt: #SuperClassInputField) widget.
	superWidget when: #clicked
		do: [self resetColor: superWidget for: superClassName].
	superWidget when: #tabbed
		do: [self resetColor: superWidget for: superClassName].
	newWidget := (bldr componentAt: #NewClassInputField) widget.
	newWidget when: #clicked do: [self resetColor: newWidget for: newClassName].
	newWidget when: #tabbed do: [self resetColor: newWidget for: newClassName]

{ #category : #'initialize - release' }
GbxAddClassDialog >> initialize

	newClassName := ValueHolder with: String new.
	superClassName := ValueHolder with: String new.
	newInstVars := ValueHolder with: String new.
	newClassVars := ValueHolder with: String new.
	modifiable := false asValue

{ #category : #'accessing' }
GbxAddClassDialog >> dictionary

	^dictionary

{ #category : #'accessing' }
GbxAddClassDialog >> modifiable

	^modifiable

{ #category : #'accessing' }
GbxAddClassDialog >> modifiable: anObject

	modifiable := anObject

{ #category : #'accessing' }
GbxAddClassDialog >> titleString
	"Unused since this is only used as a dialog"

	^'Add Server Class'

{ #category : #'accessing' }
GbxAddClassDialog >> newClassName

	^newClassName

{ #category : #'accessing' }
GbxAddClassDialog >> newClassName: anObject

	newClassName := anObject

{ #category : #'accessing' }
GbxAddClassDialog >> newClassVars

	^newClassVars

{ #category : #'accessing' }
GbxAddClassDialog >> newClassVars: anObject

	newClassVars := anObject

{ #category : #'accessing' }
GbxAddClassDialog >> newInstVars

	^newInstVars

{ #category : #'accessing' }
GbxAddClassDialog >> dictionary: anObject

	dictionary := anObject

{ #category : #'accessing' }
GbxAddClassDialog >> newInstVars: anObject

	newInstVars := anObject

{ #category : #'accessing' }
GbxAddClassDialog >> superClassName

	^superClassName

{ #category : #'accessing' }
GbxAddClassDialog >> superClassName: anObject

	superClassName := anObject

{ #category : #'actions' }
GbxAddClassDialog >> subclassCreation64BitServer

	^self session
		execute: superClassName value asString , ' subclass: '''
				, newClassName value asString , '''
		 instVarNames: #( '
				, newInstVars value , ' ) 
		 classVars: #( '
				, newClassVars value
					, ' ) 
		 classInstVars: #() 
		 poolDictionaries: #()
		 inDictionary: self
		 newVersionOf: (Object _classNamed: '''
					, newClassName value
					, ''' inDictionary: self)
		 description: nil
		 options: '
					, self modifiableString
		context: dictionary

{ #category : #'actions' }
GbxAddClassDialog >> acceptClass

	[self subclassCreation64BitServer]
		on: Error
		do: 
			[:ex |
			ex pass.
			self closeRequest.
			^nil]

{ #category : #'private' }
GbxAddClassDialog >> blankClassWarning

	^(Text fromString: 'Cannot be blank')
		emphasizeAllWith: (Array with: #color -> ColorValue red)

{ #category : #'private' }
GbxAddClassDialog >> verifySuperclass

	^self session
		evaluate: '(GsCurrentSession currentSession resolveSymbol: self asSymbol) notNil'
		context: superClassName value asString

{ #category : #'private' }
GbxAddClassDialog >> resolveDictionaryNamed: dictionaryName
	
	^session
		execute: '(System myUserProfile symbolList resolveSymbol: '
				, dictionaryName printString , ') value'

{ #category : #'private' }
GbxAddClassDialog >> resetColor: widget for: model

	model value: (widget displayContents text
				emphasizeAllWith: (Array with: #color -> ColorValue black)).
	widget invalidateNow

{ #category : #'private' }
GbxAddClassDialog >> modifiableString

	^modifiable value ifTrue: ['#(#modifiable)'] ifFalse: ['#()']

{ #category : #'private' }
GbxAddClassDialog >> invalidSuperclassWarning

	| token text |
	token := '<<< not a Behavior'.
	text := superClassName value.
	('*' , token match: superClassName value)
		ifTrue: 
			[^text
				emphasizeFrom: text size - 18
				to: text size
				with: (Array with: #color -> ColorValue red)].
	^superClassName value asText
		, (token asText emphasizeAllWith: (Array with: #color -> ColorValue red))

{ #category : #'interface specs' }
GbxAddClassDialog class >> windowSpec
	"Tools.UIPainter new openOnClass: self andSelector: #windowSpec"

	<resource: #canvas>
	^#(#{UI.FullSpec} 
		#window: 
		#(#{UI.WindowSpec} 
			#label: 'Add GemStone Class' 
			#bounds: #(#{Graphics.Rectangle} 669 386 1012 664 ) ) 
		#component: 
		#(#{UI.SpecCollection} 
			#collection: #(
				#(#{UI.LabelSpec} 
					#layout: #(#{UI.AlignmentOrigin} -10 0.4 0 0.15 1 0.5 ) 
					#name: #Label1 
					#label: 'New Class:' ) 
				#(#{UI.InputFieldSpec} 
					#layout: #(#{Graphics.LayoutFrame} 2 0.4 -15 0.15 -10 1 15 0.15 ) 
					#name: #NewClassInputField 
					#model: #newClassName 
					#type: #text ) 
				#(#{UI.LabelSpec} 
					#layout: #(#{UI.AlignmentOrigin} -10 0.4 0 0.3 1 0.5 ) 
					#name: #Label2 
					#label: 'Superclass:' ) 
				#(#{UI.InputFieldSpec} 
					#layout: #(#{Graphics.LayoutFrame} 2 0.4 -15 0.3 -10 1 15 0.3 ) 
					#name: #SuperClassInputField 
					#model: #superClassName 
					#type: #text ) 
				#(#{UI.LabelSpec} 
					#layout: #(#{UI.AlignmentOrigin} -10 0.4 0 0.45 1 0.5 ) 
					#name: #Label3 
					#label: 'Instance Variables:' ) 
				#(#{UI.InputFieldSpec} 
					#layout: #(#{Graphics.LayoutFrame} 2 0.4 -15 0.45 -10 1 15 0.45 ) 
					#name: #InputField3 
					#model: #newInstVars ) 
				#(#{UI.LabelSpec} 
					#layout: #(#{UI.AlignmentOrigin} -10 0.4 0 0.6 1 0.5 ) 
					#name: #Label4 
					#label: 'Class Variables:' ) 
				#(#{UI.InputFieldSpec} 
					#layout: #(#{Graphics.LayoutFrame} 2 0.4 -15 0.6 -10 1 15 0.6 ) 
					#name: #InputField4 
					#model: #newClassVars ) 
				#(#{UI.ActionButtonSpec} 
					#layout: #(#{Graphics.LayoutFrame} -40 0.333333 -15 0.9 40 0.333333 15 0.9 ) 
					#name: #ActionButton1 
					#model: #accept 
					#label: 'Accept' 
					#isDefault: true 
					#defaultable: true ) 
				#(#{UI.ActionButtonSpec} 
					#layout: #(#{Graphics.LayoutFrame} -40 0.666666 -15 0.9 40 0.666666 15 0.9 ) 
					#name: #ActionButton2 
					#model: #cancel 
					#label: 'Cancel' 
					#defaultable: true ) 
				#(#{UI.CheckBoxSpec} 
					#layout: #(#{UI.AlignmentOrigin} 2 0.4 0 0.75 0 0.5 ) 
					#name: #ModifiableCheckBox 
					#model: #modifiable 
					#label: 'Modifiable' ) ) ) )

{ #category : #'accessing' }
GbxAddClassDialog class >> brainClass
	"This dialog is brainless."
	
	^self shouldNotImplement

{ #category : #'instance creation' }
GbxAddClassDialog class >> on: aSession dictionary: aDelegate superClass: superclassName className: className

	| inst result dialog |
	inst := (self new)
				session: aSession;
				dictionary: aDelegate.
	inst superClassName value: superclassName asText.
	inst newClassName value: className asText.
	dialog := SimpleDialog new.
	dialog postOpenBlock: [:dlg :bldr | inst setupEventHandlingUsing: bldr].
	result := dialog openFor: inst interface: #windowSpec.
	^result
		ifTrue: 
			[inst newClassName value trimBlanks isEmpty
				ifTrue: 
					[^self
						on: aSession
						dictionary: aDelegate
						superClass: superclassName
						className: inst blankClassWarning].
			inst verifySuperclass
				ifFalse: 
					[^self
						on: aSession
						dictionary: aDelegate
						superClass: inst invalidSuperclassWarning
						className: inst newClassName value].
			inst acceptClass.
			inst newClassName value]
		ifFalse: [nil]

