Class {
	#name : 'GbsConnectorBrowserPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'session',
		'mainMenu',
		'groupList',
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
	noneRadio := self newRadioButton label: 'none'
]

{ #category : 'initialization' }
GbsConnectorBrowserPresenter >> connectPresenters [
	groupList whenSelectionChangedDo: [ :selection |
		self refreshConnectorsForGroup: selection selectedItem ].

	verificationCheck state: true.
	removeInvalidCheck state: true.
	noneRadio state: true.

	self refreshAll
]

{ #category : 'layout' }
GbsConnectorBrowserPresenter >> defaultLayout [
	| optionsLeft optionsCenter optionsRight optionsRow topAndMiddle |
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
	topAndMiddle := SpPanedLayout newVertical
		add: groupList;
		add: connectorTable;
		positionOfSlider: 18 percent;
		yourself.

	^ SpBoxLayout newTopToBottom
		add: mainMenu expand: false;
		add: topAndMiddle;
		add: optionsRow expand: false;
		spacing: 6;
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
		addItem: [ :item | item name: 'Refresh'; action: [ self refreshAll ] ];
		addItem: [ :item | item name: 'Close'; action: [ self closeWindow ] ];
		yourself
]

{ #category : 'menus' }
GbsConnectorBrowserPresenter >> menuGroup [
	^ self newMenu
		addItem: [ :item | item name: 'Refresh Groups'; action: [ self refreshGroups ] ];
		yourself
]

{ #category : 'menus' }
GbsConnectorBrowserPresenter >> menuConnector [
	^ self newMenu
		addItem: [ :item | item name: 'Initialize Fast Connectors'; action: [ self initializeFastConnectors ] ];
		addItem: [ :item | item name: 'Generate Class Connectors'; action: [ self generateClassConnectors ] ];
		addItem: [ :item | item name: 'Remove Invalid Connectors'; action: [ self removeInvalidConnectors ] ];
		yourself
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> refreshAll [
	self refreshGroups.
	self refreshConnectorsForGroup: groupList selection selectedItem
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> refreshGroups [
	| groups |
	groups := OrderedCollection new.
	groups add: 'Global connectors'.
	groups add: self sessionGroupLabel.
	groupList items: groups asArray
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
	| mgrClass pairs |
	mgrClass := Smalltalk at: #GbsSessionManager ifAbsent: [ nil ].
	mgrClass ifNil: [ ^ #() ].
	pairs := [ mgrClass globalFastConnectorsList ] on: Error do: [ #() ].
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
	| mgr |
	mgr := Smalltalk at: #GbsSessionManager ifAbsent: [ nil ].
	(mgr notNil and: [ mgr respondsTo: #initializeFastConnectors ]) ifTrue: [
		[ mgr initializeFastConnectors ]
			on: Error
			do: [ :ex | ^ self inform: 'Initialize fast connectors failed: ', ex messageText ] ].
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
	self refreshAll
]

{ #category : 'accessing' }
GbsConnectorBrowserPresenter >> session: aSession [
	session := aSession
]

{ #category : 'actions' }
GbsConnectorBrowserPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]
