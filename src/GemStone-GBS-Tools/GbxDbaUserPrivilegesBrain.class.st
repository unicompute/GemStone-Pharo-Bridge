Class {
	#name : 'GbxDbaUserPrivilegesBrain',
	#superclass : 'GbxDbaBrain',
	#instVars : [
		'privileges',
		'userBrowser',
		'validPrivileges'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'updating' }
GbxDbaUserPrivilegesBrain >> userBrowser: aGSDbaUserBrowser
[
	" Set the value of userBrowser, the GSDbaUserBrowser from which I was spawned. "

	userBrowser := aGSDbaUserBrowser.
]

{ #category : 'accessing' }
GbxDbaUserPrivilegesBrain >> privilegeValueFor: aPrivilegeSymbol
[
	" Answer true if this user has the privilege specified by aPrivilegeSymbol.
	  NOTE:  As an aside, we also make sure that aPrivilegeSymbol is valid. "

	(self validPrivileges includes: aPrivilegeSymbol) ifFalse:
		[^ self error: 'bad privilege symbol' ].
	^ self privileges includes: aPrivilegeSymbol
]

{ #category : 'accessing' }
GbxDbaUserPrivilegesBrain >> privileges
[
	" Answer the value of privileges, a list of symbols desribing the privileges of my user. "

	privileges isNil ifTrue:
		[privileges := self userBrowser user privileges.].
	^ privileges
]

{ #category : 'accessing' }
GbxDbaUserPrivilegesBrain >> checkBoxValueSymbols
[
	" Answer a list of symbols used to obtain values for check box parts."

	^self session evaluate: 'PrivilegeNames' context: OUserProfile
]

{ #category : 'accessing' }
GbxDbaUserPrivilegesBrain >> validPrivileges
[
	" Answer the value of validPrivileges, a list of all valid symbols desribing the privileges. "

	validPrivileges isNil ifTrue:
		[validPrivileges := (self sessionForwarderFor: #UserProfile) ucfw_classVars
			at: #PrivilegeNames.
		validPrivileges := validPrivileges reject:
			[: aSymb | #ReservedForFutureUse == aSymb].].
	^ validPrivileges
]

{ #category : 'accessing' }
GbxDbaUserPrivilegesBrain >> session
[
	" Answer the value of userBrowser's session, which is the GSSession that I must user.
	  NOTE:  During initialization, I will not have a userBrowser yet. "

	^ self userBrowser isNil
		ifTrue: [super session]
		ifFalse: [self userBrowser session]
]

{ #category : 'accessing' }
GbxDbaUserPrivilegesBrain >> userBrowser
[
	" Answer the value of userBrowser, the GSDbaUserBrowser from which I was spawned. "

	^ userBrowser
]

{ #category : 'actions' }
GbxDbaUserPrivilegesBrain >> accept
[
	" Save any changes that the user has made to these privileges. "

	self ok.
]

{ #category : 'actions' }
GbxDbaUserPrivilegesBrain >> ok
[
	" Save any changes that the user has made to these privileges. "

	| newPrivileges |
	self hasChanges ifFalse: [^self closeRequest].
	newPrivileges := OrderedCollection new.
	self checkBoxValueSymbols do: 
			[:aCheckBoxValueSymbol | 
			(self windowInterface booleanFor: aCheckBoxValueSymbol) 
				ifTrue: [newPrivileges add: aCheckBoxValueSymbol]].
	self userBrowser brain newPrivileges: newPrivileges asArray.
	self hasChanges: false.
	self windowInterface closeRequest
]

{ #category : 'changing' }
GbxDbaUserPrivilegesBrain >> markHasChanges
[
	" The user has clicked one of my radio buttons. "

	self hasChanges: true.
]

