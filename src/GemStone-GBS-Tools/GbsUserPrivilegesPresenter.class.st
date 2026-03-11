Class {
	#name : 'GbsUserPrivilegesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'userName',
		'privileges',
		'onAcceptBlock',
		'headerLabel',
		'dataCuratorCheck',
		'systemUserCheck',
		'hostAgentUserCheck',
		'symbolUserCheck',
		'namelessCheck',
		'gcUserCheck',
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
	headerLabel := self newLabel.
	dataCuratorCheck := self newCheckBox label: 'DataCurator'.
	systemUserCheck := self newCheckBox label: 'SystemUser'.
	hostAgentUserCheck := self newCheckBox label: 'HostAgentUser'.
	symbolUserCheck := self newCheckBox label: 'SymbolUser'.
	namelessCheck := self newCheckBox label: 'Nameless'.
	gcUserCheck := self newCheckBox label: 'GcUser'.
	saveButton := self newButton
		label: 'Save';
		icon: (self iconNamed: #smallOk);
		action: [ self acceptChanges ];
		yourself.
	cancelButton := self newButton
		label: 'Close';
		icon: (self iconNamed: #smallCancel);
		action: [ self closeWindow ];
		yourself
]

{ #category : 'initialization' }
GbsUserPrivilegesPresenter >> connectPresenters [
	headerLabel label: 'User ID: ', userName.
	self loadFromPrivileges
]

{ #category : 'layout' }
GbsUserPrivilegesPresenter >> defaultLayout [
	| checksRow buttonsRow |
	checksRow := SpBoxLayout newTopToBottom
		add: dataCuratorCheck expand: false;
		add: systemUserCheck expand: false;
		add: hostAgentUserCheck expand: false;
		add: symbolUserCheck expand: false;
		add: namelessCheck expand: false;
		add: gcUserCheck expand: false;
		spacing: 6;
		yourself.
	buttonsRow := SpBoxLayout newLeftToRight
		add: saveButton expand: false;
		add: cancelButton expand: false;
		spacing: 8;
		yourself.
	^ SpBoxLayout newTopToBottom
		add: headerLabel expand: false;
		add: checksRow;
		add: buttonsRow expand: false;
		spacing: 8;
		yourself
]

{ #category : 'initialization' }
GbsUserPrivilegesPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone User Privileges';
		initialExtent: 420 @ 300
]

{ #category : 'private' }
GbsUserPrivilegesPresenter >> loadFromPrivileges [
	self setCheck: dataCuratorCheck from: #DataCurator.
	self setCheck: systemUserCheck from: #SystemUser.
	self setCheck: hostAgentUserCheck from: #HostAgentUser.
	self setCheck: symbolUserCheck from: #SymbolUser.
	self setCheck: namelessCheck from: #Nameless.
	self setCheck: gcUserCheck from: #GcUser
]

{ #category : 'private' }
GbsUserPrivilegesPresenter >> setCheck: aCheck from: aKey [
	aCheck state: ((privileges at: aKey ifAbsent: [ false ]) == true)
]

{ #category : 'private' }
GbsUserPrivilegesPresenter >> currentPrivilegesDictionary [
	^ Dictionary newFrom: {
		#DataCurator -> (dataCuratorCheck state == true).
		#SystemUser -> (systemUserCheck state == true).
		#HostAgentUser -> (hostAgentUserCheck state == true).
		#SymbolUser -> (symbolUserCheck state == true).
		#Nameless -> (namelessCheck state == true).
		#GcUser -> (gcUserCheck state == true)
	}
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
