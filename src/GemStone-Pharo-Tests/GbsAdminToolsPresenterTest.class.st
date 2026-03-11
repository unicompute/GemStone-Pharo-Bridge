Class {
	#name : 'GbsAdminToolsPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'createUserPresenter',
		'namespacesPresenter',
		'securityPoliciesPresenter',
		'userListPresenter'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsAdminToolsPresenterTest >> setUp [
	super setUp.
	createUserPresenter := GbsCreateUserPresenter new.
	namespacesPresenter := GbsNamespacesPresenter new.
	securityPoliciesPresenter := GbsSecurityPoliciesPresenter new.
	userListPresenter := GbsUserListPresenter new
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
