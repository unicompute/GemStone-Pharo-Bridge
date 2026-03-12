Class {
	#name : 'GbsAdminToolsPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
	'createUserPresenter',
	'connectorBrowserPresenter',
	'namespacesPresenter',
	'securityPoliciesPresenter',
	'userListPresenter',
	'userInfoPresenter',
	'previousConfiguration'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsAdminToolsPresenterTest >> setUp [
	super setUp.
	previousConfiguration := GbsConfiguration current.
	createUserPresenter := GbsCreateUserPresenter new.
	connectorBrowserPresenter := GbsConnectorBrowserPresenter new.
	namespacesPresenter := GbsNamespacesPresenter new.
	securityPoliciesPresenter := GbsSecurityPoliciesPresenter new.
	userListPresenter := GbsUserListPresenter new.
	userInfoPresenter := (Smalltalk at: #GbsUserInfoPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ nil ]
]

{ #category : 'running' }
GbsAdminToolsPresenterTest >> tearDown [
	previousConfiguration ifNotNil: [ GbsConfiguration current: previousConfiguration ].
	super tearDown
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testCreateUserLiteralStringEscapesEmbeddedQuote [
	self
		assert: (createUserPresenter literalString: 'o''connor')
		equals: '''o''''connor'''
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testCreateUserScriptIncludesEscapedCredentials [
	| script |
	script := createUserPresenter
		scriptToCreateUser: 'da''ta'
		password: 'pw''1'.

	self assert: (script includesSubstring: '''da''''ta''').
	self assert: (script includesSubstring: '''pw''''1''')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testNamespacesParseRowsParsesTabSeparatedColumns [
	| rows |
	rows := namespacesPresenter parseRows: '1', Character tab asString, 'UserGlobals', Character tab asString, 'SymbolDictionary', String lf, '2', Character tab asString, 'Globals', Character tab asString, 'SymbolDictionary'.

	self assert: rows size equals: 2.
	self assert: (rows first at: 1) equals: '1'.
	self assert: (rows first at: 2) equals: 'UserGlobals'.
	self assert: (rows first at: 3) equals: 'SymbolDictionary'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesLiteralStringEscapesEmbeddedQuote [
	self
		assert: (securityPoliciesPresenter literalString: 'Data''Curator')
		equals: '''Data''''Curator'''
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesParseRowsPadsMissingColumns [
	| rows row |
	rows := securityPoliciesPresenter
		parseRows: 'Current', Character tab asString, 'Default', Character tab asString, 'DataCuratorObjectSecurityPolicy'
		expectedColumns: 8.
	row := rows first.

	self assert: row size equals: 8.
	self assert: (row at: 1) equals: 'Current'.
	self assert: (row at: 2) equals: 'Default'.
	self assert: (row at: 3) equals: 'DataCuratorObjectSecurityPolicy'.
	self assert: (row at: 8) equals: ''
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesFullReportTextIncludesPoliciesGroupsAndMembers [
	| fakePolicies fakeGroups fakeMembers report |
	fakePolicies := GbxFakeTablePresenterForRemoteDebugger new.
	fakePolicies items: { #('Current' 'Default' 'PolicyA' 'DataCurator' 'write' 'read' '2' 'No') }.
	fakeGroups := GbxFakeTablePresenterForRemoteDebugger new.
	fakeGroups items: { #('DataCuratorGroup' 'write') }.
	fakeMembers := GbxFakeListPresenterForBrowser new.
	fakeMembers items: #('DataCurator' 'GcUser').

	securityPoliciesPresenter instVarNamed: 'policiesTable' put: fakePolicies.
	securityPoliciesPresenter instVarNamed: 'groupsTable' put: fakeGroups.
	securityPoliciesPresenter instVarNamed: 'membersList' put: fakeMembers.

	report := securityPoliciesPresenter fullReportText.

	self assert: (report includesSubstring: '=== Policies ===').
	self assert: (report includesSubstring: 'PolicyA').
	self assert: (report includesSubstring: '=== Groups ===').
	self assert: (report includesSubstring: 'DataCuratorGroup').
	self assert: (report includesSubstring: '=== Members ===').
	self assert: (report includesSubstring: 'GcUser')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesMembersScriptIncludesSelectedGroupLiteral [
	| script |
	script := securityPoliciesPresenter
		membersScriptForPolicyName: 'Policy''A'
		groupName: 'Group''B'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: '''Group''''B''')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesRefreshSelectedPolicyMembersUsesSelectedGroup [
	| mockSession fakePolicies fakeGroups fakeMembers lastScript |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	lastScript := ''.
	mockSession stubs at: #evaluate put: [ :script |
		lastScript := script.
		'DataCurator', String lf, 'GcUser' ].

	fakePolicies := GbxFakeTablePresenterForRemoteDebugger new.
	fakePolicies items: { #('Current' 'Default' 'PolicyA') }.
	fakePolicies selectedItem: fakePolicies items first.

	fakeGroups := GbxFakeTablePresenterForRemoteDebugger new.
	fakeGroups items: { #('DataCuratorGroup' 'write') }.
	fakeGroups selectedItem: fakeGroups items first.

	fakeMembers := GbxFakeListPresenterForBrowser new.

	securityPoliciesPresenter instVarNamed: 'session' put: mockSession.
	securityPoliciesPresenter instVarNamed: 'policiesTable' put: fakePolicies.
	securityPoliciesPresenter instVarNamed: 'groupsTable' put: fakeGroups.
	securityPoliciesPresenter instVarNamed: 'membersList' put: fakeMembers.

	securityPoliciesPresenter refreshSelectedPolicyMembers.

	self assert: (lastScript includesSubstring: '''DataCuratorGroup''').
	self assert: fakeMembers items size equals: 2.
	self assert: fakeMembers items first equals: 'DataCurator'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesAddGroupScriptEscapesInputsAndAddsMapping [
	| script |
	script := securityPoliciesPresenter
		addGroupScriptForPolicyName: 'Policy''A'
		groupName: 'Group''B'
		accessString: 'read'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: '''Group''''B''').
	self assert: (script includesSubstring: 'Group already exists in policy').
	self assert: (script includesSubstring: 'groups at: ').
	self assert: (script includesSubstring: ' put: ')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesRemoveGroupScriptEscapesInputsAndRemovesMapping [
	| script |
	script := securityPoliciesPresenter
		removeGroupScriptForPolicyName: 'Policy''A'
		groupName: 'Group''B'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: '''Group''''B''').
	self assert: (script includesSubstring: 'removeKey:').
	self assert: (script includesSubstring: 'Group not found in policy')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesPolicyOopScriptEscapesPolicyName [
	| script |
	script := securityPoliciesPresenter policyOopScriptForPolicyName: 'Policy''A'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: 'Reflection oopOf: policy')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesGroupOopScriptEscapesPolicyAndGroupNames [
	| script |
	script := securityPoliciesPresenter
		groupOopScriptForPolicyName: 'Policy''A'
		groupName: 'Group''B'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: '''Group''''B''').
	self assert: (script includesSubstring: 'Reflection oopOf: grp')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesMemberOopScriptEscapesAllNames [
	| script |
	script := securityPoliciesPresenter
		memberOopScriptForPolicyName: 'Policy''A'
		groupName: 'Group''B'
		memberName: 'User''C'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: '''Group''''B''').
	self assert: (script includesSubstring: '''User''''C''').
	self assert: (script includesSubstring: 'Reflection oopOf: member')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesPolicyReportTextUsesSelectedPolicyOnly [
	| fakePolicies report |
	fakePolicies := GbxFakeTablePresenterForRemoteDebugger new.
	fakePolicies items: {
		#('Current' 'Default' 'PolicyA' 'OwnerA' 'write' 'read' '1' 'No').
		#('' '' 'PolicyB' 'OwnerB' 'read' 'read' '2' 'Yes') }.
	fakePolicies selectedItem: fakePolicies items second.

	securityPoliciesPresenter instVarNamed: 'policiesTable' put: fakePolicies.
	securityPoliciesPresenter instVarNamed: 'groupsTable' put: (GbxFakeTablePresenterForRemoteDebugger new).
	securityPoliciesPresenter instVarNamed: 'membersList' put: (GbxFakeListPresenterForBrowser new).

	report := securityPoliciesPresenter policyReportText.
	self assert: (report includesSubstring: 'PolicyB').
	self deny: (report includesSubstring: 'PolicyA')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesGroupAndMemberReportsIncludeContextHeaders [
	| fakePolicies fakeGroups fakeMembers groupReport memberReport |
	fakePolicies := GbxFakeTablePresenterForRemoteDebugger new.
	fakePolicies items: { #('Current' 'Default' 'PolicyA' 'OwnerA' 'write' 'read' '1' 'No') }.
	fakePolicies selectedItem: fakePolicies items first.

	fakeGroups := GbxFakeTablePresenterForRemoteDebugger new.
	fakeGroups items: { #('DataCuratorGroup' 'write') }.
	fakeGroups selectedItem: fakeGroups items first.

	fakeMembers := GbxFakeListPresenterForBrowser new.
	fakeMembers items: #('DataCurator' 'GcUser').

	securityPoliciesPresenter instVarNamed: 'policiesTable' put: fakePolicies.
	securityPoliciesPresenter instVarNamed: 'groupsTable' put: fakeGroups.
	securityPoliciesPresenter instVarNamed: 'membersList' put: fakeMembers.

	groupReport := securityPoliciesPresenter groupReportText.
	memberReport := securityPoliciesPresenter memberReportText.

	self assert: (groupReport includesSubstring: 'Policy: PolicyA').
	self assert: (groupReport includesSubstring: 'DataCuratorGroup').
	self assert: (memberReport includesSubstring: 'Policy: PolicyA').
	self assert: (memberReport includesSubstring: 'Group: DataCuratorGroup').
	self assert: (memberReport includesSubstring: 'GcUser')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesSetPolicyOwnerAccessScriptEscapesInputs [
	| script |
	script := securityPoliciesPresenter
		setPolicyOwnerAccessScriptForPolicyName: 'Policy''A'
		accessString: 'write'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: '''write''').
	self assert: (script includesSubstring: 'ownerAuthorization:').
	self assert: (script includesSubstring: 'ownerAccess:')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesSetPolicyWorldAccessScriptEscapesInputs [
	| script |
	script := securityPoliciesPresenter
		setPolicyWorldAccessScriptForPolicyName: 'Policy''A'
		accessString: 'read'.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: '''read''').
	self assert: (script includesSubstring: 'worldAuthorization:').
	self assert: (script includesSubstring: 'worldAccess:')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testSecurityPoliciesSetPolicyTrackReadsScriptWritesBooleanLiteral [
	| script |
	script := securityPoliciesPresenter
		setPolicyTrackReadsScriptForPolicyName: 'Policy''A'
		trackReads: true.

	self assert: (script includesSubstring: '''Policy''''A''').
	self assert: (script includesSubstring: 'trackReads: true').
	self assert: (script includesSubstring: 'isTrackingReads:')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserLoadOptionsFromConfigurationAppliesPostConnectAction [
	| cfg verify remove connected disconnected updateSt updateGs fwd cfwd none |
	cfg := GbsConfiguration new.
	cfg valueAt: #connectVerification put: false.
	cfg valueAt: #removeInvalidConnectors put: true.
	cfg valueAt: #connectorConnectionState put: 'disconnected'.
	cfg valueAt: #postConnectAction put: 'forwarder'.
	GbsConfiguration current: cfg.

	verify := GbxFakeTogglePresenter new.
	remove := GbxFakeTogglePresenter new.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	fwd := GbxFakeTogglePresenter new.
	cfwd := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.

	connectorBrowserPresenter instVarNamed: 'verificationCheck' put: verify.
	connectorBrowserPresenter instVarNamed: 'removeInvalidCheck' put: remove.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: fwd.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: cfwd.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter loadOptionsFromConfiguration.

	self deny: verify state.
	self assert: remove state.
	self deny: connected state.
	self assert: disconnected state.
	self assert: fwd state.
	self deny: updateSt state.
	self deny: updateGs state.
	self deny: cfwd state.
	self deny: none state
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserLoadOptionsDefaultsPostConnectActionToNone [
	| cfg verify remove connected disconnected updateSt updateGs fwd cfwd none |
	cfg := GbsConfiguration new.
	cfg valueAt: #connectVerification put: true.
	cfg valueAt: #removeInvalidConnectors put: true.
	cfg valueAt: #connectorConnectionState put: 'connected'.
	GbsConfiguration current: cfg.

	verify := GbxFakeTogglePresenter new.
	remove := GbxFakeTogglePresenter new.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	fwd := GbxFakeTogglePresenter new.
	cfwd := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.

	connectorBrowserPresenter instVarNamed: 'verificationCheck' put: verify.
	connectorBrowserPresenter instVarNamed: 'removeInvalidCheck' put: remove.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: fwd.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: cfwd.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter loadOptionsFromConfiguration.

	self assert: none state.
	self assert: (cfg valueAt: #postConnectAction ifAbsent: nil) equals: 'none'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserSaveOptionsToConfigurationStoresCurrentValues [
	| cfg verify remove connected disconnected updateSt updateGs fwd cfwd none |
	cfg := GbsConfiguration new.
	GbsConfiguration current: cfg.

	verify := GbxFakeTogglePresenter new.
	remove := GbxFakeTogglePresenter new.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	fwd := GbxFakeTogglePresenter new.
	cfwd := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.

	verify state: true.
	remove state: false.
	connected state: false.
	disconnected state: true.
	updateSt state: false.
	updateGs state: true.
	fwd state: false.
	cfwd state: false.
	none state: false.

	connectorBrowserPresenter instVarNamed: 'verificationCheck' put: verify.
	connectorBrowserPresenter instVarNamed: 'removeInvalidCheck' put: remove.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: fwd.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: cfwd.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter saveOptionsToConfiguration.

	self assert: (cfg valueAt: #connectVerification ifAbsent: nil) equals: true.
	self assert: (cfg valueAt: #removeInvalidConnectors ifAbsent: nil) equals: false.
	self assert: (cfg valueAt: #connectorConnectionState ifAbsent: nil) equals: 'disconnected'.
	self assert: (cfg valueAt: #postConnectAction ifAbsent: nil) equals: 'updateGS'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserApplyConnectionStateMapsDisconnectedSelection [
	| connected disconnected |
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.

	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.

	connectorBrowserPresenter applyConnectionState: 'disconnected'.

	self deny: connected state.
	self assert: disconnected state.
	self assert: connectorBrowserPresenter selectedConnectionState equals: 'disconnected'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserFilteredConnectorPairsHidesSessionRowsWhenDisconnected [
	| connected disconnected pairs filtered |
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	disconnected state: true.

	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.

	pairs := { #('Array' 'OArray'). #('String' 'OByteString') }.
	filtered := connectorBrowserPresenter
		filteredConnectorPairs: pairs
		forGroupLabel: 'Session connectors - ''DataCurator'' on ''gs64stone'''.

	self assert: filtered equals: #()
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserOptionSelectionChangedSavesAndRefreshes [
	| cfg verify remove connected disconnected updateSt updateGs fwd cfwd none fakeGroupList fakeTable |
	cfg := GbsConfiguration new.
	GbsConfiguration current: cfg.

	verify := GbxFakeTogglePresenter new.
	remove := GbxFakeTogglePresenter new.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	fwd := GbxFakeTogglePresenter new.
	cfwd := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.
	verify state: true.
	remove state: false.
	connected state: false.
	disconnected state: true.
	updateSt state: false.
	updateGs state: false.
	fwd state: true.
	cfwd state: false.
	none state: false.

	fakeGroupList := GbxFakeListPresenterForBrowser new.
	fakeGroupList selectedItem: 'Session connectors - ''DataCurator'' on ''gs64stone'''.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	fakeTable items: { #('sentinel') }.

	connectorBrowserPresenter instVarNamed: 'verificationCheck' put: verify.
	connectorBrowserPresenter instVarNamed: 'removeInvalidCheck' put: remove.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: fwd.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: cfwd.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.
	connectorBrowserPresenter instVarNamed: 'groupList' put: fakeGroupList.
	connectorBrowserPresenter instVarNamed: 'groupItems' put: { fakeGroupList selectedItem }.
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.

	connectorBrowserPresenter optionSelectionChanged.

	self assert: (cfg valueAt: #connectVerification ifAbsent: nil) equals: true.
	self assert: (cfg valueAt: #removeInvalidConnectors ifAbsent: nil) equals: false.
	self assert: (cfg valueAt: #connectorConnectionState ifAbsent: nil) equals: 'disconnected'.
	self assert: (cfg valueAt: #postConnectAction ifAbsent: nil) equals: 'forwarder'.
	self assert: fakeTable items equals: #()
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserApplySettingsForRowUsesRowDefaultsNotGlobalState [
	| cfg connected disconnected updateSt updateGs fwd cfwd none |
	cfg := GbsConfiguration new.
	cfg valueAt: #connectorConnectionState put: 'disconnected'.
	cfg valueAt: #postConnectAction put: 'forwarder'.
	GbsConfiguration current: cfg.

	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	fwd := GbxFakeTogglePresenter new.
	cfwd := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.

	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: fwd.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: cfwd.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter applySettingsForConnectorRow: #('Fast' 'ByteArray' 'ByteArray').

	self assert: connected state.
	self deny: disconnected state.
	self deny: updateSt state.
	self deny: updateGs state.
	self deny: fwd state.
	self deny: cfwd state.
	self assert: none state
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserAppliesDifferentSavedStatePerConnectorRow [
	| cfg connected disconnected updateSt updateGs fwd cfwd none fakeTable rowA rowB |
	cfg := GbsConfiguration new.
	GbsConfiguration current: cfg.

	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	fwd := GbxFakeTogglePresenter new.
	cfwd := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	rowA := #('Fast' 'ByteArray' 'ByteArray').
	rowB := #('Fast' 'String' 'String').

	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: fwd.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: cfwd.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.

	fakeTable selectedItem: rowA.
	connected state: false.
	disconnected state: true.
	updateSt state: false.
	updateGs state: true.
	fwd state: false.
	cfwd state: false.
	none state: false.
	connectorBrowserPresenter saveSettingsFromOptionStateForSelectedConnectors.

	fakeTable selectedItem: rowB.
	connected state: true.
	disconnected state: false.
	updateSt state: false.
	updateGs state: false.
	fwd state: false.
	cfwd state: false.
	none state: true.
	connectorBrowserPresenter saveSettingsFromOptionStateForSelectedConnectors.

	connectorBrowserPresenter applySettingsForConnectorRow: rowA.
	self deny: connected state.
	self assert: disconnected state.
	self deny: updateSt state.
	self assert: updateGs state.
	self deny: fwd state.
	self deny: cfwd state.
	self deny: none state.

	connectorBrowserPresenter applySettingsForConnectorRow: rowB.
	self assert: connected state.
	self deny: disconnected state.
	self deny: updateSt state.
	self deny: updateGs state.
	self deny: fwd state.
	self deny: cfwd state.
	self assert: none state
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserConnectDisconnectUpdatesSessionManagerState [
	| cfg connected disconnected row |
	cfg := GbsConfiguration new.
	GbsConfiguration current: cfg.
	Smalltalk globals at: #GbsConnectorConnectionRegistry put: Dictionary new.

	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	row := #('Fast' 'ByteArray' 'ByteArray').

	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: (GbxFakeTablePresenterForRemoteDebugger new).
	(connectorBrowserPresenter instVarNamed: 'connectorTable') selectedItem: row.
	connectorBrowserPresenter instVarNamed: 'session' put: (MockGbsSession new).

	connectorBrowserPresenter connectorDisconnectSelected.
	self deny: (GbsSessionManager
		isConnectorClient: 'ByteArray'
		server: 'ByteArray'
		connectedInSession: 'unknown-user@unknown-stone').

	connectorBrowserPresenter connectorConnectSelected.
	self assert: (GbsSessionManager
		isConnectorClient: 'ByteArray'
		server: 'ByteArray'
		connectedInSession: 'unknown-user@unknown-stone')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserSelectedConnectorRowsFallsBackToSelectedItem [
	| fakeTable row |
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	row := #('Fast' 'ByteArray' 'ByteArray').
	fakeTable selectedItem: row.

	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.

	self assert: connectorBrowserPresenter selectedConnectorRows size equals: 1.
	self assert: connectorBrowserPresenter hasSelectedConnectors.
	self assert: connectorBrowserPresenter hasSingleSelectedConnector.
	self assert: connectorBrowserPresenter selectedConnectorRows first equals: row
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserSelectedConnectorRowsUsesMultiSelectionWhenPresent [
	| fakeTable rowA rowB |
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	rowA := #('Fast' 'ByteArray' 'ByteArray').
	rowB := #('Fast' 'String' 'String').
	fakeTable selectedItems: { rowA. rowB }.
	fakeTable selectedItem: rowA.

	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.

	self assert: connectorBrowserPresenter selectedConnectorRows size equals: 2.
	self assert: connectorBrowserPresenter hasSelectedConnectors.
	self deny: connectorBrowserPresenter hasSingleSelectedConnector
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserCanInitializeSelectedGroupOnlyForGlobal [
	| fakeGroupList globalGroup sessionGroup |
	fakeGroupList := GbxFakeListPresenterForBrowser new.
	globalGroup := GbsConnectorGroup globalOnManagerClass: GbsSessionManager.
	sessionGroup := GbsConnectorGroup session: (MockGbsSession new) managerClass: GbsSessionManager.
	connectorBrowserPresenter instVarNamed: 'groupList' put: fakeGroupList.

	fakeGroupList selectedItem: globalGroup.
	self assert: connectorBrowserPresenter canInitializeSelectedGroup.

	fakeGroupList selectedItem: sessionGroup.
	self deny: connectorBrowserPresenter canInitializeSelectedGroup
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserUpdateControlsDisablesWhenMultiSelected [
	| fakeTable connected disconnected updateSt updateGs forwarder clientForwarder none rowA rowB |
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	rowA := #('Fast' 'ByteArray' 'ByteArray').
	rowB := #('Fast' 'String' 'String').
	fakeTable selectedItems: { rowA. rowB }.
	fakeTable selectedItem: rowA.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	forwarder := GbxFakeTogglePresenter new.
	clientForwarder := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.

	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: forwarder.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: clientForwarder.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter updateConnectorControlsFromSelection.

	self deny: connected enabled.
	self deny: disconnected enabled.
	self deny: updateSt enabled.
	self deny: updateGs enabled.
	self deny: forwarder enabled.
	self deny: clientForwarder enabled.
	self deny: none enabled.
	self deny: connected state.
	self deny: disconnected state
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserUpdateControlsEnablesForSingleSelection [
	| fakeTable connected disconnected updateSt updateGs forwarder clientForwarder none row |
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	row := #('Fast' 'ByteArray' 'ByteArray').
	fakeTable selectedItems: { row }.
	fakeTable selectedItem: row.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	forwarder := GbxFakeTogglePresenter new.
	clientForwarder := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.

	connectorBrowserPresenter instVarNamed: 'session' put: (MockGbsSession new).
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: forwarder.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: clientForwarder.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter updateConnectorControlsFromSelection.

	self assert: connected enabled.
	self assert: disconnected enabled.
	self assert: updateSt enabled.
	self assert: updateGs enabled.
	self assert: forwarder enabled.
	self assert: clientForwarder enabled.
	self assert: none enabled
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserCapabilityPredicatesTrackSelectionCount [
	| fakeTable rowA rowB |
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	rowA := #('Fast' 'ByteArray' 'ByteArray').
	rowB := #('Fast' 'String' 'String').
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.

	fakeTable selectedItems: #().
	fakeTable selectedItem: nil.
	self deny: connectorBrowserPresenter canInspectSelectedConnector.
	self deny: connectorBrowserPresenter canRemoveSelectedConnectors.
	self deny: connectorBrowserPresenter canSetConnectorClassMapping.

	fakeTable selectedItems: { rowA }.
	fakeTable selectedItem: rowA.
	self assert: connectorBrowserPresenter canInspectSelectedConnector.
	self assert: connectorBrowserPresenter canRemoveSelectedConnectors.
	self assert: connectorBrowserPresenter canSetConnectorClassMapping.

	fakeTable selectedItems: { rowA. rowB }.
	fakeTable selectedItem: rowA.
	self deny: connectorBrowserPresenter canInspectSelectedConnector.
	self assert: connectorBrowserPresenter canRemoveSelectedConnectors.
	self deny: connectorBrowserPresenter canSetConnectorClassMapping
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserCanAddRequiresSelectedGroup [
	| fakeGroupList |
	fakeGroupList := GbxFakeListPresenterForBrowser new.
	connectorBrowserPresenter instVarNamed: 'groupList' put: fakeGroupList.

	fakeGroupList selectedItem: nil.
	self deny: connectorBrowserPresenter canAddConnector.

	fakeGroupList selectedItem: (GbsConnectorGroup globalOnManagerClass: GbsSessionManager).
	self assert: connectorBrowserPresenter canAddConnector
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserAddRemoveAreReflectedInConnectorPaneAfterRefresh [
	| globalGroup fakeTable clientName serverName |
	Smalltalk globals at: #GbsFastConnectorRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorObjectRegistry put: Dictionary new.
	globalGroup := GbsSessionManager globalConnectorGroup.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.
	clientName := 'ABCConnectorTest'.
	serverName := 'DEFConnectorTest'.

	connectorBrowserPresenter refreshConnectorsForGroup: globalGroup.
	self deny: (fakeTable items anySatisfy: [ :row |
		(connectorBrowserPresenter rowClientName: row) = clientName
			and: [ (connectorBrowserPresenter rowServerName: row) = serverName ] ]).

	GbsSessionManager addConnectorClient: clientName server: serverName.
	connectorBrowserPresenter refreshConnectorsForGroup: globalGroup.
	self assert: (fakeTable items anySatisfy: [ :row |
		(connectorBrowserPresenter rowClientName: row) = clientName
			and: [ (connectorBrowserPresenter rowServerName: row) = serverName ] ]).

	GbsSessionManager removeConnectorClient: clientName server: serverName.
	connectorBrowserPresenter refreshConnectorsForGroup: globalGroup.
	self deny: (fakeTable items anySatisfy: [ :row |
		(connectorBrowserPresenter rowClientName: row) = clientName
			and: [ (connectorBrowserPresenter rowServerName: row) = serverName ] ])
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserPostConnectActionPersistsAcrossUpdate [
	| cfg globalGroup fakeGroupList fakeTable connected disconnected updateSt updateGs forwarder clientForwarder none verification selectedRow |
	cfg := GbsConfiguration new.
	GbsConfiguration current: cfg.
	Smalltalk globals at: #GbsFastConnectorRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorObjectRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorPostConnectActionRegistry put: Dictionary new.
	GbsSessionManager addConnectorClient: 'PersistClient' server: 'PersistServer'.
	globalGroup := GbsSessionManager globalConnectorGroup.
	fakeGroupList := GbxFakeListPresenterForBrowser new.
	fakeGroupList selectedItem: globalGroup.
	fakeTable := GbxFakeTablePresenterForRemoteDebugger new.
	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	forwarder := GbxFakeTogglePresenter new.
	clientForwarder := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.
	verification := GbxFakeTogglePresenter new.
	verification state: true.

	connectorBrowserPresenter instVarNamed: 'groupList' put: fakeGroupList.
	connectorBrowserPresenter instVarNamed: 'groupItems' put: { globalGroup }.
	connectorBrowserPresenter instVarNamed: 'connectorTable' put: fakeTable.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: forwarder.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: clientForwarder.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.
	connectorBrowserPresenter instVarNamed: 'verificationCheck' put: verification.

	connectorBrowserPresenter refreshConnectorsForGroup: globalGroup.
	selectedRow := fakeTable items
		detect: [ :row | (connectorBrowserPresenter rowClientName: row) = 'PersistClient' ]
		ifNone: [ nil ].
	self assert: selectedRow notNil.
	fakeTable selectedItem: selectedRow.
	connectorBrowserPresenter postConnectActionChangedTo: 'forwarder'.
	self assert: forwarder state.

	connectorBrowserPresenter update.
	selectedRow := fakeTable items
		detect: [ :row | (connectorBrowserPresenter rowClientName: row) = 'PersistClient' ]
		ifNone: [ nil ].
	self assert: selectedRow notNil.
	fakeTable selectedItem: selectedRow.
	connectorBrowserPresenter applySettingsForConnectorRow: selectedRow.
	self assert: forwarder state.
	self deny: none state
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserPostConnectActionPersistsAcrossReopen [
	| connectorObject presenter2 updateSt1 updateGs1 forwarder1 clientForwarder1 none1 connected1 disconnected1 updateSt2 updateGs2 forwarder2 clientForwarder2 none2 connected2 disconnected2 |
	Smalltalk globals at: #GbsFastConnectorRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorObjectRegistry put: Dictionary new.
	Smalltalk globals at: #GbsConnectorPostConnectActionRegistry put: Dictionary new.
	GbsSessionManager addConnectorClient: 'ReopenClient' server: 'ReopenServer'.
	GbsSessionManager
		setPostConnectAction: 'clientForwarder'
		forConnectorClient: 'ReopenClient'
		server: 'ReopenServer'.
	connectorObject := GbsSessionManager
		connectorObjectForClient: 'ReopenClient'
		server: 'ReopenServer'.

	updateSt1 := GbxFakeTogglePresenter new.
	updateGs1 := GbxFakeTogglePresenter new.
	forwarder1 := GbxFakeTogglePresenter new.
	clientForwarder1 := GbxFakeTogglePresenter new.
	none1 := GbxFakeTogglePresenter new.
	connected1 := GbxFakeTogglePresenter new.
	disconnected1 := GbxFakeTogglePresenter new.
	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected1.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected1.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt1.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs1.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: forwarder1.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: clientForwarder1.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none1.
	connectorBrowserPresenter applySettingsForConnectorRow: connectorObject.
	self assert: clientForwarder1 state.

	presenter2 := GbsConnectorBrowserPresenter new.
	updateSt2 := GbxFakeTogglePresenter new.
	updateGs2 := GbxFakeTogglePresenter new.
	forwarder2 := GbxFakeTogglePresenter new.
	clientForwarder2 := GbxFakeTogglePresenter new.
	none2 := GbxFakeTogglePresenter new.
	connected2 := GbxFakeTogglePresenter new.
	disconnected2 := GbxFakeTogglePresenter new.
	presenter2 instVarNamed: 'connectedRadio' put: connected2.
	presenter2 instVarNamed: 'disconnectedRadio' put: disconnected2.
	presenter2 instVarNamed: 'updateStRadio' put: updateSt2.
	presenter2 instVarNamed: 'updateGsRadio' put: updateGs2.
	presenter2 instVarNamed: 'forwarderRadio' put: forwarder2.
	presenter2 instVarNamed: 'clientForwarderRadio' put: clientForwarder2.
	presenter2 instVarNamed: 'noneRadio' put: none2.
	presenter2 applySettingsForConnectorRow: connectorObject.
	self assert: clientForwarder2 state.
	self deny: none2 state
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testConnectorBrowserInvalidPostActionsDisableButtonsAndCoerceSelection [
	| cfg connected disconnected updateSt updateGs fwd cfwd none row settings |
	cfg := GbsConfiguration new.
	GbsConfiguration current: cfg.
	Smalltalk globals at: #GbsConnectorInvalidActionRegistry put: Dictionary new.
	GbsSessionManager
		setInvalidPostConnectActions: #('updateGS' 'forwarder')
		forConnectorClient: 'ByteArray'
		server: 'ByteArray'.

	connected := GbxFakeTogglePresenter new.
	disconnected := GbxFakeTogglePresenter new.
	updateSt := GbxFakeTogglePresenter new.
	updateGs := GbxFakeTogglePresenter new.
	fwd := GbxFakeTogglePresenter new.
	cfwd := GbxFakeTogglePresenter new.
	none := GbxFakeTogglePresenter new.
	row := #('Fast' 'ByteArray' 'ByteArray').
	settings := Dictionary new
		at: 'ByteArray->ByteArray' put: (Dictionary new at: #postConnectAction put: 'updateGS'; yourself);
		yourself.
	cfg valueAt: #connectorRowSettings put: settings.

	connectorBrowserPresenter instVarNamed: 'connectedRadio' put: connected.
	connectorBrowserPresenter instVarNamed: 'disconnectedRadio' put: disconnected.
	connectorBrowserPresenter instVarNamed: 'updateStRadio' put: updateSt.
	connectorBrowserPresenter instVarNamed: 'updateGsRadio' put: updateGs.
	connectorBrowserPresenter instVarNamed: 'forwarderRadio' put: fwd.
	connectorBrowserPresenter instVarNamed: 'clientForwarderRadio' put: cfwd.
	connectorBrowserPresenter instVarNamed: 'noneRadio' put: none.

	connectorBrowserPresenter applySettingsForConnectorRow: row.

	self deny: updateGs enabled.
	self deny: fwd enabled.
	self assert: none state
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoFetchGroupsForUserParsesCsv [
	| mockSession groups |
	userInfoPresenter ifNil: [ self skip: 'GbsUserInfoPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #evaluate put: 'DataCuratorGroup,Subscribers'.
	userInfoPresenter session: mockSession.

	groups := userInfoPresenter fetchGroupsForUser: 'DataCurator'.

	self assert: groups size equals: 2.
	self assert: (groups includes: 'DataCuratorGroup').
	self assert: (groups includes: 'Subscribers')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoRefreshInfoTextUpdatesTextPresenter [
	| mockSession fakeText |
	userInfoPresenter ifNil: [ self skip: 'GbsUserInfoPresenter not loaded' ].
	mockSession := MockGbsSession new.
	mockSession stubs at: #evaluate put: 'User: DataCurator', String lf, 'Class: UserProfile'.
	fakeText := GbxFakeTextPresenterForRemoteDebugger new.

	userInfoPresenter session: mockSession.
	userInfoPresenter userName: 'DataCurator'.
	userInfoPresenter infoText: ''.
	userInfoPresenter instVarNamed: 'textPresenter' put: fakeText.

	userInfoPresenter refreshInfoText.

	self assert: (fakeText text includesSubstring: 'User: DataCurator').
	self assert: (fakeText text includesSubstring: 'Class: UserProfile')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoEditPrivilegesPersistsUpdatedPrivilegesViaSessionExecute [
	| presenter mockSession executedScript updatedMap capturedUser capturedInitial |
	presenter := (Smalltalk at: #GbsUserInfoPresenter ifAbsent: [ nil ])
		ifNotNil: [ :klass | klass new ]
		ifNil: [ self skip: 'GbsUserInfoPresenter not loaded' ].
	mockSession := MockGbsSession new.
	executedScript := ''.
	capturedUser := nil.
	capturedInitial := nil.
	mockSession stubs at: #evaluate put: [ :script |
		(script includesSubstring: 'privilegeNames do:')
			ifTrue: [ ^ 'SystemControl', Character tab asString, 'false' ].
		(script includesSubstring: 'String streamContents')
			ifTrue: [ ^ 'DataCuratorGroup' ].
		'User: DataCurator' ].
	mockSession stubs at: #execute put: [ :script | executedScript := script. true ].
	updatedMap := Dictionary new
		at: #SystemControl put: true;
		yourself.

	presenter
		userName: 'DataCurator';
		session: mockSession;
		infoText: '';
		privilegesEditorBlock: [ :user :initial :accept |
			capturedUser := user.
			capturedInitial := initial.
			accept value: updatedMap ].

	presenter editPrivileges.

	self assert: capturedUser equals: 'DataCurator'.
	self assert: ((capturedInitial at: #SystemControl ifAbsent: [ nil ]) == false).
	self assert: (executedScript includesSubstring: 'isSystemControl: true')
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoInitializeSetsSafeDefaults [
	| presenter |
	presenter := (Smalltalk at: #GbsUserInfoPresenter ifAbsent: [ nil ]) new.
	self assert: (presenter instVarNamed: 'userName') equals: ''.
	self assert: (presenter instVarNamed: 'infoText') equals: ''
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserInfoInfoTextSetterNormalizesNilToEmptyString [
	| presenter |
	presenter := (Smalltalk at: #GbsUserInfoPresenter ifAbsent: [ nil ]) new.
	presenter infoText: nil.
	self assert: (presenter instVarNamed: 'infoText') equals: ''
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserListFetchGroupsParsesCsvAndSetsUserField [
	| mockSession fakeGroupsList fakeTextField |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #evaluate put: 'DataCurator,GcUser'.

	fakeGroupsList := GbxFakeListPresenterForBrowser new.
	fakeTextField := GbxFakeTextPresenterForRemoteDebugger new.

	userListPresenter instVarNamed: 'session' put: mockSession.
	userListPresenter instVarNamed: 'groupList' put: fakeGroupsList.
	userListPresenter instVarNamed: 'userNameField' put: fakeTextField.

	userListPresenter fetchGroupsFor: 'DataCurator'.

	self assert: fakeGroupsList items size equals: 2.
	self assert: fakeTextField text equals: 'DataCurator'
]

{ #category : 'tests' }
GbsAdminToolsPresenterTest >> testUserListRefreshPopulatesUsersAndClearsGroups [
	| mockSession fakeUserList fakeGroupsList fakeTextField |
	mockSession := MockGbsSession new.
	mockSession isLoggedIn: true.
	mockSession stubs at: #evaluate put: 'DataCurator,GcUser,HostAgentUser'.

	fakeUserList := GbxFakeListPresenterForBrowser new.
	fakeGroupsList := GbxFakeListPresenterForBrowser new.
	fakeTextField := GbxFakeTextPresenterForRemoteDebugger new.

	userListPresenter instVarNamed: 'session' put: mockSession.
	userListPresenter instVarNamed: 'userList' put: fakeUserList.
	userListPresenter instVarNamed: 'groupList' put: fakeGroupsList.
	userListPresenter instVarNamed: 'userNameField' put: fakeTextField.

	userListPresenter refreshUserList.

	self assert: fakeUserList items size equals: 3.
	self assert: fakeGroupsList items isEmpty.
	self assert: fakeTextField text equals: ''
]
