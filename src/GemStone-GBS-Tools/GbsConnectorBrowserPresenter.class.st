Class {
	#name : 'GbsConnectorBrowserPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'connectorActionSession',
		'mainMenu',
		'groupList',
		'groupItems',
		'connectorTable',
		'verificationCheck',
		'removeInvalidCheck',
		'connectedRadio',
		'disconnectedRadio',
		'updateStRadio',
		'updateGsRadio',
		'forwarderRadio',
		'clientForwarderRadio',
		'noneRadio'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsConnectorBrowserPresenter class >> openOn: aSession [
	| presenter |
	aSession ifNil: [ ^ self inform: 'No connected GemStone session. Please login first.' ].
	presenter := self new.
	presenter
		session: aSession;
		open.
	^ presenter
]

{ #category : 'initialization' }
GbsConnectorBrowserPresenter >> initializePresenters [
	mainMenu := self buildMenuBar.

	groupList := self newList.
	groupList display: [ :each | self groupDisplayStringFor: each ].

	connectorTable := self newTable.
	connectorTable
		addColumn: (SpStringTableColumn title: 'Type' evaluated: [ :row | self rowType: row ]);
		addColumn: (SpStringTableColumn title: 'Client' evaluated: [ :row | self rowClientName: row ]);
		addColumn: (SpStringTableColumn title: 'Server' evaluated: [ :row | self rowServerName: row ]);
		yourself.

	verificationCheck := self newCheckBox label: 'Verification'.
	removeInvalidCheck := self newCheckBox label: 'Remove invalid'.

	connectedRadio := self newRadioButton label: 'Connected'.
	disconnectedRadio := self newRadioButton label: 'Disconnected'.
	updateStRadio := self newRadioButton label: 'updateST'.
	updateGsRadio := self newRadioButton label: 'updateGS'.
	forwarderRadio := self newRadioButton label: 'forwarder'.
	clientForwarderRadio := self newRadioButton label: 'clientForwarder'.
	noneRadio := self newRadioButton label: 'none'.

	self configureRadioGroups.
	self enableOptionControls
]

{ #category : 'initialization' }
GbsConnectorBrowserPresenter >> connectPresenters [
	groupList whenSelectionChangedDo: [ :selection |
		self refreshConnectorsForGroup: (self selectedItemFromSelectionEvent: selection) ].
	(connectorTable respondsTo: #whenSelectionChangedDo:) ifTrue: [
		connectorTable whenSelectionChangedDo: [ :selection |
			self connectorSelectionChanged: (self selectedItemFromSelectionEvent: selection) ] ].
	(connectorTable respondsTo: #whenActivatedDo:) ifTrue: [
		connectorTable whenActivatedDo: [ :selection |
			(self selectedItemFromSelectionEvent: selection) ifNotNil: [ self inspectSelectedClientConnector ] ] ].
	(groupList respondsTo: #contextMenu:) ifTrue: [
		groupList contextMenu: [ self menuGroupPopup ] ].
	(connectorTable respondsTo: #contextMenu:) ifTrue: [
		connectorTable contextMenu: [ self menuConnectorPopup ] ].

	self loadOptionsFromConfiguration.
	self wireOptionChangeNotifications.
	self wireRadioSelectionHandlers.

	self refreshAll
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> configureRadioGroups [
	(connectedRadio respondsTo: #associatedRadioButtons:)
		ifTrue: [ connectedRadio associatedRadioButtons: { disconnectedRadio } ].
	(disconnectedRadio respondsTo: #associatedRadioButtons:)
		ifTrue: [ disconnectedRadio associatedRadioButtons: { connectedRadio } ].
	(updateStRadio respondsTo: #associatedRadioButtons:)
		ifTrue: [ updateStRadio associatedRadioButtons: { updateGsRadio. forwarderRadio. clientForwarderRadio. noneRadio } ].
	(updateGsRadio respondsTo: #associatedRadioButtons:)
		ifTrue: [ updateGsRadio associatedRadioButtons: { updateStRadio. forwarderRadio. clientForwarderRadio. noneRadio } ].
	(forwarderRadio respondsTo: #associatedRadioButtons:)
		ifTrue: [ forwarderRadio associatedRadioButtons: { updateStRadio. updateGsRadio. clientForwarderRadio. noneRadio } ].
	(clientForwarderRadio respondsTo: #associatedRadioButtons:)
		ifTrue: [ clientForwarderRadio associatedRadioButtons: { updateStRadio. updateGsRadio. forwarderRadio. noneRadio } ].
	(noneRadio respondsTo: #associatedRadioButtons:)
		ifTrue: [ noneRadio associatedRadioButtons: { updateStRadio. updateGsRadio. forwarderRadio. clientForwarderRadio } ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> enableOptionControls [
	{
		verificationCheck.
		removeInvalidCheck.
		connectedRadio.
		disconnectedRadio.
		updateStRadio.
		updateGsRadio.
		forwarderRadio.
		clientForwarderRadio.
		noneRadio.
	} do: [ :presenter |
		(presenter respondsTo: #enabled:)
			ifTrue: [ presenter enabled: true ] ]
]

{ #category : 'layout' }
GbsConnectorBrowserPresenter >> defaultLayout [
	| optionsLeft optionsCenter postRow1 postRow2 postRow3 optionsRight optionsRow panes |
	optionsLeft := SpBoxLayout newTopToBottom
		add: verificationCheck expand: false;
		add: removeInvalidCheck expand: false;
		spacing: 4;
		yourself.
	optionsCenter := SpBoxLayout newTopToBottom
		add: connectedRadio expand: false;
		add: disconnectedRadio expand: false;
		spacing: 4;
		yourself.
	postRow1 := SpBoxLayout newLeftToRight
		add: updateStRadio expand: false;
		add: updateGsRadio expand: false;
		spacing: 10;
		yourself.
	postRow2 := SpBoxLayout newLeftToRight
		add: forwarderRadio expand: false;
		add: clientForwarderRadio expand: false;
		spacing: 10;
		yourself.
	postRow3 := SpBoxLayout newLeftToRight
		add: noneRadio expand: false;
		yourself.
	optionsRight := SpBoxLayout newTopToBottom
		add: (self newLabel label: 'Postconnect Action') expand: false;
		add: postRow1 expand: false;
		add: postRow2 expand: false;
		add: postRow3 expand: false;
		spacing: 2;
		yourself.
	optionsRow := SpBoxLayout newLeftToRight
		add: optionsLeft expand: false;
		add: optionsCenter expand: false;
		add: optionsRight;
		spacing: 18;
		yourself.
	panes := SpPanedLayout newVertical
		add: groupList;
		add: connectorTable;
		positionOfSlider: 24 percent;
		yourself.

	^ SpBoxLayout newTopToBottom
		spacing: 0;
		add: mainMenu expand: false;
		add: panes;
		add: optionsRow expand: false;
		yourself
]

{ #category : 'initialization' }
GbsConnectorBrowserPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'Connector Browser';
		initialExtent: 980 @ 700
]

{ #category : 'menus' }
GbsConnectorBrowserPresenter >> buildMenuBar [
	^ self newMenuBar
		addGroup: [ :group |
			group
				addItem: [ :item | item name: 'File'; subMenu: self menuFile ];
				addItem: [ :item | item name: 'Group'; subMenu: self menuGroup ];
				addItem: [ :item | item name: 'Connector'; subMenu: self menuConnector ] ]
]

{ #category : 'menus' }
GbsConnectorBrowserPresenter >> menuFile [
	^ self newMenu
		addItem: [ :item | item name: 'Update'; action: [ self update ] ];
		addItem: [ :item | item name: 'Close'; action: [ self closeWindow ] ];
		yourself
]

{ #category : 'menus' }
GbsConnectorBrowserPresenter >> menuGroup [
	^ self newMenu
		addItem: [ :item |
			item name: 'Initialize'; action: [ self initializeGlobalConnectors ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canInitializeSelectedGroup ] ];
		yourself
]

{ #category : 'menus' }
GbsConnectorBrowserPresenter >> menuConnector [
	^ self newMenu
		addItem: [ :item |
			item name: 'Inspect Client'; action: [ self inspectSelectedClientConnector ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canInspectSelectedConnector ] ];
		addItem: [ :item |
			item name: 'Inspect Server'; action: [ self inspectSelectedServerConnector ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canInspectSelectedConnector ] ];
		addItem: [ :item |
			item name: 'Add...'; action: [ self createAndAddConnector ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canAddConnector ] ];
		addItem: [ :item |
			item name: 'Remove...'; action: [ self removeConnector ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canRemoveSelectedConnectors ] ];
		addItem: [ :item |
			item name: 'Set Connector Class...'; action: [ self setSelectedConnectorClassMapping ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canSetConnectorClassMapping ] ];
		addItem: [ :item |
			item name: 'Clear Connector Class Override'; action: [ self clearSelectedConnectorClassMapping ].
			(item respondsTo: #enabled:) ifTrue: [ item enabled: self canSetConnectorClassMapping ] ];
		yourself
]

{ #category : 'menus' }
GbsConnectorBrowserPresenter >> menuGroupPopup [
	^ self menuGroup
]

{ #category : 'menus' }
GbsConnectorBrowserPresenter >> menuConnectorPopup [
	^ self menuConnector
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> refreshAll [
	self update
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> update [
	| previousGroupLabel previousConnectorKey |
	previousGroupLabel := [ self groupDisplayStringFor: groupList selection selectedItem ] on: Error do: [ nil ].
	previousConnectorKey := self connectorSettingKeyForRow: self currentSelectedConnectorRow.
	self updateGroupList.
	previousGroupLabel ifNotNil: [ self selectGroupWithDisplayString: previousGroupLabel ].
	self updateConnectorList.
	previousConnectorKey ifNotNil: [ self selectConnectorWithSettingKey: previousConnectorKey ].
	self updateConnectorControlsFromSelection
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> updateGroupList [
	| previousSelection previousLabel newSelection |
	previousSelection := [ groupList selection selectedItem ] on: Error do: [ nil ].
	previousLabel := previousSelection
		ifNil: [ nil ]
		ifNotNil: [ self groupDisplayStringFor: previousSelection ].
	self refreshGroups.
	newSelection := (previousLabel notNil and: [ groupItems isEmpty not ])
		ifTrue: [
			groupItems
				detect: [ :each | (self groupDisplayStringFor: each) = previousLabel ]
				ifNone: [ nil ] ]
		ifFalse: [ groupItems ifEmpty: [ nil ] ifNotEmpty: [ groupItems first ] ].
	newSelection ifNotNil: [
		(groupList respondsTo: #selectItem:)
			ifTrue: [ groupList selectItem: newSelection ]
			ifFalse: [
				(groupList respondsTo: #selection)
					ifTrue: [ [ groupList selection selectItem: newSelection ] on: Error do: [ ] ] ] ]
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> updateConnectorList [
	| selectedGroup |
	selectedGroup := [ groupList selection selectedItem ] on: Error do: [ nil ].
	selectedGroup ifNil: [ selectedGroup := groupItems ifEmpty: [ nil ] ifNotEmpty: [ groupItems first ] ].
	(self fastConnectorPairs isEmpty and: [ verificationCheck state = true ])
		ifTrue: [ [ self managerPerform: #initializeFastConnectors ifUnavailable: [ nil ] ] on: Error do: [ ] ].
	selectedGroup
		ifNil: [ connectorTable items: #() ]
		ifNotNil: [ self refreshConnectorsForGroup: selectedGroup ]
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> refreshGroups [
	groupItems := OrderedCollection new.
	groupItems add: self globalConnectorGroup.
	(self knownConnectorGroups) do: [ :each | groupItems add: each ].
	groupItems := groupItems asArray.
	groupList items: groupItems
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> refreshConnectorsForGroup: aGroupLabel [
	| rows previousSelection previousKey selectedRow matchingSelection |
	aGroupLabel ifNil: [ connectorTable items: #(). ^ self ].
	previousSelection := [ connectorTable selection selectedItem ] on: Error do: [ nil ].
	previousKey := self connectorSettingKeyForRow: previousSelection.
	rows := self connectorRowsForGroup: aGroupLabel.
	connectorTable items: rows.
	matchingSelection := previousKey
		ifNil: [
			(previousSelection notNil and: [ rows isEmpty not ])
				ifTrue: [ rows detect: [ :each | each = previousSelection ] ifNone: [ nil ] ]
				ifFalse: [ nil ] ]
		ifNotNil: [
			rows
				detect: [ :each | (self connectorSettingKeyForRow: each) = previousKey ]
				ifNone: [ nil ] ].
	(matchingSelection notNil)
		ifTrue: [
			(connectorTable respondsTo: #selectItem:)
				ifTrue: [ connectorTable selectItem: matchingSelection ]
				ifFalse: [
					(connectorTable respondsTo: #selection)
						ifTrue: [ [ connectorTable selection selectItem: matchingSelection ] on: Error do: [ ] ] ] ]
		ifFalse: [
			rows ifNotEmpty: [
				(connectorTable respondsTo: #selectItem:)
					ifTrue: [ connectorTable selectItem: rows first ]
					ifFalse: [
						(connectorTable respondsTo: #selection)
							ifTrue: [ [ connectorTable selection selectItem: rows first ] on: Error do: [ ] ] ] ] ].
	selectedRow := self currentSelectedConnectorRow.
	selectedRow ifNil: [ ^ self updateConnectorControlsFromSelection ].
	self updateConnectorControlsFromSelection
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> connectorRowsForGroup: aGroupLabel [
	| connectors label |
	label := self groupDisplayStringFor: aGroupLabel.
	((label beginsWith: 'Session connectors') and: [ self selectedConnectionState = 'disconnected' ])
		ifTrue: [ ^ #() ].
	connectors := self connectorObjectsForGroup: aGroupLabel.
	^ (connectors asArray
		sort: [ :a :b |
			| aClient bClient |
			aClient := (self connectorClientNameFor: a) asLowercase.
			bClient := (self connectorClientNameFor: b) asLowercase.
			aClient = bClient
				ifTrue: [ (self connectorServerNameFor: a) asLowercase <= (self connectorServerNameFor: b) asLowercase ]
				ifFalse: [ aClient <= bClient ] ])
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> filteredConnectorPairs: pairs forGroupLabel: aGroupLabel [
	| label |
	pairs ifNil: [ ^ #() ].
	label := aGroupLabel ifNil: [ '' ] ifNotNil: [ aGroupLabel asString ].
	((label beginsWith: 'Session connectors') and: [ self selectedConnectionState = 'disconnected' ])
		ifTrue: [ ^ #() ].
	^ pairs
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> fastConnectorPairs [
	| pairs |
	pairs := [ self managerPerform: #connectorPairs ifUnavailable: [
		self managerPerform: #globalFastConnectorsList ifUnavailable: [ #() ] ] ]
		on: Error
		do: [ #() ].
	^ pairs ifNil: [ #() ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> sessionGroupLabel [
	| user stone |
	user := self parameterValueNamed: #username default: 'unknown-user'.
	stone := self parameterValueNamed: #gemStoneName default: 'unknown-stone'.
	^ 'Session connectors - ''', user, ''' on ''', stone, ''''
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> globalConnectorGroup [
	^ self
		managerPerform: #globalConnectorGroup
		ifUnavailable: [ 'Global connectors' ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> knownConnectorGroups [
	| groups |
	groups := self
		managerPerform: #knownParameters
		ifUnavailable: [ #() ].
	^ groups ifNil: [ #() ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> groupDisplayStringFor: aGroup [
	(aGroup respondsTo: #connectorGroupDescription) ifTrue: [ ^ aGroup connectorGroupDescription ].
	^ aGroup asString
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> connectorObjectsForGroup: aGroup [
	(aGroup respondsTo: #connectorList) ifTrue: [ ^ aGroup connectorList ].
	^ (self fastConnectorPairs collect: [ :pair |
		self
			managerPerform: #connectorObjectForClient:server:
			withArguments: {
				(pair at: 1 ifAbsent: [ '' ]) asString.
				(pair at: 2 ifAbsent: [ '' ]) asString }
			ifUnavailable: [ nil ] ]) reject: [ :each | each isNil ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> connectorTypeStringFor: aConnector [
	(aConnector respondsTo: #connectorType) ifTrue: [
		^ [ aConnector connectorType asString ] on: Error do: [ aConnector class name asString ] ].
	(aConnector respondsTo: #type) ifTrue: [
		^ [ aConnector type asString ] on: Error do: [ aConnector class name asString ] ].
	^ aConnector class name asString
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> connectorClientNameFor: aConnector [
	(aConnector respondsTo: #connectorClient) ifTrue: [
		^ [ aConnector connectorClient asString ] on: Error do: [ '' ] ].
	(aConnector respondsTo: #stDescription) ifTrue: [
		^ [ aConnector stDescription asString ] on: Error do: [ '' ] ].
	(aConnector respondsTo: #connectorClientName) ifTrue: [
		^ [ aConnector connectorClientName asString ] on: Error do: [ '' ] ].
	^ ''
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> connectorServerNameFor: aConnector [
	(aConnector respondsTo: #connectorServer) ifTrue: [
		^ [ aConnector connectorServer asString ] on: Error do: [ '' ] ].
	(aConnector respondsTo: #gsDescription) ifTrue: [
		^ [ aConnector gsDescription asString ] on: Error do: [ '' ] ].
	(aConnector respondsTo: #connectorServerName) ifTrue: [
		^ [ aConnector connectorServerName asString ] on: Error do: [ '' ] ].
	^ ''
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> parameterValueNamed: selector default: defaultString [
	| params |
	params := self sessionParameters.
	params ifNil: [ ^ defaultString ].
	(params respondsTo: selector) ifFalse: [ ^ defaultString ].
	^ [ (params perform: selector) ifNil: [ defaultString ] ifNotNil: [ :v | v asString ] ]
		on: Error
		do: [ defaultString ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> sessionParameters [
	(session respondsTo: #instVarNamed:) ifFalse: [ ^ nil ].
	^ [ session instVarNamed: 'parameters' ] on: Error do: [ nil ]
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> initializeFastConnectors [
	[
		self managerPerform: #initializeFastConnectors ifUnavailable: [
			^ self inform: 'Initialize fast connectors is not available in this image.' ]
	] on: Error do: [ :ex |
		^ self inform: 'Initialize fast connectors failed: ', ex messageText ].
	self refreshAll
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> initializeGlobalConnectors [
	(self isGlobalGroupSelected not)
		ifTrue: [ ^ self inform: 'Initialize is only available for Global connectors.' ].
	(UIManager default
		confirm: 'This will remove all but kernel connectors. Continue?'
		label: 'Initialize Global Connectors') ifFalse: [ ^ self ].
	[
		self managerPerform: #initializeGlobalConnectors ifUnavailable: [
			self managerPerform: #initializeFastConnectors ifUnavailable: [
				^ self inform: 'Initialize global connectors is not available in this image.' ] ]
	] on: Error do: [ :ex |
		^ self inform: 'Initialize global connectors failed: ', ex messageText ].
	self refreshAll
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> generateClassConnectors [
	| cfg |
	cfg := Smalltalk at: #GbsConfiguration ifAbsent: [ nil ].
	(cfg notNil and: [ cfg respondsTo: #generateClassConnectors ]) ifTrue: [
		[ cfg generateClassConnectors ]
			on: Error
			do: [ :ex | ^ self inform: 'Generate class connectors failed: ', ex messageText ] ].
	[
		self managerPerform: #generateClassConnectors ifUnavailable: [ nil ]
	] on: Error do: [ :ex |
		^ self inform: 'Generate class connectors failed: ', ex messageText ].
	self refreshAll
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> removeInvalidConnectors [
	| cfg |
	cfg := Smalltalk at: #GbsConfiguration ifAbsent: [ nil ].
	(cfg notNil and: [ cfg respondsTo: #removeInvalidConnectors ]) ifTrue: [
		[ cfg removeInvalidConnectors ]
			on: Error
			do: [ :ex | ^ self inform: 'Remove invalid connectors failed: ', ex messageText ] ].
	[
		self managerPerform: #removeInvalidConnectors ifUnavailable: [ nil ]
	] on: Error do: [ :ex |
		^ self inform: 'Remove invalid connectors failed: ', ex messageText ].
	self refreshAll
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> addConnector [
	"Legacy entrypoint. Delegate to type-driven add flow."
	^ self createAndAddConnector
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> createAndAddConnector [
	| connectorClass clientName serverName connector selectedGroup |
	selectedGroup := [ groupList selection selectedItem ] on: Error do: [ nil ].
	selectedGroup ifNil: [ ^ self inform: 'You must first select a connector group.' ].
	connectorClass := self chooseConnectorClassForAdd.
	connectorClass ifNil: [ ^ self ].
	clientName := UIManager default request: 'Client class name:' initialAnswer: ''.
	(clientName isNil or: [ clientName trimBoth isEmpty ]) ifTrue: [ ^ self ].
	serverName := UIManager default request: 'Server class name:' initialAnswer: ''.
	(serverName isNil or: [ serverName trimBoth isEmpty ]) ifTrue: [ ^ self ].
	connector := self instantiateConnectorClass: connectorClass client: clientName trimBoth server: serverName trimBoth.
	[
		(selectedGroup respondsTo: #addNoConnectGlobalConnector:)
			ifTrue: [
				self isGlobalGroupSelected
					ifTrue: [ selectedGroup addNoConnectGlobalConnector: connector ]
					ifFalse: [ selectedGroup addNoConnectConnector: connector ] ]
			ifFalse: [
				self
					managerPerform: #addConnectorClient:server:
					withArguments: { clientName trimBoth. serverName trimBoth }
					ifUnavailable: [ ^ self inform: 'Add connector is not available in this image.' ] ].
	] on: Error do: [ :ex | ^ self inform: 'Add connector failed: ', ex messageText ].
	self refreshConnectorsForCurrentGroup
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> chooseConnectorClassForAdd [
	| choices labels selected |
	choices := self
		managerPerform: #connectorClassChoices
		ifUnavailable: [ GbsConnector allSubclasses ].
	choices := choices asArray select: [ :each |
		(each isBehavior) and: [ each inheritsFrom: GbsConnector ] ].
	choices isEmpty ifTrue: [ ^ nil ].
	labels := choices collect: [ :each | each name asString ].
	selected := UIManager default chooseFrom: labels title: 'Which type of connector?'.
	selected = 0 ifTrue: [ ^ nil ].
	^ choices at: selected ifAbsent: [ nil ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> instantiateConnectorClass: connectorClass client: clientName server: serverName [
	| connector |
	connector := (connectorClass respondsTo: #stName:gsName:)
		ifTrue: [ connectorClass stName: clientName gsName: serverName ]
		ifFalse: [ connectorClass new ].
	(connector respondsTo: #stName:) ifTrue: [ connector stName: clientName ].
	(connector respondsTo: #gsName:) ifTrue: [ connector gsName: serverName ].
	(connector respondsTo: #connectorClientName:) ifTrue: [ connector connectorClientName: clientName ].
	(connector respondsTo: #connectorServerName:) ifTrue: [ connector connectorServerName: serverName ].
	^ connector
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> removeConnector [
	| rows selectedGroup |
	rows := self selectedConnectorRows.
	rows isEmpty ifTrue: [ ^ self inform: 'Select connector(s) first.' ].
	(UIManager default
		confirm: 'Do you really want to remove selected connector(s)?'
		label: 'Remove Connector(s)') ifFalse: [ ^ self ].
	selectedGroup := [ groupList selection selectedItem ] on: Error do: [ nil ].
	[
		rows do: [ :row |
			| clientName serverName connectorObject |
			clientName := self rowClientName: row.
			serverName := self rowServerName: row.
			connectorObject := self
				managerPerform: #connectorObjectForClient:server:
				withArguments: { clientName asString. serverName asString }
				ifUnavailable: [ nil ].
			((selectedGroup respondsTo: #removeGlobalConnector:) and: [ self isGlobalGroupSelected ])
				ifTrue: [ selectedGroup removeGlobalConnector: connectorObject ]
				ifFalse: [
					(selectedGroup respondsTo: #removeConnector:)
						ifTrue: [ selectedGroup removeConnector: connectorObject ]
						ifFalse: [
							self
								managerPerform: #removeConnectorClient:server:
								withArguments: { clientName asString. serverName asString }
								ifUnavailable: [ ^ self inform: 'Remove connector is not available in this image.' ] ] ] ].
	] on: Error do: [ :ex | ^ self inform: 'Remove connector failed: ', ex messageText ].
	self refreshConnectorsForCurrentGroup
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> setSelectedConnectorClassMapping [
	| row clientName serverName mgr choices labels selectedIndex selectedClass |
	row := self currentSelectedConnectorRow.
	row ifNil: [ ^ self inform: 'Select a connector first.' ].
	clientName := self rowClientName: row.
	serverName := self rowServerName: row.
	mgr := self managerClass.
	(mgr isNil or: [ (mgr respondsTo: #setConnectorClass:forClient:server:) not ]) ifTrue: [
		^ self inform: 'Connector class mapping is not available in this image.' ].
	choices := (mgr respondsTo: #connectorClassChoices)
		ifTrue: [ mgr connectorClassChoices ]
		ifFalse: [ { GbsFastConnector. GbsNameConnector. GbsClassConnector. GbsClassVarConnector. GbsClassInstVarConnector } ].
	labels := choices collect: [ :each | each name asString ].
	selectedIndex := UIManager default chooseFrom: labels title: 'Connector class for ', clientName, ' -> ', serverName.
	selectedIndex = 0 ifTrue: [ ^ self ].
	selectedClass := choices at: selectedIndex ifAbsent: [ ^ self ].
	[
		mgr
			setConnectorClass: selectedClass
			forClient: clientName
			server: serverName.
		self refreshConnectorsForCurrentGroup.
	] on: Error do: [ :ex |
		self inform: 'Set connector class failed: ', ex messageText ]
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> clearSelectedConnectorClassMapping [
	| row clientName serverName mgr |
	row := self currentSelectedConnectorRow.
	row ifNil: [ ^ self inform: 'Select a connector first.' ].
	clientName := self rowClientName: row.
	serverName := self rowServerName: row.
	mgr := self managerClass.
	(mgr isNil or: [ (mgr respondsTo: #clearConnectorClassForClient:server:) not ]) ifTrue: [
		^ self inform: 'Connector class mapping is not available in this image.' ].
	[
		mgr clearConnectorClassForClient: clientName server: serverName.
		self refreshConnectorsForCurrentGroup.
	] on: Error do: [ :ex |
		self inform: 'Clear connector class mapping failed: ', ex messageText ]
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> inspectSelectedClientConnector [
	| row connectorObject resolved |
	row := connectorTable selection selectedItem.
	row ifNil: [ ^ self inform: 'Select a connector first.' ].
	connectorObject := self connectorObjectForRow: row.
	(connectorObject notNil and: [ connectorObject respondsTo: #resolveSTObjIfFail: ]) ifTrue: [
		resolved := connectorObject resolveSTObjIfFail: [ nil ].
		resolved ifNotNil: [ ^ self inspectResolvedSTObject: resolved connector: connectorObject ] ].
	(self rowClientName: row) isEmpty
		ifTrue: [ UIManager default inform: 'Client connector not available for selection.' ]
		ifFalse: [ self inspectClassNamed: (self rowClientName: row) asString fallbackLabel: 'Client connector' ]
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> inspectSelectedServerConnector [
	| row connectorObject selectedSession resolved |
	row := connectorTable selection selectedItem.
	row ifNil: [ ^ self inform: 'Select a connector first.' ].
	connectorObject := self connectorObjectForRow: row.
	selectedSession := self chooseConnectorSessionIfFail: [ ^ self ].
	(selectedSession respondsTo: #isLoggedIn)
		ifTrue: [ (selectedSession isLoggedIn == true) ifFalse: [ ^ self inform: 'GemStone session not logged in' ] ].
	(connectorObject notNil and: [ connectorObject respondsTo: #resolveGSObjInSession:ifFail: ]) ifTrue: [
		resolved := connectorObject
			resolveGSObjInSession: selectedSession
			ifFail: [ nil ].
		resolved ifNotNil: [ ^ self inspectResolvedGSObject: resolved connector: connectorObject ] ].
	(self rowServerName: row) isEmpty
		ifTrue: [ UIManager default inform: 'Server connector not available for selection.' ]
		ifFalse: [ self inspectClassNamed: (self rowServerName: row) asString fallbackLabel: 'Server connector' ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> connectorObjectForRow: aRow [
	| clientName serverName |
	aRow ifNil: [ ^ nil ].
	(aRow respondsTo: #resolveSTObjIfFail:) ifTrue: [ ^ aRow ].
	(aRow respondsTo: #connector) ifTrue: [ ^ aRow connector ].
	clientName := self rowClientName: aRow.
	serverName := self rowServerName: aRow.
	^ self
		managerPerform: #connectorObjectForClient:server:
		withArguments: { clientName asString. serverName asString }
		ifUnavailable: [ nil ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> inspectResolvedSTObject: resolvedObject connector: connectorObject [
	| obj |
	obj := resolvedObject.
	(connectorObject notNil and: [ connectorObject respondsTo: #connectsAssociation ]) ifTrue: [
		(connectorObject connectsAssociation and: [ obj respondsTo: #value ]) ifTrue: [ obj := obj value ] ].
	^ obj inspect
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> inspectResolvedGSObject: resolvedObject connector: connectorObject [
	| obj |
	obj := resolvedObject.
	(connectorObject notNil and: [ connectorObject respondsTo: #connectsAssociation ]) ifTrue: [
		connectorObject connectsAssociation ifTrue: [
			(obj respondsTo: #remotePerform:)
				ifTrue: [ obj := obj remotePerform: #value ]
				ifFalse: [ (obj respondsTo: #value) ifTrue: [ obj := obj value ] ] ] ].
	^ obj inspect
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> managerClass [
	^ Smalltalk at: #GbsSessionManager ifAbsent: [ nil ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> managerPerform: aSelector ifUnavailable: unavailableBlock [
	^ self managerPerform: aSelector withArguments: #() ifUnavailable: unavailableBlock
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> managerPerform: aSelector withArguments: args ifUnavailable: unavailableBlock [
	| cls manager |
	cls := self managerClass.
	(cls notNil and: [ cls respondsTo: aSelector ]) ifTrue: [ ^ cls perform: aSelector withArguments: args ].
	manager := (cls notNil and: [ cls respondsTo: #current ])
		ifTrue: [ [ cls current ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	(manager notNil and: [ manager respondsTo: aSelector ]) ifTrue: [
		^ manager perform: aSelector withArguments: args ].
	^ unavailableBlock value
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> inspectClassNamed: aString fallbackLabel: labelString [
	| classObject symbolObject |
	classObject := Smalltalk at: aString asSymbol ifAbsent: [ nil ].
	classObject ifNotNil: [ ^ classObject inspect ].
	symbolObject := aString asSymbol.
	^ symbolObject inspect
]

{ #category : 'accessing' }
GbsConnectorBrowserPresenter >> session: aSession [
	session := aSession
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> closeWindow [
	self saveOptionsToConfiguration.
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> configuration [
	^ GbsConfiguration current
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> loadOptionsFromConfiguration [
	| cfg rawPostAction |
	cfg := self configuration.
	verificationCheck state: (self asBooleanResult: (cfg valueAt: #connectVerification ifAbsent: true) default: true).
	removeInvalidCheck state: (self asBooleanResult: (cfg valueAt: #removeInvalidConnectors ifAbsent: true) default: true).
	self applyConnectionState: (cfg valueAt: #connectorConnectionState ifAbsent: 'connected').
	rawPostAction := cfg valueAt: #postConnectAction ifAbsent: [ nil ].
	(rawPostAction isNil or: [ rawPostAction asString trimBoth isEmpty ]) ifTrue: [
		rawPostAction := 'none'.
		cfg valueAt: #postConnectAction put: rawPostAction ].
	self applyPostConnectAction: rawPostAction
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> saveOptionsToConfiguration [
	| cfg |
	cfg := self configuration.
	cfg
		valueAt: #connectVerification put: (verificationCheck state == true);
		valueAt: #removeInvalidConnectors put: (removeInvalidCheck state == true);
		valueAt: #connectorConnectionState put: self selectedConnectionState;
		valueAt: #postConnectAction put: self selectedPostConnectAction.
	self saveSettingsFromOptionStateForSelectedConnectors
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> wireOptionChangeNotifications [
	{
		verificationCheck.
		removeInvalidCheck.
	} do: [ :presenter | self wireChangeNotificationOn: presenter ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> wireChangeNotificationOn: aPresenter [
	(aPresenter respondsTo: #whenChangedDo:)
		ifTrue: [ aPresenter whenChangedDo: [ self optionSelectionChanged ] ].
	(aPresenter respondsTo: #whenActivatedDo:)
		ifTrue: [ aPresenter whenActivatedDo: [ self optionSelectionChanged ] ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> optionSelectionChanged [
	| selectedKey |
	selectedKey := self connectorSettingKeyForRow: self currentSelectedConnectorRow.
	self saveOptionsToConfiguration.
	self refreshConnectorsForCurrentGroup.
	selectedKey ifNotNil: [ self selectConnectorWithSettingKey: selectedKey ].
	self updateConnectorControlsFromSelection
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> wireRadioSelectionHandlers [
	self wireRadio: connectedRadio selectBlock: [ self connectorConnectSelected ].
	self wireRadio: disconnectedRadio selectBlock: [ self connectorDisconnectSelected ].
	self wireRadio: updateStRadio selectBlock: [ self postConnectActionChangedTo: 'updateST' ].
	self wireRadio: updateGsRadio selectBlock: [ self postConnectActionChangedTo: 'updateGS' ].
	self wireRadio: forwarderRadio selectBlock: [ self postConnectActionChangedTo: 'forwarder' ].
	self wireRadio: clientForwarderRadio selectBlock: [ self postConnectActionChangedTo: 'clientForwarder' ].
	self wireRadio: noneRadio selectBlock: [ self postConnectActionChangedTo: 'none' ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> wireRadio: aRadioPresenter selectBlock: aBlock [
	aRadioPresenter ifNil: [ ^ self ].
	(aRadioPresenter respondsTo: #whenActivatedDo:)
		ifTrue: [ aRadioPresenter whenActivatedDo: aBlock ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> refreshConnectorsForCurrentGroup [
	| selected |
	selected := [ groupList selection selectedItem ] on: Error do: [ nil ].
	selected ifNil: [
		selected := [ groupItems first ] on: Error do: [ nil ] ].
	self refreshConnectorsForGroup: selected
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> connectorSelectionChanged: selectedRow [
	self updateConnectorControlsFromSelection
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> currentSelectedConnectorRow [
	^ [ connectorTable selection selectedItem ] on: Error do: [ nil ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> selectedConnectorRows [
	| selection selected |
	selection := [ connectorTable selection ] on: Error do: [ nil ].
	selection isNil ifTrue: [ ^ #() ].
	(selection respondsTo: #selectedItems) ifTrue: [
		selected := [ selection selectedItems ] on: Error do: [ #() ].
		(selected isCollection and: [ selected isEmpty not ]) ifTrue: [ ^ selected asArray ] ].
	(selection respondsTo: #selectedItem) ifTrue: [
		selected := [ selection selectedItem ] on: Error do: [ nil ].
		selected ifNotNil: [ ^ { selected } ] ].
	^ #()
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> connectorSettingKeyForRow: aRow [
	| clientName serverName |
	aRow ifNil: [ ^ nil ].
	clientName := self rowClientName: aRow.
	serverName := self rowServerName: aRow.
	(clientName isEmpty or: [ serverName isEmpty ]) ifTrue: [ ^ nil ].
	^ clientName asString, '->', serverName asString
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> connectorSettingsMap [
	| cfg raw |
	cfg := self configuration.
	raw := cfg valueAt: #connectorRowSettings ifAbsent: [ Dictionary new ].
	(raw isDictionary) ifTrue: [ ^ raw ].
	^ Dictionary new
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> saveConnectorSettingsMap: aDictionary [
	self configuration valueAt: #connectorRowSettings put: aDictionary
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> applySettingsForSelectedConnector [
	self applySettingsForConnectorRow: self currentSelectedConnectorRow
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> applySettingsForConnectorRow: aRow [
	| key map rowSettings persistedAction connectorObject |
	key := self connectorSettingKeyForRow: aRow.
	key ifNil: [
		self applyConnectionState: self defaultConnectionState.
		self applyPostConnectAction: self defaultPostConnectAction.
		self setAllPostConnectActionOptionsEnabled: true.
		^ self ].
	self applyConnectionStateForConnectorRow: aRow.
	connectorObject := self connectorObjectForRow: aRow.
	map := self connectorSettingsMap.
	rowSettings := map at: key ifAbsent: [ nil ].
	persistedAction := (rowSettings isDictionary)
		ifTrue: [ rowSettings at: #postConnectAction ifAbsent: [ nil ] ]
		ifFalse: [ nil ].
	(persistedAction isNil or: [ persistedAction asString trimBoth isEmpty ]) ifTrue: [
		persistedAction := (connectorObject notNil and: [ connectorObject respondsTo: #postConnectAction ])
			ifTrue: [ [ connectorObject postConnectAction ] on: Error do: [ nil ] ]
			ifFalse: [ nil ] ].
	(persistedAction isNil or: [ persistedAction asString trimBoth isEmpty ]) ifTrue: [
		persistedAction := self
			managerPerform: #postConnectActionForConnectorClient:server:
			withArguments: { (self rowClientName: aRow) asString. (self rowServerName: aRow) asString }
			ifUnavailable: [ nil ] ].
	(persistedAction isNil or: [ persistedAction asString trimBoth isEmpty ]) ifTrue: [
		persistedAction := self defaultPostConnectAction ].
	self applyPostConnectAction: persistedAction.
	self updatePostConnectActionEnablementForRow: aRow
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> saveSettingsFromOptionStateForSelectedConnectors [
	| rows map entry |
	rows := self selectedConnectorRows.
	rows isEmpty ifTrue: [ ^ self ].
	map := self connectorSettingsMap copy.
	entry := Dictionary new
		at: #connectionState put: self selectedConnectionState;
		at: #postConnectAction put: self selectedPostConnectAction;
		yourself.
	rows do: [ :row |
		| key |
		key := self connectorSettingKeyForRow: row.
		key ifNotNil: [ map at: key put: entry copy ] ].
	self saveConnectorSettingsMap: map
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> saveSettingsFromOptionStateForSelectedConnector [
	"Backward-compatible delegate"
	^ self saveSettingsFromOptionStateForSelectedConnectors
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> postConnectActionChangedTo: actionString [
	self applyPostConnectAction: actionString.
	self applyPostConnectActionToSelectedConnectors: actionString.
	self saveOptionsToConfiguration
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> applyPostConnectActionToSelectedConnectors: actionString [
	| rows |
	rows := self selectedConnectorRows.
	rows do: [ :row |
		| clientName serverName connectorObject |
		clientName := self rowClientName: row.
		serverName := self rowServerName: row.
		self
			managerPerform: #setPostConnectAction:forConnectorClient:server:
			withArguments: { actionString. clientName asString. serverName asString }
			ifUnavailable: [ nil ].
		connectorObject := self connectorObjectForRow: row.
		(connectorObject notNil and: [ connectorObject respondsTo: #postConnectAction: ]) ifTrue: [
			[ connectorObject postConnectAction: actionString ] on: Error do: [ ] ] ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> connectorConnectSelected [
	| selectedKey |
	selectedKey := self connectorSettingKeyForRow: self currentSelectedConnectorRow.
	self setConnectionStateForSelectedConnector: 'connected'.
	self applyConnectionState: 'connected'.
	self saveOptionsToConfiguration.
	self refreshConnectorsForCurrentGroup.
	selectedKey ifNotNil: [ self selectConnectorWithSettingKey: selectedKey ].
	self updateConnectorControlsFromSelection
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> connectorDisconnectSelected [
	| selectedKey |
	selectedKey := self connectorSettingKeyForRow: self currentSelectedConnectorRow.
	self setConnectionStateForSelectedConnector: 'disconnected'.
	self applyConnectionState: 'disconnected'.
	self saveOptionsToConfiguration.
	self refreshConnectorsForCurrentGroup.
	selectedKey ifNotNil: [ self selectConnectorWithSettingKey: selectedKey ].
	self updateConnectorControlsFromSelection
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> applyConnectionStateForConnectorRow: aRow [
	| clientName serverName connectedValue connectorObject selectedSession key map rowSettings |
	clientName := self rowClientName: aRow.
	serverName := self rowServerName: aRow.
	key := self connectorSettingKeyForRow: aRow.
	map := self connectorSettingsMap.
	rowSettings := key ifNil: [ nil ] ifNotNil: [ map at: key ifAbsent: [ nil ] ].
	(rowSettings isDictionary and: [ rowSettings includesKey: #connectionState ]) ifTrue: [
		^ self applyConnectionState: (rowSettings at: #connectionState ifAbsent: [ self defaultConnectionState ]) ].
	connectorObject := self connectorObjectForRow: aRow.
	selectedSession := self selectedConnectorSession.
	(connectorObject notNil and: [ connectorObject respondsTo: #isConnectedInSession: ]) ifTrue: [
		connectedValue := [ connectorObject isConnectedInSession: selectedSession ] on: Error do: [ nil ].
		connectedValue ifNotNil: [
			^ self applyConnectionState: (connectedValue == true ifTrue: [ 'connected' ] ifFalse: [ 'disconnected' ]) ] ].
	connectedValue := self
		managerPerform: #isConnectorClient:server:connectedInSession:
		withArguments: { clientName asString. serverName asString. self selectedConnectorSessionKey }
		ifUnavailable: [ nil ].
	connectedValue isNil
		ifTrue: [ self applyConnectionState: self defaultConnectionState ]
		ifFalse: [ self applyConnectionState: (connectedValue == true ifTrue: [ 'connected' ] ifFalse: [ 'disconnected' ]) ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> setConnectionStateForSelectedConnector: stateString [
	| row clientName serverName selectedSession connectorObject connectedBoolean |
	row := self currentSelectedConnectorRow.
	row ifNil: [ ^ self ].
	clientName := self rowClientName: row.
	serverName := self rowServerName: row.
	connectedBoolean := stateString asLowercase = 'connected'.
	selectedSession := self chooseConnectorSessionIfFail: [ ^ self ].
	connectorObject := self connectorObjectForRow: row.
	connectorObject ifNotNil: [
		connectedBoolean
			ifTrue: [
				(connectorObject respondsTo: #connectInSession:ifFail:)
					ifTrue: [
						[ connectorObject connectInSession: selectedSession ifFail: [ :msg | self inform: msg ] ]
							on: Error
							do: [ :ex | self inform: ex messageText ] ] ]
			ifFalse: [
				(connectorObject respondsTo: #disconnectInSession:)
					ifTrue: [ [ connectorObject disconnectInSession: selectedSession ] on: Error do: [ :ex | self inform: ex messageText ] ] ] ].
	self
		managerPerform: #setConnectorClient:server:connected:inSession:
		withArguments: {
			clientName asString.
			serverName asString.
			connectedBoolean.
			self selectedConnectorSessionKey }
		ifUnavailable: [ nil ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> connectorSessionKey [
	| user stone |
	user := self parameterValueNamed: #username default: 'unknown-user'.
	stone := self parameterValueNamed: #gemStoneName default: 'unknown-stone'.
	^ user, '@', stone
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> selectedConnectorSessionKey [
	| sess |
	sess := self selectedConnectorSession.
	(sess isNil or: [ sess == session ]) ifTrue: [ ^ self connectorSessionKey ].
	(sess respondsTo: #parameters) ifTrue: [
		^ [ ((sess parameters username ifNil: [ 'unknown-user' ]) asString), '@', ((sess parameters gemStoneName ifNil: [ 'unknown-stone' ]) asString) ]
			on: Error
			do: [ self connectorSessionKey ] ].
	^ self connectorSessionKey
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> selectedConnectorSession [
	^ connectorActionSession ifNil: [ session ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> chooseConnectorSessionIfFail: failBlock [
	| candidates chosen labels |
	candidates := self appropriateSessions.
	candidates isEmpty ifTrue: [ ^ failBlock value ].
	candidates size = 1 ifTrue: [
		connectorActionSession := candidates first.
		^ connectorActionSession ].
	labels := candidates collect: [ :each |
		[ each printString ] on: Error do: [ 'Session' ] ].
	chosen := UIManager default
		chooseFrom: labels
		title: 'In which session?'.
	chosen = 0 ifTrue: [ ^ failBlock value ].
	connectorActionSession := candidates at: chosen ifAbsent: [ nil ].
	connectorActionSession ifNil: [ ^ failBlock value ].
	^ connectorActionSession
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> appropriateSessions [
	| selectedGroup groupSession sessionsFromManager current |
	selectedGroup := [ groupList selection selectedItem ] on: Error do: [ nil ].
	(selectedGroup respondsTo: #session) ifTrue: [
		groupSession := selectedGroup session.
		groupSession ifNotNil: [ ^ { groupSession } ] ].
	sessionsFromManager := self
		managerPerform: #loggedInSessions
		ifUnavailable: [ #() ].
	(sessionsFromManager isCollection and: [ sessionsFromManager isEmpty not ]) ifTrue: [ ^ sessionsFromManager asArray ].
	current := session ifNil: [ GbsSessionParameters currentSession ].
	current ifNil: [ ^ #() ].
	^ { current }
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> hasSelectedGroup [
	^ [ groupList selection selectedItem notNil ] on: Error do: [ false ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> hasSelectedConnector [
	^ [ connectorTable selection selectedItem notNil ] on: Error do: [ false ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> hasSelectedConnectors [
	^ self selectedConnectorRows isEmpty not
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> hasSingleSelectedConnector [
	^ self selectedConnectorRows size = 1
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> canInitializeSelectedGroup [
	^ self isGlobalGroupSelected
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> canInspectSelectedConnector [
	^ self hasSingleSelectedConnector
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> canAddConnector [
	^ self hasSelectedGroup
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> canRemoveSelectedConnectors [
	^ self hasSelectedConnectors
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> canSetConnectorClassMapping [
	^ self hasSingleSelectedConnector
		and: [ (self managerClass notNil)
		and: [ (self managerClass respondsTo: #setConnectorClass:forClient:server:)
		and: [ self managerClass respondsTo: #clearConnectorClassForClient:server: ] ] ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> isGlobalGroupSelected [
	| selected |
	selected := [ groupList selection selectedItem ] on: Error do: [ nil ].
	selected ifNil: [ ^ false ].
	(selected respondsTo: #isGlobalGroup) ifTrue: [ ^ selected isGlobalGroup ].
	^ selected asString = 'Global connectors'
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> rowType: aRow [
	aRow ifNil: [ ^ '' ].
	(aRow respondsTo: #type) ifTrue: [ ^ aRow type ].
	(aRow respondsTo: #connectorType) ifTrue: [ ^ aRow connectorType ].
	(aRow respondsTo: #at:ifAbsent:) ifTrue: [ ^ aRow at: 1 ifAbsent: [ '' ] ].
	^ self connectorTypeStringFor: aRow
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> rowClientName: aRow [
	aRow ifNil: [ ^ '' ].
	(aRow respondsTo: #clientName) ifTrue: [ ^ aRow clientName ].
	(aRow respondsTo: #connectorClient) ifTrue: [ ^ aRow connectorClient ].
	(aRow respondsTo: #at:ifAbsent:) ifTrue: [ ^ aRow at: 2 ifAbsent: [ '' ] ].
	^ self connectorClientNameFor: aRow
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> rowServerName: aRow [
	aRow ifNil: [ ^ '' ].
	(aRow respondsTo: #serverName) ifTrue: [ ^ aRow serverName ].
	(aRow respondsTo: #connectorServer) ifTrue: [ ^ aRow connectorServer ].
	(aRow respondsTo: #at:ifAbsent:) ifTrue: [ ^ aRow at: 3 ifAbsent: [ '' ] ].
	^ self connectorServerNameFor: aRow
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> updateConnectorControlsFromSelection [
	| selected single hasSession selectedRow |
	selected := self selectedConnectorRows.
	single := selected size = 1.
	hasSession := self appropriateSessions isEmpty not.
	self setConnectionControlsEnabled: (single and: [ hasSession ]).
	self setAllPostConnectActionOptionsEnabled: single.
	single ifFalse: [
		self clearConnectionStateSelection.
		self clearPostConnectActionSelection.
		^ self ].
	selectedRow := selected first.
	self applySettingsForConnectorRow: selectedRow
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> setConnectionControlsEnabled: aBoolean [
	(connectedRadio respondsTo: #enabled:) ifTrue: [ connectedRadio enabled: aBoolean ].
	(disconnectedRadio respondsTo: #enabled:) ifTrue: [ disconnectedRadio enabled: aBoolean ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> clearConnectionStateSelection [
	connectedRadio state: false.
	disconnectedRadio state: false
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> clearPostConnectActionSelection [
	updateStRadio state: false.
	updateGsRadio state: false.
	forwarderRadio state: false.
	clientForwarderRadio state: false.
	noneRadio state: false
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> invalidPostConnectActionsForRow: aRow [
	| clientName serverName raw connectorObject |
	aRow ifNil: [ ^ #() ].
	connectorObject := self connectorObjectForRow: aRow.
	(connectorObject notNil and: [ connectorObject respondsTo: #invalidPostConnectActions ]) ifTrue: [
		raw := [ connectorObject invalidPostConnectActions ] on: Error do: [ #() ].
		(raw isCollection and: [ raw isString not ]) ifTrue: [
			^ raw collect: [ :each | each asString asLowercase ] ] ].
	clientName := self rowClientName: aRow.
	serverName := self rowServerName: aRow.
	raw := self
		managerPerform: #invalidPostConnectActionsForConnectorClient:server:
		withArguments: { clientName asString. serverName asString }
		ifUnavailable: [ #() ].
	(raw isCollection and: [ raw isString not ]) ifFalse: [ ^ #() ].
	^ raw collect: [ :each | each asString asLowercase ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> setAllPostConnectActionOptionsEnabled: aBoolean [
	{ updateStRadio. updateGsRadio. forwarderRadio. clientForwarderRadio. noneRadio } do: [ :button |
		(button respondsTo: #enabled:)
			ifTrue: [ button enabled: aBoolean ] ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> updatePostConnectActionEnablementForRow: aRow [
	| invalid selected validFallback |
	invalid := self invalidPostConnectActionsForRow: aRow.
	self setAllPostConnectActionOptionsEnabled: true.
	(invalid includes: 'updatest') ifTrue: [ (updateStRadio respondsTo: #enabled:) ifTrue: [ updateStRadio enabled: false ] ].
	(invalid includes: 'updategs') ifTrue: [ (updateGsRadio respondsTo: #enabled:) ifTrue: [ updateGsRadio enabled: false ] ].
	(invalid includes: 'forwarder') ifTrue: [ (forwarderRadio respondsTo: #enabled:) ifTrue: [ forwarderRadio enabled: false ] ].
	(invalid includes: 'clientforwarder') ifTrue: [ (clientForwarderRadio respondsTo: #enabled:) ifTrue: [ clientForwarderRadio enabled: false ] ].
	(invalid includes: 'none') ifTrue: [ (noneRadio respondsTo: #enabled:) ifTrue: [ noneRadio enabled: false ] ].

	selected := self selectedPostConnectAction asLowercase.
	(invalid includes: selected) ifTrue: [
		validFallback := #('none' 'updateST' 'updateGS' 'forwarder' 'clientForwarder')
			detect: [ :each | (invalid includes: each asLowercase) not ]
			ifNone: [ 'none' ].
		self applyPostConnectAction: validFallback.
		self saveSettingsFromOptionStateForSelectedConnectors ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> applyConnectionState: rawValue [
	| value |
	value := rawValue ifNil: [ 'connected' ] ifNotNil: [ rawValue asString asLowercase ].
	connectedRadio state: value ~= 'disconnected'.
	disconnectedRadio state: value = 'disconnected'
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> selectedConnectionState [
	disconnectedRadio state == true ifTrue: [ ^ 'disconnected' ].
	^ 'connected'
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> applyPostConnectAction: rawValue [
	| value |
	value := rawValue ifNil: [ 'none' ] ifNotNil: [ rawValue asString asLowercase ].
	updateStRadio state: value = 'updatest'.
	updateGsRadio state: value = 'updategs'.
	forwarderRadio state: value = 'forwarder'.
	clientForwarderRadio state: value = 'clientforwarder'.
	noneRadio state: (value = 'none' or: [ value isEmpty ])
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> selectedPostConnectAction [
	updateStRadio state == true ifTrue: [ ^ 'updateST' ].
	updateGsRadio state == true ifTrue: [ ^ 'updateGS' ].
	forwarderRadio state == true ifTrue: [ ^ 'forwarder' ].
	clientForwarderRadio state == true ifTrue: [ ^ 'clientForwarder' ].
	^ 'none'
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> asBooleanResult: raw default: defaultBoolean [
	raw ifNil: [ ^ defaultBoolean ].
	(raw == true or: [ raw == false ]) ifTrue: [ ^ raw ].
	(raw respondsTo: #asString) ifFalse: [ ^ defaultBoolean ].
	(#('true' '1' 'yes') includes: raw asString asLowercase) ifTrue: [ ^ true ].
	(#('false' '0' 'no' 'nil' '') includes: raw asString asLowercase) ifTrue: [ ^ false ].
	^ defaultBoolean
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> defaultConnectionState [
	^ 'connected'
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> defaultPostConnectAction [
	^ 'none'
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> selectedItemFromSelectionEvent: selectionEvent [
	selectionEvent ifNil: [ ^ nil ].
	(selectionEvent respondsTo: #selectedItem)
		ifTrue: [ ^ selectionEvent selectedItem ].
	^ selectionEvent
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> selectGroupWithDisplayString: aString [
	| match |
	aString ifNil: [ ^ self ].
	match := groupItems
		detect: [ :each | (self groupDisplayStringFor: each) = aString ]
		ifNone: [ nil ].
	match ifNil: [ ^ self ].
	(groupList respondsTo: #selectItem:)
		ifTrue: [ ^ groupList selectItem: match ].
	(groupList respondsTo: #selectedItem:)
		ifTrue: [ ^ groupList selectedItem: match ].
	(groupList respondsTo: #selection)
		ifTrue: [ [ groupList selection selectItem: match ] on: Error do: [ ] ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> selectConnectorWithSettingKey: aKeyString [
	| match |
	aKeyString ifNil: [ ^ self ].
	match := (connectorTable items ifNil: [ #() ])
		detect: [ :each | (self connectorSettingKeyForRow: each) = aKeyString ]
		ifNone: [ nil ].
	match ifNil: [ ^ self ].
	(connectorTable respondsTo: #selectItem:)
		ifTrue: [ ^ connectorTable selectItem: match ].
	(connectorTable respondsTo: #selectedItem:)
		ifTrue: [ ^ connectorTable selectedItem: match ].
	(connectorTable respondsTo: #selection)
		ifTrue: [ [ connectorTable selection selectItem: match ] on: Error do: [ ] ]
]
