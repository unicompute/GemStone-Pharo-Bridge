Class {
	#name : 'GbsConnectorBrowserPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
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
	groupList display: [ :each | each asString ].

	connectorTable := self newTable.
	connectorTable
		addColumn: (SpStringTableColumn title: 'Type' evaluated: [ :row | row at: 1 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Client' evaluated: [ :row | row at: 2 ifAbsent: [ '' ] ]);
		addColumn: (SpStringTableColumn title: 'Server' evaluated: [ :row | row at: 3 ifAbsent: [ '' ] ]);
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
		self refreshConnectorsForGroup: selection selectedItem ].
	(connectorTable respondsTo: #whenActivatedDo:) ifTrue: [
		connectorTable whenActivatedDo: [ :selection |
			selection selectedItem ifNotNil: [ self inspectSelectedClientConnector ] ] ].

	self loadOptionsFromConfiguration.
	self wireOptionChangeNotifications.

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
	| optionsLeft optionsCenter optionsRight optionsRow panes |
	optionsLeft := SpBoxLayout newTopToBottom
		add: verificationCheck expand: false;
		add: removeInvalidCheck expand: false;
		spacing: 6;
		yourself.
	optionsCenter := SpBoxLayout newTopToBottom
		add: connectedRadio expand: false;
		add: disconnectedRadio expand: false;
		spacing: 6;
		yourself.
	optionsRight := SpBoxLayout newTopToBottom
		add: (self newLabel label: 'Postconnect Action') expand: false;
		add: updateStRadio expand: false;
		add: updateGsRadio expand: false;
		add: forwarderRadio expand: false;
		add: clientForwarderRadio expand: false;
		add: noneRadio expand: false;
		spacing: 4;
		yourself.
	optionsRow := SpBoxLayout newLeftToRight
		add: optionsLeft;
		add: optionsCenter;
		add: optionsRight;
		spacing: 24;
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
		initialExtent: 640 @ 560
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
		addItem: [ :item | item name: 'Update'; action: [ self refreshAll ] ];
		addItem: [ :item | item name: 'Close'; action: [ self closeWindow ] ];
		yourself
]

{ #category : 'menus' }
GbsConnectorBrowserPresenter >> menuGroup [
	^ self newMenu
		addItem: [ :item | item name: 'Initialize'; action: [ self initializeFastConnectors ] ];
		yourself
]

{ #category : 'menus' }
GbsConnectorBrowserPresenter >> menuConnector [
	^ self newMenu
		addItem: [ :item | item name: 'Inspect Client'; action: [ self inspectSelectedClientConnector ] ];
		addItem: [ :item | item name: 'Inspect Server'; action: [ self inspectSelectedServerConnector ] ];
		addItem: [ :item | item name: 'Add'; action: [ self addConnector ] ];
		addItem: [ :item | item name: 'Remove'; action: [ self removeConnector ] ];
		yourself
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> refreshAll [
	self refreshGroups.
	(groupItems isEmpty)
		ifTrue: [ connectorTable items: #() ]
		ifFalse: [
			(groupList respondsTo: #selectIndex:)
				ifTrue: [ groupList selectIndex: 1 ]
				ifFalse: [ (groupList respondsTo: #selectItem:) ifTrue: [ groupList selectItem: groupItems first ] ].
			(self fastConnectorPairs isEmpty and: [ verificationCheck state = true ])
				ifTrue: [ [ self managerPerform: #initializeFastConnectors ifUnavailable: [ nil ] ] on: Error do: [ ] ].
			self refreshConnectorsForGroup: groupItems first ]
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> refreshGroups [
	groupItems := {
		'Global connectors'.
		self sessionGroupLabel
	}.
	groupList items: groupItems
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> refreshConnectorsForGroup: aGroupLabel [
	| rows |
	aGroupLabel ifNil: [ connectorTable items: #(). ^ self ].
	rows := self connectorRowsForGroup: aGroupLabel.
	connectorTable items: rows
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> connectorRowsForGroup: aGroupLabel [
	| list |
	list := self fastConnectorPairs.
	^ list collect: [ :pair |
		{ 'Fast'. (pair at: 1 ifAbsent: [ '' ]) asString. (pair at: 2 ifAbsent: [ '' ]) asString } ]
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
	| clientName serverName |
	clientName := UIManager default request: 'Client class name:' initialAnswer: ''.
	(clientName isNil or: [ clientName trimBoth isEmpty ]) ifTrue: [ ^ self ].
	serverName := UIManager default request: 'Server class name:' initialAnswer: ''.
	(serverName isNil or: [ serverName trimBoth isEmpty ]) ifTrue: [ ^ self ].
	[
		self
			managerPerform: #addConnectorClient:server:
			withArguments: { clientName trimBoth. serverName trimBoth }
			ifUnavailable: [ ^ self inform: 'Add connector is not available in this image.' ].
	] on: Error do: [ :ex | ^ self inform: 'Add connector failed: ', ex messageText ].
	self refreshAll
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> removeConnector [
	| row clientName serverName |
	row := connectorTable selection selectedItem.
	row ifNil: [ ^ self inform: 'Select a connector first.' ].
	clientName := row at: 2 ifAbsent: [ '' ].
	serverName := row at: 3 ifAbsent: [ '' ].
	(UIManager default
		confirm: 'Remove connector "', clientName asString, ' -> ', serverName asString, '"?'
		label: 'Remove Connector') ifFalse: [ ^ self ].
	[
		self
			managerPerform: #removeConnectorClient:server:
			withArguments: { clientName asString. serverName asString }
			ifUnavailable: [ ^ self inform: 'Remove connector is not available in this image.' ].
	] on: Error do: [ :ex | ^ self inform: 'Remove connector failed: ', ex messageText ].
	self refreshAll
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> inspectSelectedClientConnector [
	| row |
	row := connectorTable selection selectedItem.
	row ifNil: [ ^ self inform: 'Select a connector first.' ].
	(row size >= 2)
		ifTrue: [ self inspectClassNamed: (row at: 2) asString fallbackLabel: 'Client connector' ]
		ifFalse: [ UIManager default inform: 'Client connector not available for selection.' ]
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> inspectSelectedServerConnector [
	| row |
	row := connectorTable selection selectedItem.
	row ifNil: [ ^ self inform: 'Select a connector first.' ].
	(row size >= 3)
		ifTrue: [ self inspectClassNamed: (row at: 3) asString fallbackLabel: 'Server connector' ]
		ifFalse: [ UIManager default inform: 'Server connector not available for selection.' ]
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
	| cfg |
	cfg := self configuration.
	verificationCheck state: (self asBooleanResult: (cfg valueAt: #connectVerification ifAbsent: true) default: true).
	removeInvalidCheck state: (self asBooleanResult: (cfg valueAt: #removeInvalidConnectors ifAbsent: true) default: true).
	self applyConnectionState: (cfg valueAt: #connectorConnectionState ifAbsent: 'connected').
	self applyPostConnectAction: (cfg valueAt: #postConnectAction ifAbsent: 'none')
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> saveOptionsToConfiguration [
	| cfg |
	cfg := self configuration.
	cfg
		valueAt: #connectVerification put: (verificationCheck state == true);
		valueAt: #removeInvalidConnectors put: (removeInvalidCheck state == true);
		valueAt: #connectorConnectionState put: self selectedConnectionState;
		valueAt: #postConnectAction put: self selectedPostConnectAction
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> wireOptionChangeNotifications [
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
	} do: [ :presenter | self wireChangeNotificationOn: presenter ]
]

{ #category : 'private' }
GbsConnectorBrowserPresenter >> wireChangeNotificationOn: aPresenter [
	(aPresenter respondsTo: #whenChangedDo:)
		ifTrue: [ aPresenter whenChangedDo: [ self saveOptionsToConfiguration ] ].
	(aPresenter respondsTo: #whenActivatedDo:)
		ifTrue: [ aPresenter whenActivatedDo: [ self saveOptionsToConfiguration ] ]
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
