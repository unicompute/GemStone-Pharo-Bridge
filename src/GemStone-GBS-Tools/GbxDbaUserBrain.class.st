Class {
	#name : #'GbxDbaUserBrain',
	#superclass : #'GbxDbaBrain',
	#instVars : [ #'user' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Tools'
}

{ #category : #'changing' }
GbxDbaUserBrain >> languageChange
	" The user has changed the native language. "

	| goodLang newLang |

	self newLanguage: self currentLanguage gbxTrimBlanks.
	newLang := self currentLanguage.
	newLang isEmpty ifTrue:
		[^ self newLanguage: self user language ].
	goodLang := (self sessionForwarderFor: #GemStoneError) includesKey: newLang.
	goodLang ifFalse:
		[self gbsMessenger warn: 'The %1 language\is not available in the GemStoneError language dictionary.' with: newLang.
		^ self newLanguage: self user language ].
	self hasChanges: true.

{ #category : #'changing' }
GbxDbaUserBrain >> passwordChange
	" The user has changed the password. "

	self currentPassword = self currentPassword gbxTrimBlanks
		ifFalse: 
			[self gbsMessenger
				warn: 'All leading and trailing blanks have\been removed from your password.'].
	self newPassword: self currentPassword gbxTrimBlanks.
	self currentPassword isEmpty ifTrue: [^self].
	self hasChanges: true.
	^tool repeatPassword: self

{ #category : #'changing' }
GbxDbaUserBrain >> userIdChange
	" The user has changed the user ID. "

	| isNewUser newName newUser oldUser revertBlock hadError |

	self newId: self currentId gbxTrimBlanks.
	oldUser := self user.
	revertBlock :=
		[self hasChanges: false.
		self newId: oldUser userId asString.
		^ oldUser userId isEmpty
			ifTrue: [self ]
			ifFalse: [self userIdChange ]].
	self	checkWildcardInUserId: self currentId
		ifMatch:
			[: aUserId | self newId: aUserId.]
		ifNoMatch:
			[(self currentId includes: $*) ifTrue:
				[self gbsMessenger warn: 'No match for %1.' with: self currentId.
				^ revertBlock value ].].
	newName := self currentId.
	(newName isEmpty or: [self discardChanges not]) ifTrue:
		[^ revertBlock value ].
	self enableOtherFields.
	self enableUserButtons.
	newUser := self userNamed: newName.
	isNewUser := newUser isNil.
	oldUser := self user.
	hadError := false.
	[
		self user: (isNewUser
			ifTrue: [GbxUserProfileHolder newUserId: newName in: self session]
			ifFalse: [GbxUserProfileHolder on: newUser]).
		self updateAllData.
		isNewUser ifTrue: [self hasChanges: true.].
	]
		on: GbsError errorSignal
		do: [: ex |
			hadError := true.
			self gbsMessenger warn: 'You (as User ID %1) do not have\authority to view %2.\\%3'
				with: self session parameters username
				with: newUser userId asString
				with: ex originator messageText.
			ex return
		].

	hadError ifTrue: [^revertBlock value].

{ #category : #'changing' }
GbxDbaUserBrain >> cleanupPasswordString: originalString
	"GBS Private. Transform the originalString into a form that can be used as
	 a password. This was necessary for handling double byte strings. The VA
	 equivalent is 'originalString asByteArray asString', but there is no VW
	 equivalent because #asByteArray fails with TwoByteStrings."

	| stream |
	stream := WriteStream on: (String new: originalString size * 2).
	originalString do: [:chr |
		| intValue |
		intValue := chr asInteger.
		intValue >= 16r100 ifTrue: [stream nextPut: (Character value: intValue // 16r100)].
		stream nextPut: (Character value: intValue \\ 16r100).
	].
	^stream contents

{ #category : #'testing' }
GbxDbaUserBrain >> hasCompatiblePasteBuffer
	" Answer true if the current item in the clipboard is a segment for this session. "

	| assn |

	assn := GbxClipboardObj
		getObjectForSession: self session
		context: #Segment
		quietly: true.
	^ assn notNil

{ #category : #'testing' }
GbxDbaUserBrain >> hasValidNewUserInfo
	" Answer true if my data is sufficient for a valid new UserProfile. "

	self currentId isEmpty ifTrue:
		[self gbsMessenger warn: 'A User ID (name) is required.'.
		^ false ].
	self currentPassword isEmpty ifTrue:
		[(self gbsMessenger confirm: 'Use default password "gemstone"?') ifFalse:
			[^ false ].
		self newPassword: 'gemstone'.].
	^ true

{ #category : #'testing' }
GbxDbaUserBrain >> isUserGroupSelected
	" Answer true when a group is selected. "

	^ self currentGroupsSelection notNil

{ #category : #'accessing' }
GbxDbaUserBrain >> userLanguageChoices
	" Answer a sorted list of all currently available languages (as strings). "

	^ ((self sessionForwarderFor: #GemStoneError) ucfwkeys ucfwasSortedCollection asArray
		collect: [: aSymbol | aSymbol asString])
			asSortedCollection asArray

{ #category : #'accessing' }
GbxDbaUserBrain >> user
	" Answer the value of user, the GSUserProfileHolder whose information shows in my window. "

	user isNil ifTrue:
		[^ nil].
	user gbxIsGSDefunct ifTrue:
		[self gbsMessenger warn: 'This user is no longer connected to the repository.\Click on the OK button to close this window.'.
		self hasChanges: false.
		self closeRequest.
		^ nil].
	^ user

{ #category : #'private' }
GbxDbaUserBrain >> addGroupNamed: aName

	self session
		execute: 'AllGroups at: self put: (UserProfileGroup groupWithName: self ifAbsent:[UserProfileGroup newGroupWithName: self])'
		context: aName asSymbol.
	self user remoteUserProfile gbxDelegate
		remotePerform: #addGroup:
		with: aName

{ #category : #'window accessing' }
GbxDbaUserBrain >> newLanguage: aString
	" Set the value of my window's language field. "

	^ self windowInterface newLanguage: aString

{ #category : #'window accessing' }
GbxDbaUserBrain >> currentGroups
	" Answer the list of groups in my window's groups field. "

	^ self windowInterface currentGroups

{ #category : #'window accessing' }
GbxDbaUserBrain >> newId: aString
	" Set the value of my window's id field. "

	^ self windowInterface newId: aString

{ #category : #'window accessing' }
GbxDbaUserBrain >> currentPassword
	" Answer the value of my window's password field. "

	^ self windowInterface currentPassword

{ #category : #'window accessing' }
GbxDbaUserBrain >> newGroupsSelection: aSymbol
	" I change the current selection of my window's groups list. "

	self windowInterface newGroupsSelection: aSymbol.

{ #category : #'window accessing' }
GbxDbaUserBrain >> newGroups: aGroupNameList
	" Set the list of groups in my window's groups field. "

	self windowInterface newGroups: aGroupNameList.

{ #category : #'window accessing' }
GbxDbaUserBrain >> currentLanguage
	" Answer the value of my window's language field. "

	^ self windowInterface currentLanguage

{ #category : #'window accessing' }
GbxDbaUserBrain >> currentId
	" Answer the value of my window's id field. "

	^ self windowInterface currentId

{ #category : #'window accessing' }
GbxDbaUserBrain >> newPassword: aString
	" I change the value of my window's password field to aString. "

	^ self windowInterface newPassword: aString

{ #category : #'window accessing' }
GbxDbaUserBrain >> currentGroupsSelection
	" Answer the current selection of my window's groups. "

	^ self windowInterface currentGroupsSelection

{ #category : #'actions' }
GbxDbaUserBrain >> showSymbolList
	" Spawn a window that shows the SymbolList for this user. "

	self user isNil ifTrue:
		[^ self ].
	GbxDbaSymbolListBrowser
		openOnUser: self user
		in: self session.

{ #category : #'actions' }
GbxDbaUserBrain >> addExistingGroup
	" Allow the user to specify an existing group from a menu of group names. "

	| choiceIndex choices |

	choices := self existingGroupChoices.
	choices isEmpty ifTrue:
		[^ self gbsMessenger warn: 'All existing groups have been added.'].
	choiceIndex := self choiceIndexFromMenuArray: choices.
	choiceIndex isNil ifTrue:
		[^ self].
	self addGroup: (choices at: choiceIndex).
	self ableAddGroupButtons.

{ #category : #'actions' }
GbxDbaUserBrain >> updateUserRequest
	" I allow the user to refresh the current repository user. "

	| myUser hadError |

	myUser := self userNamed: self user gemStoneUserId.
	myUser isNil ifTrue:
		[^ self ].
	self discardChanges ifFalse:
		[^ self ].
	hadError := false.
	[self user: (GbxUserProfileHolder newUserId: self user userId in: self session).]
		on: GbsError errorSignal
		do: [:ex |
			 hadError := true.
			 self gbsMessenger
				warn: 'You (as User ID %1) do not have\authority to view %2.\\%3'
				with: self session parameters username
				with: self user userId asString
				with: ex originator messageText.
			ex return
		].
	hadError ifTrue: [ ^self ].
	self updateAllData.
	self userIdChange.

{ #category : #'actions' }
GbxDbaUserBrain >> moveUserGlobalsFrom: aSymbolListDictionaryForwarderList
to: aSymbolListDictionaryForwarder
	" I must add all of my user's UserGlobals entries to the new UserGlobals in aSymbolListDictionaryForwarder. "

	| newKeys oldUG |

	oldUG := aSymbolListDictionaryForwarderList
		detect:
			[: aSymbListDictForwarder |
			aSymbolListDictionaryForwarder name = aSymbListDictForwarder name ]
		ifNone:
			[^ self ].
	newKeys := oldUG ucfwkeys asArray asSet.
	newKeys remove: aSymbolListDictionaryForwarder name.
	newKeys do:
		[: aSymbol |
		aSymbolListDictionaryForwarder
			ucfwat: aSymbol
			put: (oldUG ucfwat: aSymbol).].
	aSymbolListDictionaryForwarderList
		at: (aSymbolListDictionaryForwarderList identityIndexOf: oldUG)
		put: aSymbolListDictionaryForwarder.

{ #category : #'actions' }
GbxDbaUserBrain >> apply
	" I save all changes to the GemStone DB image. "
	"Note: The expected return value from here is questionable.
			Is nil expected, or should it always be self? Original behavior
			of returning nil was maintained for now."

	| mode |
	self hasChanges
		ifFalse: 
			[self gbsMessenger warn: 'No changes!'.
			^nil].
	mode := (self hasUserNamed: self currentId)
				ifTrue: [#update]
				ifFalse: [self user hasChangedUserId ifTrue: [#rename] ifFalse: [#add]].
	^
	[#update == mode
		ifTrue: 
			[self confirmAdd
				ifTrue: [self updateUserInfo]
				ifFalse: 
					[self gbsMessenger warn: 'No updates applied'.
					hasChanges := false.
					^self]]
		ifFalse: 
			[#rename == mode
				ifTrue: 
					[(self tool password value isEmpty
						or: [self tool confirmPassword value isEmpty])
							ifTrue: 
								[self gbsMessenger warn: 'Password must be changed when user is renamed.'.
								^nil].
					self tool confirmPassword value ~= self tool password value
						ifTrue: 
							[self gbsMessenger warn: 'Passwords do not match.'.
							^nil].
					self updateRenamedUserInfo]
				ifFalse: [self addNewUserInfo]].
	self session commitTransaction.
	self]
			on: GbsError errorSignal
			do: 
				[:ex |
				self gbsMessenger
					warn: 'GemStone has disallowed this %1 for the following reason:\\%2'
					with: mode asString
					with: ex originator messageText.
				mode == #add
					ifTrue: 
						[| remoteUser |
						remoteUser := self session
									execute: 'self isNil ifFalse:[AllUsers userWithId: self ifAbsent:[]]'
									context: user newUserId.
						remoteUser = self session oopNil
							ifFalse: 
								[(self sessionForwarderFor: #AllUsers) gbxDelegate
									remotePerform: #removeAndCleanup:
									with: remoteUser]].
				ex return]

{ #category : #'actions' }
GbxDbaUserBrain >> updateUserCommonInfo
	" The user is saving changes to an existing UserProfile.  I must determine what has changed and apply the changes to the SmalltalkDB image. "

	self updateUserPasswordOk
		ifFalse: [^self gbsMessenger warn: 'Password not valid or does not match'].
	self updateUserPrivileges.
	self updateUserGroups.
	self updateDefaultSegment.
	tool updateAuthenticationSchemeFor: self user.
	self gbsMessenger warn: 'Changes saved.'.
	self hasChanges: false.
	self changeNotification: #dbaUserChanged

{ #category : #'actions' }
GbxDbaUserBrain >> renameUserId
	" I obtain the new User ID from the administrator. "

	| newUserId oldUserId |
	oldUserId := self user userId.
	(self session
		evaluate: 'UserProfile isSpecialUserId: ''' , oldUserId , '''')
			ifTrue: [self gbsMessenger warn: 'You cannot rename this privileged user.']
			ifFalse: 
				[newUserId := self gbsMessenger
							request: 'New name for user ''%1''?'
							with: self user userId
							default: self user userId.
				newUserId size = 0
					ifTrue: [self gbsMessenger warn: 'Not changed.']
					ifFalse: 
						[(self hasUserNamed: newUserId)
							ifTrue: 
								[self gbsMessenger warn: 'Not changed - ''%1'' already exists.'
									with: newUserId]
							ifFalse: 
								[self user newUserId: newUserId.
								self newId: newUserId.
								self gbsMessenger
									warn: 'User ID changed from ''%1'' to ''%2''.
** You must change the password **'
									with: oldUserId
									with: newUserId.
								self clearPassword.
								self hasChanges: true]]]

{ #category : #'actions' }
GbxDbaUserBrain >> updateUserInfo
	" The user is saving changes to an existing UserProfile.  I must determine what has changed and apply the changes to the SmalltalkDB image. "

	self updateUserCommonInfo

{ #category : #'actions' }
GbxDbaUserBrain >> addNewSymbolListsTo: aNewUserProfileForwarder
	" I must pass the user's new symbol list dictionaries to the new UserProfile in GemStone.
	  NOTE:  A newly-created UserProfile has two symbol list dictionaries named UserGlobals and Globals.  Globals is the same as my user's Globals, but I must add all of my user's UserGlobals entries to the new UserProfile.  The order of adding other symbol list dictionaries from my user is also tricky.
	  WARNING:  The #collect: block for currNames is sent to GemStone SmalltalkGS, so the parameter name must NOT have a space between it and the colon. "

	| addIndex currLists currNames newLists |

	currLists := aNewUserProfileForwarder ucfwsymbolList.
	newLists := self user newSymbDicts.
	self	moveUserGlobalsFrom: newLists
		to: (currLists ucfwat: 1).
	currNames := currLists ucfwasArray collect: [:aSymlListDictForwarder | aSymlListDictForwarder name ].
		" Note:  ucfwasArray avoids a 5.0 alpha 2 bug. "
	addIndex := 1.
	newLists do:
		[: aSymlListDictForwarder |
		(currNames includes: aSymlListDictForwarder name) ifFalse:
			[aNewUserProfileForwarder
				ucfwinsertDictionary: aSymlListDictForwarder
				at: addIndex.
			aSymlListDictForwarder ucfwassignToObjectSecurityPolicy: aNewUserProfileForwarder ucfwdefaultObjectSecurityPolicy.].
		addIndex := addIndex + 1.].

{ #category : #'actions' }
GbxDbaUserBrain >> showSegments

	GbxSegmentTool openOnSession: tool session

{ #category : #'actions' }
GbxDbaUserBrain >> removeGroup
	" Allow the user to delete the currently selected group. "

	self removeGroup: self currentGroupsSelection.
	self ableAddGroupButtons.

{ #category : #'actions' }
GbxDbaUserBrain >> updateUserPrivileges
	" The user is saving changes to an existing UserProfile.  I must determine what has changed and apply the changes to the SmalltalkDB image. "

	self user newPrivileges isNil ifTrue:
		[^ self ].
	self user newPrivileges asSortedCollection = self user basicPrivileges asSortedCollection ifTrue:
		[^ self ].
	self user remoteUserProfile ucfwprivileges: self user newPrivileges.

{ #category : #'actions' }
GbxDbaUserBrain >> clearPassword
	" Discard any changes made to the password. "

	self newPassword: String new.
	tool confirmPassword: String new.

{ #category : #'actions' }
GbxDbaUserBrain >> updateDataRequest
	" I allow external changes to refresh the current repository user. "

	self updateUserRequest.

{ #category : #'actions' }
GbxDbaUserBrain >> existingGroupChoices
	" Answer a sorted list of existing group names (excluding those already being used) for use in a menu. "

	| choices |

	choices := self allExistingGroupChoices.
	self currentGroups do:
		[: aGroupNameString |
		choices
			remove: aGroupNameString
			ifAbsent:  [].].
	^ choices asSortedCollection asArray

{ #category : #'actions' }
GbxDbaUserBrain >> ok
	" I save all changes to the GemStone DB image. "

	self apply.
	self windowInterface closeRequest.

{ #category : #'actions' }
GbxDbaUserBrain >> updateRenamedUserInfo
	" The user is saving changes to an existing UserProfile whose user ID is being changed.  I must determine what has changed and apply the changes to the SmalltalkDB image. "

	(self gbsMessenger
		confirm: 'Really update user %1 (changed from %2)?'
		with: self user userId asString
		with: self user gemStoneUserId)
	ifFalse: [^ self gbsMessenger warn: 'Not saved.' ].

	self updateUserId.
	self updateUserCommonInfo.
	self changeNotification: #dbaUserAdded.

{ #category : #'actions' }
GbxDbaUserBrain >> addNewGroup
	" Allow the user to specify the name for a new group. "

	| newName |

	newName := self gbsMessenger request: 'Enter group name'.
	(newName size = 0) ifTrue: [^ self].
	(self currentGroups includes: newName) ifTrue:
		[^ self gbsMessenger warn: 'You have already added group %1.' with: newName ].
	(self allExistingGroupChoices includes: newName) ifTrue: [
		(self gbsMessenger confirm: 'Group %1 already exists.\Add it anyway?' with: newName)
			ifFalse: [^ self ].
	].
	self addGroup: newName.
	self ableAddGroupButtons.

{ #category : #'actions' }
GbxDbaUserBrain >> validateName: sgmtName inDict: dictProxy withName: dictName
	"Verify that the given Security Policy name is a valid key for a segment in the given dictionary."

	| sgmtSymbolProxy |
	sgmtName = 'DefaultSegment'
		ifTrue: [^'The segment name ''DefaultSegment'' is reserved in the event of an unnamed default segment!'].
	(sgmtName beginsWith: 'Unnamed')
		ifTrue: [^'Segment names which start with ''Unnamed'' are reserved for unnamed segments!'].
	(dictProxy performOnGsServer: #includesKey:
		withArguments: (Array with: sgmtName asSymbol))
			ifTrue: [^'Dictionary ''' , dictName , ''' already includes an object named ''' , sgmtName , '''!'].
	sgmtSymbolProxy := self userProfileProxy
				remotePerform: #objectNamed:
				with: sgmtName asSymbol.
	(sgmtSymbolProxy performOnGsServer: #notNil)
		ifTrue: 
			[(self gbsMessenger
				confirm: 'The name ''%1'' is not unique within this session!\Do you still wish to use this name?'
				with: sgmtName) ifFalse: [^'']].
	^nil

{ #category : #'actions' }
GbxDbaUserBrain >> removeGroup: aGroupNameString
	" Remove aGroupNameString from the list of groups. "

	self
		newGroups: ((self currentGroups asSet)
				remove: aGroupNameString;
				yourself) asSortedCollection
				asArray.
	self hasChanges: true.
	tool disableButtons: self

{ #category : #'actions' }
GbxDbaUserBrain >> updateUserId
	" The user is saving changes to an existing UserProfile.  I must determine what has changed and apply the changes to the SmalltalkDB image. "

	self user resetCachedUserId.
	self user remoteUserProfile
		performOnGsServer: #userId:password:
		withArguments: (Array
			with: self user userId
			with: self tool password value)

{ #category : #'actions' }
GbxDbaUserBrain >> allExistingGroupChoices
	" Answer a set of all possible existing group names for use in a menu. "

	| allGroups choices |
	allGroups := self session resolveSymbol: #AllGroups.
	choices := allGroups performOnGsServer: #asArray.
	choices := (choices collect: [:ea | ea asSymbol]) asSet.
	choices addAll: self currentGroups.
	^choices

{ #category : #'actions' }
GbxDbaUserBrain >> showPrivileges
	" Spawn a window that shows the privilege for this user. "

	GbxDbaUserPrivilegesBrowser dialogOnBrowser: self windowInterface.

{ #category : #'actions' }
GbxDbaUserBrain >> updateUserPasswordOk
	"Determine if the password has changed, and if so, apply it to the SmalltalkDB image.
	 Answer false if the change fails in any way. The #cleanupPasswordString: send was
	 added to fix BUG18321--DBStrings when changing GS password cause problems."

	| oldPassword remoteUser newPassword |
	tool confirmPasswordMatch ifFalse: [^false].
	newPassword := self cleanupPasswordString: self currentPassword.
	newPassword isEmpty ifTrue: [^true].	" no change "
	self user isNewUser ifTrue: [^true].
	remoteUser := self user remoteUserProfile.
	(remoteUser validatePassword: newPassword) ifTrue: [^true].	" same password, so no real change "
	remoteUser asGSObject = ((self sessionForwarderFor: #System) asGSObject remotePerform: #myUserProfile)
		ifFalse: 
			[" We are changing the password of some other user - if we have permission. "
			remoteUser ucfwpassword: newPassword.
			^true].
	oldPassword := self cleanupPasswordString: (self passwordRequest: 'Old Password?').
	oldPassword isEmpty
		ifTrue: 
			[self gbsMessenger warn: 'Operation cancelled.'.
			^false].
	(remoteUser validatePassword: oldPassword)
		ifFalse: 
			[self gbsMessenger warn: 'Wrong password - operation cancelled.'.
			^false].
	remoteUser ucfwoldPassword: oldPassword newPassword: newPassword.
	^true

{ #category : #'actions' }
GbxDbaUserBrain >> createSecurityPolicy: securityPolicyName
	"Create a new Object Security Policy with the given name in the given dictionary."

	| dictProxy securityPolicyProxy sgmtHldr symDictClassProxy dictSecurityPolicyProxy result dictName |
	dictName := self session evaluate: 'self name'
				context: self session defaultDictionary.
	(securityPolicyName isEmpty or: [dictName isEmpty])
		ifTrue: [^'The Object Security Policy and dictionary must be named!'].
	dictProxy := self userProfileProxy remotePerform: #objectNamed:
				with: dictName asSymbol.
	symDictClassProxy := self session resolveSymbol: #SymbolDictionary.
	((dictProxy performOnGsServer: #isNil) or: 
			[(dictProxy performOnGsServer: #isKindOf:
				withArguments: (Array with: symDictClassProxy)) not])
		ifTrue: 
			[^'There is no dictionary named ''' , dictName
				, ''' in this GemStone session!'].
	dictSecurityPolicyProxy := dictProxy remotePerform: #objectSecurityPolicy.
	dictSecurityPolicyProxy = Onil
		ifFalse: 
			[(dictSecurityPolicyProxy performOnGsServer: #currentUserCanWrite)
				ifFalse: 
					[^'You do not have write authorization for dictionary ''' , dictName
						, '''!']].
	result := self
				validateName: securityPolicyName
				inDict: dictProxy
				withName: dictName.
	result notNil
		ifTrue: 
			[result isEmpty ifTrue: [result := 'Object Security Policy not created!'].
			^result].
	securityPolicyProxy := (self session resolveSymbol: #GsObjectSecurityPolicy) remotePerform: #new.
	securityPolicyProxy remotePerform: #worldAuthorization: with: #read.
	dictProxy
		remotePerform: #at:put:
		with: securityPolicyName asSymbol
		with: securityPolicyProxy.
	sgmtHldr := GbxSegmentHolder
				newWithSgmt: securityPolicyProxy
				name: securityPolicyName asSymbol
				dict: dictProxy.
	self allSegments add: sgmtHldr.
	^sgmtHldr segmentProxy	"just return the delegate"

{ #category : #'actions' }
GbxDbaUserBrain >> updateDefaultSegment
	" I must determine if the Default Object Security Policy has changed and, if so, apply the changes to the SmalltalkDB image. "

	| value |
	value := self user newDefaultSegment.
	value = self user remoteUserProfile ucfwdefaultObjectSecurityPolicy gbxDelegate
		ifTrue: [^self].
	[self user remoteUserProfile ucfwdefaultObjectSecurityPolicy: value]
		on: GbsError errorSignal
		do: 
			[:ex |
			self gbsMessenger
				warn: 'You (as User ID %1) do not have authority\to update this user''s default object security policy.\\%2'
				with: self session parameters username
				with: ex originator messageText.
			ex return]

{ #category : #'actions' }
GbxDbaUserBrain >> abortTransaction
	" Allow the user to discard all changes made in the current transaction. "

	super abortTransaction.
	self updateUserRequest.

{ #category : #'actions' }
GbxDbaUserBrain >> userGroupSelected
	" When no group is selected, certain buttons must be disabled. "

	self isUserGroupSelected
		ifTrue:
			[self enableButtons.]
		ifFalse:
			[self disableButtons.].

{ #category : #'actions' }
GbxDbaUserBrain >> updateUserGroups
	" I must determine if any entries is the group list have changed, and if so, apply those changes to the SmalltalkDB image. "

	| newGroups oldGroups |
	newGroups := self currentGroups asSet.
	oldGroups := self user groups asSet.
	newGroups - oldGroups
		do: [:aNewGroupName | self addGroupNamed: aNewGroupName].
	oldGroups - newGroups do: 
			[:aDeletedGroupName |
			(self tool session evaluate: 'AllGroups includes: self'
				context: aDeletedGroupName)
					ifTrue: 
						[self user remoteUserProfile gbxDelegate remotePerform: #removeGroup:
							with: aDeletedGroupName]]

{ #category : #'actions' }
GbxDbaUserBrain >> addGroup: aGroupNameString
	" Add aGroupNameString to the list of groups. "

	(self session evaluate: '(AllGroups at: self ifAbsent:[]) isNil'
		context: aGroupNameString asSymbol)
			ifTrue: 
				[self session
					execute: 'AllGroups at: self  put: (UserProfileGroup groupWithName: self ifAbsent:[UserProfileGroup newGroupWithName: self])'
					context: aGroupNameString asSymbol].
	self
		newGroups: ((self currentGroups asSet)
				add: aGroupNameString;
				yourself) asSortedCollection
				asList.
	self hasChanges: true

{ #category : #'actions' }
GbxDbaUserBrain >> pasteSegment
	" I make the GemStone Object Security Policy in the paste buffer the security policy for my GemStone user profile. "

	| segment |

	segment := GbxClipboardObj
		getObjectForSession: self session
		context: #Segment
		quietly: true.
	self user newDefaultSegment: segment.
	self hasChanges: true.
	self gbsMessenger warn: 'Pasted.'.

{ #category : #'actions' }
GbxDbaUserBrain >> addNewUserInfo
	" The user is saving changes to a new UserProfile.  I must pass all data to the SmalltalkDB image. "

	| defaultOSP newGsUser |
	self hasValidNewUserInfo ifFalse: [^self gbsMessenger warn: 'Not saved.'].
	self confirmAdd ifFalse: [^self gbsMessenger warn: 'Not saved.'].
	tool confirmPasswordMatch
		ifFalse: [^self gbsMessenger warn: 'Passwords do not match.'].
	(self gbsMessenger
		confirm: 'This will commit the current transaction.\Do you want to continue?')
			ifFalse: [^self gbsMessenger warn: 'User not added.']
			ifTrue: 
				[self session commitTransaction.	"temporary Object Security Policies must be committed first."
				defaultOSP := self user newDefaultSegment].
	newGsUser := (self sessionForwarderFor: #UserProfile)
				ucfwnewWithUserId: self currentId
				password: self currentPassword
				defaultObjectSecurityPolicy: defaultOSP
				privileges: self user privileges
				inGroups: self currentGroups asArray.
	(self user newDefaultSegment notNil and: 
			[(self user newDefaultSegment remotePerform: #owner) == ONil	"do not change existing owner"])
		ifTrue: [defaultOSP asForwarder ucfwowner: newGsUser].
	tool updateLanguageFor: newGsUser brain: self.
	tool updateAuthenticationSchemeFor: newGsUser.
	self addNewSymbolListsTo: newGsUser.
	self hasChanges: false.
	self gbsMessenger warn: 'User %1 added.' with: self currentId.
	self userIdChange.
	self changeNotification: #dbaUserAdded.
	^newGsUser

{ #category : #'actions' }
GbxDbaUserBrain >> selectSegment

	| segments segment seg |
	segments := self allSegments.
	segment := self gbsMessenger
				choose: tool segmentDialogString
				fromList: (segments collect: [:ea | ea segmentName asString])
				values: segments
				lines: 10
				cancel: [nil].
	^segment isNil
		ifTrue: 
			[(self gbsMessenger confirm: 'None selected. Would you like to create new?')
				ifTrue: 
					[self user newDefaultSegment: (seg := self user defaultSegment).
					seg]
				ifFalse: [nil]]
		ifFalse: [segment segmentProxy]

{ #category : #'actions' }
GbxDbaUserBrain >> updateUserLanguage
	" The user is saving changes to an existing UserProfile.  I must determine what has changed and apply the changes to the SmalltalkDB image. "

	| value |

	value := self currentLanguage.
	value asString = self user language asString ifTrue:
		[^ self ].
	self user remoteUserProfile ucfwnativeLanguage: value asSymbol.

{ #category : #'actions' }
GbxDbaUserBrain >> confirmAdd

	^tool confirmAdd: self

{ #category : #'window changing' }
GbxDbaUserBrain >> disableOtherFields
	" Certain fields must be disabled when no user ID is present. "

	self enableOtherFields: false.

{ #category : #'window changing' }
GbxDbaUserBrain >> enableOtherFields: anEnableBoolean
	" Certain of my window's fields must be enabled or disabled, depending on whether a user ID is present. "

	self windowInterface enableOtherFields: anEnableBoolean.

{ #category : #'window changing' }
GbxDbaUserBrain >> ablePasteSegmentButton
	" Activate or deactivate the 'Paste To Default Segment' button.
	  NOTE:  To be VW / VS compatible, button names must start with an uppercase letter.
	  WARNING:  Do not use # within array declarations. "

	self hasCompatiblePasteBuffer
		ifTrue:
			[self enableGroup: #( PasteSegmentButton ).]
		ifFalse:
			[self disableGroup: #( PasteSegmentButton ).].

{ #category : #'window changing' }
GbxDbaUserBrain >> updateAllData
	" I have switched to a new user, so I must update all data that shows in my window. "

	self clearPassword.
	self newLanguage: self user language.
	self newGroupsSelection: nil.
	self newGroups: self user groups.
	self disableButtons.
	self disableSaveButtons.
	self hasChanges: false.
	tool ableAddGroupButtons: self

{ #category : #'window changing' }
GbxDbaUserBrain >> ableAddGroupButtons
	" Activate or deactivate the Add... button.
	  NOTE:  To be VW / VS compatible, button names must start with an uppercase letter.
	  WARNING:  Do not use # within array declarations. "

	self existingGroupChoices isEmpty | self user userId isEmpty
		ifTrue:
			[self disableGroup: #( AddExistingGroupButton ).]
		ifFalse:
			[self enableGroup: #( AddExistingGroupButton ).].

{ #category : #'window changing' }
GbxDbaUserBrain >> enableSaveButtons
	" Activate certain buttons after the user has made changes.
	  NOTE:  To be VW / VS compatible, button names must start with an uppercase letter.
	  WARNING:  Do not use # within array declarations. "

	self enableGroup: #( OkButton  ApplyButton ).

{ #category : #'window changing' }
GbxDbaUserBrain >> enableOtherFields
	" Certain fields must be enabled when a user ID is present. "

	self enableOtherFields: true.

{ #category : #'window changing' }
GbxDbaUserBrain >> enableUserButtons
	" Activate the default buttons when a user ID has been specified.
	  NOTE:  To be VW / VS compatible, button names must start with an uppercase letter.
	  WARNING:  Do not use # within array declarations. "

	tool enableUserButtons

{ #category : #'window changing' }
GbxDbaUserBrain >> disableButtons
	" Deactivate certain buttons until a user is selected."

	tool disableGroup: self

{ #category : #'window changing' }
GbxDbaUserBrain >> disableSaveButtons
	" Deactivate certain buttons until the user has made changes.
	  NOTE:  To be VW / VS compatible, button names must start with an uppercase letter.
	  WARNING:  Do not use # within array declarations. "

	self disableGroup: #( OkButton  ApplyButton ).

{ #category : #'window changing' }
GbxDbaUserBrain >> enableButtons
	" Activate certain buttons while a user is selected.
	  NOTE:  To be VW / VS compatible, button names must start with an uppercase letter.
	  WARNING:  Do not use # within array declarations. "

	self enableGroup: #( RemoveGroupButton ).

{ #category : #'interface opening' }
GbxDbaUserBrain >> postBuild
	" I take any additional action after the builder has completed work on my window. "

	super postBuild.
	self currentId isEmpty
		ifTrue: [self disableOtherFields]
		ifFalse: 
			[self enableOtherFields.
			self enableUserButtons].
	tool enablePasteButton

{ #category : #'external changing' }
GbxDbaUserBrain >> updateNotification: aSymbol
	" Some other DBA window has changed something.  I may have to update my user ID menu or my information. "

	#clipboardChange == aSymbol ifTrue:
		[self ablePasteSegmentButton.].
	super updateNotification: aSymbol.

{ #category : #'updating' }
GbxDbaUserBrain >> update: anAspectSymbol
with: aParameter
	" Receive a change notice from an object of whom the receiver is a dependent.  The argument anAspectSymbol is typically a Symbol that indicates what change has occurred. "

	super update: anAspectSymbol.
	#dbaUserChanged == anAspectSymbol ifTrue:
		[(self user notNil and: [self user userId = aParameter]) ifTrue:
			[self discardChanges ifTrue:
				[self hasChanges: false.
				self userIdChange.].].].

{ #category : #'updating' }
GbxDbaUserBrain >> hasChanges: aBoolean
	" Enable certain buttons if the user has done anything that needs to be saved. "

	super hasChanges: aBoolean.
	self hasChanges
		ifTrue:
			[self enableSaveButtons.]
		ifFalse:
			[self disableSaveButtons.].

{ #category : #'updating' }
GbxDbaUserBrain >> newPrivileges: anArray
	" Save the array of symbols identifying this user's privileges on GemStone. "

	self user newPrivileges: anArray.
	self hasChanges: true.

{ #category : #'updating' }
GbxDbaUserBrain >> user: aGSUserProfileHolder
	" Set the value of user, the GSUserProfileHolder whose information shows in my window. "

	user := aGSUserProfileHolder.

