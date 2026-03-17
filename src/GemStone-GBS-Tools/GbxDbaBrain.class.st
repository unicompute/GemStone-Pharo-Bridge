Class {
	#name : #'GbxDbaBrain',
	#superclass : #'GbxAdminToolsBrain',
	#instVars : [ #'hasChanges' #'allUsersForwarder' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Tools'
}

{ #category : #'accessing' }
GbxDbaBrain >> defaultSecurityPolicyChoices

	^((self allSegments collect: [:ea | ea segmentName]) asSortedCollection)
		add: #nil;
		yourself

{ #category : #'accessing' }
GbxDbaBrain >> allUsers
	" Answer the value of allUsers, which contains a reference to #AllUsers in GemStone. "

	(allUsersForwarder isNil or: [allUsersForwarder gbxIsGSDefunct]) ifTrue:
		[allUsersForwarder := self sessionForwarderFor: #AllUsers.].
	^ allUsersForwarder

{ #category : #'accessing' }
GbxDbaBrain >> allUserIds
	" Answer a list of userId strings from the UserProfiles in AllUsers. "

	self showBusyWhile: 
			[^tool session evaluate: 'AllUsers collect:[:ea | ea userId asString]']

{ #category : #'accessing' }
GbxDbaBrain >> allGroups
	" Answer a list of GbxGroupHolders for the groups named in GemStone's AllGroups global. "

	| allGrps list |
	self showBusyWhile: 
			[list := OrderedCollection new.
			allGrps := (self session resolveSymbol: #AllGroups) performOnGsServer: #asArray.
			allGrps do: [:aGroupNameString | list add: (GbxGroupHolder newWithGrp: aGroupNameString users: self allUsers)].
			^list]

{ #category : #'accessing' }
GbxDbaBrain >> sessionForwarderFor: aSymbol
	" Answer an UNCACHED forwarder for the object whose name is aSymbol in the current session. "

	^ self session
		uncachedForwarderAt: aSymbol
		ifAbsent: [self error: aSymbol printString , ' not defined']

{ #category : #'accessing' }
GbxDbaBrain >> userForwarderFor: aSymbol
	" Answer an UNCACHED forwarder for the object whose name is aSymbol in the current user. "

	^ self user userForwarderFor: aSymbol

{ #category : #'accessing' }
GbxDbaBrain >> userNamed: aNameString 
	" Answer the UserProfile from AllUsers whose name matches aNameString.
	  Answer nil if no such user exists. "

	| result |
	aNameString isEmpty ifTrue: [^nil].
	self showBusyWhile: 
			[result := self session 
						execute: 'AllUsers userWithId: ' , aNameString printString 
								, ' ifAbsent: [ nil ]'.
			^result = self session oopNil ifTrue: [nil] ifFalse: [result asForwarder]]

{ #category : #'accessing' }
GbxDbaBrain >> discardChanges
	" Answer false if the user has made changes and wants to keep them. "

	^ self discardChanges: false

{ #category : #'accessing' }
GbxDbaBrain >> userNameChoices
	" Answer a list of user IDs for use in a menu. "

	^self session evaluate: 
			'| list nextUser |
			list := AllUsers collect: [:each | each userId asString].
			list asSortedCollection asArray'.

{ #category : #'accessing' }
GbxDbaBrain >> hasChanges
	" Answer the value of hasChanges, which is true if the user has done anything that needs to be saved. "

	hasChanges isNil ifTrue:
		[hasChanges := false.].
	^ hasChanges

{ #category : #'testing' }
GbxDbaBrain >> discardChanges: aMarkBoolean
	" Answer false if the user has made changes and wants to keep them.  If aMarkBoolean is true, I must give the user a visual indication of which window I am. "

	self hasChanges ifFalse: [^ true].
	^self gbsMessenger confirm: 'Discard changes?'

	"The code that propagated the aMarkBoolean was removed. This was the only sender of
	 code to select the default dialog button. It was already a no-op for VA. The VW code
	 was fragile. Therefore, it was removed as of GbsAdminToolsVW 51.6"

{ #category : #'testing' }
GbxDbaBrain >> hasUserNamed: aNameString
	" Answer true if AllUsers contains a UserProfile whose name matches aNameString. "

	^ (self userNamed: aNameString) notNil

{ #category : #'private' }
GbxDbaBrain >> checkWildcardIn: aString
for: aList
ifNoMatch: anExitBlock
	" Answer a string selected by the user from a menu of matching items in aList if the user has typed a wildcard selection in aString.  If no matches are found, I evaluate anExitBlock. "

	^ self
		checkWildcardIn: aString
		for: aList
		title: ''
		ifNoMatch: anExitBlock

{ #category : #'private' }
GbxDbaBrain >> checkWildcardIn: aString
for: aList
title: aTitleString
ifNoMatch: anExitBlock
	" Answer a string selected by the user from a menu of matching items in aList if the user has typed a wildcard selection in aString.  If no matches are found, I evaluate anExitBlock.
	NOTE:  Answer aString if the user has not typed a wildcard selection. "

	| choiceIndex matchList |

	matchList := OrderedCollection new.
	aList do:
		[: anObjectHolder |
		(aString match: anObjectHolder displayString) ifTrue:
			[matchList add: anObjectHolder displayString.].].
	matchList isEmpty ifTrue:
		[^ anExitBlock value ].
	matchList size = 1 & aTitleString isEmpty ifTrue:
		[^ matchList first asString ].
	aTitleString isEmpty ifFalse:
		[matchList addFirst: aTitleString.].
	choiceIndex := self choiceIndexFromMenuArray: matchList.
	choiceIndex isNil ifTrue:
		[^ anExitBlock value ].
	^ (matchList at: choiceIndex) asString

{ #category : #'private' }
GbxDbaBrain >> checkWildcardInUserId: aString
ifMatch: aOneArgMatchBlock
ifNoMatch: anExitBlock
	" If the user has typed a wildcard user ID selection in aString, I present a menu of matching user IDs. "

	| chosenName |

	chosenName := self
		checkWildcardIn: aString
		for: self allUserIds
		ifNoMatch: [^ anExitBlock value ].
	^ aOneArgMatchBlock value: chosenName

{ #category : #'window accessing' }
GbxDbaBrain >> newUserListSelection: aGSUserProfileHolder
	" I change the current selection of my window's user list. "

	self windowInterface newUserListSelection: aGSUserProfileHolder.

{ #category : #'window accessing' }
GbxDbaBrain >> passwordRequest: aMessageString
	" Answer a password (string) obtained from the user. "

	^ self windowInterface passwordRequest: aMessageString

{ #category : #'window accessing' }
GbxDbaBrain >> choiceIndexFromMenuArray: aList
	" Answer an index into aList, as specified by the user from a menu.
	  Answer nil if no entry is chosen. "

	^ self windowInterface choiceIndexFromMenuArray: aList

{ #category : #'actions' }
GbxDbaBrain >> abortTransaction
	" Allow the user to discard all changes made in the current transaction.
	  Answer true if the user aborted, or false if the abort was cancelled.
	  NOTE:  The current list of users may not be valid after the abort. "

	allUsersForwarder := nil.
	super abortTransaction.

{ #category : #'actions' }
GbxDbaBrain >> closeRequest
	" Answer true if I may close my window without loosing any changes (or if the user doesn't care). "

	^ self discardChanges

{ #category : #'window changing' }
GbxDbaBrain >> able: anEnableBoolean
components: idList

	self windowInterface
		able: anEnableBoolean
		components: idList.

{ #category : #'window changing' }
GbxDbaBrain >> disableGroup: idList

	self able: false components: idList

{ #category : #'window changing' }
GbxDbaBrain >> displayStatus: aString
	" Show the specified message to the user while he/she is waiting. "

	self windowInterface displayStatus: aString.

{ #category : #'window changing' }
GbxDbaBrain >> enableGroup: idList

	self able: true components: idList

{ #category : #'updating' }
GbxDbaBrain >> updateRequest: aspect
	" The session I am attached to wants to do something.  Return a boolean granting or denying request.
	WARNING:  Do NOT use # in the array declaration. "

	( #( queryAbort  queryCommit queryEndSession ) includes: aspect) ifFalse:
		[^ true ].
	^ self discardChanges: true

{ #category : #'updating' }
GbxDbaBrain >> hasChanges: aBoolean
	" Set the value of hasChanges, which is true if the user has done anything that needs to be saved. "

	hasChanges := aBoolean.

{ #category : #'external changing' }
GbxDbaBrain class >> myUserIDMenuNotificationSymbols
	" Answer a list of symbols that mean I have to update my user ID menu list.
	  WARNING:  For VW / VS compatibility, do not user '#' before each symbol. "

	^ #( aborted  dbaUserAdded  dbaUserDeleted )

