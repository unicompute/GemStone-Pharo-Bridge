Extension { #name : 'Menu' }

{ #category : '*GbsToolsOverrides-Extensions' }
Menu >> addItemLabel: aString value: aValueModel
[
	"Add a new MenuItem with the given string as its label (see MenuItem labeled:).  The new menu item will become part of the last group of menu items."
	"overriden by GBS - provide a default nameKey for later item identifcation"

	| item | 
	self addItem: (item := MenuItem labeled: aString) value: aValueModel.
	aString isString
		ifTrue: [item nameKey: (aString copyWithout: $&) asSymbol]
]

