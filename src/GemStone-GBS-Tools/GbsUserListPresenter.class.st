Class {
	#name : 'GbsUserListPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
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
		add: topLists;
		add: userRow expand: false;
		add: buttonsRow expand: false;
		spacing: 8;
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
	| userName script info |
	userName := self selectedUserName.
	userName ifNil: [ ^ self ].
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
					| gName |
					gName := (g respondsTo: #name)
						ifTrue: [ g name asString ]
						ifFalse: [ g asString ].
					((gName isNil or: [ gName asString isEmpty ]) not) ifTrue: [ groupNames add: gName ] ].
				groupNames := groupNames asArray asSet asArray asSortedCollection.
				strm nextPutAll: ''Groups: ''.
				groupNames
					do: [ :each | strm nextPutAll: each ]
					separatedBy: [ strm nextPutAll: '', '' ].
				strm cr ] ] ].
	strm contents'.
	info := [ session evaluate: script ] on: Error do: [ :ex | 'Could not fetch user info: ', ex messageText ].
	UIManager default inform: (info ifNil: [ 'No information available.' ] ifNotNil: [ info asString ])
]

{ #category : 'private' }
GbsUserListPresenter >> updateActionButtons [
	| hasSelection |
	hasSelection := self selectedUserName notNil.
	showUserInfoButton ifNotNil: [ hasSelection ifTrue: [ showUserInfoButton enable ] ifFalse: [ showUserInfoButton disable ] ].
	deleteUserButton ifNotNil: [ hasSelection ifTrue: [ deleteUserButton enable ] ifFalse: [ deleteUserButton disable ] ]
]
