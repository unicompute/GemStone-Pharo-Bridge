Class {
	#name : 'GbsUserInfoPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'userName',
		'infoText',
		'session',
		'privilegesEditorBlock',
		'mainMenu',
		'textPresenter',
		'closeButton',
		'privilegesButton'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsUserInfoPresenter class >> openForUser: aUserName text: aString [
	^ self openForUser: aUserName text: aString session: nil
]

{ #category : 'instance creation' }
GbsUserInfoPresenter class >> openForUser: aUserName text: aString session: aSession [
	| presenter |
	presenter := self new.
	presenter
		userName: aUserName;
		infoText: aString;
		session: aSession;
		open.
	(presenter respondsTo: #refreshInfoText) ifTrue: [ presenter refreshInfoText ].
	^ presenter
]

{ #category : 'initialization' }
GbsUserInfoPresenter >> initialize [
	super initialize.
	userName := ''.
	infoText := ''
]

{ #category : 'accessing' }
GbsUserInfoPresenter >> userName: aString [
	userName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsUserInfoPresenter >> infoText: aString [
	infoText := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsUserInfoPresenter >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
GbsUserInfoPresenter >> privilegesEditorBlock: aBlock [
	privilegesEditorBlock := aBlock
]

{ #category : 'initialization' }
GbsUserInfoPresenter >> initializePresenters [
	mainMenu := self buildMenuBar.
	textPresenter := self newList.
	self updateInfoDisplay.
	privilegesButton := self newButton
		label: 'Privileges...';
		action: [ self editPrivileges ];
		yourself.
	closeButton := self newButton
		label: 'Close';
		icon: (self iconNamed: #smallCancel);
		action: [ self closeWindow ];
		yourself
]

{ #category : 'initialization' }
GbsUserInfoPresenter >> connectPresenters [
	self updateInfoDisplay
]

{ #category : 'layout' }
GbsUserInfoPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: mainMenu expand: false;
		add: textPresenter;
		add: (SpBoxLayout newLeftToRight
			add: (self newLabel label: '');
			add: privilegesButton expand: false;
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
				addItem: [ :item | item name: 'User'; subMenu: self menuUser ];
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

{ #category : 'menus' }
GbsUserInfoPresenter >> menuUser [
	^ self newMenu
		addItem: [ :item | item name: 'Privileges...'; action: [ self editPrivileges ] ];
		addItem: [ :item | item name: 'Refresh'; action: [ self refreshInfoText ] ];
		yourself
]

{ #category : 'actions' }
GbsUserInfoPresenter >> editPrivileges [
	| creator currentPrivileges groups |
	session ifNil: [ ^ self ].
	creator := GbsCreateUserPresenter new.
	creator session: session.
	currentPrivileges := creator fetchPrivilegesForUser: userName.
	groups := self fetchGroupsForUser: userName.
	[
		self
			openPrivilegesEditorForUser: userName
			initialPrivileges: currentPrivileges
			onAccept: [ :updated |
				| script |
				script := creator
					scriptToSaveUser: userName
					password: ''
					groups: groups
					privileges: updated.
				session execute: script.
				self refreshInfoText ]
	] on: Error do: [ :ex |
		UIManager default inform: 'Could not open privileges window: ', ex messageText ]
]

{ #category : 'private' }
GbsUserInfoPresenter >> openPrivilegesEditorForUser: aUserName initialPrivileges: privilegeMap onAccept: acceptBlock [
	privilegesEditorBlock ifNotNil: [
		^ privilegesEditorBlock
			value: aUserName
			value: privilegeMap
			value: acceptBlock ].
	^ GbsUserPrivilegesPresenter
		openForUser: aUserName
		initialPrivileges: privilegeMap
		onAccept: acceptBlock
]

{ #category : 'private' }
GbsUserInfoPresenter >> fetchGroupsForUser: aUserName [
	| script raw |
	session ifNil: [ ^ #() ].
	script := '
	| users user names |
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ ^ '''' ].
	user := users detect: [ :u | u userId asString = ''', aUserName, ''' ] ifNone: [ nil ].
	user ifNil: [ ^ '''' ].
	names := (user respondsTo: #groups)
		ifTrue: [ user groups collect: [ :g | (g respondsTo: #name) ifTrue: [ g name asString ] ifFalse: [ g asString ] ] ]
		ifFalse: [ #() ].
	String streamContents: [ :s |
		names asSortedCollection
			do: [ :n | s nextPutAll: n asString ]
			separatedBy: [ s nextPut: $, ] ]'.
	raw := [ session evaluate: script ] on: Error do: [ '' ].
	(raw isString and: [ raw isNotEmpty ])
		ifTrue: [ ^ (raw splitOn: $,) reject: [ :each | each isEmpty ] ].
	^ #()
]

{ #category : 'actions' }
GbsUserInfoPresenter >> refreshInfoText [
	| script raw |
	session ifNil: [ ^ self ].
	script := '
	| users user strm |
	strm := WriteStream on: String new.
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNotNil: [
		user := users detect: [ :u | u userId asString = ''', userName, ''' ] ifNone: [ nil ].
		user ifNotNil: [
			strm
				nextPutAll: ''User: ''; nextPutAll: user userId asString; cr;
				nextPutAll: ''Class: ''; nextPutAll: user class name asString; cr.
			(user respondsTo: #groups) ifTrue: [
				| names |
				names := user groups collect: [ :g | (g respondsTo: #name) ifTrue: [ g name asString ] ifFalse: [ g asString ] ].
				strm nextPutAll: ''Groups: ''.
				names asSortedCollection
					do: [ :n | strm nextPutAll: n asString ]
					separatedBy: [ strm nextPutAll: '', '' ].
				strm cr ] ] ].
	strm contents'.
	raw := [ session evaluate: script ] on: Error do: [ infoText ].
	infoText := raw ifNil: [ infoText ] ifNotNil: [ raw asString ].
	infoText := infoText, self privilegeSummaryText.
	self updateInfoDisplay
]

{ #category : 'private' }
GbsUserInfoPresenter >> privilegeSummaryText [
	| creator map enabled |
	session ifNil: [ ^ '' ].
	creator := GbsCreateUserPresenter new.
	creator session: session.
	map := [ creator fetchPrivilegesForUser: userName ] on: Error do: [ Dictionary new ].
	enabled := ((map associations
		select: [ :assoc | assoc value == true ])
		collect: [ :assoc | assoc key asString ]) asSortedCollection.
	enabled isEmpty ifTrue: [ ^ String cr, 'Privileges: <none>' ].
	^ String cr, 'Privileges: ', (String streamContents: [ :s |
		enabled
			do: [ :each | s nextPutAll: each ]
			separatedBy: [ s nextPutAll: ', ' ] ])
]

{ #category : 'private' }
GbsUserInfoPresenter >> displayLinesFromInfoText [
	| text |
	text := infoText ifNil: [ '' ] ifNotNil: [ infoText asString ].
	text isEmpty ifTrue: [ ^ #() ].
	^ text lines
]

{ #category : 'private' }
GbsUserInfoPresenter >> updateInfoDisplay [
	textPresenter ifNil: [ ^ self ].
	(textPresenter respondsTo: #text:)
		ifTrue: [ textPresenter text: (infoText ifNil: [ '' ] ifNotNil: [ infoText asString ]) ].
	(textPresenter respondsTo: #items:)
		ifTrue: [ textPresenter items: self displayLinesFromInfoText ]
]

{ #category : 'actions' }
GbsUserInfoPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]
