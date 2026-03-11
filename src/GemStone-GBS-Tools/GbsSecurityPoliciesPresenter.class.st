Class {
	#name : 'GbsSecurityPoliciesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'policiesTable',
		'groupsTable',
		'membersList',
		'refreshButton',
		'closeButton'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsSecurityPoliciesPresenter class >> openOn: aSession [
	| presenter |
	aSession ifNil: [ ^ self inform: 'No connected GemStone session. Please login first.' ].
	presenter := self new.
	presenter
		session: aSession;
		open.
	^ presenter
]

{ #category : 'initialization' }
GbsSecurityPoliciesPresenter >> connectPresenters [
	policiesTable whenSelectionChangedDo: [ :selection |
		selection selectedItem
			ifNotNil: [ :row | self refreshGroupsAndMembersForPolicyName: (row at: 3 ifAbsent: [ '' ]) ]
			ifNil: [ groupsTable items: #(). membersList items: #() ] ].
	refreshButton action: [ self refreshAll ].
	closeButton action: [ self closeWindow ].
	self refreshAll
]

{ #category : 'layout' }
GbsSecurityPoliciesPresenter >> defaultLayout [
	| lower |
	lower := SpBoxLayout newLeftToRight
		add: groupsTable;
		add: membersList;
		yourself.
	^ SpBoxLayout newTopToBottom
		add: policiesTable;
		add: lower;
		add: (SpBoxLayout newLeftToRight
			add: refreshButton;
			add: closeButton;
			spacing: 8;
			yourself) expand: false;
		yourself
]

{ #category : 'initialization' }
GbsSecurityPoliciesPresenter >> initializePresenters [
	policiesTable := self newTable.
	policiesTable
		addColumn: (SpStringTableColumn title: 'Current' evaluated: [ :row | row at: 1 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Default' evaluated: [ :row | row at: 2 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Security Policy Name' evaluated: [ :row | row at: 3 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Owner Name' evaluated: [ :row | row at: 4 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Owner Access' evaluated: [ :row | row at: 5 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'World Access' evaluated: [ :row | row at: 6 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Id' evaluated: [ :row | row at: 7 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Track Reads' evaluated: [ :row | row at: 8 ifAbsent: [ '' ] ]);
		yourself.

	groupsTable := self newTable.
	groupsTable
		addColumn: (SpStringTableColumn title: 'Group Name' evaluated: [ :row | row at: 1 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Group Access' evaluated: [ :row | row at: 2 ifAbsent: [ '' ] ]);
		yourself.

	membersList := self newList.
	membersList headerTitle: 'Group Member List'.
	membersList display: [ :each | each asString ].

	refreshButton := self newButton
		label: 'Refresh';
		icon: (self iconNamed: #smallUpdate);
		yourself.
	closeButton := self newButton
		label: 'Close';
		icon: (self iconNamed: #smallCancel);
		yourself
]

{ #category : 'initialization' }
GbsSecurityPoliciesPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'Security Policy Tool';
		initialExtent: 980 @ 560
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> literalString: aString [
	^ '''', (aString copyReplaceAll: '''' with: ''''''), ''''
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> parseRows: rawString expectedColumns: expectedColumns [
	| lines |
	(rawString isString and: [ rawString isNotEmpty ]) ifFalse: [ ^ #() ].
	lines := rawString lines.
	^ lines collect: [ :line |
		| columns |
		columns := line splitOn: Character tab.
		(1 to: expectedColumns) collect: [ :index | columns at: index ifAbsent: [ '' ] ] ]
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> refreshAll [
	| raw policies |
	raw := [ session evaluate: self securityPoliciesScript ] on: Error do: [ :ex | self inform: 'Fetch security policies failed: ', ex messageText. '' ].
	policies := self parseRows: raw expectedColumns: 8.
	policiesTable items: policies.
	groupsTable items: #().
	membersList items: #()
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> refreshGroupsAndMembersForPolicyName: policyName [
	| rawGroup rawMembers |
	rawGroup := [ session evaluate: (self groupsScriptForPolicyName: policyName) ] on: Error do: [ '' ].
	groupsTable items: (self parseRows: rawGroup expectedColumns: 2).
	rawMembers := [ session evaluate: (self membersScriptForPolicyName: policyName) ] on: Error do: [ '' ].
	membersList items: (rawMembers isString ifTrue: [ rawMembers lines ] ifFalse: [ #() ])
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> groupsScriptForPolicyName: policyName [
	| nameLiteral |
	nameLiteral := self literalString: policyName.
	^ '
	| allPolicies policy strm groups |
	strm := WriteStream on: String new.
	allPolicies := System myUserProfile symbolList objectNamed: #AllSecurityPolicies.
	allPolicies ifNil: [ allPolicies := System myUserProfile symbolList objectNamed: #AllObjectSecurityPolicies ].
	allPolicies ifNil: [
		| resolved |
		resolved := (System myUserProfile respondsTo: #resolveSymbol:)
			ifTrue: [ System myUserProfile resolveSymbol: #SystemRepository ]
			ifFalse: [ nil ].
		allPolicies := (resolved respondsTo: #value)
			ifTrue: [ resolved value ]
			ifFalse: [ resolved ] ].
	allPolicies ifNil: [ ^ '''' ].
	policy := allPolicies
		detect: [ :p | ((p respondsTo: #name) ifTrue: [ p name asString ] ifFalse: [ p printString ]) = ', nameLiteral, ' ]
		ifNone: [ nil ].
	policy ifNil: [ ^ '''' ].
	(policy respondsTo: #groups) ifFalse: [ ^ '''' ].
	groups := policy groups.
	(groups respondsTo: #keysAndValuesDo:)
		ifTrue: [
			groups keysAndValuesDo: [ :groupName :auth |
				strm
					nextPutAll: groupName asString;
					tab;
					nextPutAll: auth asString;
					cr ] ]
		ifFalse: [
			groups do: [ :each |
				| gName gAccess |
				(each isAssociation)
					ifTrue: [
						gName := each key asString.
						gAccess := each value asString ]
					ifFalse: [
						gName := each asString.
						gAccess := '''' ].
				strm nextPutAll: gName; tab; nextPutAll: gAccess; cr ] ].
	strm contents'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> membersScriptForPolicyName: policyName [
	| nameLiteral |
	nameLiteral := self literalString: policyName.
	^ '
	| allPolicies policy strm |
	strm := WriteStream on: String new.
	allPolicies := System myUserProfile symbolList objectNamed: #AllSecurityPolicies.
	allPolicies ifNil: [ ^ '''' ].
	policy := allPolicies
		detect: [ :p | ((p respondsTo: #name) ifTrue: [ p name asString ] ifFalse: [ p printString ]) = ', nameLiteral, ' ]
		ifNone: [ nil ].
	policy ifNil: [ ^ '''' ].
	(policy respondsTo: #groups) ifTrue: [
		policy groups do: [ :g |
			(g respondsTo: #members) ifTrue: [
				g members do: [ :member |
					strm nextPutAll: member asString; cr ] ] ] ].
	strm contents'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> securityPoliciesScript [
	^ '
	| allPolicies currentPolicy defaultPolicy strm |
	strm := WriteStream on: String new.
	allPolicies := System myUserProfile symbolList objectNamed: #AllSecurityPolicies.
	allPolicies ifNil: [ allPolicies := System myUserProfile symbolList objectNamed: #AllObjectSecurityPolicies ].
	allPolicies ifNil: [
		| resolved |
		resolved := (System myUserProfile respondsTo: #resolveSymbol:)
			ifTrue: [ System myUserProfile resolveSymbol: #SystemRepository ]
			ifFalse: [ nil ].
		allPolicies := (resolved respondsTo: #value)
			ifTrue: [ resolved value ]
			ifFalse: [ resolved ] ].
	currentPolicy := (System myUserProfile respondsTo: #securityPolicy)
		ifTrue: [ System myUserProfile securityPolicy ]
		ifFalse: [
			(System respondsTo: #currentObjectSecurityPolicy)
				ifTrue: [ System currentObjectSecurityPolicy ]
				ifFalse: [ nil ] ].
	defaultPolicy := (System myUserProfile respondsTo: #defaultObjectSecurityPolicy)
		ifTrue: [ System myUserProfile defaultObjectSecurityPolicy ]
		ifFalse: [
			(System myUserProfile class respondsTo: #defaultSecurityPolicy)
				ifTrue: [ System myUserProfile class defaultSecurityPolicy ]
				ifFalse: [ nil ] ].
	allPolicies ifNil: [ ^ strm contents ].
	allPolicies do: [ :policy |
		| currentMark defaultMark name owner ownerAccess worldAccess id trackReads |
		currentMark := policy == currentPolicy ifTrue: [ ''Current'' ] ifFalse: [ '''' ].
		defaultMark := policy == defaultPolicy ifTrue: [ ''Default'' ] ifFalse: [ '''' ].
		name := (policy respondsTo: #name) ifTrue: [ policy name asString ] ifFalse: [ policy printString ].
		owner := (policy respondsTo: #owner)
			ifTrue: [ (policy owner ifNil: [ '''' ]) asString ]
			ifFalse: [ '''' ].
		ownerAccess := (policy respondsTo: #ownerAuthorization)
			ifTrue: [ policy ownerAuthorization asString ]
			ifFalse: [ (policy respondsTo: #ownerAccess) ifTrue: [ policy ownerAccess asString ] ifFalse: [ '''' ] ].
		worldAccess := (policy respondsTo: #worldAuthorization)
			ifTrue: [ policy worldAuthorization asString ]
			ifFalse: [ (policy respondsTo: #worldAccess) ifTrue: [ policy worldAccess asString ] ifFalse: [ '''' ] ].
		id := (policy respondsTo: #objectSecurityPolicyId)
			ifTrue: [ policy objectSecurityPolicyId asString ]
			ifFalse: [ (policy respondsTo: #id) ifTrue: [ policy id asString ] ifFalse: [ '''' ] ].
		trackReads := (policy respondsTo: #trackReads)
			ifTrue: [ policy trackReads printString ]
			ifFalse: [ (policy respondsTo: #isTrackingReads) ifTrue: [ policy isTrackingReads printString ] ifFalse: [ '''' ] ].
		strm
			nextPutAll: currentMark;
			tab;
			nextPutAll: defaultMark;
			tab;
			nextPutAll: name;
			tab;
			nextPutAll: owner;
			tab;
			nextPutAll: ownerAccess;
			tab;
			nextPutAll: worldAccess;
			tab;
			nextPutAll: id;
			tab;
			nextPutAll: trackReads;
			cr ].
	strm contents'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> session: aSession [
	session := aSession
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]
