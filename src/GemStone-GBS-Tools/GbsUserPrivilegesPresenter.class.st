Class {
	#name : 'GbsUserPrivilegesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'userName',
		'privileges',
		'onAcceptBlock',
		'checkContainer',
		'checkBoxesByName',
		'saveButton',
		'cancelButton'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsUserPrivilegesPresenter class >> openForUser: aUserName initialPrivileges: aDictionary onAccept: aBlock [
	| presenter |
	presenter := self new.
	presenter
		userName: aUserName;
		privileges: aDictionary;
		onAcceptBlock: aBlock;
		open.
	^ presenter
]

{ #category : 'accessing' }
GbsUserPrivilegesPresenter >> userName: aString [
	userName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsUserPrivilegesPresenter >> privileges: aDictionary [
	privileges := (aDictionary ifNil: [ Dictionary new ]) copy
]

{ #category : 'accessing' }
GbsUserPrivilegesPresenter >> onAcceptBlock: aBlock [
	onAcceptBlock := aBlock
]

{ #category : 'initialization' }
GbsUserPrivilegesPresenter >> initializePresenters [
	checkContainer := SpBoxLayout newTopToBottom.
	checkBoxesByName := Dictionary new.
	saveButton := self newButton
		label: 'OK';
		icon: (self iconNamed: #smallOk);
		action: [ self acceptChanges ];
		yourself.
	cancelButton := self newButton
		label: 'Cancel';
		icon: (self iconNamed: #smallCancel);
		action: [ self closeWindow ];
		yourself
]

{ #category : 'initialization' }
GbsUserPrivilegesPresenter >> connectPresenters [
	privileges ifNil: [ privileges := Dictionary new ].
	self rebuildChecksFromPrivileges
]

{ #category : 'layout' }
GbsUserPrivilegesPresenter >> defaultLayout [
	| buttonsRow |
	buttonsRow := SpBoxLayout newLeftToRight
		add: (self newLabel label: '');
		add: saveButton expand: false;
		add: cancelButton expand: false;
		spacing: 8;
		yourself.
	^ SpBoxLayout newTopToBottom
		add: checkContainer;
		add: buttonsRow expand: false;
		spacing: 8;
		yourself
]

{ #category : 'initialization' }
GbsUserPrivilegesPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'Privileges';
		initialExtent: 360 @ 760
]

{ #category : 'private' }
GbsUserPrivilegesPresenter >> rebuildChecksFromPrivileges [
	| orderedNames |
	checkContainer ifNil: [ checkContainer := SpBoxLayout newTopToBottom ].
	(checkContainer respondsTo: #removeAll) ifTrue: [ checkContainer removeAll ].
	privileges ifNil: [ privileges := Dictionary new ].
	checkBoxesByName := Dictionary new.
	orderedNames := self orderedPrivilegeNames.
	orderedNames do: [ :privName |
		| check |
		check := self newCheckBox label: privName asString.
		check state: ((privileges at: privName ifAbsent: [ false ]) == true).
		checkContainer add: check expand: false.
		checkBoxesByName at: privName put: check ].
	checkContainer spacing: 6
]

{ #category : 'private' }
GbsUserPrivilegesPresenter >> currentPrivilegesDictionary [
	| dict |
	dict := Dictionary new.
	checkBoxesByName keysAndValuesDo: [ :k :check |
		dict at: k put: (check state == true) ].
	^ dict
]

{ #category : 'private' }
GbsUserPrivilegesPresenter >> orderedPrivilegeNames [
	^ #(
		SystemControl
		ObsoleteStatistics
		SessionAccess
		UserPassword
		DefaultObjectSecurityPolicy
		PrivUnused5
		OtherPassword
		ObjectSecurityPolicyCreation
		ObjectSecurityPolicyProtection
		FileControl
		GarbageCollection
		CodeModification
		NoPerformOnServer
		NoUserAction
		NoGsFileOnServer
		NoGsFileOnClient
		SessionPriority
		CompilePrimitives
		ChangeUserId
		MigrateObjects
		DisableObjectReadLogging
		DynamicDisableObjectReadLogging
		ReadOtherUserProfile
		CreateOnetimePassword
		DataCurator
		SystemUser
		HostAgentUser
		SymbolUser
		Nameless
		GcUser
	)
]

{ #category : 'actions' }
GbsUserPrivilegesPresenter >> acceptChanges [
	| updated |
	updated := self currentPrivilegesDictionary.
	onAcceptBlock ifNotNil: [ onAcceptBlock cull: updated ].
	self closeWindow
]

{ #category : 'actions' }
GbsUserPrivilegesPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]
