Class {
	#name : 'GbsMethodQueryResultsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'references',
		'windowTitle',
		'methodsList',
		'sourceText'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsMethodQueryResultsPresenter class >> openOn: aSession references: aCollection title: aString [
	| presenter |
	presenter := self new.
	presenter
		session: aSession;
		references: aCollection;
		windowTitle: aString;
		open.
	^ presenter
]

{ #category : 'accessing' }
GbsMethodQueryResultsPresenter >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbsMethodQueryResultsPresenter >> references: aCollection [
	references := (aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ])
]

{ #category : 'accessing' }
GbsMethodQueryResultsPresenter >> windowTitle: aString [
	windowTitle := (aString ifNil: [ '' ] ifNotNil: [ aString asString ])
]

{ #category : 'initialization' }
GbsMethodQueryResultsPresenter >> initializePresenters [
	references ifNil: [ references := #() ].
	methodsList := self newList.
	methodsList display: [ :each | each asString ].
	sourceText := self newText.
	(sourceText respondsTo: #beNotEditable) ifTrue: [ sourceText beNotEditable ].
]

{ #category : 'initialization' }
GbsMethodQueryResultsPresenter >> connectPresenters [
	references ifNil: [ references := #() ].
	methodsList whenSelectionChangedDo: [ :selection |
		self showSourceForReference: selection selectedItem ].
	methodsList items: references.
	(references notNil and: [ references isEmpty not ]) ifTrue: [
		(methodsList respondsTo: #selectIndex:)
			ifTrue: [ methodsList selectIndex: 1 ]
			ifFalse: [
				(methodsList respondsTo: #selectItem:)
					ifTrue: [ methodsList selectItem: references first ] ].
		self showSourceForReference: references first ]
]

{ #category : 'layout' }
GbsMethodQueryResultsPresenter >> defaultLayout [
	^ SpPanedLayout newTopToBottom
		positionOfSlider: 45 percent;
		add: methodsList;
		add: sourceText;
		yourself
]

{ #category : 'initialization' }
GbsMethodQueryResultsPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: (windowTitle ifNil: [ 'Method Query Results' ] ifNotNil: [ windowTitle ]);
		initialExtent: 980 @ 720
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> showSourceForReference: referenceString [
	| parsed className selector classLookup script source |
	referenceString ifNil: [
		sourceText text: ''.
		^ self ].
	parsed := self parseReference: referenceString asString.
	parsed ifNil: [
		sourceText text: ''.
		^ self ].
	className := parsed first.
	selector := parsed second.
	classLookup := parsed third
		ifTrue: [ '(System myUserProfile symbolList objectNamed: #', className, ') class' ]
		ifFalse: [ 'System myUserProfile symbolList objectNamed: #', className ].
	script := '[
		| cls meth |
		cls := ', classLookup, '.
		cls ifNil: [ ^ '''' ].
		meth := cls compiledMethodAt: #''', (selector copyReplaceAll: '''' with: ''''''), ''' ifAbsent: [ nil ].
		meth ifNil: [ '''' ] ifNotNil: [ meth sourceString ]
	] value'.
	source := [ session executeAndFetch: script context: 20 ] on: Error do: [ '' ].
	sourceText text: (source ifNil: [ '' ] ifNotNil: [ source asString ])
]

{ #category : 'private' }
GbsMethodQueryResultsPresenter >> parseReference: referenceString [
	| split classPart selectorPart classSide className |
	(referenceString includesSubstring: '>>') ifFalse: [ ^ nil ].
	split := referenceString findString: '>>' startingAt: 1.
	classPart := (referenceString copyFrom: 1 to: split - 1) trimBoth.
	selectorPart := (referenceString copyFrom: split + 2 to: referenceString size) trimBoth.
	selectorPart isEmpty ifTrue: [ ^ nil ].
	classSide := classPart endsWith: ' class'.
	className := classSide
		ifTrue: [ classPart copyFrom: 1 to: classPart size - 6 ]
		ifFalse: [ classPart ].
	className isEmpty ifTrue: [ ^ nil ].
	^ { className. selectorPart. classSide }
]
