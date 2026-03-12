Class {
	#name : 'GbsSecurityPoliciesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'mainMenu',
		'policiesTable',
		'groupsTable',
		'membersList'
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
	groupsTable whenSelectionChangedDo: [ :selection |
		| policyName groupName |
		policyName := self selectedPolicyName.
		groupName := selection selectedItem
			ifNotNil: [ :row | row at: 1 ifAbsent: [ '' ] ]
			ifNil: [ '' ].
		((policyName isNil or: [ policyName isEmpty ]) or: [ groupName isEmpty ])
			ifTrue: [ membersList items: #() ]
			ifFalse: [ self refreshMembersForPolicyName: policyName groupName: groupName ] ].
	(policiesTable respondsTo: #whenActivatedDo:) ifTrue: [
		policiesTable whenActivatedDo: [ :selection |
			selection selectedItem
				ifNotNil: [ :row | self refreshGroupsAndMembersForPolicyName: (row at: 3 ifAbsent: [ '' ]) ] ] ].
	(policiesTable respondsTo: #contextMenu:) ifTrue: [
		policiesTable contextMenu: [ self menuPolicyPopup ] ].
	(groupsTable respondsTo: #contextMenu:) ifTrue: [
		groupsTable contextMenu: [ self menuGroupPopup ] ].
	(membersList respondsTo: #contextMenu:) ifTrue: [
		membersList contextMenu: [ self menuMemberPopup ] ].
	self refreshAll
]

{ #category : 'layout' }
GbsSecurityPoliciesPresenter >> defaultLayout [
	| lower |
	lower := SpBoxLayout newLeftToRight
		add: groupsTable;
		add: membersList;
		spacing: 8;
		yourself.
	^ SpBoxLayout newTopToBottom
		add: mainMenu expand: false;
		add: policiesTable;
		add: lower;
		spacing: 8;
		yourself
]

{ #category : 'initialization' }
GbsSecurityPoliciesPresenter >> initializePresenters [
	mainMenu := self buildMenuBar.

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
	membersList display: [ :each | each asString ]
]

{ #category : 'initialization' }
GbsSecurityPoliciesPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'Security Policy Tool';
		initialExtent: 980 @ 560
]

{ #category : 'menus' }
GbsSecurityPoliciesPresenter >> buildMenuBar [
	^ self newMenuBar
		addGroup: [ :group |
			group
				addItem: [ :item | item name: 'File'; subMenu: self menuFile ];
				addItem: [ :item | item name: 'Security Policy'; subMenu: self menuSecurityPolicy ];
				addItem: [ :item | item name: 'Group'; subMenu: self menuGroup ];
				addItem: [ :item | item name: 'Member'; subMenu: self menuMember ];
				addItem: [ :item | item name: 'Report'; subMenu: self menuReport ];
				addItem: [ :item | item name: 'Help'; subMenu: self menuHelp ] ]
]

{ #category : 'menus' }
GbsSecurityPoliciesPresenter >> menuFile [
	^ self newMenu
		addItem: [ :item | item name: 'Refresh'; action: [ self refreshAll ] ];
		addItem: [ :item | item name: 'Close'; action: [ self closeWindow ] ];
		yourself
]

{ #category : 'menus' }
GbsSecurityPoliciesPresenter >> menuSecurityPolicy [
	^ self newMenu
		addItem: [ :item | item name: 'Refresh'; action: [ self refreshAll ] ];
		addItem: [ :item |
			item name: 'Set Current'; action: [ self setSelectedPolicyCurrent ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedPolicy ] ];
		addItem: [ :item |
			item name: 'Set Default'; action: [ self setSelectedPolicyDefault ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedPolicy ] ];
		addItem: [ :item |
			item name: 'Edit Owner Access...'; action: [ self editSelectedPolicyOwnerAccess ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedPolicy ] ];
		addItem: [ :item |
			item name: 'Edit World Access...'; action: [ self editSelectedPolicyWorldAccess ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedPolicy ] ];
		addItem: [ :item |
			item name: 'Toggle Track Reads'; action: [ self toggleSelectedPolicyTrackReads ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedPolicy ] ];
		addItem: [ :item |
			item name: 'Inspect Selected'; action: [ self inspectSelectedPolicy ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedPolicy ] ];
		yourself
]

{ #category : 'menus' }
GbsSecurityPoliciesPresenter >> menuGroup [
	^ self newMenu
		addItem: [ :item |
			item name: 'Refresh Groups'; action: [ self refreshSelectedPolicyGroups ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedPolicy ] ];
		addItem: [ :item |
			item name: 'Add Group...'; action: [ self addGroupToSelectedPolicy ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedPolicy ] ];
		addItem: [ :item |
			item name: 'Remove Selected Group'; action: [ self removeSelectedGroupFromPolicy ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedGroup ] ];
		addItem: [ :item |
			item name: 'Inspect Selected Group'; action: [ self inspectSelectedGroup ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedGroup ] ];
		addItem: [ :item |
			item name: 'Edit Group Access...'; action: [ self editSelectedGroupAccess ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedGroup ] ];
		yourself
]

{ #category : 'menus' }
GbsSecurityPoliciesPresenter >> menuMember [
	^ self newMenu
		addItem: [ :item |
			item name: 'Refresh Members'; action: [ self refreshSelectedPolicyMembers ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedGroup ] ];
		addItem: [ :item |
			item name: 'Add Member...'; action: [ self addMemberToSelectedGroup ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedGroup ] ];
		addItem: [ :item |
			item name: 'Remove Selected Member'; action: [ self removeSelectedMemberFromGroup ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedMember ] ];
		addItem: [ :item |
			item name: 'Inspect Selected Member'; action: [ self inspectSelectedMember ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedMember ] ];
		yourself
]

{ #category : 'menus' }
GbsSecurityPoliciesPresenter >> menuReport [
	^ self newMenu
		addItem: [ :item |
			item name: 'Copy Policy Report'; action: [ self copyPolicyReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedPolicy ] ];
		addItem: [ :item |
			item name: 'Copy Group Report'; action: [ self copyGroupReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedGroup ] ];
		addItem: [ :item |
			item name: 'Copy Member Report'; action: [ self copyMemberReport ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canOperateOnSelectedMember ] ];
		addItem: [ :item | item name: 'Copy Full Report'; action: [ self copyFullReport ] ];
		addItem: [ :item | item name: 'Show Full Report'; action: [ self showFullReport ] ];
		yourself
]

{ #category : 'menus' }
GbsSecurityPoliciesPresenter >> menuPolicyPopup [
	^ self menuSecurityPolicy
]

{ #category : 'menus' }
GbsSecurityPoliciesPresenter >> menuGroupPopup [
	^ self menuGroup
]

{ #category : 'menus' }
GbsSecurityPoliciesPresenter >> menuMemberPopup [
	^ self menuMember
]

{ #category : 'menus' }
GbsSecurityPoliciesPresenter >> menuHelp [
	^ self newMenu
		addItem: [ :item | item name: 'About Security Policy Tool'; action: [ self aboutTool ] ];
		yourself
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> aboutTool [
	UIManager default inform: 'GemStone Security Policy Tool'
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> copyPolicyReport [
	Clipboard clipboardText: self policyReportText
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> copyGroupReport [
	Clipboard clipboardText: self groupReportText
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> copyMemberReport [
	Clipboard clipboardText: self memberReportText
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> copyFullReport [
	Clipboard clipboardText: self fullReportText
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> showFullReport [
	UIManager default inform: self fullReportText
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> fullReportText [
	^ String streamContents: [ :stream |
		stream nextPutAll: self policyReportText.
		stream cr.
		stream nextPutAll: self groupReportText.
		stream cr.
		stream nextPutAll: self memberReportText ]
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> policyReportText [
	| rows selected |
	rows := policiesTable items ifNil: [ #() ].
	selected := self selectedPolicyRow.
	(selected notNil and: [ rows includes: selected ])
		ifTrue: [ rows := { selected } ].
	^ String streamContents: [ :stream |
		stream nextPutAll: '=== Policies ==='; cr.
		rows do: [ :row |
			stream nextPutAll: ((row collect: [ :each | each asString ]) joinUsing: Character tab asString); cr ] ]
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> groupReportText [
	| rows policyName |
	rows := groupsTable items ifNil: [ #() ].
	policyName := self selectedPolicyName ifNil: [ '' ].
	^ String streamContents: [ :stream |
		stream nextPutAll: '=== Groups ==='; cr.
		policyName isEmpty ifFalse: [
			stream nextPutAll: 'Policy: '; nextPutAll: policyName asString; cr ].
		rows do: [ :row |
			stream nextPutAll: ((row collect: [ :each | each asString ]) joinUsing: Character tab asString); cr ] ]
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> memberReportText [
	| members policyName groupName |
	members := membersList items ifNil: [ #() ].
	policyName := self selectedPolicyName ifNil: [ '' ].
	groupName := self selectedGroupName ifNil: [ '' ].
	^ String streamContents: [ :stream |
		stream nextPutAll: '=== Members ==='; cr.
		policyName isEmpty ifFalse: [
			stream nextPutAll: 'Policy: '; nextPutAll: policyName asString; cr ].
		groupName isEmpty ifFalse: [
			stream nextPutAll: 'Group: '; nextPutAll: groupName asString; cr ].
		members do: [ :each |
			stream nextPutAll: each asString; cr ] ]
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> inspectSelectedPolicy [
	| policyName script |
	policyName := self selectedPolicyName.
	(policyName isNil or: [ policyName isEmpty ]) ifTrue: [ ^ self inform: 'Select a policy first.' ].
	script := self policyOopScriptForPolicyName: policyName.
	self inspectRemoteObjectUsingScript: script missingMessage: 'Could not inspect selected policy.'
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> inspectSelectedGroup [
	| policyName groupName script |
	policyName := self selectedPolicyName.
	groupName := self selectedGroupName.
	(policyName isNil or: [ policyName isEmpty ]) ifTrue: [ ^ self inform: 'Select a policy first.' ].
	(groupName isNil or: [ groupName isEmpty ]) ifTrue: [ ^ self inform: 'Select a group first.' ].
	script := self groupOopScriptForPolicyName: policyName groupName: groupName.
	self inspectRemoteObjectUsingScript: script missingMessage: 'Could not inspect selected group.'
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> inspectSelectedMember [
	| policyName groupName memberName script |
	policyName := self selectedPolicyName.
	groupName := self selectedGroupName.
	memberName := self selectedMemberName.
	(policyName isNil or: [ policyName isEmpty ]) ifTrue: [ ^ self inform: 'Select a policy first.' ].
	(groupName isNil or: [ groupName isEmpty ]) ifTrue: [ ^ self inform: 'Select a group first.' ].
	(memberName isNil or: [ memberName isEmpty ]) ifTrue: [ ^ self inform: 'Select a member first.' ].
	script := self
		memberOopScriptForPolicyName: policyName
		groupName: groupName
		memberName: memberName.
	self inspectRemoteObjectUsingScript: script missingMessage: 'Could not inspect selected member.'
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> refreshSelectedPolicyGroups [
	| row policyName |
	row := policiesTable selection selectedItem.
	row ifNil: [ ^ self ].
	policyName := row at: 3 ifAbsent: [ '' ].
	policyName isEmpty ifTrue: [ ^ self ].
	self refreshGroupsAndMembersForPolicyName: policyName
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> refreshSelectedPolicyMembers [
	| policyName groupName |
	policyName := self selectedPolicyName.
	groupName := self selectedGroupName.
	(policyName isNil or: [ policyName isEmpty ]) ifTrue: [ ^ self ].
	(groupName isNil or: [ groupName isEmpty ]) ifTrue: [ ^ self ].
	^ self refreshMembersForPolicyName: policyName groupName: groupName
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> selectedPolicyRow [
	| sel |
	(policiesTable respondsTo: #selection) ifFalse: [ ^ nil ].
	sel := [ policiesTable selection selectedItem ] on: Error do: [ nil ].
	^ sel
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> selectedPolicyName [
	| row |
	row := self selectedPolicyRow.
	row ifNil: [ ^ nil ].
	^ row at: 3 ifAbsent: [ nil ]
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> selectedGroupRow [
	| sel |
	(groupsTable respondsTo: #selection) ifFalse: [ ^ nil ].
	sel := [ groupsTable selection selectedItem ] on: Error do: [ nil ].
	^ sel
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> selectedGroupName [
	| row |
	row := self selectedGroupRow.
	row ifNil: [ ^ nil ].
	^ row at: 1 ifAbsent: [ nil ]
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> selectedMemberName [
	| sel |
	(membersList respondsTo: #selection) ifFalse: [ ^ nil ].
	sel := [ membersList selection selectedItem ] on: Error do: [ nil ].
	^ sel ifNotNil: [ sel asString ]
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> canOperateOnSelectedPolicy [
	| policyName |
	policyName := self selectedPolicyName.
	^ policyName isString and: [ policyName isNotEmpty ]
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> canOperateOnSelectedGroup [
	| groupName |
	groupName := self selectedGroupName.
	^ self canOperateOnSelectedPolicy and: [ groupName isString and: [ groupName isNotEmpty ] ]
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> canOperateOnSelectedMember [
	| memberName |
	memberName := self selectedMemberName.
	^ self canOperateOnSelectedGroup and: [ memberName isString and: [ memberName isNotEmpty ] ]
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> setSelectedPolicyCurrent [
	| policyName script |
	policyName := self selectedPolicyName.
	(policyName isNil or: [ policyName isEmpty ]) ifTrue: [ ^ self inform: 'Select a policy first.' ].
	(UIManager default
		confirm: 'Set "', policyName asString, '" as current security policy?'
		label: 'Set Current Policy') ifFalse: [ ^ self ].
	script := self setCurrentPolicyScriptForPolicyName: policyName.
	[
		session execute: script.
		self refreshAll
	] on: Error do: [ :ex | self inform: 'Set current policy failed: ', ex messageText ]
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> setSelectedPolicyDefault [
	| policyName script |
	policyName := self selectedPolicyName.
	(policyName isNil or: [ policyName isEmpty ]) ifTrue: [ ^ self inform: 'Select a policy first.' ].
	(UIManager default
		confirm: 'Set "', policyName asString, '" as default security policy?'
		label: 'Set Default Policy') ifFalse: [ ^ self ].
	script := self setDefaultPolicyScriptForPolicyName: policyName.
	[
		session execute: script.
		self refreshAll
	] on: Error do: [ :ex | self inform: 'Set default policy failed: ', ex messageText ]
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> editSelectedPolicyOwnerAccess [
	| policyName currentValue newValue script |
	policyName := self selectedPolicyName.
	(policyName isNil or: [ policyName isEmpty ]) ifTrue: [ ^ self inform: 'Select a policy first.' ].
	currentValue := [ (self selectedPolicyRow at: 5 ifAbsent: [ '' ]) asString ] on: Error do: [ '' ].
	newValue := UIManager default
		request: 'Owner access (e.g. read/write/none):'
		initialAnswer: currentValue.
	(newValue isNil or: [ newValue trimBoth isEmpty ]) ifTrue: [ ^ self ].
	script := self
		setPolicyOwnerAccessScriptForPolicyName: policyName
		accessString: newValue trimBoth.
	[
		session execute: script.
		self refreshAll
	] on: Error do: [ :ex | self inform: 'Edit owner access failed: ', ex messageText ]
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> editSelectedPolicyWorldAccess [
	| policyName currentValue newValue script |
	policyName := self selectedPolicyName.
	(policyName isNil or: [ policyName isEmpty ]) ifTrue: [ ^ self inform: 'Select a policy first.' ].
	currentValue := [ (self selectedPolicyRow at: 6 ifAbsent: [ '' ]) asString ] on: Error do: [ '' ].
	newValue := UIManager default
		request: 'World access (e.g. read/write/none):'
		initialAnswer: currentValue.
	(newValue isNil or: [ newValue trimBoth isEmpty ]) ifTrue: [ ^ self ].
	script := self
		setPolicyWorldAccessScriptForPolicyName: policyName
		accessString: newValue trimBoth.
	[
		session execute: script.
		self refreshAll
	] on: Error do: [ :ex | self inform: 'Edit world access failed: ', ex messageText ]
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> toggleSelectedPolicyTrackReads [
	| policyName currentTrackReads targetValue script |
	policyName := self selectedPolicyName.
	(policyName isNil or: [ policyName isEmpty ]) ifTrue: [ ^ self inform: 'Select a policy first.' ].
	currentTrackReads := [ (self selectedPolicyRow at: 8 ifAbsent: [ '' ]) asString asLowercase ] on: Error do: [ '' ].
	targetValue := (currentTrackReads = 'true' or: [ currentTrackReads = 'yes' ])
		ifTrue: [ false ]
		ifFalse: [ true ].
	script := self
		setPolicyTrackReadsScriptForPolicyName: policyName
		trackReads: targetValue.
	[
		session execute: script.
		self refreshAll
	] on: Error do: [ :ex | self inform: 'Toggle track reads failed: ', ex messageText ]
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> editSelectedGroupAccess [
	| policyName groupName currentAccess newAccess script |
	policyName := self selectedPolicyName.
	groupName := self selectedGroupName.
	(policyName isNil or: [ policyName isEmpty ]) ifTrue: [ ^ self inform: 'Select a policy first.' ].
	(groupName isNil or: [ groupName isEmpty ]) ifTrue: [ ^ self inform: 'Select a group first.' ].
	currentAccess := [ (self selectedGroupRow at: 2 ifAbsent: [ '' ]) asString ] on: Error do: [ '' ].
	newAccess := UIManager default
		request: 'Group access (e.g. read/write/none):'
		initialAnswer: currentAccess.
	(newAccess isNil or: [ newAccess trimBoth isEmpty ]) ifTrue: [ ^ self ].
	(UIManager default
		confirm: 'Change access for group "', groupName asString, '" in policy "', policyName asString, '" to "', newAccess trimBoth, '"?'
		label: 'Edit Group Access') ifFalse: [ ^ self ].
	script := self
		setGroupAccessScriptForPolicyName: policyName
		groupName: groupName
		accessString: newAccess trimBoth.
	[
		session execute: script.
		self refreshGroupsAndMembersForPolicyName: policyName
	] on: Error do: [ :ex | self inform: 'Edit group access failed: ', ex messageText ]
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> addGroupToSelectedPolicy [
	| policyName groupName accessString script |
	policyName := self selectedPolicyName.
	(policyName isNil or: [ policyName isEmpty ]) ifTrue: [ ^ self inform: 'Select a policy first.' ].
	groupName := UIManager default
		request: 'Group name to add:'
		initialAnswer: ''.
	(groupName isNil or: [ groupName trimBoth isEmpty ]) ifTrue: [ ^ self ].
	accessString := UIManager default
		request: 'Group access (e.g. read/write/none):'
		initialAnswer: 'read'.
	(accessString isNil or: [ accessString trimBoth isEmpty ]) ifTrue: [ ^ self ].
	(UIManager default
		confirm: 'Add group "', groupName trimBoth, '" to policy "', policyName asString, '" with access "', accessString trimBoth, '"?'
		label: 'Add Group') ifFalse: [ ^ self ].
	script := self
		addGroupScriptForPolicyName: policyName
		groupName: groupName trimBoth
		accessString: accessString trimBoth.
	[
		session execute: script.
		self refreshGroupsAndMembersForPolicyName: policyName
	] on: Error do: [ :ex | self inform: 'Add group failed: ', ex messageText ]
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> removeSelectedGroupFromPolicy [
	| policyName groupName script |
	policyName := self selectedPolicyName.
	groupName := self selectedGroupName.
	(policyName isNil or: [ policyName isEmpty ]) ifTrue: [ ^ self inform: 'Select a policy first.' ].
	(groupName isNil or: [ groupName isEmpty ]) ifTrue: [ ^ self inform: 'Select a group first.' ].
	(UIManager default
		confirm: 'Remove group "', groupName asString, '" from policy "', policyName asString, '"?'
		label: 'Remove Group') ifFalse: [ ^ self ].
	script := self
		removeGroupScriptForPolicyName: policyName
		groupName: groupName.
	[
		session execute: script.
		self refreshGroupsAndMembersForPolicyName: policyName
	] on: Error do: [ :ex | self inform: 'Remove group failed: ', ex messageText ]
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> addMemberToSelectedGroup [
	| policyName groupName memberName script |
	policyName := self selectedPolicyName.
	groupName := self selectedGroupName.
	(policyName isNil or: [ policyName isEmpty ]) ifTrue: [ ^ self inform: 'Select a policy first.' ].
	(groupName isNil or: [ groupName isEmpty ]) ifTrue: [ ^ self inform: 'Select a group first.' ].
	memberName := UIManager default
		request: 'Member user ID to add:'
		initialAnswer: ''.
	(memberName isNil or: [ memberName trimBoth isEmpty ]) ifTrue: [ ^ self ].
	(UIManager default
		confirm: 'Add member "', memberName trimBoth, '" to group "', groupName asString, '"?'
		label: 'Add Group Member') ifFalse: [ ^ self ].
	script := self
		addMemberScriptForPolicyName: policyName
		groupName: groupName
		memberName: memberName trimBoth.
	[
		session execute: script.
		self refreshGroupsAndMembersForPolicyName: policyName
	] on: Error do: [ :ex | self inform: 'Add member failed: ', ex messageText ]
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> removeSelectedMemberFromGroup [
	| policyName groupName memberName script |
	policyName := self selectedPolicyName.
	groupName := self selectedGroupName.
	memberName := self selectedMemberName.
	(policyName isNil or: [ policyName isEmpty ]) ifTrue: [ ^ self inform: 'Select a policy first.' ].
	(groupName isNil or: [ groupName isEmpty ]) ifTrue: [ ^ self inform: 'Select a group first.' ].
	(memberName isNil or: [ memberName isEmpty ]) ifTrue: [ ^ self inform: 'Select a member first.' ].
	(UIManager default
		confirm: 'Remove member "', memberName, '" from group "', groupName asString, '"?'
		label: 'Remove Group Member') ifFalse: [ ^ self ].
	script := self
		removeMemberScriptForPolicyName: policyName
		groupName: groupName
		memberName: memberName.
	[
		session execute: script.
		self refreshGroupsAndMembersForPolicyName: policyName
	] on: Error do: [ :ex | self inform: 'Remove member failed: ', ex messageText ]
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
	| raw policies previousPolicyName selected |
	(self isSessionUsable not) ifTrue: [
		policiesTable items: #().
		groupsTable items: #().
		membersList items: #().
		^ self
	].
	previousPolicyName := self selectedPolicyName.
	raw := [ session evaluate: self securityPoliciesScript ] on: Error do: [ :ex | self inform: 'Fetch security policies failed: ', ex messageText. '' ].
	policies := self parseRows: raw expectedColumns: 8.
	policiesTable items: policies.
	groupsTable items: #().
	membersList items: #().
	(policies isEmpty not) ifTrue: [
		selected := previousPolicyName
			ifNil: [ nil ]
			ifNotNil: [
				policies
					detect: [ :row | (row at: 3 ifAbsent: [ '' ]) = previousPolicyName ]
					ifNone: [ nil ] ].
		selected ifNil: [ selected := policies first ].
		(policiesTable respondsTo: #selectItem:)
			ifTrue: [ policiesTable selectItem: selected ]
			ifFalse: [
				(policiesTable respondsTo: #selectIndex:)
					ifTrue: [ policiesTable selectIndex: (policies indexOf: selected ifAbsent: [ 1 ]) ] ].
		self refreshGroupsAndMembersForPolicyName: (selected at: 3 ifAbsent: [ '' ])
	]
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> refreshGroupsAndMembersForPolicyName: policyName [
	| rawGroup groups previousGroupName selectedGroup |
	self isSessionUsable ifFalse: [
		groupsTable items: #().
		membersList items: #().
		^ self
	].
	previousGroupName := self selectedGroupName.
	(policyName isString and: [ policyName isEmpty ]) ifTrue: [ 
		groupsTable items: #().
		membersList items: #().
		^ self ].
	rawGroup := [ session evaluate: (self groupsScriptForPolicyName: policyName) ] on: Error do: [ '' ].
	groups := self parseRows: rawGroup expectedColumns: 2.
	groupsTable items: groups.
	membersList items: #().
	groups isEmpty ifFalse: [
		selectedGroup := previousGroupName
			ifNil: [ nil ]
			ifNotNil: [
				groups
					detect: [ :row | (row at: 1 ifAbsent: [ '' ]) = previousGroupName ]
					ifNone: [ nil ] ].
		selectedGroup ifNil: [ selectedGroup := groups first ].
		(groupsTable respondsTo: #selectItem:)
			ifTrue: [ groupsTable selectItem: selectedGroup ]
			ifFalse: [
				(groupsTable respondsTo: #selectIndex:)
					ifTrue: [ groupsTable selectIndex: (groups indexOf: selectedGroup ifAbsent: [ 1 ]) ] ].
		self refreshMembersForPolicyName: policyName groupName: (selectedGroup at: 1 ifAbsent: [ '' ]) ]
]

{ #category : 'actions' }
GbsSecurityPoliciesPresenter >> refreshMembersForPolicyName: policyName groupName: groupName [
	| rawMembers members previousMemberName selectedMember |
	self isSessionUsable ifFalse: [
		membersList items: #().
		^ self
	].
	previousMemberName := self selectedMemberName.
	((policyName isNil or: [ policyName isEmpty ]) or: [ groupName isNil or: [ groupName isEmpty ] ])
		ifTrue: [ membersList items: #(). ^ self ].
	rawMembers := [ session evaluate: (self membersScriptForPolicyName: policyName groupName: groupName) ]
		on: Error
		do: [ '' ].
	members := (rawMembers isString ifTrue: [ rawMembers lines ] ifFalse: [ #() ]).
	membersList items: members.
	((membersList respondsTo: #selectedItem:) and: [ members isEmpty not ]) ifTrue: [
		selectedMember := previousMemberName
			ifNil: [ nil ]
			ifNotNil: [ members detect: [ :each | each asString = previousMemberName ] ifNone: [ nil ] ].
		membersList selectedItem: (selectedMember ifNil: [ members first ] ifNotNil: [ selectedMember ]) ]
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
GbsSecurityPoliciesPresenter >> membersScriptForPolicyName: policyName groupName: groupName [
	| nameLiteral groupLiteral |
	nameLiteral := self literalString: policyName.
	groupLiteral := self literalString: groupName.
	^ '
	| allPolicies policy strm allGroups grp |
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
	allGroups := System myUserProfile symbolList objectNamed: #AllGroups.
	grp := nil.
	(policy groups respondsTo: #at:ifAbsent:)
		ifTrue: [ grp := policy groups at: ', groupLiteral, ' ifAbsent: [ nil ] ].
	grp ifNil: [
		(policy groups respondsTo: #detect:ifNone:)
			ifTrue: [
				grp := policy groups
					detect: [ :each | (each respondsTo: #name) and: [ each name asString = ', groupLiteral, ' ] ]
					ifNone: [ nil ] ] ].
	grp ifNil: [ ^ '''' ].
	(allGroups notNil and: [ grp isString ])
		ifTrue: [
			grp := allGroups at: grp ifAbsent: [ nil ] ].
	(grp notNil and: [ grp respondsTo: #members ]) ifTrue: [
		grp members do: [ :member | strm nextPutAll: member asString; cr ] ].
	strm contents'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> setCurrentPolicyScriptForPolicyName: policyName [
	| nameLiteral |
	nameLiteral := self literalString: policyName.
	^ '
	| allPolicies policy |
	allPolicies := System myUserProfile symbolList objectNamed: #AllSecurityPolicies.
	allPolicies ifNil: [ allPolicies := System myUserProfile symbolList objectNamed: #AllObjectSecurityPolicies ].
	allPolicies ifNil: [ self error: ''AllSecurityPolicies not found'' ].
	policy := allPolicies
		detect: [ :p | ((p respondsTo: #name) ifTrue: [ p name asString ] ifFalse: [ p printString ]) = ', nameLiteral, ' ]
		ifNone: [ nil ].
	policy ifNil: [ self error: ''Policy not found'' ].
	(System myUserProfile respondsTo: #securityPolicy:)
		ifTrue: [ System myUserProfile securityPolicy: policy ]
		ifFalse: [
			(System respondsTo: #currentObjectSecurityPolicy:)
				ifTrue: [ System currentObjectSecurityPolicy: policy ]
				ifFalse: [ self error: ''No API for current policy'' ] ].
	true'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> setDefaultPolicyScriptForPolicyName: policyName [
	| nameLiteral |
	nameLiteral := self literalString: policyName.
	^ '
	| allPolicies policy |
	allPolicies := System myUserProfile symbolList objectNamed: #AllSecurityPolicies.
	allPolicies ifNil: [ allPolicies := System myUserProfile symbolList objectNamed: #AllObjectSecurityPolicies ].
	allPolicies ifNil: [ self error: ''AllSecurityPolicies not found'' ].
	policy := allPolicies
		detect: [ :p | ((p respondsTo: #name) ifTrue: [ p name asString ] ifFalse: [ p printString ]) = ', nameLiteral, ' ]
		ifNone: [ nil ].
	policy ifNil: [ self error: ''Policy not found'' ].
	(System myUserProfile respondsTo: #defaultObjectSecurityPolicy:)
		ifTrue: [ System myUserProfile defaultObjectSecurityPolicy: policy ]
		ifFalse: [
			(System myUserProfile class respondsTo: #defaultSecurityPolicy:)
				ifTrue: [ System myUserProfile class defaultSecurityPolicy: policy ]
				ifFalse: [ self error: ''No API for default policy'' ] ].
	true'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> setPolicyOwnerAccessScriptForPolicyName: policyName accessString: accessString [
	| p a |
	p := self literalString: policyName.
	a := self literalString: accessString.
	^ '
	| allPolicies policy |
	allPolicies := System myUserProfile symbolList objectNamed: #AllSecurityPolicies.
	allPolicies ifNil: [ allPolicies := System myUserProfile symbolList objectNamed: #AllObjectSecurityPolicies ].
	allPolicies ifNil: [ self error: ''AllSecurityPolicies not found'' ].
	policy := allPolicies
		detect: [ :sp | ((sp respondsTo: #name) ifTrue: [ sp name asString ] ifFalse: [ sp printString ]) = ', p, ' ]
		ifNone: [ nil ].
	policy ifNil: [ self error: ''Policy not found'' ].
	(policy respondsTo: #ownerAuthorization:)
		ifTrue: [ policy ownerAuthorization: ', a, ' ]
		ifFalse: [
			(policy respondsTo: #ownerAccess:)
				ifTrue: [ policy ownerAccess: ', a, ' ]
				ifFalse: [ self error: ''No API for owner access'' ] ].
	true'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> setPolicyWorldAccessScriptForPolicyName: policyName accessString: accessString [
	| p a |
	p := self literalString: policyName.
	a := self literalString: accessString.
	^ '
	| allPolicies policy |
	allPolicies := System myUserProfile symbolList objectNamed: #AllSecurityPolicies.
	allPolicies ifNil: [ allPolicies := System myUserProfile symbolList objectNamed: #AllObjectSecurityPolicies ].
	allPolicies ifNil: [ self error: ''AllSecurityPolicies not found'' ].
	policy := allPolicies
		detect: [ :sp | ((sp respondsTo: #name) ifTrue: [ sp name asString ] ifFalse: [ sp printString ]) = ', p, ' ]
		ifNone: [ nil ].
	policy ifNil: [ self error: ''Policy not found'' ].
	(policy respondsTo: #worldAuthorization:)
		ifTrue: [ policy worldAuthorization: ', a, ' ]
		ifFalse: [
			(policy respondsTo: #worldAccess:)
				ifTrue: [ policy worldAccess: ', a, ' ]
				ifFalse: [ self error: ''No API for world access'' ] ].
	true'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> setPolicyTrackReadsScriptForPolicyName: policyName trackReads: aBoolean [
	| p flag |
	p := self literalString: policyName.
	flag := aBoolean ifTrue: [ 'true' ] ifFalse: [ 'false' ].
	^ '
	| allPolicies policy |
	allPolicies := System myUserProfile symbolList objectNamed: #AllSecurityPolicies.
	allPolicies ifNil: [ allPolicies := System myUserProfile symbolList objectNamed: #AllObjectSecurityPolicies ].
	allPolicies ifNil: [ self error: ''AllSecurityPolicies not found'' ].
	policy := allPolicies
		detect: [ :sp | ((sp respondsTo: #name) ifTrue: [ sp name asString ] ifFalse: [ sp printString ]) = ', p, ' ]
		ifNone: [ nil ].
	policy ifNil: [ self error: ''Policy not found'' ].
	(policy respondsTo: #trackReads:)
		ifTrue: [ policy trackReads: ', flag, ' ]
		ifFalse: [
			(policy respondsTo: #isTrackingReads:)
				ifTrue: [ policy isTrackingReads: ', flag, ' ]
				ifFalse: [ self error: ''No API for track reads'' ] ].
	true'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> setGroupAccessScriptForPolicyName: policyName groupName: groupName accessString: accessString [
	| p g a |
	p := self literalString: policyName.
	g := self literalString: groupName.
	a := self literalString: accessString.
	^ '
	| allPolicies policy groups |
	allPolicies := System myUserProfile symbolList objectNamed: #AllSecurityPolicies.
	allPolicies ifNil: [ allPolicies := System myUserProfile symbolList objectNamed: #AllObjectSecurityPolicies ].
	allPolicies ifNil: [ self error: ''AllSecurityPolicies not found'' ].
	policy := allPolicies
		detect: [ :sp | ((sp respondsTo: #name) ifTrue: [ sp name asString ] ifFalse: [ sp printString ]) = ', p, ' ]
		ifNone: [ nil ].
	policy ifNil: [ self error: ''Policy not found'' ].
	(policy respondsTo: #groups) ifFalse: [ self error: ''Policy has no groups API'' ].
	groups := policy groups.
	(groups respondsTo: #at:put:)
		ifTrue: [ groups at: ', g, ' put: ', a, ' ]
		ifFalse: [ self error: ''Groups dictionary is not mutable'' ].
	true'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> addGroupScriptForPolicyName: policyName groupName: groupName accessString: accessString [
	| p g a |
	p := self literalString: policyName.
	g := self literalString: groupName.
	a := self literalString: accessString.
	^ '
	| allPolicies policy groups allGroups |
	allPolicies := System myUserProfile symbolList objectNamed: #AllSecurityPolicies.
	allPolicies ifNil: [ allPolicies := System myUserProfile symbolList objectNamed: #AllObjectSecurityPolicies ].
	allPolicies ifNil: [ self error: ''AllSecurityPolicies not found'' ].
	policy := allPolicies
		detect: [ :sp | ((sp respondsTo: #name) ifTrue: [ sp name asString ] ifFalse: [ sp printString ]) = ', p, ' ]
		ifNone: [ nil ].
	policy ifNil: [ self error: ''Policy not found'' ].
	(policy respondsTo: #groups) ifFalse: [ self error: ''Policy has no groups API'' ].
	groups := policy groups.
	(groups respondsTo: #at:ifAbsent:)
		ifTrue: [ (groups at: ', g, ' ifAbsent: [ nil ]) ifNotNil: [ self error: ''Group already exists in policy'' ] ].
	allGroups := System myUserProfile symbolList objectNamed: #AllGroups.
	allGroups ifNotNil: [
		(allGroups at: ', g, ' ifAbsent: [ nil ]) ifNil: [ self error: ''Group not found'' ] ].
	(groups respondsTo: #at:put:)
		ifTrue: [ groups at: ', g, ' put: ', a, ' ]
		ifFalse: [ self error: ''Groups dictionary is not mutable'' ].
	true'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> removeGroupScriptForPolicyName: policyName groupName: groupName [
	| p g |
	p := self literalString: policyName.
	g := self literalString: groupName.
	^ '
	| allPolicies policy groups |
	allPolicies := System myUserProfile symbolList objectNamed: #AllSecurityPolicies.
	allPolicies ifNil: [ allPolicies := System myUserProfile symbolList objectNamed: #AllObjectSecurityPolicies ].
	allPolicies ifNil: [ self error: ''AllSecurityPolicies not found'' ].
	policy := allPolicies
		detect: [ :sp | ((sp respondsTo: #name) ifTrue: [ sp name asString ] ifFalse: [ sp printString ]) = ', p, ' ]
		ifNone: [ nil ].
	policy ifNil: [ self error: ''Policy not found'' ].
	(policy respondsTo: #groups) ifFalse: [ self error: ''Policy has no groups API'' ].
	groups := policy groups.
	(groups respondsTo: #removeKey:ifAbsent:)
		ifTrue: [ groups removeKey: ', g, ' ifAbsent: [ self error: ''Group not found in policy'' ] ]
		ifFalse: [ self error: ''Groups dictionary is not mutable'' ].
	true'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> addMemberScriptForPolicyName: policyName groupName: groupName memberName: memberName [
	| g m |
	g := self literalString: groupName.
	m := self literalString: memberName.
	^ '
	| allGroups allUsers grp user |
	allGroups := System myUserProfile symbolList objectNamed: #AllGroups.
	allUsers := System myUserProfile symbolList objectNamed: #AllUsers.
	allGroups ifNil: [ self error: ''AllGroups not found'' ].
	allUsers ifNil: [ self error: ''AllUsers not found'' ].
	grp := allGroups at: ', g, ' ifAbsent: [ nil ].
	grp ifNil: [ self error: ''Group not found'' ].
	user := allUsers detect: [ :u | u userId asString = ', m, ' ] ifNone: [ nil ].
	user ifNil: [ self error: ''User not found'' ].
	(grp respondsTo: #add:)
		ifTrue: [ grp add: user ]
		ifFalse: [
			(grp respondsTo: #addMember:)
				ifTrue: [ grp addMember: user ]
				ifFalse: [ self error: ''Group add API not found'' ] ].
	true'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> removeMemberScriptForPolicyName: policyName groupName: groupName memberName: memberName [
	| g m |
	g := self literalString: groupName.
	m := self literalString: memberName.
	^ '
	| allGroups allUsers grp user |
	allGroups := System myUserProfile symbolList objectNamed: #AllGroups.
	allUsers := System myUserProfile symbolList objectNamed: #AllUsers.
	allGroups ifNil: [ self error: ''AllGroups not found'' ].
	allUsers ifNil: [ self error: ''AllUsers not found'' ].
	grp := allGroups at: ', g, ' ifAbsent: [ nil ].
	grp ifNil: [ self error: ''Group not found'' ].
	user := allUsers detect: [ :u | u userId asString = ', m, ' ] ifNone: [ nil ].
	user ifNil: [ self error: ''User not found'' ].
	(grp respondsTo: #remove:)
		ifTrue: [ grp remove: user ifAbsent: [ ] ]
		ifFalse: [
			(grp respondsTo: #removeMember:)
				ifTrue: [ grp removeMember: user ]
				ifFalse: [ self error: ''Group remove API not found'' ] ].
	true'
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
GbsSecurityPoliciesPresenter >> policyOopScriptForPolicyName: policyName [
	| p |
	p := self literalString: policyName.
	^ '
	| allPolicies policy |
	allPolicies := System myUserProfile symbolList objectNamed: #AllSecurityPolicies.
	allPolicies ifNil: [ allPolicies := System myUserProfile symbolList objectNamed: #AllObjectSecurityPolicies ].
	allPolicies ifNil: [ ^ 20 ].
	policy := allPolicies
		detect: [ :sp | ((sp respondsTo: #name) ifTrue: [ sp name asString ] ifFalse: [ sp printString ]) = ', p, ' ]
		ifNone: [ nil ].
	policy ifNil: [ ^ 20 ].
	Reflection oopOf: policy'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> groupOopScriptForPolicyName: policyName groupName: groupName [
	| p g |
	p := self literalString: policyName.
	g := self literalString: groupName.
	^ '
	| allPolicies policy groups grp allGroups |
	allPolicies := System myUserProfile symbolList objectNamed: #AllSecurityPolicies.
	allPolicies ifNil: [ allPolicies := System myUserProfile symbolList objectNamed: #AllObjectSecurityPolicies ].
	allPolicies ifNil: [ ^ 20 ].
	policy := allPolicies
		detect: [ :sp | ((sp respondsTo: #name) ifTrue: [ sp name asString ] ifFalse: [ sp printString ]) = ', p, ' ]
		ifNone: [ nil ].
	policy ifNil: [ ^ 20 ].
	(policy respondsTo: #groups) ifFalse: [ ^ 20 ].
	groups := policy groups.
	(groups respondsTo: #at:ifAbsent:)
		ifTrue: [ grp := groups at: ', g, ' ifAbsent: [ nil ] ]
		ifFalse: [ grp := nil ].
	(grp isString) ifTrue: [
		allGroups := System myUserProfile symbolList objectNamed: #AllGroups.
		grp := allGroups ifNil: [ nil ] ifNotNil: [ allGroups at: grp ifAbsent: [ nil ] ] ].
	grp ifNil: [ ^ 20 ].
	Reflection oopOf: grp'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> memberOopScriptForPolicyName: policyName groupName: groupName memberName: memberName [
	| p g m |
	p := self literalString: policyName.
	g := self literalString: groupName.
	m := self literalString: memberName.
	^ '
	| allPolicies policy groups grp allGroups member |
	allPolicies := System myUserProfile symbolList objectNamed: #AllSecurityPolicies.
	allPolicies ifNil: [ allPolicies := System myUserProfile symbolList objectNamed: #AllObjectSecurityPolicies ].
	allPolicies ifNil: [ ^ 20 ].
	policy := allPolicies
		detect: [ :sp | ((sp respondsTo: #name) ifTrue: [ sp name asString ] ifFalse: [ sp printString ]) = ', p, ' ]
		ifNone: [ nil ].
	policy ifNil: [ ^ 20 ].
	(policy respondsTo: #groups) ifFalse: [ ^ 20 ].
	groups := policy groups.
	(groups respondsTo: #at:ifAbsent:)
		ifTrue: [ grp := groups at: ', g, ' ifAbsent: [ nil ] ]
		ifFalse: [ grp := nil ].
	(grp isString) ifTrue: [
		allGroups := System myUserProfile symbolList objectNamed: #AllGroups.
		grp := allGroups ifNil: [ nil ] ifNotNil: [ allGroups at: grp ifAbsent: [ nil ] ] ].
	(grp isNil or: [ (grp respondsTo: #members) not ]) ifTrue: [ ^ 20 ].
	member := grp members detect: [ :each | each asString = ', m, ' ] ifNone: [ nil ].
	member ifNil: [ ^ 20 ].
	Reflection oopOf: member'
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> inspectRemoteObjectUsingScript: scriptString missingMessage: missingMessageString [
	| oop |
	(session isNil or: [ scriptString isNil or: [ scriptString isEmpty ] ]) ifTrue: [ ^ self ].
	oop := [ session serverInterface apiGciExecuteStr: scriptString context: 20 env: 0 ] on: Error do: [ nil ].
	((oop isNumber) and: [ oop > 20 ])
		ifTrue: [ GbsInspector inspect: oop session: session ]
		ifFalse: [ self inform: missingMessageString ]
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> session: aSession [
	session := aSession
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> isSessionUsable [
	session ifNil: [ ^ false ].
	(session respondsTo: #isLoggedIn)
		ifTrue: [ ^ [ session isLoggedIn == true ] on: Error do: [ false ] ].
	^ true
]

{ #category : 'private' }
GbsSecurityPoliciesPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]
