Class {
	#name : 'GbsUserListPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'mainMenu',
		'userList',
		'session',
		'groupList',
		'userNameField',
		'createUserButton',
		'showUserInfoButton',
		'deleteUserButton',
		'closeButton'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsUserListPresenter class >> openOn: aSession [
	| presenter |
	aSession ifNil: [ ^ self inform: 'No connected GemStone session. Please login first.' ].
	(aSession respondsTo: #isLoggedIn)
		ifTrue: [ ([ aSession isLoggedIn == true ] on: Error do: [ false ])
			ifFalse: [ ^ self inform: 'No connected GemStone session. Please login first.' ] ].
	presenter := self new.
	presenter session: aSession.
	presenter open.
	^ presenter
]

{ #category : 'layout' }
GbsUserListPresenter >> connectPresenters [
	userList whenSelectionChangedDo: [ :selection |
		selection selectedItem
			ifNotNil: [ :userName | self fetchGroupsFor: userName. self updateActionButtons ]
			ifNil: [ groupList items: #(  ). userNameField text: ''. self updateActionButtons ]
	].

	createUserButton action: [ self openCreateUserDialog ].
	showUserInfoButton action: [ self showSelectedUserInfo ].
	deleteUserButton action: [ self deleteSelectedUser ].
	closeButton action: [ self closeWindow ].

	session ifNil: [ session := GbsSessionParameters currentSession ].
	(self isSessionUsable not) ifTrue: [
		userList items: #( ).
		groupList items: #( ).
		userNameField text: ''.
		self updateActionButtons.
		^ self
	].

	self refreshUserList.
	self updateActionButtons.
]

{ #category : 'layout' }
GbsUserListPresenter >> defaultLayout [
	| topLists userRow buttonsRow |
	topLists := SpBoxLayout newLeftToRight
		add: userList;
		add: groupList;
		spacing: 8;
		yourself.
	userRow := SpBoxLayout newLeftToRight
		add: (self newLabel label: 'User') expand: false;
		add: userNameField;
		spacing: 8;
		yourself.
	buttonsRow := SpBoxLayout newLeftToRight
		add: createUserButton;
		add: showUserInfoButton;
		add: deleteUserButton;
		add: closeButton;
		spacing: 10;
		yourself.
	^ SpBoxLayout newTopToBottom
		add: mainMenu expand: false;
		add: topLists;
		add: userRow expand: false;
		add: buttonsRow expand: false;
		spacing: 8;
		yourself
]

{ #category : 'menus' }
GbsUserListPresenter >> buildMenuBar [
	^ self newMenuBar
		addGroup: [ :group |
			group
				addItem: [ :item | item name: 'File'; subMenu: self menuFile ];
				addItem: [ :item | item name: 'User'; subMenu: self menuUser ];
				addItem: [ :item | item name: 'Report'; subMenu: self menuReport ];
				addItem: [ :item | item name: 'Help'; subMenu: self menuHelp ] ];
		yourself
]

{ #category : 'menus' }
GbsUserListPresenter >> menuFile [
	^ self newMenu
		addItem: [ :item | item name: 'Refresh'; action: [ self refreshUserList ] ];
		addItem: [ :item | item name: 'Close'; action: [ self closeWindow ] ];
		yourself
]

{ #category : 'menus' }
GbsUserListPresenter >> menuUser [
	^ self newMenu
		addItem: [ :item | item name: 'Create User...'; action: [ self openCreateUserDialog ] ];
		addItem: [ :item | item name: 'Show User Info'; action: [ self showSelectedUserInfo ] ];
		addItem: [ :item | item name: 'Delete User...'; action: [ self deleteSelectedUser ] ];
		yourself
]

{ #category : 'menus' }
GbsUserListPresenter >> menuHelp [
	^ self newMenu
		addItem: [ :item | item name: 'About GemStone User List'; action: [ UIManager default inform: 'GemStone User List' ] ];
		yourself
]

{ #category : 'menus' }
GbsUserListPresenter >> menuReport [
	^ self newMenu
		addItem: [ :item | item name: 'Copy User Report'; action: [ Clipboard clipboardText: self userReportText ] ];
		addItem: [ :item | item name: 'Copy Group Report'; action: [ Clipboard clipboardText: self groupReportText ] ];
		addItem: [ :item | item name: 'Show Full Report'; action: [ UIManager default edit: self fullReportText label: 'GemStone User Report' ] ];
		yourself
]

{ #category : 'layout' }
GbsUserListPresenter >> fetchGroupsFor: userName [
	| script rawString groupNames |
	(self isSessionUsable not) ifTrue: [ ^ self ].

	script := '
	| users user strm |
	strm := WriteStream on: String new.
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNotNil: [
		user := users detect: [:u | u userId asString = ''', userName, '''] ifNone: [ nil ].
		user ifNotNil: [
			user groups do: [:g | strm nextPutAll: g name asString] separatedBy: [strm nextPutAll: '',''].
		].
	].
	strm contents'.
	
	"2. Fetch and unpack"
	rawString := [ session evaluate: script ] on: Error do: [ '' ].

	(rawString isString and: [ rawString isNotEmpty ]) 
		ifTrue: [ groupNames := (rawString splitOn: ',') reject: #isEmpty ]
		ifFalse: [ groupNames := #() ].

	groupList items: groupNames asSortedCollection asArray.
	userNameField text: userName asString
]

{ #category : 'private' }
GbsUserListPresenter >> isSessionUsable [
	session ifNil: [ ^ false ].
	(session respondsTo: #isLoggedIn)
		ifTrue: [ ^ [ session isLoggedIn == true ] on: Error do: [ false ] ].
	^ true
]

{ #category : 'accessing - deprecated' }
GbsUserListPresenter >> initialExtent [

  ^ 400 @ 500 "Width @ Height"
]

{ #category : 'accessing' }
GbsUserListPresenter >> initializePresenters [
	mainMenu := self buildMenuBar.

	userList := self newList.
	userList headerTitle: 'Users'.
	userList display: [ :each | each asString ].

	groupList := self newList.
	groupList headerTitle: 'Groups'.
	groupList display: [ :each | each asString ].

	userNameField := self newTextInput.
	userNameField beNotEditable.

	createUserButton := self newButton
		label: 'Create User...';
		icon: (self iconNamed: #add);
		yourself.
	showUserInfoButton := self newButton
		label: 'Show User Info';
		yourself.
	deleteUserButton := self newButton
		label: 'Delete User...';
		icon: (self iconNamed: #delete);
		yourself.
	closeButton := self newButton
		label: 'Close';
		icon: (self iconNamed: #smallCancel);
		yourself
]

{ #category : 'accessing - deprecated' }
GbsUserListPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone User List';
		initialExtent: 760 @ 560
]

{ #category : 'accessing' }
GbsUserListPresenter >> refreshUserList [
	| script rawString userNames |
	(self isSessionUsable not) ifTrue: [ ^ self ].
	
	"Iterate over the UserProfileSet and extract the userId"
	script := '
	| users strm |
	strm := WriteStream on: String new.
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNotNil: [
		users do: [:u | strm nextPutAll: u userId asString] separatedBy: [strm nextPutAll: '',''].
	].
	strm contents'.
	
	rawString := [ session evaluate: script ] on: Error do: [ '' ].
	
	(rawString isString and: [ rawString isNotEmpty ]) 
		ifTrue: [ userNames := (rawString splitOn: ',') reject: #isEmpty ]
		ifFalse: [ userNames := #() ].

	userList items: userNames asSortedCollection asArray.
	groupList items: #( ).
	userNameField text: ''.
	self updateActionButtons
]

{ #category : 'accessing' }
GbsUserListPresenter >> session: aGbsSession [
    session := aGbsSession.
    self isSessionUsable ifFalse: [
		userList ifNotNil: [ userList items: #( ) ].
		groupList ifNotNil: [ groupList items: #( ) ].
		userNameField ifNotNil: [ userNameField text: '' ].
		self updateActionButtons.
	]
]

{ #category : 'accessing - deprecated' }
GbsUserListPresenter >> title [
	^ 'GemStone User List'
]

{ #category : 'actions' }
GbsUserListPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]

{ #category : 'actions' }
GbsUserListPresenter >> deleteSelectedUser [
	| userName confirmed script |
	userName := self selectedUserName.
	userName ifNil: [ ^ self ].
	confirmed := UIManager default
		confirm: 'Delete user "', userName, '"?'
		label: 'Delete GemStone User'.
	confirmed ifFalse: [ ^ self ].
	script := '
	| users user |
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ self error: ''AllUsers not found'' ].
	user := users detect: [ :u | u userId asString = ''', userName, ''' ] ifNone: [ nil ].
	user ifNil: [ self error: ''User not found'' ].
	(users respondsTo: #remove:)
		ifTrue: [ users remove: user ]
		ifFalse: [
			(users respondsTo: #removeUser:)
				ifTrue: [ users removeUser: user ]
				ifFalse: [ self error: ''Cannot remove user with available API'' ] ].
	true'.
	[
		session execute: script.
		self refreshUserList.
		UIManager default inform: 'Deleted user ', userName, '.'
	] on: Error do: [ :ex |
		self inform: 'Delete user failed: ', ex messageText
	]
]

{ #category : 'actions' }
GbsUserListPresenter >> openCreateUserDialog [
	(self isSessionUsable not) ifTrue: [ ^ self ].
	GbsCreateUserPresenter
		openOn: session
		onCreated: [ self refreshUserList ]
]

{ #category : 'private' }
GbsUserListPresenter >> selectedUserName [
	^ userList selection selectedItem ifNotNil: [ :name | name asString ]
]

{ #category : 'actions' }
GbsUserListPresenter >> showSelectedUserInfo [
	| userName info opened |
	userName := self selectedUserName.
	userName ifNil: [ ^ self ].
	info := self userInfoTextFor: userName.
	opened := self openUserInfoWindowFor: userName text: info session: session.
	opened ifFalse: [
		(self openUserInfoFallbackText: info forUser: userName)
			ifFalse: [ UIManager default inform: 'Could not open user info window.' ] ]
]

{ #category : 'private' }
GbsUserListPresenter >> userInfoPresenterClass [
	^ Smalltalk at: #GbsUserInfoPresenter ifAbsent: [ nil ]
]

{ #category : 'private' }
GbsUserListPresenter >> openUserInfoWindowFor: userName text: infoTextValue session: aSession [
	| klass |
	klass := self userInfoPresenterClass.
	klass ifNil: [ ^ false ].
	(klass respondsTo: #openForUser:text:session:) ifFalse: [ ^ false ].
	^ [
		klass openForUser: userName text: infoTextValue session: aSession.
		true
	] on: Error do: [ false ]
]

{ #category : 'private' }
GbsUserListPresenter >> openUserInfoFallbackText: infoTextValue forUser: userName [
	| label text |
	text := infoTextValue ifNil: [ '' ] ifNotNil: [ infoTextValue asString ].
	label := 'GemStone User Info - ', (userName ifNil: [ '' ] ifNotNil: [ userName asString ]).
	(UIManager default respondsTo: #edit:label:)
		ifTrue: [ UIManager default edit: text label: label. ^ true ].
	(UIManager default respondsTo: #inform:)
		ifTrue: [ UIManager default inform: text. ^ true ].
	^ false
]

{ #category : 'private' }
GbsUserListPresenter >> userInfoTextFor: userName [
	| script info creator map enabled privilegeText |
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
				| groupNames |
				groupNames := OrderedCollection new.
				user groups do: [ :g |
					| gName open close |
					gName := (g respondsTo: #name)
						ifTrue: [ g name asString ]
						ifFalse: [ g asString ].
					open := gName indexOf: $( ifAbsent: [ 0 ].
					close := gName indexOf: $) ifAbsent: [ 0 ].
					(open > 0 and: [ close > open ])
						ifTrue: [ gName := (gName copyFrom: open + 1 to: close - 1) withBlanksTrimmed ].
					((gName isNil or: [ gName asString isEmpty ]) not) ifTrue: [ groupNames add: gName ] ].
				groupNames := groupNames asArray asSet asArray asSortedCollection.
				strm nextPutAll: ''Groups: ''.
				groupNames
					do: [ :each | strm nextPutAll: each ]
					separatedBy: [ strm nextPutAll: '', '' ].
				strm cr ] ] ].
	strm contents'.
	info := [ session evaluate: script ] on: Error do: [ :ex | 'Could not fetch user info: ', ex messageText ].
	creator := GbsCreateUserPresenter new.
	creator session: session.
	map := [ creator fetchPrivilegesForUser: userName ] on: Error do: [ Dictionary new ].
	enabled := ((map associations
		select: [ :assoc | assoc value == true ])
		collect: [ :assoc | assoc key asString ]) asSortedCollection.
	privilegeText := enabled isEmpty
		ifTrue: [ 'Privileges: <none>' ]
		ifFalse: [
			'Privileges: ', (String streamContents: [ :s |
				enabled do: [ :each | s nextPutAll: each ] separatedBy: [ s nextPutAll: ', ' ] ]) ].
	^ (info ifNil: [ 'No information available.' ] ifNotNil: [ info asString ]), String cr, privilegeText
]

{ #category : 'private' }
GbsUserListPresenter >> updateActionButtons [
	| hasSelection |
	hasSelection := self selectedUserName notNil.
	showUserInfoButton ifNotNil: [ hasSelection ifTrue: [ showUserInfoButton enable ] ifFalse: [ showUserInfoButton disable ] ].
	deleteUserButton ifNotNil: [ hasSelection ifTrue: [ deleteUserButton enable ] ifFalse: [ deleteUserButton disable ] ]
]

{ #category : 'private' }
GbsUserListPresenter >> userReportText [
	| users selected |
	users := userList ifNil: [ #() ] ifNotNil: [ userList items ifNil: [ #() ] ].
	selected := self selectedUserName.
	(selected notNil and: [ selected isEmpty not ]) ifTrue: [ users := { selected } ].
	^ String streamContents: [ :stream |
		stream nextPutAll: '=== Users ==='; cr.
		users do: [ :each | stream nextPutAll: each asString; cr ] ]
]

{ #category : 'private' }
GbsUserListPresenter >> groupReportText [
	| groups selected |
	groups := groupList ifNil: [ #() ] ifNotNil: [ groupList items ifNil: [ #() ] ].
	selected := self selectedUserName.
	^ String streamContents: [ :stream |
		stream nextPutAll: '=== Groups ==='; cr.
		selected ifNotNil: [
			stream nextPutAll: 'User: '; nextPutAll: selected asString; cr ].
		groups do: [ :each | stream nextPutAll: each asString; cr ] ]
]

{ #category : 'private' }
GbsUserListPresenter >> fullReportText [
	^ self userReportText, String cr, self groupReportText
]
