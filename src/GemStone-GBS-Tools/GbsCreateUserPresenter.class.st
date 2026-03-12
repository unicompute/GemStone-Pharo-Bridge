Class {
	#name : 'GbsCreateUserPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'createdBlock',
		'pendingPrivileges',
		'mainMenu',
		'userField',
		'passwordField',
		'confirmPasswordField',
		'gemStoneAuthRadio',
		'unixAuthRadio',
		'ldapAuthRadio',
		'baseDnField',
		'filterDnField',
		'memberGroupsList',
		'availableGroupsList',
		'addGroupButton',
		'removeGroupButton',
		'newGroupField',
		'createGroupButton',
		'saveButton',
		'saveAndCommitButton',
		'closeButton',
		'privilegesButton',
		'symbolListButton',
		'securityPoliciesButton'
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

{ #category : 'initialization' }
GbsCreateUserPresenter >> initializePresenters [
	mainMenu := self buildMenuBar.

	userField := self newTextInput.
	passwordField := self newTextInput bePassword.
	confirmPasswordField := self newTextInput bePassword.
	gemStoneAuthRadio := self newRadioButton label: 'GemStone'.
	unixAuthRadio := self newRadioButton label: 'UNIX'.
	ldapAuthRadio := self newRadioButton label: 'LDAP'.
	baseDnField := self newTextInput.
	filterDnField := self newTextInput.

	memberGroupsList := self newList.
	memberGroupsList headerTitle: 'Is Member Of'.
	memberGroupsList display: [ :each | each asString ].
	availableGroupsList := self newList.
	availableGroupsList headerTitle: 'Available'.
	availableGroupsList display: [ :each | each asString ].

	addGroupButton := self newButton
		label: '<<';
		action: [ self addSelectedGroup ];
		yourself.
	removeGroupButton := self newButton
		label: '>>';
		action: [ self removeSelectedGroup ];
		yourself.

	newGroupField := self newTextInput.
	createGroupButton := self newButton
		label: 'Create';
		action: [ self createGroup ];
		yourself.

	privilegesButton := self newButton
		label: 'Privileges...';
		action: [ self editPrivileges ];
		yourself.
	symbolListButton := self newButton
		label: 'Symbol List...';
		action: [ self editSymbolList ];
		yourself.
	securityPoliciesButton := self newButton
		label: 'Object Security Policies ...';
		action: [ self editSecurityPolicies ];
		yourself.

	saveButton := self newButton
		label: 'Save';
		action: [ self saveUserCommit: false ];
		yourself.
	saveAndCommitButton := self newButton
		label: 'Save And Commit';
		action: [ self saveUserCommit: true ];
		yourself.
	closeButton := self newButton
		label: 'Close';
		action: [ self closeWindow ];
		yourself
]

{ #category : 'initialization' }
GbsCreateUserPresenter >> connectPresenters [
	self configureAuthRadioGroup.
	self wireAuthRadioEvents.
	gemStoneAuthRadio state: true.
	unixAuthRadio state: false.
	ldapAuthRadio state: false.
	baseDnField enabled: false.
	filterDnField enabled: false.
	pendingPrivileges := nil.
	self refreshGroups
]

{ #category : 'layout' }
GbsCreateUserPresenter >> defaultLayout [
	| credentialsPane authPane sideButtons sideAndAuthPane transferButtons groupLists groupsPane groupsButtons newGroupRow actionRow |
	credentialsPane := SpBoxLayout newTopToBottom
		add: (self textRowLabel: 'User ID' field: userField) expand: false;
		add: (self textRowLabel: 'Password' field: passwordField) expand: false;
		add: (self textRowLabel: 'Confirm Password' field: confirmPasswordField) expand: false;
		spacing: 4;
		yourself.

	authPane := SpBoxLayout newTopToBottom
		add: (self newLabel label: 'Authentication Method') expand: false;
		add: gemStoneAuthRadio expand: false;
		add: unixAuthRadio expand: false;
		add: ldapAuthRadio expand: false;
		add: (self textRowLabel: 'Base DN' field: baseDnField fieldWidth: self authFieldWidth) expand: false;
		add: (self textRowLabel: 'Filter DN' field: filterDnField fieldWidth: self authFieldWidth) expand: false;
		spacing: 4;
		yourself.

	sideButtons := SpBoxLayout newTopToBottom
		add: privilegesButton width: self sideButtonWidth;
		add: symbolListButton width: self sideButtonWidth;
		add: securityPoliciesButton width: self sideButtonWidth;
		spacing: 10;
		yourself.

	sideAndAuthPane := SpBoxLayout newLeftToRight
		add: sideButtons expand: false;
		add: authPane;
		spacing: 10;
		yourself.

	transferButtons := SpBoxLayout newTopToBottom
		add: (self newLabel label: '') expand: true;
		add: addGroupButton width: self transferButtonWidth;
		add: removeGroupButton width: self transferButtonWidth;
		add: (self newLabel label: '') expand: true;
		spacing: 10;
		yourself.

	groupLists := SpBoxLayout newLeftToRight
		add: memberGroupsList width: self groupListWidth;
		add: transferButtons expand: false;
		add: availableGroupsList width: self groupListWidth;
		spacing: 8;
		yourself.

	groupsPane := SpBoxLayout newTopToBottom
		add: (self newLabel label: 'Groups') expand: false;
		add: groupLists;
		spacing: 6;
		yourself.

	newGroupRow := SpBoxLayout newLeftToRight
		add: (self newLabel label: 'Name') width: self rowLabelWidth;
		add: newGroupField width: self newGroupFieldWidth;
		add: createGroupButton width: self createButtonWidth;
		spacing: 8;
		yourself.
	groupsButtons := SpBoxLayout newTopToBottom
		add: (self newLabel label: 'New Group') expand: false;
		add: newGroupRow expand: false;
		spacing: 6;
		yourself.

	actionRow := SpBoxLayout newLeftToRight
		add: saveButton width: self actionButtonWidth;
		add: saveAndCommitButton width: self actionButtonWidth;
		add: closeButton width: self actionButtonWidth;
		spacing: 10;
		yourself.

	^ SpBoxLayout newTopToBottom
		add: mainMenu expand: false;
		add: (self centeredPane: credentialsPane width: self contentWidth) expand: false;
		add: (self centeredPane: sideAndAuthPane width: self contentWidth) expand: false;
		add: (self centeredPane: groupsPane width: self contentWidth);
		add: (self centeredPane: groupsButtons width: self contentWidth) expand: false;
		add: (self centeredPane: actionRow width: self contentWidth) expand: false;
		spacing: 6;
		yourself
]

{ #category : 'layout' }
GbsCreateUserPresenter >> textRowLabel: labelString field: aField [
	^ self textRowLabel: labelString field: aField fieldWidth: self textFieldWidth
]

{ #category : 'layout' }
GbsCreateUserPresenter >> textRowLabel: labelString field: aField fieldWidth: widthValue [
	^ SpBoxLayout newLeftToRight
		add: (self newLabel label: labelString) width: self rowLabelWidth;
		add: aField width: widthValue;
		spacing: 6;
		yourself
]

{ #category : 'layout' }
GbsCreateUserPresenter >> rowLabelWidth [
	^ 150
]

{ #category : 'layout' }
GbsCreateUserPresenter >> textFieldWidth [
	^ 520
]

{ #category : 'layout' }
GbsCreateUserPresenter >> sideButtonWidth [
	^ 250
]

{ #category : 'layout' }
GbsCreateUserPresenter >> groupListWidth [
	^ 300
]

{ #category : 'layout' }
GbsCreateUserPresenter >> transferButtonWidth [
	^ 90
]

{ #category : 'layout' }
GbsCreateUserPresenter >> newGroupFieldWidth [
	^ 440
]

{ #category : 'layout' }
GbsCreateUserPresenter >> createButtonWidth [
	^ 120
]

{ #category : 'layout' }
GbsCreateUserPresenter >> actionButtonWidth [
	^ 180
]

{ #category : 'layout' }
GbsCreateUserPresenter >> authFieldWidth [
	^ 280
]

{ #category : 'layout' }
GbsCreateUserPresenter >> contentWidth [
	^ 800
]

{ #category : 'layout' }
GbsCreateUserPresenter >> centeredPane: aPaneLayout width: aWidth [
	^ SpBoxLayout newLeftToRight
		add: (self newLabel label: '') expand: true;
		add: aPaneLayout width: aWidth;
		add: (self newLabel label: '') expand: true;
		yourself
]

{ #category : 'initialization' }
GbsCreateUserPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone User';
		initialExtent: 860 @ 760
]

{ #category : 'actions' }
GbsCreateUserPresenter >> refreshGroups [
	| groups |
	groups := self fetchAllGroups.
	memberGroupsList items: #().
	availableGroupsList items: groups
]

{ #category : 'private' }
GbsCreateUserPresenter >> fetchAllGroups [
	| raw |
	raw := [ session evaluate: self groupsScript ] on: Error do: [ '' ].
	(raw isString and: [ raw isNotEmpty ]) ifFalse: [ ^ #() ].
	^ ((raw splitOn: Character tab) reject: [ :each | each isEmpty ]) asSortedCollection asArray
]

{ #category : 'private' }
GbsCreateUserPresenter >> groupsScript [
	^ '
	| strm allUsers groupNames |
	strm := WriteStream on: String new.
	groupNames := Set new.
	allUsers := System myUserProfile symbolList objectNamed: #AllUsers.
	allUsers ifNotNil: [
		allUsers do: [ :u |
			(u respondsTo: #groups) ifTrue: [
				u groups do: [ :g |
					| name |
					name := (g respondsTo: #name)
						ifTrue: [ g name asString ]
						ifFalse: [ g asString ].
					groupNames add: name ] ] ] ].
	groupNames asArray asSortedCollection do: [ :n |
		strm nextPutAll: n; tab ].
	strm contents'
]

{ #category : 'actions' }
GbsCreateUserPresenter >> addSelectedGroup [
	| group members avail |
	group := self selectedItemFromList: availableGroupsList.
	group ifNil: [ ^ self ].
	members := memberGroupsList items asOrderedCollection.
	(members includes: group) ifFalse: [ members add: group ].
	avail := availableGroupsList items asOrderedCollection.
	avail remove: group ifAbsent: [ ].
	memberGroupsList items: members asArray.
	availableGroupsList items: avail asArray
]

{ #category : 'actions' }
GbsCreateUserPresenter >> removeSelectedGroup [
	| group members avail |
	group := self selectedItemFromList: memberGroupsList.
	group ifNil: [ ^ self ].
	members := memberGroupsList items asOrderedCollection.
	members remove: group ifAbsent: [ ].
	avail := availableGroupsList items asOrderedCollection.
	(avail includes: group) ifFalse: [ avail add: group ].
	memberGroupsList items: members asArray.
	availableGroupsList items: (avail asSortedCollection asArray)
]

{ #category : 'actions' }
GbsCreateUserPresenter >> createGroup [
	| groupName avail |
	groupName := newGroupField text asString withBlanksTrimmed.
	groupName isEmpty ifTrue: [ ^ self ].
	avail := availableGroupsList items asOrderedCollection.
	(avail includes: groupName) ifFalse: [ avail add: groupName ].
	availableGroupsList items: (avail asSortedCollection asArray).
	newGroupField text: ''
]

{ #category : 'private' }
GbsCreateUserPresenter >> configureAuthRadioGroup [
	(gemStoneAuthRadio respondsTo: #associatedRadioButtons:)
		ifTrue: [ gemStoneAuthRadio associatedRadioButtons: { unixAuthRadio. ldapAuthRadio } ].
	(unixAuthRadio respondsTo: #associatedRadioButtons:)
		ifTrue: [ unixAuthRadio associatedRadioButtons: { gemStoneAuthRadio. ldapAuthRadio } ].
	(ldapAuthRadio respondsTo: #associatedRadioButtons:)
		ifTrue: [ ldapAuthRadio associatedRadioButtons: { gemStoneAuthRadio. unixAuthRadio } ].
]

{ #category : 'private' }
GbsCreateUserPresenter >> wireAuthRadioEvents [
	(gemStoneAuthRadio respondsTo: #whenChangedDo:)
		ifTrue: [ gemStoneAuthRadio whenChangedDo: [ self updateAuthFieldVisibility ] ].
	(unixAuthRadio respondsTo: #whenChangedDo:)
		ifTrue: [ unixAuthRadio whenChangedDo: [ self updateAuthFieldVisibility ] ].
	(ldapAuthRadio respondsTo: #whenChangedDo:)
		ifTrue: [ ldapAuthRadio whenChangedDo: [ self updateAuthFieldVisibility ] ].
	(gemStoneAuthRadio respondsTo: #whenActivatedDo:)
		ifTrue: [ gemStoneAuthRadio whenActivatedDo: [ self updateAuthFieldVisibility ] ].
	(unixAuthRadio respondsTo: #whenActivatedDo:)
		ifTrue: [ unixAuthRadio whenActivatedDo: [ self updateAuthFieldVisibility ] ].
	(ldapAuthRadio respondsTo: #whenActivatedDo:)
		ifTrue: [ ldapAuthRadio whenActivatedDo: [ self updateAuthFieldVisibility ] ].
]

{ #category : 'private' }
GbsCreateUserPresenter >> updateAuthFieldVisibility [
	| ldapSelected |
	ldapSelected := ldapAuthRadio state == true.
	baseDnField enabled: ldapSelected.
	filterDnField enabled: ldapSelected.
]

{ #category : 'private' }
GbsCreateUserPresenter >> selectedItemFromList: aListPresenter [
	| selected |
	aListPresenter ifNil: [ ^ nil ].
	(aListPresenter respondsTo: #selectedItem)
		ifTrue: [
			selected := [ aListPresenter selectedItem ] on: Error do: [ nil ].
			selected ifNotNil: [ ^ selected ] ].
	(aListPresenter respondsTo: #selection)
		ifTrue: [
			selected := [ aListPresenter selection selectedItem ] on: Error do: [ nil ].
			selected ifNotNil: [ ^ selected ] ].
	^ nil
]

{ #category : 'actions' }
GbsCreateUserPresenter >> saveUserCommit: commitAfterSave [
	| userName password confirm script |
	userName := userField text asString withBlanksTrimmed.
	password := passwordField text asString.
	confirm := confirmPasswordField text asString.
	userName isEmpty ifTrue: [ ^ self inform: 'User ID is required.' ].
	(password isEmpty not and: [ password ~= confirm ])
		ifTrue: [ ^ self inform: 'Password and confirmation do not match.' ].

	script := self
		scriptToSaveUser: userName
		password: password
		groups: memberGroupsList items
		privileges: (pendingPrivileges ifNil: [ self defaultPrivilegesDictionary ]).
	[
		session execute: script.
		commitAfterSave ifTrue: [
			(session respondsTo: #commitTransaction) ifTrue: [ session commitTransaction ] ].
		createdBlock ifNotNil: [ createdBlock value ].
		self closeWindow
	] on: Error do: [ :ex |
		self inform: 'Save user failed: ', ex messageText
	]
]

{ #category : 'private' }
GbsCreateUserPresenter >> scriptToSaveUser: userName password: password groups: groupNames privileges: privilegeMap [
	| userLiteral passLiteral groupsLiteral privilegesLiteral |
	userLiteral := self literalString: userName.
	passLiteral := self literalString: password.
	groupsLiteral := self literalArrayOfStrings: groupNames.
	privilegesLiteral := self literalDictionary: privilegeMap.
	^ '
		| allUsers user groupsWanted privilegeMap applyFlag ensureGroup removeGroup |
	allUsers := System myUserProfile symbolList objectNamed: #AllUsers.
	allUsers ifNil: [ self error: ''AllUsers not found'' ].
	user := allUsers detect: [ :u | u userId asString = ', userLiteral, ' ] ifNone: [ nil ].
	user ifNil: [
		(allUsers respondsTo: #addNewUserWithId:password:)
			ifTrue: [ allUsers addNewUserWithId: ', userLiteral, ' password: ', passLiteral, ' ]
			ifFalse: [
				(allUsers respondsTo: #addUser:password:)
					ifTrue: [ allUsers addUser: ', userLiteral, ' password: ', passLiteral, ' ]
					ifFalse: [ self error: ''Cannot create user with available API'' ] ].
		user := allUsers detect: [ :u | u userId asString = ', userLiteral, ' ] ifNone: [ nil ] ].
	user ifNil: [ self error: ''Failed to resolve created user'' ].
	', (password isEmpty
		ifTrue: [ '' ]
		ifFalse: [ '
	(user respondsTo: #password:) ifTrue: [ user password: ', passLiteral, ' ].
	(user respondsTo: #setPassword:) ifTrue: [ user setPassword: ', passLiteral, ' ].' ]), '
	groupsWanted := ', groupsLiteral, '.
	(user respondsTo: #groups) ifTrue: [
		| existing |
		existing := user groups collect: [ :g | (g respondsTo: #name) ifTrue: [ g name asString ] ifFalse: [ g asString ] ].
		groupsWanted do: [ :gName |
			(existing includes: gName) ifFalse: [
				(user respondsTo: #addToGroupNamed:)
						ifTrue: [ user addToGroupNamed: gName ] ] ] ].
	ensureGroup := [ :groupName |
		(user respondsTo: #addToGroupNamed:) ifTrue: [ user addToGroupNamed: groupName ] ].
	removeGroup := [ :groupName |
		(user respondsTo: #removeFromGroupNamed:)
			ifTrue: [ user removeFromGroupNamed: groupName ] ].
		applyFlag := [ :privName :enabled |
			| setter1 setter2 base alt |
			base := privName asString.
			alt := (base isEmpty)
				ifTrue: [ base ]
				ifFalse: [ (base first asLowercase asString), (base allButFirst) ].
			setter1 := (''is'', base, '':'') asSymbol.
			setter2 := (alt, '':'') asSymbol.
			(user respondsTo: setter1)
				ifTrue: [ user perform: setter1 with: enabled ]
				ifFalse: [
					(user respondsTo: setter2)
						ifTrue: [ user perform: setter2 with: enabled ] ] ].
		privilegeMap := ', privilegesLiteral, '.
		privilegeMap keysAndValuesDo: [ :k :v | applyFlag value: k value: (v == true) ].
		((privilegeMap at: #DataCurator ifAbsent: [ false ]) == true)
			ifTrue: [ ensureGroup value: ''DataCuratorGroup'' ].
		((privilegeMap at: #DataCurator ifAbsent: [ false ]) == false)
			ifTrue: [ removeGroup value: ''DataCuratorGroup'' ].
		true'
]

{ #category : 'private' }
GbsCreateUserPresenter >> scriptToCreateUser: userName password: password [
	^ self
		scriptToSaveUser: userName
		password: password
		groups: #()
		privileges: self defaultPrivilegesDictionary
]

{ #category : 'private' }
GbsCreateUserPresenter >> literalString: aString [
	^ '''', (aString copyReplaceAll: '''' with: ''''''), ''''
]

{ #category : 'private' }
GbsCreateUserPresenter >> literalArrayOfStrings: aCollection [
	| parts |
	parts := (aCollection ifNil: [ #() ]) collect: [ :each | self literalString: each asString ].
	^ '{ ', (parts joinUsing: '. '), ' }'
]

{ #category : 'private' }
GbsCreateUserPresenter >> literalDictionary: aDictionary [
	| pairs |
	pairs := (aDictionary ifNil: [ Dictionary new ]) associations collect: [ :assoc |
		'(', assoc key storeString, ' -> ', ((assoc value == true) ifTrue: [ 'true' ] ifFalse: [ 'false' ]), ')' ].
	^ 'Dictionary newFrom: { ', (pairs joinUsing: '. '), ' }'
]

{ #category : 'private' }
GbsCreateUserPresenter >> defaultPrivilegesDictionary [
	| dict |
	dict := Dictionary new.
	self supportedPrivilegeNames do: [ :each | dict at: each put: false ].
	^ dict
]

{ #category : 'private' }
GbsCreateUserPresenter >> supportedPrivilegeNames [
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

{ #category : 'private' }
GbsCreateUserPresenter >> fetchPrivilegesForUser: userName [
	| script raw map |
	script := self privilegesScriptForUser: userName.
	raw := [ session evaluate: script ] on: Error do: [ '' ].
	map := self defaultPrivilegesDictionary copy.
	(raw isString and: [ raw isNotEmpty ]) ifFalse: [ ^ map ].
	raw lines do: [ :line |
		| parts key value |
		parts := line splitOn: Character tab.
		parts size >= 2 ifTrue: [
			key := (parts first asString ifEmpty: [ '' ]) asSymbol.
			value := (parts second asString asLowercase = 'true').
			(map includesKey: key) ifTrue: [ map at: key put: value ]
		]
	].
	^ map
]

{ #category : 'private' }
GbsCreateUserPresenter >> privilegesScriptForUser: userName [
	| userLiteral privilegeArrayLiteral |
	userLiteral := self literalString: userName.
	privilegeArrayLiteral := self literalArrayOfSymbols: self supportedPrivilegeNames.
	^ '
	| users user strm groups privilegeNames valueFor |
	strm := WriteStream on: String new.
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ ^ '''' ].
	user := users detect: [ :u | u userId asString = ', userLiteral, ' ] ifNone: [ nil ].
	user ifNil: [ ^ '''' ].
	groups := (user respondsTo: #groups)
		ifTrue: [ user groups collect: [ :g | (g respondsTo: #name) ifTrue: [ g name asString ] ifFalse: [ g asString ] ] ]
		ifFalse: [ #() ].
	privilegeNames := ', privilegeArrayLiteral, '.
	valueFor := [ :privName |
		| base alt getter1 getter2 |
		base := privName asString.
		alt := (base isEmpty)
			ifTrue: [ base ]
			ifFalse: [ (base first asLowercase asString), (base allButFirst) ].
		getter1 := (''is'', base) asSymbol.
		getter2 := alt asSymbol.
		(user respondsTo: getter1)
			ifTrue: [ ^ (user perform: getter1) == true ].
		(user respondsTo: getter2)
			ifTrue: [ ^ (user perform: getter2) == true ].
		(base = ''DataCurator'') ifTrue: [ ^ groups includes: ''DataCuratorGroup'' ].
		(base = ''SystemUser'') ifTrue: [ ^ groups includes: ''System'' ].
		(base = ''HostAgentUser'') ifTrue: [ ^ groups includes: ''HostAgentUser'' ].
		(base = ''SymbolUser'') ifTrue: [ ^ groups includes: ''SymbolUser'' ].
		(base = ''Nameless'') ifTrue: [ ^ groups includes: ''Nameless'' ].
		(base = ''GcUser'') ifTrue: [ ^ groups includes: ''GcUser'' ].
		^ false ].
	privilegeNames do: [ :name |
		strm
			nextPutAll: name asString;
			tab;
			nextPutAll: ((valueFor value: name) ifTrue: [ ''true'' ] ifFalse: [ ''false'' ]);
			cr ].
	strm contents'
]

{ #category : 'private' }
GbsCreateUserPresenter >> literalArrayOfSymbols: aCollection [
	| parts |
	parts := (aCollection ifNil: [ #() ]) collect: [ :each | each storeString ].
	^ '#( ', (parts joinUsing: ' '), ' )'
]

{ #category : 'actions' }
GbsCreateUserPresenter >> editPrivileges [
	| userName current |
	session ifNil: [ ^ self ].
	userName := userField text asString withBlanksTrimmed.
	userName isEmpty ifTrue: [ ^ self inform: 'Enter User ID before editing privileges.' ].
	current := pendingPrivileges
		ifNil: [ self fetchPrivilegesForUser: userName ]
		ifNotNil: [ pendingPrivileges copy ].
	[
		GbsUserPrivilegesPresenter
			openForUser: userName
			initialPrivileges: current
			onAccept: [ :updated |
				pendingPrivileges := updated copy ]
	] on: Error do: [ :ex |
		self inform: 'Could not open privileges window: ', ex messageText ]
]

{ #category : 'actions' }
GbsCreateUserPresenter >> editSymbolList [
	| userName |
	session ifNil: [ ^ self ].
	userName := userField text asString withBlanksTrimmed.
	[
		GbsSymbolListBrowserPresenter
			openOn: session
			userName: userName
	] on: Error do: [ :ex | self inform: 'Could not open Symbol List Browser: ', ex messageText ]
]

{ #category : 'actions' }
GbsCreateUserPresenter >> editSecurityPolicies [
	session ifNil: [ ^ self ].
	[ GbsSecurityPoliciesPresenter openOn: session ] on: Error do: [ :ex | self inform: ex messageText ]
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

{ #category : 'menus' }
GbsCreateUserPresenter >> buildMenuBar [
	^ self newMenuBar
		addGroup: [ :group |
			group
				addItem: [ :item | item name: 'File'; subMenu: self menuFile ];
				addItem: [ :item | item name: 'User'; subMenu: self menuUser ];
				addItem: [ :item | item name: 'Help'; subMenu: self menuHelp ] ];
		yourself
]

{ #category : 'menus' }
GbsCreateUserPresenter >> menuFile [
	^ self newMenu
		addItem: [ :item | item name: 'Save'; action: [ self saveUserCommit: false ] ];
		addItem: [ :item | item name: 'Save And Commit'; action: [ self saveUserCommit: true ] ];
		addItem: [ :item | item name: 'Close'; action: [ self closeWindow ] ];
		yourself
]

{ #category : 'menus' }
GbsCreateUserPresenter >> menuUser [
	^ self newMenu
		addItem: [ :item | item name: 'Privileges...'; action: [ self editPrivileges ] ];
		addItem: [ :item | item name: 'Symbol List...'; action: [ self editSymbolList ] ];
		addItem: [ :item | item name: 'Object Security Policies...'; action: [ self editSecurityPolicies ] ];
		yourself
]

{ #category : 'menus' }
GbsCreateUserPresenter >> menuHelp [
	^ self newMenu
		addItem: [ :item | item name: 'About GemStone User'; action: [ UIManager default inform: 'GemStone User Editor' ] ];
		yourself
]
