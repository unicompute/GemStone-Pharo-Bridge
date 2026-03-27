Extension { #name : 'ContextListPolicy' }

{ #category : '*GbsToolsOverrides-Extensions' }
ContextListPolicy >> filterStack
[
	"Update filteredStack atomically to prevent race condition; bug 48047"

	| filteredStackHolder |
	filteredStackHolder := OrderedCollection new.
	patterns isEmpty
		ifTrue:
			[1 to: stack size do: 
				[:i | filteredStackHolder add: (Array with: (stack at: i) printString with: i with: nil).].
			^filteredStack := filteredStackHolder].
	1 to: stack size do:
		[:i | | context componentString match id |
		context := stack at: i.
		componentString := self componentStringFor: context method homeMethod.
		context isBlockContext ifTrue:
			[componentString := '$B$', componentString].
		match := patterns detect: [:pat | pat pattern perform: matchSymbol with: componentString] ifNone: [nil].
		id := match notNil
			ifTrue: [match name]
			ifFalse: [nil].
		(id notNil or: [i <= displayAllLimit])
			ifTrue: [filteredStackHolder add: (Array with: context printString with: i with: id)]].
	^filteredStack := filteredStackHolder
]

