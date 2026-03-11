Class {
	#name : 'GbsSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'configuration',
		'libraryField',
		'initialCacheSizeField',
		'initialDirtyPoolField',
		'haltOnErrorField',
		'faultLevelRpcField',
		'delayInterruptField',
		'traversalBufferField',
		'eventPollingField',
		'eventPriorityField',
		'blockReplicationPolicyDrop',
		'defaultFaultPolicyDrop',
		'bulkLoadYes',
		'bulkLoadNo',
		'generateClassConnectorsYes',
		'generateClassConnectorsNo',
		'generateClientClassesYes',
		'generateClientClassesNo',
		'generateServerClassesYes',
		'generateServerClassesNo',
		'connectorNillingYes',
		'connectorNillingNo',
		'connectVerificationYes',
		'connectVerificationNo',
		'removeInvalidConnectorsYes',
		'removeInvalidConnectorsNo',
		'assertionChecksYes',
		'assertionChecksNo',
		'forwarderDebuggingYes',
		'forwarderDebuggingNo',
		'stubDebuggingYes',
		'stubDebuggingNo',
		'autoMarkDirtyYes',
		'autoMarkDirtyNo',
		'blockReplicationEnabledYes',
		'blockReplicationEnabledNo',
		'freeSlotsOnStubbingYes',
		'freeSlotsOnStubbingNo',
		'blockingProtocolRpcYes',
		'blockingProtocolRpcNo',
		'fullCompressionYes',
		'fullCompressionNo',
		'confirmYes',
		'confirmNo',
		'verboseYes',
		'verboseNo',
		'saveButton',
		'cancelButton',
		'browseButton'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbsSettingsPresenter class >> open [
	| presenter |
	presenter := self new.
	presenter configuration: GbsConfiguration current.
	presenter open.
	^ presenter
]

{ #category : 'accessing' }
GbsSettingsPresenter >> configuration: aConfiguration [
	configuration := aConfiguration.
	configuration ifNotNil: [ configuration initializeDefaults ]
]

{ #category : 'initialization' }
GbsSettingsPresenter >> initializePresenters [
	libraryField := self newTextInput.
	initialCacheSizeField := self newTextInput.
	initialDirtyPoolField := self newTextInput.
	haltOnErrorField := self newTextInput.
	faultLevelRpcField := self newTextInput.
	delayInterruptField := self newTextInput.
	traversalBufferField := self newTextInput.
	eventPollingField := self newTextInput.
	eventPriorityField := self newTextInput.
	blockReplicationPolicyDrop := self newDropList.
	defaultFaultPolicyDrop := self newDropList.
	blockReplicationPolicyDrop items: #( 'replicate' 'stub' 'none' ).
	defaultFaultPolicyDrop items: #( 'lazy' 'eager' 'none' ).

	browseButton := self newButton
		label: 'Browse';
		action: [ self chooseLibraryPath ];
		yourself.

	bulkLoadYes := self newRadioButton label: 'Yes'. bulkLoadNo := self newRadioButton label: 'No'.
	generateClassConnectorsYes := self newRadioButton label: 'Yes'. generateClassConnectorsNo := self newRadioButton label: 'No'.
	generateClientClassesYes := self newRadioButton label: 'Yes'. generateClientClassesNo := self newRadioButton label: 'No'.
	generateServerClassesYes := self newRadioButton label: 'Yes'. generateServerClassesNo := self newRadioButton label: 'No'.
	connectorNillingYes := self newRadioButton label: 'Yes'. connectorNillingNo := self newRadioButton label: 'No'.
	connectVerificationYes := self newRadioButton label: 'Yes'. connectVerificationNo := self newRadioButton label: 'No'.
	removeInvalidConnectorsYes := self newRadioButton label: 'Yes'. removeInvalidConnectorsNo := self newRadioButton label: 'No'.
	assertionChecksYes := self newRadioButton label: 'Yes'. assertionChecksNo := self newRadioButton label: 'No'.
	forwarderDebuggingYes := self newRadioButton label: 'Yes'. forwarderDebuggingNo := self newRadioButton label: 'No'.
	stubDebuggingYes := self newRadioButton label: 'Yes'. stubDebuggingNo := self newRadioButton label: 'No'.
	autoMarkDirtyYes := self newRadioButton label: 'Yes'. autoMarkDirtyNo := self newRadioButton label: 'No'.
	blockReplicationEnabledYes := self newRadioButton label: 'Yes'. blockReplicationEnabledNo := self newRadioButton label: 'No'.
	freeSlotsOnStubbingYes := self newRadioButton label: 'Yes'. freeSlotsOnStubbingNo := self newRadioButton label: 'No'.
	blockingProtocolRpcYes := self newRadioButton label: 'Yes'. blockingProtocolRpcNo := self newRadioButton label: 'No'.
	fullCompressionYes := self newRadioButton label: 'Yes'. fullCompressionNo := self newRadioButton label: 'No'.
	confirmYes := self newRadioButton label: 'Yes'. confirmNo := self newRadioButton label: 'No'.
	verboseYes := self newRadioButton label: 'Yes'. verboseNo := self newRadioButton label: 'No'.

	saveButton := self newButton
		label: 'Save';
		icon: (self iconNamed: #smallOk);
		action: [ self saveSettings ];
		yourself.
	cancelButton := self newButton
		label: 'Cancel';
		icon: (self iconNamed: #smallCancel);
		action: [ self closeWindow ];
		yourself
]

{ #category : 'initialization' }
GbsSettingsPresenter >> connectPresenters [
	self loadFromConfiguration
]

{ #category : 'layout' }
GbsSettingsPresenter >> defaultLayout [
	| libraryRow leftCol rightCol buttonRow columnsRow |
	libraryRow := SpBoxLayout newLeftToRight
		add: (self newLabel label: 'libraryName*') expand: false;
		add: libraryField;
		add: browseButton expand: false;
		spacing: 6;
		yourself.
	leftCol := SpBoxLayout newTopToBottom
		add: (self sectionTitle: 'CacheTuning') expand: false;
		add: (self yesNoRowLabel: 'bulkLoad' yes: bulkLoadYes no: bulkLoadNo) expand: false;
		add: (self textRowLabel: 'initialCacheSize' field: initialCacheSizeField) expand: false;
		add: (self textRowLabel: 'initialDirtyPoolSize' field: initialDirtyPoolField) expand: false;
		add: (self sectionTitle: 'ClassGeneration') expand: false;
		add: (self yesNoRowLabel: 'generateClassConnectors' yes: generateClassConnectorsYes no: generateClassConnectorsNo) expand: false;
		add: (self yesNoRowLabel: 'generateClientClasses' yes: generateClientClassesYes no: generateClientClassesNo) expand: false;
		add: (self yesNoRowLabel: 'generateServerClasses' yes: generateServerClassesYes no: generateServerClassesNo) expand: false;
		add: (self sectionTitle: 'Connectors') expand: false;
		add: (self yesNoRowLabel: 'connectorNilling' yes: connectorNillingYes no: connectorNillingNo) expand: false;
		add: (self yesNoRowLabel: 'connectVerification' yes: connectVerificationYes no: connectVerificationNo) expand: false;
		add: (self yesNoRowLabel: 'removeInvalidConnectors' yes: removeInvalidConnectorsYes no: removeInvalidConnectorsNo) expand: false;
		add: (self sectionTitle: 'Debugging') expand: false;
		add: (self yesNoRowLabel: 'assertionChecks' yes: assertionChecksYes no: assertionChecksNo) expand: false;
		add: (self yesNoRowLabel: 'forwarderDebugging' yes: forwarderDebuggingYes no: forwarderDebuggingNo) expand: false;
		add: (self textRowLabel: 'haltOnError' field: haltOnErrorField) expand: false;
		add: (self yesNoRowLabel: 'stubDebugging' yes: stubDebuggingYes no: stubDebuggingNo) expand: false;
		spacing: 4;
		yourself.
	rightCol := SpBoxLayout newTopToBottom
		add: (self sectionTitle: 'Replication') expand: false;
		add: (self yesNoRowLabel: 'autoMarkDirty' yes: autoMarkDirtyYes no: autoMarkDirtyNo) expand: false;
		add: (self yesNoRowLabel: 'blockReplicationEnabled' yes: blockReplicationEnabledYes no: blockReplicationEnabledNo) expand: false;
		add: (self textRowLabel: 'blockReplicationPolicy' field: blockReplicationPolicyDrop) expand: false;
		add: (self textRowLabel: 'defaultFaultPolicy' field: defaultFaultPolicyDrop) expand: false;
		add: (self textRowLabel: 'faultLevelRpc' field: faultLevelRpcField) expand: false;
		add: (self yesNoRowLabel: 'freeSlotsOnStubbing' yes: freeSlotsOnStubbingYes no: freeSlotsOnStubbingNo) expand: false;
		add: (self sectionTitle: 'ServerCommunication') expand: false;
		add: (self yesNoRowLabel: 'blockingProtocolRpc' yes: blockingProtocolRpcYes no: blockingProtocolRpcNo) expand: false;
		add: (self textRowLabel: 'delayInterruptPeriod' field: delayInterruptField) expand: false;
		add: (self yesNoRowLabel: 'fullCompression' yes: fullCompressionYes no: fullCompressionNo) expand: false;
		add: (self textRowLabel: 'traversalBufferSize' field: traversalBufferField) expand: false;
		add: (self sectionTitle: 'SignalsAndEvents') expand: false;
		add: (self textRowLabel: 'eventPollingFrequency' field: eventPollingField) expand: false;
		add: (self textRowLabel: 'eventPriority' field: eventPriorityField) expand: false;
		add: (self sectionTitle: 'UserInterface') expand: false;
		add: (self yesNoRowLabel: 'confirm' yes: confirmYes no: confirmNo) expand: false;
		add: (self yesNoRowLabel: 'verbose' yes: verboseYes no: verboseNo) expand: false;
		spacing: 4;
		yourself.
	columnsRow := SpBoxLayout newLeftToRight
		add: leftCol;
		add: rightCol;
		spacing: 16;
		yourself.
	buttonRow := SpBoxLayout newLeftToRight
		add: (self newLabel label: '');
		add: saveButton expand: false;
		add: cancelButton expand: false;
		spacing: 8;
		yourself.
	^ SpBoxLayout newTopToBottom
		add: libraryRow expand: false;
		add: columnsRow;
		add: buttonRow expand: false;
		spacing: 6;
		yourself
]

{ #category : 'layout' }
GbsSettingsPresenter >> sectionTitle: aString [
	^ self newLabel label: aString
]

{ #category : 'layout' }
GbsSettingsPresenter >> yesNoRowLabel: labelString yes: yesButton no: noButton [
	^ SpBoxLayout newLeftToRight
		add: (self newLabel label: labelString) expand: false;
		add: (self newLabel label: '') "stretch spacer to align radio columns"
			expand: true;
		add: yesButton expand: false;
		add: (self newLabel label: '   ') expand: false;
		add: noButton expand: false;
		spacing: 6;
		yourself
]

{ #category : 'layout' }
GbsSettingsPresenter >> textRowLabel: labelString field: aField [
	^ SpBoxLayout newLeftToRight
		add: (self newLabel label: labelString) expand: false;
		add: aField;
		spacing: 6;
		yourself
]

{ #category : 'initialization' }
GbsSettingsPresenter >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'GemBuilder Settings';
		initialExtent: 860 @ 660
]

{ #category : 'actions' }
GbsSettingsPresenter >> chooseLibraryPath [
	| path |
	path := UIManager default request: 'Path to libgcirpc library:' initialAnswer: (libraryField text ifNil: [ '' ]).
	path ifNotNil: [ libraryField text: path ]
]

{ #category : 'actions' }
GbsSettingsPresenter >> loadFromConfiguration [
	configuration := configuration ifNil: [ GbsConfiguration current ].
	libraryField text: (self stringValueAt: #libraryName default: '').
	initialCacheSizeField text: (self formattedIntegerValueAt: #clientMapCapacity default: 5003).
	initialDirtyPoolField text: (self stringValueAt: #initialDirtyPoolSize default: 157).
	haltOnErrorField text: (self stringValueAt: #faultLevelLnk default: -1).
	faultLevelRpcField text: (self stringValueAt: #faultLevelRpc default: 4).
	delayInterruptField text: (self stringValueAt: #socketWaitTimeout default: 10).
	traversalBufferField text: (self formattedIntegerValueAt: #traversalBufferSize default: 250000).
	eventPollingField text: (self stringValueAt: #eventPollingFrequency default: 300).
	eventPriorityField text: (self stringValueAt: #eventPriority default: 3).
	self selectDrop: blockReplicationPolicyDrop value: (self stringValueAt: #blockReplicationPolicy default: 'replicate').
	self selectDrop: defaultFaultPolicyDrop value: (self stringValueAt: #defaultFaultPolicy default: 'lazy').
	self setYesNo: { bulkLoadYes. bulkLoadNo } value: (self booleanAt: #bulkLoad default: false).
	self setYesNo: { generateClassConnectorsYes. generateClassConnectorsNo } value: (self booleanAt: #generateClassConnectors default: true).
	self setYesNo: { generateClientClassesYes. generateClientClassesNo } value: (self booleanAt: #generateClientClasses default: true).
	self setYesNo: { generateServerClassesYes. generateServerClassesNo } value: (self booleanAt: #generateServerClasses default: true).
	self setYesNo: { connectorNillingYes. connectorNillingNo } value: (self booleanAt: #connectorNilling default: true).
	self setYesNo: { connectVerificationYes. connectVerificationNo } value: (self booleanAt: #connectVerification default: true).
	self setYesNo: { removeInvalidConnectorsYes. removeInvalidConnectorsNo } value: (self booleanAt: #removeInvalidConnectors default: true).
	self setYesNo: { assertionChecksYes. assertionChecksNo } value: (self booleanAt: #assertionChecks default: false).
	self setYesNo: { forwarderDebuggingYes. forwarderDebuggingNo } value: (self booleanAt: #forwarderDebugging default: false).
	self setYesNo: { stubDebuggingYes. stubDebuggingNo } value: (self booleanAt: #stubDebugging default: false).
	self setYesNo: { autoMarkDirtyYes. autoMarkDirtyNo } value: (self booleanAt: #autoMarkDirty default: true).
	self setYesNo: { blockReplicationEnabledYes. blockReplicationEnabledNo } value: (self booleanAt: #blockReplicationEnabled default: true).
	self setYesNo: { freeSlotsOnStubbingYes. freeSlotsOnStubbingNo } value: (self booleanAt: #freeSlotsOnStubbing default: true).
	self setYesNo: { blockingProtocolRpcYes. blockingProtocolRpcNo } value: (self booleanAt: #blockingProtocolRpc default: false).
	self setYesNo: { fullCompressionYes. fullCompressionNo } value: (self booleanAt: #fullCompression default: false).
	self setYesNo: { confirmYes. confirmNo } value: (self booleanAt: #confirm default: true).
	self setYesNo: { verboseYes. verboseNo } value: (self booleanAt: #verbose default: true)
]

{ #category : 'private' }
GbsSettingsPresenter >> booleanAt: ivarName default: defaultBoolean [
	| value |
	configuration ifNil: [ ^ defaultBoolean ].
	value := configuration valueAt: ivarName ifAbsent: defaultBoolean.
	(value == true or: [ value == false ]) ifTrue: [ ^ value ].
	^ defaultBoolean
]

{ #category : 'private' }
GbsSettingsPresenter >> stringValueAt: ivarName default: defaultValue [
	| value |
	configuration ifNil: [ ^ defaultValue asString ].
	value := configuration valueAt: ivarName ifAbsent: defaultValue.
	value ifNil: [ ^ defaultValue asString ].
	^ value asString
]

{ #category : 'private' }
GbsSettingsPresenter >> formattedIntegerValueAt: ivarName default: defaultInteger [
	| raw integerValue |
	raw := configuration ifNil: [ defaultInteger ] ifNotNil: [ configuration valueAt: ivarName ifAbsent: defaultInteger ].
	raw ifNil: [ raw := defaultInteger ].
	integerValue := [ raw asInteger ] on: Error do: [ defaultInteger ].
	^ integerValue asStringWithCommas
]

{ #category : 'private' }
GbsSettingsPresenter >> setYesNo: pair value: aBoolean [
	(pair at: 1) state: aBoolean == true.
	(pair at: 2) state: aBoolean ~= true
]

{ #category : 'private' }
GbsSettingsPresenter >> selectDrop: aDropList value: aString [
	| value |
	value := aString asString.
	(aDropList respondsTo: #selectItem:)
		ifTrue: [ aDropList selectItem: value ]
		ifFalse: [
			(aDropList respondsTo: #selectedItem:)
				ifTrue: [ aDropList selectedItem: value ] ]
]

{ #category : 'private' }
GbsSettingsPresenter >> selectedDropText: aDropList default: defaultString [
	| selected |
	selected := [ aDropList selectedItem ] on: Error do: [ nil ].
	selected ifNil: [ ^ defaultString ].
	^ selected asString
]

{ #category : 'private' }
GbsSettingsPresenter >> yesNoValueFor: pair [
	^ (pair at: 1) state == true
]

{ #category : 'actions' }
GbsSettingsPresenter >> saveSettings [
	configuration ifNil: [ configuration := GbsConfiguration current ].
	configuration
		valueAt: #libraryName put: libraryField text asString;
		valueAt: #clientMapCapacity put: (self integerFromField: initialCacheSizeField default: 5003);
		valueAt: #initialDirtyPoolSize put: (self integerFromField: initialDirtyPoolField default: 157);
		valueAt: #faultLevelLnk put: (self integerFromField: haltOnErrorField default: -1);
		valueAt: #faultLevelRpc put: (self integerFromField: faultLevelRpcField default: 4);
		valueAt: #socketWaitTimeout put: (self integerFromField: delayInterruptField default: 10);
		valueAt: #traversalBufferSize put: (self integerFromField: traversalBufferField default: 250000);
		valueAt: #eventPollingFrequency put: (self integerFromField: eventPollingField default: 300);
		valueAt: #eventPriority put: (self integerFromField: eventPriorityField default: 3);
		valueAt: #blockReplicationPolicy put: (self selectedDropText: blockReplicationPolicyDrop default: 'replicate');
		valueAt: #defaultFaultPolicy put: (self selectedDropText: defaultFaultPolicyDrop default: 'lazy');
		valueAt: #bulkLoad put: (self yesNoValueFor: { bulkLoadYes. bulkLoadNo });
		valueAt: #generateClassConnectors put: (self yesNoValueFor: { generateClassConnectorsYes. generateClassConnectorsNo });
		valueAt: #generateClientClasses put: (self yesNoValueFor: { generateClientClassesYes. generateClientClassesNo });
		valueAt: #generateServerClasses put: (self yesNoValueFor: { generateServerClassesYes. generateServerClassesNo });
		valueAt: #connectorNilling put: (self yesNoValueFor: { connectorNillingYes. connectorNillingNo });
		valueAt: #connectVerification put: (self yesNoValueFor: { connectVerificationYes. connectVerificationNo });
		valueAt: #removeInvalidConnectors put: (self yesNoValueFor: { removeInvalidConnectorsYes. removeInvalidConnectorsNo });
		valueAt: #assertionChecks put: (self yesNoValueFor: { assertionChecksYes. assertionChecksNo });
		valueAt: #forwarderDebugging put: (self yesNoValueFor: { forwarderDebuggingYes. forwarderDebuggingNo });
		valueAt: #stubDebugging put: (self yesNoValueFor: { stubDebuggingYes. stubDebuggingNo });
		valueAt: #autoMarkDirty put: (self yesNoValueFor: { autoMarkDirtyYes. autoMarkDirtyNo });
		valueAt: #blockReplicationEnabled put: (self yesNoValueFor: { blockReplicationEnabledYes. blockReplicationEnabledNo });
		valueAt: #freeSlotsOnStubbing put: (self yesNoValueFor: { freeSlotsOnStubbingYes. freeSlotsOnStubbingNo });
		valueAt: #blockingProtocolRpc put: (self yesNoValueFor: { blockingProtocolRpcYes. blockingProtocolRpcNo });
		valueAt: #fullCompression put: (self yesNoValueFor: { fullCompressionYes. fullCompressionNo });
		valueAt: #confirm put: (self yesNoValueFor: { confirmYes. confirmNo });
		valueAt: #verbose put: (self yesNoValueFor: { verboseYes. verboseNo }).

	GbsConfiguration current: configuration.
	[ GbsServerInterface uniqueInstance libraryPath: (libraryField text asString) ] on: Error do: [ ].
	UIManager default inform: 'GemBuilder settings saved.'
]

{ #category : 'private' }
GbsSettingsPresenter >> integerFromField: aField default: anInteger [
	| raw |
	raw := aField text asString copyWithout: $,.
	^ [ raw asInteger ] on: Error do: [ anInteger ]
]

{ #category : 'actions' }
GbsSettingsPresenter >> closeWindow [
	self window
		ifNotNil: [ self window close ]
		ifNil: [ self delete ]
]
