Extension { #name : 'Navigator' }

{ #category : '*GbsTrippy-Extensions' }
Navigator >> gbxCreateInspectorForObjectAt: index
[
	| inspectorClass object obj |
	obj := visit object isNil 
				ifTrue: [Tools.Trippy.Inspector wrappedOrNot: inspector object]
				ifFalse: [Tools.Trippy.Inspector wrappedOrNot: visit object].
	inspectorClass := inspectorClasses at: index.
	object := obj inspectableObjectFor: inspectorClass.
	^inspectorCache at: index put: (inspectorClass on: object)
]

{ #category : '*GbsTrippy-Extensions' }
Navigator >> nilInitialInspector
[
	"Note: this instance variable appears undefined when the overrides have been removed in preparation for publishing."

	initialInspectorClass := nil
]

{ #category : '*GbsTrippy-Extensions' }
Navigator >> gbxShell
[
	^shell
]

{ #category : '*GbsTrippy-Extensions' }
Navigator >> gbxHasNonGemStoneTabs
[

	^((inspectorClasses copyWithout: WatchLogInspector)
		detect: [:ea | ea gbxIsGbsInspector not]
		ifNone: []) notNil
]

{ #category : '*GbsTrippy-Extensions' }
Navigator >> gbxHasShell
[

	^shell notNil
]

{ #category : '*GbsTrippy-Extensions' }
Navigator >> gbxHasGemStoneTabs
[

	^(inspectorClasses detect: [:ea | ea == GemStone.Gbs.GbxDelegateInspector] ifNone: []) notNil
]

{ #category : '*GbsTrippy-Extensions' }
Navigator >> refreshLocalInspectorClasses
[
	"don't try to do anything gemstoney"

	| selectionIndex |
	self ignoringInspectorSelectionChange: 
			[inspectorClasses := self objectLocalInspectorClasses.
			self inspectorHolder 
				list: (inspectorClasses 
						collect: [:each | each tabLabel asString copyWithout: $&]) asList.
			selectionIndex := inspectorClasses indexOf: inspector class.
			self inspectorHolder selectionIndex: selectionIndex.
			inspectorCache := Array new: inspectorClasses size.
			inspectorCache at: selectionIndex put: inspector]
]

{ #category : '*GbsTrippy-Extensions' }
Navigator >> objectLocalInspectorClasses
[
	"just get the local classes"

	^Inspector cautiousInspectorClassesFor: self object
]

{ #category : '*GbsTrippy-Extensions' }
Navigator >> refresh
[
	inspectorCache do: [:each | each ifNotNil: [each refresh]]
]

{ #category : '*GbsTrippy-Extensions' }
Navigator >> updateShellsInspectedObject
[
	"need an accessor in case we change the object internally"

	shell inspectedObjectChanged
]

{ #category : '*GbsTrippy-Extensions' }
Navigator >> gbxDoItAgent
[
	
	^inspector gbxDoItAgent
		ifNil: [super gbxDoItAgent]
		ifNotNil: [:obj | obj]
]

