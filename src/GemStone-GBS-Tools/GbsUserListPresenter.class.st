Class {
	#name : 'GbsUserListPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'userList',
		'session',
		'groupList'
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
	"1. Keep your existing selection logic"
	userList whenSelectionChangedDo: [ :selection |
		selection selectedItem
			ifNotNil: [ :userName | self fetchGroupsFor: userName ]
			ifNil: [ groupList items: #(  ) ]
	].
	
	"2. Automatically grab the active session if it hasn't been injected"
	session ifNil: [ session := GbsSessionParameters currentSession ].
	(self isSessionUsable not) ifTrue: [
		userList items: #( ).
		groupList items: #( ).
		^ self
	].
	
	"3. Force the lists to populate right before the window appears!"
	self refreshUserList.
]

{ #category : 'layout' }
GbsUserListPresenter >> defaultLayout [

  ^ SpBoxLayout newLeftToRight
      add: userList;
      add: groupList;
      yourself
]

{ #category : 'layout' }
GbsUserListPresenter >> fetchGroupsFor: userName [
	| script rawString groupNames |
	(self isSessionUsable not) ifTrue: [ ^ self ].
	
	"1. Use 'g name' because GemStone groups are UserProfileGroup objects!"
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
	
	"3. Safely parse"
	(rawString isString and: [ rawString isNotEmpty ]) 
		ifTrue: [ groupNames := (rawString splitOn: ',') reject: #isEmpty ]
		ifFalse: [ groupNames := #() ].
		
	groupList items: groupNames asSortedCollection asArray
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
	userList display: [ :each | each asString ]. "Force Spec2 to render the text"

	groupList := self newList.
	groupList headerTitle: 'Groups'.
	groupList display: [ :each | each asString ].
]

{ #category : 'accessing - deprecated' }
GbsUserListPresenter >> initializeWindow: aWindowPresenter [

  aWindowPresenter
    title: 'GemStone Database Users';
    initialExtent: 400 @ 500
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
		
	userList items: userNames asSortedCollection asArray
]

{ #category : 'accessing' }
GbsUserListPresenter >> session: aGbsSession [
    session := aGbsSession.
    self isSessionUsable ifFalse: [
		userList ifNotNil: [ userList items: #( ) ].
		groupList ifNotNil: [ groupList items: #( ) ].
	]
]

{ #category : 'accessing - deprecated' }
GbsUserListPresenter >> title [

  ^ 'GemStone Database Users'
]
