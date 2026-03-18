Class {
	#name : 'GbxIncrementalSearchModule',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbxIncrementalSearchModule >> session
[

	^session
]

{ #category : 'accessing' }
GbxIncrementalSearchModule >> session: anObject
[

	session := anObject
]

{ #category : 'initialize-release' }
GbxIncrementalSearchModule >> setupDrivers
[
	"This message is sent from the layout after its interface has been built."

	entryModule continuouslyAccept.
	searchDriver := (GbxBackgroundSearchDriver new)
				patternHolder: entryModule entryHolder
					searchBlock: searchBlock
					resultHolder: [:results | self acceptSearchResults: results];
				session: session.
	" Disabled for now, to avoid flashing. Need to do something about it.
	searchDriver
		when: #searching send: #searchStarted to: self;
		when: #stopped send: #searchFinished to: self.
"
	guessDriver := (CompletionDriver new)
				beCaseInsensitive;
				beNotAuto;
				widget: entryModule entryWidget;
				choicesHolder: [self currentStrings]
]

{ #category : 'instance creation-predefined' }
GbxIncrementalSearchModule class >> forGemStoneClassSelection: aString browser: browser
[
	"Change to get a 5 element Array back from the search: class name, class, dictionary name, dictionary, display string.
	 The display string includes the symbol dictionary name for disambiguating 'duplicate' class names."

	| instance |
	instance := self new.
	instance
		firstLabel: aString;
		secondLabel: #ClassesC << #labels >> 'GemStone Classes:';
		searchBlock: 
				[:string |
				string isEmpty
					ifTrue: [Array new]
					ifFalse: [browser findMatchingClasses: string]];
		objectToStringBlock: [:classSearchResultHolder | classSearchResultHolder displayString];
		displayStringSelector: #displayString;
		iconSelector: #toolListIcon.
	^instance
]

