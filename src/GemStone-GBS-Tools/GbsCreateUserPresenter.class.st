Class {
	#name : 'GbsCreateUserPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'userField',
		'passwordField',
		'confirmPasswordField',
		'createButton',
		'cancelButton',
		'createdBlock'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsCreateUserPresenter class >> openOn: aSession onCreated: aBlock [
	| presenter |
	aSession ifNil: [ ^ self ].
	presenter := self new.
	presenter
		session: aSession;
		createdBlock: aBlock;
		open.
	^ presenter
]

{ #category : 'private' }
GbsCreateUserPresenter >> createdBlock: aBlock [
	createdBlock := aBlock
]

{ #category : 'layout' }
GbsCreateUserPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		add: (SpGridLayout new
			add: 'User ID:' atPoint: 1@1;
			add: userField atPoint: 2@1;
			add: 'Password:' atPoint: 1@2;
			add: passwordField atPoint: 2@2;
			add: 'Confirm:' atPoint: 1@3;
			add: confirmPasswordField atPoint: 2@3;
			yourself);
		add: (SpBoxLayout newLeftToRight
			add: createButton;
			add: cancelButton;
			spacing: 8;
			yourself) expand: false;
		yourself
]

{ #category : 'actions' }
GbsCreateUserPresenter >> doCreateUser [
	| userName password confirm script |
	userName := userField text asString withBlanksTrimmed.
	password := passwordField text asString.
	confirm := confirmPasswordField text asString.
	userName isEmpty ifTrue: [ ^ self inform: 'User ID is required.' ].
	password isEmpty ifTrue: [ ^ self inform: 'Password is required.' ].
	password = confirm ifFalse: [ ^ self inform: 'Password and confirmation do not match.' ].
	script := self scriptToCreateUser: userName password: password.
	[
		session execute: script.
		createdBlock ifNotNil: [ createdBlock value ].
		self closeWindow
	] on: Error do: [ :ex |
		self inform: 'Create user failed: ', ex messageText
	]
]

{ #category : 'actions' }
GbsCreateUserPresenter >> doCancel [
	self closeWindow
]

{ #category : 'initialization' }
GbsCreateUserPresenter >> initializePresenters [
	userField := self newTextInput.
	passwordField := self newTextInput bePassword.
	confirmPasswordField := self newTextInput bePassword.
	createButton := self newButton
		label: 'Create';
		icon: (self iconNamed: #smallOk);
		action: [ self doCreateUser ];
		yourself.
	cancelButton := self newButton
		label: 'Cancel';
		icon: (self iconNamed: #smallCancel);
		action: [ self doCancel ];
		yourself
]

{ #category : 'initialization' }
GbsCreateUserPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'Create GemStone User';
		initialExtent: 420 @ 180
]

{ #category : 'private' }
GbsCreateUserPresenter >> literalString: aString [
	^ '''', (aString copyReplaceAll: '''' with: ''''''), ''''
]

{ #category : 'private' }
GbsCreateUserPresenter >> scriptToCreateUser: userName password: password [
	| userLiteral passLiteral |
	userLiteral := self literalString: userName.
	passLiteral := self literalString: password.
	^ '
	| allUsers created |
	created := false.
	allUsers := System myUserProfile symbolList objectNamed: #AllUsers.
	allUsers ifNil: [ self error: ''AllUsers not found'' ].
	(allUsers respondsTo: #addNewUserWithId:password:)
		ifTrue: [
			allUsers addNewUserWithId: ', userLiteral, ' password: ', passLiteral, '.
			created := true ].
	created ifFalse: [
		(allUsers respondsTo: #addUser:password:)
			ifTrue: [
				allUsers addUser: ', userLiteral, ' password: ', passLiteral, '.
				created := true ] ].
	created ifFalse: [ self error: ''Cannot create user with available API'' ].
	true'
]

{ #category : 'private' }
GbsCreateUserPresenter >> session: aSession [
	session := aSession
]

{ #category : 'private' }
GbsCreateUserPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]
