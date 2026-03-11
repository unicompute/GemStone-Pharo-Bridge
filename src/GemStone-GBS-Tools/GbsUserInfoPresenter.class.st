Class {
	#name : 'GbsUserInfoPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'userName',
		'infoText',
		'mainMenu',
		'textPresenter',
		'closeButton'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsUserInfoPresenter class >> openForUser: aUserName text: aString [
	| presenter |
	presenter := self new.
	presenter
		userName: aUserName;
		infoText: aString;
		open.
	^ presenter
]

{ #category : 'accessing' }
GbsUserInfoPresenter >> userName: aString [
	userName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsUserInfoPresenter >> infoText: aString [
	infoText := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'initialization' }
GbsUserInfoPresenter >> initializePresenters [
	mainMenu := self buildMenuBar.
	textPresenter := self newText.
	(textPresenter respondsTo: #beNotEditable) ifTrue: [ textPresenter beNotEditable ].
	closeButton := self newButton
		label: 'Close';
		icon: (self iconNamed: #smallCancel);
		action: [ self closeWindow ];
		yourself
]

{ #category : 'initialization' }
GbsUserInfoPresenter >> connectPresenters [
	(textPresenter respondsTo: #text:) ifTrue: [ textPresenter text: infoText ]
]

{ #category : 'layout' }
GbsUserInfoPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: mainMenu expand: false;
		add: textPresenter;
		add: (SpBoxLayout newLeftToRight
			add: (self newLabel label: '');
			add: closeButton expand: false;
			yourself) expand: false;
		spacing: 8;
		yourself
]

{ #category : 'initialization' }
GbsUserInfoPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone User Info - ', userName;
		initialExtent: 620 @ 420
]

{ #category : 'menus' }
GbsUserInfoPresenter >> buildMenuBar [
	^ self newMenuBar
		addGroup: [ :group |
			group
				addItem: [ :item | item name: 'File'; subMenu: self menuFile ];
				addItem: [ :item | item name: 'Help'; subMenu: self menuHelp ] ];
		yourself
]

{ #category : 'menus' }
GbsUserInfoPresenter >> menuFile [
	^ self newMenu
		addItem: [ :item | item name: 'Copy'; action: [ Clipboard clipboardText: infoText ] ];
		addItem: [ :item | item name: 'Close'; action: [ self closeWindow ] ];
		yourself
]

{ #category : 'menus' }
GbsUserInfoPresenter >> menuHelp [
	^ self newMenu
		addItem: [ :item | item name: 'About User Info'; action: [ UIManager default inform: 'GemStone User Info' ] ];
		yourself
]

{ #category : 'actions' }
GbsUserInfoPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]
