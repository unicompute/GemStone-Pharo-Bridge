Extension { #name : 'AbstractChangeList' }

{ #category : '*GbsToolsOverrides-Extensions' }
AbstractChangeList >> textMenu
[
	"Answer a minimal Menu for the text pane."

	| menu |
	menu := menus at: #textMenu ifAbsentPut: [self buildTextMenu].
	Menu gbxAdjustForGSItemsFor: menu.
	^menu
]

