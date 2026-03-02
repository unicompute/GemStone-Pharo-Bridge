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

{ #category : 'layout' }
GbsUserListPresenter >> connectPresenters [
	"1. Keep your existing selection logic"
	userList whenSelectionChangedDo: [ :selection |
		selection selectedItem
			ifNotNil: [ :userName | self fetchGroupsFor: userName ]
			ifNil: [ groupList items: #(  ) ]
	].
	
	"2. Automatically grab the active session if it hasn't been injected"
	session ifNil: [ 
		"Uses the Singleton we discussed, with a fallback just in case"
		session := GbsSessionParameters classPool at: #CurrentSession ifAbsent: [ nil ] 
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
	session ifNil: [ ^ self ].
	
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
	rawString := session evaluate: script.
	
	"3. Safely parse"
	(rawString isString and: [ rawString isNotEmpty ]) 
		ifTrue: [ groupNames := (rawString splitOn: ',') reject: #isEmpty ]
		ifFalse: [ groupNames := #() ].
		
	groupList items: groupNames asSortedCollection asArray
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
	session ifNil: [ ^ self ].
	
	"Iterate over the UserProfileSet and extract the userId"
	script := '
	| users strm |
	strm := WriteStream on: String new.
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNotNil: [
		users do: [:u | strm nextPutAll: u userId asString] separatedBy: [strm nextPutAll: '',''].
	].
	strm contents'.
	
	rawString := session evaluate: script.
	
	(rawString isString and: [ rawString isNotEmpty ]) 
		ifTrue: [ userNames := (rawString splitOn: ',') reject: #isEmpty ]
		ifFalse: [ userNames := #() ].
		
	userList items: userNames asSortedCollection asArray
]

{ #category : 'accessing' }
GbsUserListPresenter >> session: aGbsSession [
    session := aGbsSession.
    self refreshUserList. "Automatically fetch data when the session is set"
]

{ #category : 'accessing - deprecated' }
GbsUserListPresenter >> title [

  ^ 'GemStone Database Users'
]
