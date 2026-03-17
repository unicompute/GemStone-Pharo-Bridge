Class {
	#name : #'GbxDbaUserListBrain',
	#superclass : #'GbxDbaBrain',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Tools'
}

{ #category : #'accessing' }
GbxDbaUserListBrain >> databaseUserList
	" Answer a sorted list of all possible users of the current repository. "
	"This is a little ugly, but the old user profile holder requires the user
	be a forwarder. To avoid rewriting that heavily-used class completely, 
	we do a pass to get the users, a second pass to get a collection of
	delegates from which to make forwarders, and finally a pass to get
	the userIds. That's only 3 round trips."

	| userProfiles ids |
	self showBusyWhile: 
			[| sortedUsersProxy |
			sortedUsersProxy := self session
						execute: '
	| sc |
	sc := SortedCollection sortBlock: [ :u1 :u2 | u1 userId <= u2 userId ].
	sc addAll: AllUsers.
	sc asArray'.
			userProfiles := sortedUsersProxy fetchObjectValues
						collect: [:upProxy | GbxUserProfileHolder on: upProxy asForwarder].
			ids := self session evaluate: 'self collect:[:ea | ea userId]'
						context: (userProfiles collect: [:ea | ea remoteUserProfile]).	"collect inital ids on one trip"
			userProfiles with: ids do: [:profile :id | profile cachedUserId: id].
			^userProfiles]

{ #category : #'accessing' }
GbxDbaUserListBrain >> currentUser
	" Answer the currently selected user in my userList. "

	| currUser |

	currUser := self currentUserListSelection.
	currUser isNil ifTrue:
		[^ nil].
	currUser gbxIsGSDefunct ifTrue:
		[self gbsMessenger warn: 'This user is no longer connected to the repository.\Click on the OK button to close this window.'.
		self newUserName: nil.
		self closeRequest.
		^ nil].
	^ currUser

{ #category : #'testing' }
GbxDbaUserListBrain >> isDatabaseUserSelected
	" Answer true when a GemStone user is selected. "

	^ self currentUser notNil

{ #category : #'changing' }
GbxDbaUserListBrain >> dbUserNameChange
	" The user has modified the text for the name of the currently selected GemStone user. "

	| disableBlock name user |

	self basicCurrentUserName = self currentUserName ifFalse:
		[self newUserName: self currentUserName.].
	disableBlock :=
		[self newUserListSelection: nil.
		self disableButtons. ].
	self	checkWildcardInUserId: self windowInterface currentUserName
		ifMatch:
			[: aUserId |
			self currentUserName = aUserId ifFalse:
				[self newUserName: aUserId.].]
		ifNoMatch:
			[(self windowInterface currentUserName includes: $*) ifTrue:
				[self gbsMessenger warn: 'No match for %1.' with: self currentUserName.
				self newUserName: ''.
				^ disableBlock value ].].
	name := self currentUserName.
	name = '' ifTrue:
		[^ disableBlock value].
	user := self userNamed: name.
	user isNil
		ifTrue:
			[disableBlock value.]
		ifFalse:
			[self newUserListSelection: (GbxUserProfileHolder on: user).
			self enableButtons.].

{ #category : #'private' }
GbxDbaUserListBrain >> protectedUserNames

	^self class protectedUserNames

{ #category : #'window accessing' }
GbxDbaUserListBrain >> newUserName: aString
	" I change the value of my window's user name field to aString. "

	self windowInterface newUserName: aString.

{ #category : #'window accessing' }
GbxDbaUserListBrain >> currentUserListSelection
	" Answer the current selection of my window's user list. "

	^ self windowInterface currentUserListSelection

{ #category : #'window accessing' }
GbxDbaUserListBrain >> currentUserName
	" Answer the value of my window's user name field with leading/trailing blanks removed. "

	^ self windowInterface currentUserName

{ #category : #'window accessing' }
GbxDbaUserListBrain >> newUserList: aList
	" I change the value of my window's user list's list. "

	self windowInterface newUserList: aList.

{ #category : #'window accessing' }
GbxDbaUserListBrain >> basicCurrentUserName
	" Answer the value of my window's user name field without trimming blanks. "

	^ self windowInterface basicCurrentUserName

{ #category : #'actions' }
GbxDbaUserListBrain >> reallyDeleteUser: aDeleteUserProfileGSForwarder switchingTo: aReplacementUserProfileGSForwarder
	" I delete the specified UserProfile on the SmalltalkGS side and change security policies owned by it to be owned by the replacement UserProfile. "

	| mug name1 securityPolicy securityPolicies sysRepos userId userTag |
	self displayStatus: 'Finding this user''s security policies...'.
	securityPolicies := Set new.
	sysRepos := self sessionForwarderFor: #SystemRepository.
	1 to: sysRepos size
		do: 
			[:ix |
			securityPolicy := sysRepos ucfwat: ix.
			securityPolicy ucfwowner userId = aDeleteUserProfileGSForwarder userId
				ifTrue: [securityPolicies add: securityPolicy]].
	securityPolicies isEmpty
		ifFalse: 
			[self displayStatus: 'Making you the owner...'.
			securityPolicies
				do: [:eachForwarder | eachForwarder ucfwowner: aReplacementUserProfileGSForwarder]].
	self displayStatus: ''.
	mug := (self sessionForwarderFor: #System) ucfwmyUserGlobals.
	userId := aDeleteUserProfileGSForwarder userId.
	userTag := userId copyWithout: $ .
	name1 := userTag , '_userProfile'.
	mug ucfwat: name1 asSymbol put: aDeleteUserProfileGSForwarder.
	(self sessionForwarderFor: #AllUsers) gbxDelegate
		remotePerform: #removeAndCleanup:
		with: aDeleteUserProfileGSForwarder.
	self gbsMessenger warn: 'User removed and security policies cleaned up'.

{ #category : #'actions' }
GbxDbaUserListBrain >> reallyDeleteUser
	" I allow the GemStone administrator to delete the current GemStone user. "

	| deleteUserProfileObj myUserProfileObj hadError |
	self currentUser isNil ifTrue: [^self].
	myUserProfileObj := (self sessionForwarderFor: #System) asGSObject
				remotePerform: #myUserProfile.
	deleteUserProfileObj := self currentUser remoteUserProfile asGSObject.
	myUserProfileObj = deleteUserProfileObj
		ifTrue: [^self gbsMessenger warn: 'You can''t delete your own account!'].
	(self session
		evaluate: 'System myUserProfile _hasPrivilegeName: #OtherPassword')
			ifFalse: 
				[^self gbsMessenger
					warn: 'Removing a user requires #OtherPassword privilege.\See UserProfileSet>>#removeAndCleanup:'].
	self protectedUserNames do: 
			[:name |
			self currentUser userId asString = name
				ifTrue: 
					[^self gbsMessenger warn: 'You can''t delete the ' , name , ' account!']].
	(self gbsMessenger confirm: 'Really delete user %1?'
		with: self currentUser userId asString) ifFalse: [^self].
	hadError := false.
	
	[self reallyDeleteUser: self currentUser remoteUserProfile
		switchingTo: myUserProfileObj asForwarder]
			on: GbsError errorSignal
			do: 
				[:ex |
				hadError := true.
				^ex resume].
	hadError ifTrue: [^self].
	self changeNotification: #dbaUserDeleted

{ #category : #'actions' }
GbxDbaUserListBrain >> deleteUser
	" I allow the GemStone administrator to delete the current GemStone user. "

	self showBusyWhile:
		[ self reallyDeleteUser. ].

{ #category : #'actions' }
GbxDbaUserListBrain >> browserClass

	^GbxDbaUserBrowser3

{ #category : #'actions' }
GbxDbaUserListBrain >> createUser
	" Spawn a window that allows the GemStone administrator to create a new GemStone user. "

	| currName currUser aBuilder |
	currUser := self currentUser.
	currName := self currentUserName.
	currUser isNil & currName isNil ifTrue: [^self].
	(currUser notNil and: [currUser userId asString = currName])
		ifTrue: [currName := ''].
	aBuilder := self browserClass openOnUserId: currName in: self session.
	^aBuilder window model

{ #category : #'actions' }
GbxDbaUserListBrain >> userInfoOpen
	" Spawn a window on the GemStone user that is currently selected. "

	| name user |

	user := self currentUser.
	user notNil
		ifTrue: [^ self browserClass
					openOnUser: user
					in: self session].
	name := self currentUserName.
	name isNil
		ifTrue: [^ self].
	self browserClass
		openOnUserId: name
		in: self session.

{ #category : #'actions' }
GbxDbaUserListBrain >> abortTransaction
	" Allow the user to discard all changes made in the current transaction. "

	super abortTransaction.
	self updateUsersRequest.

{ #category : #'actions' }
GbxDbaUserListBrain >> showUserInfo
	" Spawn a window on the GemStone user that is currently selected. "
	"Note: The expected return value here is questionable."

	| theBuilder |
	self currentUser isNil ifTrue: [^self].
	^
	[theBuilder := self browserClass openOnUser: self currentUser
				in: self session.
	(theBuilder componentAt: #UserId) widget controller readOnly: true.
	theBuilder window model]
			on: GbsError errorSignal
			do: 
				[:ex |
				self gbsMessenger
					warn: 'You (as User ID %1) do not have\authority to view %2.\\%3'
					with: self session parameters username
					with: self currentUser userId asString
					with: ex originator messageText.
				ex return: false]

{ #category : #'window changing' }
GbxDbaUserListBrain >> databaseUserSelected
	" When no user is selected, certain buttons must be disabled. "

	self isDatabaseUserSelected
		ifTrue:
			[self enableButtons.
			self newUserName: self currentUser userId asString.]
		ifFalse:
			[self disableButtons.
			self newUserName: ''.].

{ #category : #'window changing' }
GbxDbaUserListBrain >> displayStatus: aString
	" Show the specified message to the user while he/she is waiting. "

	super displayStatus: (aString isEmpty
		ifTrue: [self session printString]
		ifFalse: [aString]).

{ #category : #'window changing' }
GbxDbaUserListBrain >> disableButtons
	" Deactivate certain buttons until a user is selected.
	  NOTE:  To be VW / VS compatible, button names must start with an uppercase letter.
	  WARNING:  Do not use # within array declarations. "

	self disableGroup: #( DeleteUserButton  ShowUserInfoButton ).

{ #category : #'window changing' }
GbxDbaUserListBrain >> enableButtons
	" Activate certain buttons while a user is selected.
	  NOTE:  To be VW / VS compatible, button names must start with an uppercase letter.
	  WARNING:  Do not use # within array declarations. "

	self enableGroup: #( DeleteUserButton  ShowUserInfoButton ).

{ #category : #'external changing' }
GbxDbaUserListBrain >> updateDataRequest
	" I allow external changes to refresh the list of current GemStone users. "

	self updateUsersRequest.

{ #category : #'external changing' }
GbxDbaUserListBrain >> updateUsersRequest
	" I allow the GemStone administrator to refresh the list of current GemStone users. "

	self showBusyWhile:
		[ self newUserList: self databaseUserList.
		self newUserName: ''.
		self dbUserNameChange. ].

{ #category : #'external changing' }
GbxDbaUserListBrain class >> myNotificationSymbols
	" Answer a list of symbols that mean I have to update my information.
	  WARNING:  For VW / VS compatibility, do not user '#' before each symbol. "

	^ #( aborted  dbaUserAdded  dbaUserDeleted )

{ #category : #'utility' }
GbxDbaUserListBrain class >> protectedUserNames

	^#('CodeLibrarianUser' ' DataCurator' 'SystemUser' 'GcUser' 'HostAgentUser' 'Nameless' 'SymbolUser')

