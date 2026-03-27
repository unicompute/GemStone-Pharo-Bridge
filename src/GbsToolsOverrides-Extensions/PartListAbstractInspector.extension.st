Extension { #name : 'PartListAbstractInspector' }

{ #category : '*GbsToolsOverrides-Extensions' }
PartListAbstractInspector >> doItReceiver
[
	"Answer the object that should be informed of the result of evaluating a
	text selection."
	"GBS: doItReceiver will be self more than likely, but if it is a replication wrapper, get the appropriate subObject"

	^self class gbxIsGbsInspector
		ifTrue: [object doItReceiver]
		ifFalse: [object]
]

{ #category : '*GbsToolsOverrides-Extensions' }
PartListAbstractInspector >> computeMultiSelectionText
[
	"Martin wants VW 9.x to preserve the long string truncation that was present in 8.x."

	| stream |
	stream := TextStream on: (String new: 200).
	self selections do:
		[:each |
		stream
			nextPutAllText: each displayString copy asText allBold;
			nextPutAll: ':  ';
			nextPutAllText: each text.
		stream cr].
	^self gbxTrimLongString: stream contents
]

{ #category : '*GbsToolsOverrides-Extensions' }
PartListAbstractInspector >> replaceSelectionsWith: newValue
[
	| selections |
	selections := self selections reject: [:some | some isReadOnly].
	selections isEmpty ifTrue: [^self].
	self
		checkProtectionOf: selections
		ifCancelled: [^self].
	self rememberUndo: (self createReplacementUndo: selections).
	selections
		do:
			[:each | 
			each value: newValue.
			self container partValueChanged: each].
	(self widgetAt: #fieldList) invalidate.
	self documentHolder value: self computeText.
	self gbxUpdateInspectorText
]

{ #category : '*GbsToolsOverrides-Extensions' }
PartListAbstractInspector >> computeSingleSelectionText
[
	"Martin wants VW 9.x to preserve the long string truncation that was present in 8.x."

	^self gbxTrimLongString: self selection text
]

{ #category : '*GbsToolsOverrides-Extensions' }
PartListAbstractInspector >> driverClass
[

	^self isSegmented
		ifTrue: 
			[self class gbxIsGbsInspector
				ifTrue: [GbxSegmentedPageDriver]
				ifFalse: [SegmentedPageDriver]]
		ifFalse: [PageDriver]
]

{ #category : '*GbsToolsOverrides-Extensions' }
PartListAbstractInspector >> accept
[

	self textAcceptAllowed ifFalse: [^self].
	self class gbxIsGbsInspector
		ifTrue: [^self gbxTextAccepted: self documentWidget document asString].
	self documentWidget accept.
	self postAccept
]

{ #category : '*GbsToolsOverrides-Extensions' }
PartListAbstractInspector >> spawn
[

	| obj |
	obj := self hasSingleSelection
				ifTrue: [self selection value]
				ifFalse: 
					[self hasMultiSelection
						ifTrue: [self selections collect: [:each | each value]]
						ifFalse: [self object]].
	InputState default shiftDown
		ifTrue: [obj gbxOldInspect]
		ifFalse: [obj inspect]
]

{ #category : '*GbsToolsOverrides-Extensions' }
PartListAbstractInspector >> addSelectionActionsToFieldMenu: aMenu
[
	"We take some care here to deal with cases, such as bad DerivedFields where, so that we don't fail to construct the menu."
	
	| value |
	[value := Tools.Trippy.Inspector wrappedOrNot: self selection value]
		on: Error
		do: [^self].
	self addObject: value actionsTo: aMenu
]

{ #category : '*GbsToolsOverrides-Extensions' }
PartListAbstractInspector >> buildDiveMenu
[

	| menu submenu included |
	menu := UI.Menu new.
	menu addItem:
		((UI.MenuItem labeled: 'yourself')
			value: [self container diveInto: self selection];
			yourself).
self selectedObjectOrInspectedObject gbxIsProxy ifFalse: [
	included := Set new.
	((self _objectClass: self selectedObjectOrInspectedObject) withAllSuperclasses allButLast: 1) do: [:eachClass |
		submenu := UI.Menu new.
		((eachClass selectors select: [:each | each numArgs = 0])
			reject: [:each | included includes: each])
				asSortedCollection do: [:eachSelector |
			submenu addItem:
				((UI.MenuItem labeled: eachSelector asString)
					value: [self container diveInto:
						(DerivedAttribute label: eachSelector value: 
							(self selectedObjectOrInspectedObject perform: eachSelector))];
					yourself)].
		submenu menuItems isEmpty ifFalse: [
			menu addItem:
				((UI.MenuItem labeled: eachClass name)
					submenu: submenu;
					yourself)]].
].
	^menu
]

