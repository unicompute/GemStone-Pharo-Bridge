Extension { #name : 'GbsSettingsPresenter' }

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSettingsPresenter class >> bridgeStateRegistry [
	| registry |
	registry := Smalltalk globals at: #GbsSettingsPresenterBridgeState ifAbsent: [ nil ].
	registry ifNil: [
		| registryClass |
		registryClass := Smalltalk globals at: #WeakIdentityKeyDictionary ifAbsent: [ IdentityDictionary ].
		registry := registryClass new.
		Smalltalk globals at: #GbsSettingsPresenterBridgeState put: registry ].
	^ registry
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSettingsPresenter >> bridgeBooleanAt: ivarName default: defaultBoolean [
	| value |
	value := self bridgeConfigurationValueAt: ivarName default: defaultBoolean.
	(value == true or: [ value == false ]) ifTrue: [ ^ value ].
	^ defaultBoolean
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSettingsPresenter >> bridgeConfigurationValueAt: ivarName default: defaultValue [
	configuration ifNil: [ ^ defaultValue ].
	(configuration respondsTo: ivarName) ifTrue: [
		^ [ configuration perform: ivarName ] on: Error do: [ defaultValue ] ].
	^ configuration valueAt: ivarName ifAbsent: defaultValue
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSettingsPresenter >> bridgeControlAt: aSymbol [
	^ self bridgeState at: aSymbol
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSettingsPresenter >> bridgeControlAt: aSymbol put: aPresenter [
	self bridgeState at: aSymbol put: aPresenter.
	^ aPresenter
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSettingsPresenter >> bridgeFormattedIntegerValueAt: ivarName default: defaultInteger [
	| raw integerValue |
	raw := self bridgeConfigurationValueAt: ivarName default: defaultInteger.
	raw ifNil: [ raw := defaultInteger ].
	integerValue := [ raw asInteger ] on: Error do: [ defaultInteger ].
	^ integerValue asStringWithCommas
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSettingsPresenter >> bridgeState [
	^ self class bridgeStateRegistry
		at: self
		ifAbsentPut: [ IdentityDictionary new ]
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSettingsPresenter >> bridgeStringValueAt: ivarName default: defaultValue [
	| value |
	value := self bridgeConfigurationValueAt: ivarName default: defaultValue.
	value ifNil: [ ^ defaultValue asString ].
	^ value asString
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSettingsPresenter >> defaultLayout [
	| libraryRow leftCol rightCol buttonRow columnsRow |
	libraryRow := SpBoxLayout newLeftToRight
		add: (self newLabel label: 'libraryName*') expand: false;
		add: libraryField width: 500;
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
		add: (self textRowLabel: 'storeTraversalTransport' field: (self bridgeControlAt: #storeTraversalTransportDrop)) expand: false;
		add: (self textRowLabel: 'serverMapMode' field: (self bridgeControlAt: #serverMapModeDrop)) expand: false;
		add: (self textRowLabel: 'freeOopBatchSize' field: (self bridgeControlAt: #freeOopBatchSizeField)) expand: false;
		add: (self sectionTitle: 'ServerCommunication') expand: false;
		add: (self yesNoRowLabel: 'blockingProtocolRpc' yes: blockingProtocolRpcYes no: blockingProtocolRpcNo) expand: false;
		add: (self textRowLabel: 'delayInterruptPeriod' field: delayInterruptField) expand: false;
		add: (self yesNoRowLabel: 'fullCompression' yes: fullCompressionYes no: fullCompressionNo) expand: false;
		add: (self textRowLabel: 'traversalBufferSize' field: traversalBufferField) expand: false;
		add: (self sectionTitle: 'SignalsAndEvents') expand: false;
		add: (self yesNoRowLabel: 'asyncSignalPollingEnabled'
			yes: (self bridgeControlAt: #asyncSignalPollingEnabledYes)
			no: (self bridgeControlAt: #asyncSignalPollingEnabledNo)) expand: false;
		add: (self textRowLabel: 'eventPollingFrequency' field: eventPollingField) expand: false;
		add: (self textRowLabel: 'eventPriority' field: eventPriorityField) expand: false;
		add: (self sectionTitle: 'UserInterface') expand: false;
		add: (self yesNoRowLabel: 'confirm' yes: confirmYes no: confirmNo) expand: false;
		add: (self yesNoRowLabel: 'verbose' yes: verboseYes no: verboseNo) expand: false;
		spacing: 4;
		yourself.
	columnsRow := SpBoxLayout newLeftToRight
		add: leftCol width: 430;
		add: rightCol;
		spacing: 10;
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

{ #category : '*GemStone-GBS-Core-Tools' }
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
	self bridgeControlAt: #freeOopBatchSizeField put: self newTextInput.
	self bridgeControlAt: #storeTraversalTransportDrop put: self newDropList.
	self bridgeControlAt: #serverMapModeDrop put: self newDropList.
	(self bridgeControlAt: #storeTraversalTransportDrop) items: #( 'script' 'binary' 'binaryRequired' ).
	(self bridgeControlAt: #serverMapModeDrop) items: #( 'weak' 'strong' ).

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
	self bridgeControlAt: #asyncSignalPollingEnabledYes put: (self newRadioButton label: 'Yes').
	self bridgeControlAt: #asyncSignalPollingEnabledNo put: (self newRadioButton label: 'No').
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

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSettingsPresenter >> loadFromConfiguration [
	| resolvedLibrary |
	configuration := configuration ifNil: [ GbsConfiguration current ].
	resolvedLibrary := self currentLibraryPathCandidate.
	libraryField text: resolvedLibrary.
	initialCacheSizeField text: (self bridgeFormattedIntegerValueAt: #clientMapCapacity default: 5003).
	initialDirtyPoolField text: (self bridgeStringValueAt: #initialDirtyPoolSize default: 157).
	haltOnErrorField text: (self bridgeStringValueAt: #faultLevelLnk default: -1).
	faultLevelRpcField text: (self bridgeStringValueAt: #faultLevelRpc default: 4).
	delayInterruptField text: (self bridgeStringValueAt: #socketWaitTimeout default: 10).
	traversalBufferField text: (self bridgeFormattedIntegerValueAt: #traversalBufferSize default: 250000).
	eventPollingField text: (self bridgeStringValueAt: #eventPollingFrequency default: 300).
	eventPriorityField text: (self bridgeStringValueAt: #eventPriority default: 3).
	(self bridgeControlAt: #freeOopBatchSizeField) text: (self bridgeStringValueAt: #freeOopBatchSize default: 256).
	self selectDrop: blockReplicationPolicyDrop value: (self bridgeStringValueAt: #blockReplicationPolicy default: 'replicate').
	self selectDrop: defaultFaultPolicyDrop value: (self bridgeStringValueAt: #defaultFaultPolicy default: 'lazy').
	self selectDrop: (self bridgeControlAt: #storeTraversalTransportDrop) value: (self bridgeStringValueAt: #storeTraversalTransport default: 'script').
	self selectDrop: (self bridgeControlAt: #serverMapModeDrop) value: (self bridgeStringValueAt: #serverMapMode default: 'weak').
	self setYesNo: { bulkLoadYes. bulkLoadNo } value: (self bridgeBooleanAt: #bulkLoad default: false).
	self setYesNo: { generateClassConnectorsYes. generateClassConnectorsNo } value: (self bridgeBooleanAt: #generateClassConnectors default: true).
	self setYesNo: { generateClientClassesYes. generateClientClassesNo } value: (self bridgeBooleanAt: #generateClientClasses default: true).
	self setYesNo: { generateServerClassesYes. generateServerClassesNo } value: (self bridgeBooleanAt: #generateServerClasses default: true).
	self setYesNo: { connectorNillingYes. connectorNillingNo } value: (self bridgeBooleanAt: #connectorNilling default: true).
	self setYesNo: { connectVerificationYes. connectVerificationNo } value: (self bridgeBooleanAt: #connectVerification default: true).
	self setYesNo: { removeInvalidConnectorsYes. removeInvalidConnectorsNo } value: (self bridgeBooleanAt: #removeInvalidConnectors default: true).
	self setYesNo: { assertionChecksYes. assertionChecksNo } value: (self bridgeBooleanAt: #assertionChecks default: false).
	self setYesNo: { forwarderDebuggingYes. forwarderDebuggingNo } value: (self bridgeBooleanAt: #forwarderDebugging default: false).
	self setYesNo: { stubDebuggingYes. stubDebuggingNo } value: (self bridgeBooleanAt: #stubDebugging default: false).
	self setYesNo: { autoMarkDirtyYes. autoMarkDirtyNo } value: (self bridgeBooleanAt: #autoMarkDirty default: true).
	self setYesNo: { blockReplicationEnabledYes. blockReplicationEnabledNo } value: (self bridgeBooleanAt: #blockReplicationEnabled default: true).
	self setYesNo: { freeSlotsOnStubbingYes. freeSlotsOnStubbingNo } value: (self bridgeBooleanAt: #freeSlotsOnStubbing default: true).
	self setYesNo: { (self bridgeControlAt: #asyncSignalPollingEnabledYes). (self bridgeControlAt: #asyncSignalPollingEnabledNo) }
		value: (self bridgeBooleanAt: #asyncSignalPollingEnabled default: false).
	self setYesNo: { blockingProtocolRpcYes. blockingProtocolRpcNo } value: (self bridgeBooleanAt: #blockingProtocolRpc default: false).
	self setYesNo: { fullCompressionYes. fullCompressionNo } value: (self bridgeBooleanAt: #fullCompression default: false).
	self setYesNo: { confirmYes. confirmNo } value: (self bridgeBooleanAt: #confirm default: true).
	self setYesNo: { verboseYes. verboseNo } value: (self bridgeBooleanAt: #verbose default: true)
]

{ #category : '*GemStone-GBS-Core-Tools' }
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
		freeOopBatchSize: (self integerFromField: (self bridgeControlAt: #freeOopBatchSizeField) default: 256);
		valueAt: #blockReplicationPolicy put: (self selectedDropText: blockReplicationPolicyDrop default: 'replicate');
		valueAt: #defaultFaultPolicy put: (self selectedDropText: defaultFaultPolicyDrop default: 'lazy');
		storeTraversalTransport: (self selectedDropText: (self bridgeControlAt: #storeTraversalTransportDrop) default: 'script');
		serverMapMode: (self selectedDropText: (self bridgeControlAt: #serverMapModeDrop) default: 'weak');
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
		asyncSignalPollingEnabled: (self yesNoValueFor: { (self bridgeControlAt: #asyncSignalPollingEnabledYes). (self bridgeControlAt: #asyncSignalPollingEnabledNo) });
		valueAt: #blockingProtocolRpc put: (self yesNoValueFor: { blockingProtocolRpcYes. blockingProtocolRpcNo });
		valueAt: #fullCompression put: (self yesNoValueFor: { fullCompressionYes. fullCompressionNo });
		valueAt: #confirm put: (self yesNoValueFor: { confirmYes. confirmNo });
		valueAt: #verbose put: (self yesNoValueFor: { verboseYes. verboseNo }).

	GbsConfiguration current: configuration.
	[ GbsServerInterface uniqueInstance libraryPath: (libraryField text asString) ] on: Error do: [ ].
	UIManager default inform: 'GemBuilder settings saved.'.
	self closeWindow
]
