Class {
	#name : 'GbsCreateUserPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'createdBlock',
		'pendingPrivileges',
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
	gemStoneAuthRadio state: true.
	baseDnField enabled: false.
	filterDnField enabled: false.
	pendingPrivileges := nil.
	self refreshGroups
]

{ #category : 'layout' }
GbsCreateUserPresenter >> defaultLayout [
	| headerRow authPane sideButtons groupsPane groupsButtons groupLists newGroupRow actionRow |
	headerRow := SpGridLayout new
		add: 'User ID' atPoint: 1 @ 1;
		add: userField atPoint: 2 @ 1;
		add: 'Password' atPoint: 1 @ 2;
		add: passwordField atPoint: 2 @ 2;
		add: 'Confirm Password' atPoint: 1 @ 3;
		add: confirmPasswordField atPoint: 2 @ 3;
		yourself.

	authPane := SpBoxLayout newTopToBottom
		add: (self newLabel label: 'Authentication Method') expand: false;
		add: gemStoneAuthRadio expand: false;
		add: unixAuthRadio expand: false;
		add: ldapAuthRadio expand: false;
		add: (self textRowLabel: 'Base DN' field: baseDnField) expand: false;
		add: (self textRowLabel: 'Filter DN' field: filterDnField) expand: false;
		spacing: 4;
		yourself.

	sideButtons := SpBoxLayout newTopToBottom
		add: privilegesButton expand: false;
		add: symbolListButton expand: false;
		add: securityPoliciesButton expand: false;
		spacing: 8;
		yourself.

	groupLists := SpBoxLayout newLeftToRight
		add: memberGroupsList;
		add: (SpBoxLayout newTopToBottom
			add: addGroupButton expand: false;
			add: removeGroupButton expand: false;
			spacing: 8;
			yourself) expand: false;
		add: availableGroupsList;
		spacing: 8;
		yourself.

	groupsPane := SpBoxLayout newTopToBottom
		add: (self newLabel label: 'Groups') expand: false;
		add: groupLists;
		spacing: 6;
		yourself.

	newGroupRow := SpBoxLayout newLeftToRight
		add: (self newLabel label: 'Name') expand: false;
		add: newGroupField;
		add: createGroupButton expand: false;
		spacing: 8;
		yourself.
	groupsButtons := SpBoxLayout newTopToBottom
		add: (self newLabel label: 'New Group') expand: false;
		add: newGroupRow expand: false;
		spacing: 4;
		yourself.

	actionRow := SpBoxLayout newLeftToRight
		add: saveButton;
		add: saveAndCommitButton;
		add: closeButton;
		spacing: 8;
		yourself.

	^ SpBoxLayout newTopToBottom
		add: headerRow expand: false;
		add: (SpBoxLayout newLeftToRight add: sideButtons; add: authPane; spacing: 12; yourself) expand: false;
		add: groupsPane;
		add: groupsButtons expand: false;
		add: actionRow expand: false;
		spacing: 8;
		yourself
]

{ #category : 'layout' }
GbsCreateUserPresenter >> textRowLabel: labelString field: aField [
	^ SpBoxLayout newLeftToRight
		add: (self newLabel label: labelString) expand: false;
		add: aField;
		spacing: 6;
		yourself
]

{ #category : 'initialization' }
GbsCreateUserPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemStone User';
		initialExtent: 780 @ 620
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
	group := availableGroupsList selection selectedItem.
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
	group := memberGroupsList selection selectedItem.
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
	applyFlag := [ :getterSel :setterSel :groupName :enabled |
		(user respondsTo: setterSel)
			ifTrue: [ user perform: setterSel with: enabled ]
			ifFalse: [ enabled ifTrue: [ ensureGroup value: groupName ] ifFalse: [ removeGroup value: groupName ] ] ].
	privilegeMap := ', privilegesLiteral, '.
	applyFlag value: #isDataCurator value: #isDataCurator: value: ''DataCuratorGroup'' value: ((privilegeMap at: #DataCurator ifAbsent: [ false ]) == true).
	applyFlag value: #isSystemUser value: #isSystemUser: value: ''System'' value: ((privilegeMap at: #SystemUser ifAbsent: [ false ]) == true).
	applyFlag value: #isHostAgentUser value: #isHostAgentUser: value: ''HostAgentUser'' value: ((privilegeMap at: #HostAgentUser ifAbsent: [ false ]) == true).
	applyFlag value: #isSymbolUser value: #isSymbolUser: value: ''SymbolUser'' value: ((privilegeMap at: #SymbolUser ifAbsent: [ false ]) == true).
	applyFlag value: #isNameless value: #isNameless: value: ''Nameless'' value: ((privilegeMap at: #Nameless ifAbsent: [ false ]) == true).
	applyFlag value: #isGcUser value: #isGcUser: value: ''GcUser'' value: ((privilegeMap at: #GcUser ifAbsent: [ false ]) == true).
	true'
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
	^ Dictionary newFrom: {
		#DataCurator -> false.
		#SystemUser -> false.
		#HostAgentUser -> false.
		#SymbolUser -> false.
		#Nameless -> false.
		#GcUser -> false
	}
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
	| userLiteral |
	userLiteral := self literalString: userName.
	^ '
	| users user strm groups flagFor |
	strm := WriteStream on: String new.
	users := System myUserProfile symbolList objectNamed: #AllUsers.
	users ifNil: [ ^ '''' ].
	user := users detect: [ :u | u userId asString = ', userLiteral, ' ] ifNone: [ nil ].
	user ifNil: [ ^ '''' ].
	groups := (user respondsTo: #groups)
		ifTrue: [ user groups collect: [ :g | (g respondsTo: #name) ifTrue: [ g name asString ] ifFalse: [ g asString ] ] ]
		ifFalse: [ #() ].
	flagFor := [ :getterSel :groupName |
		(user respondsTo: getterSel)
			ifTrue: [ (user perform: getterSel) == true ]
			ifFalse: [ groups includes: groupName ] ].
	{
		#DataCurator -> (flagFor value: #isDataCurator value: ''DataCuratorGroup'').
		#SystemUser -> (flagFor value: #isSystemUser value: ''System'').
		#HostAgentUser -> (flagFor value: #isHostAgentUser value: ''HostAgentUser'').
		#SymbolUser -> (flagFor value: #isSymbolUser value: ''SymbolUser'').
		#Nameless -> (flagFor value: #isNameless value: ''Nameless'').
		#GcUser -> (flagFor value: #isGcUser value: ''GcUser'')
	} do: [ :assoc |
		strm nextPutAll: assoc key asString; tab; nextPutAll: (assoc value ifTrue: [ ''true'' ] ifFalse: [ ''false'' ]); cr ].
	strm contents'
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
	GbsUserPrivilegesPresenter
		openForUser: userName
		initialPrivileges: current
		onAccept: [ :updated |
			pendingPrivileges := updated copy ]
]

{ #category : 'actions' }
GbsCreateUserPresenter >> editSymbolList [
	session ifNil: [ ^ self ].
	[ GbsNamespacesPresenter openOn: session ] on: Error do: [ :ex | self inform: ex messageText ]
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
