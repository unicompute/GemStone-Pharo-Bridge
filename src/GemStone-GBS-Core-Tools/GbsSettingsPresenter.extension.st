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
	(#(asyncSignalPollingEnabled freeOopAllocationBatchSize freeOopBatchSize nativeStoreTraversalShapeValidationEnabled serverMapMode storeDirtyOnCommit storeTraversalTransport strictMutationProtectionEnabled) includes: ivarName) ifTrue: [
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
GbsSettingsPresenter >> bridgeSetConfigurationValueAt: aKey put: aValue [
	| setter |
	configuration ifNil: [ configuration := GbsConfiguration current ].
	(#(asyncSignalPollingEnabled freeOopAllocationBatchSize freeOopBatchSize nativeStoreTraversalShapeValidationEnabled serverMapMode storeDirtyOnCommit storeTraversalTransport strictMutationProtectionEnabled) includes: aKey) ifTrue: [
		setter := (aKey asString, ':') asSymbol.
		^ configuration perform: setter with: aValue ].
	^ configuration valueAt: aKey put: aValue
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
		add: (self yesNoRowLabel: 'strictMutationProtection'
			yes: (self bridgeControlAt: #strictMutationProtectionEnabledYes)
			no: (self bridgeControlAt: #strictMutationProtectionEnabledNo)) expand: false;
		add: (self yesNoRowLabel: 'blockReplicationEnabled' yes: blockReplicationEnabledYes no: blockReplicationEnabledNo) expand: false;
		add: (self textRowLabel: 'blockReplicationPolicy' field: blockReplicationPolicyDrop) expand: false;
		add: (self textRowLabel: 'defaultFaultPolicy' field: defaultFaultPolicyDrop) expand: false;
		add: (self textRowLabel: 'faultLevelRpc' field: faultLevelRpcField) expand: false;
		add: (self yesNoRowLabel: 'freeSlotsOnStubbing' yes: freeSlotsOnStubbingYes no: freeSlotsOnStubbingNo) expand: false;
		add: (self yesNoRowLabel: 'storeDirtyOnCommit'
			yes: (self bridgeControlAt: #storeDirtyOnCommitYes)
			no: (self bridgeControlAt: #storeDirtyOnCommitNo)) expand: false;
		add: (self textRowLabel: 'storeTraversalTransport' field: (self bridgeControlAt: #storeTraversalTransportDrop)) expand: false;
		add: (self yesNoRowLabel: 'nativeStoreTraversalShapeValidation'
			yes: (self bridgeControlAt: #nativeStoreTraversalShapeValidationEnabledYes)
			no: (self bridgeControlAt: #nativeStoreTraversalShapeValidationEnabledNo)) expand: false;
		add: (self textRowLabel: 'serverMapMode' field: (self bridgeControlAt: #serverMapModeDrop)) expand: false;
		add: (self textRowLabel: 'freeOopAllocationBatchSize' field: (self bridgeControlAt: #freeOopAllocationBatchSizeField)) expand: false;
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
	blockReplicationPolicyDrop items: (GbsReplicationPolicy legalValuesForSetting: #blockReplicationPolicy).
	defaultFaultPolicyDrop items: (GbsReplicationPolicy legalValuesForSetting: #defaultFaultPolicy).
	self bridgeControlAt: #freeOopBatchSizeField put: self newTextInput.
	self bridgeControlAt: #freeOopAllocationBatchSizeField put: self newTextInput.
	self bridgeControlAt: #storeDirtyOnCommitYes put: (self newRadioButton label: 'Yes').
	self bridgeControlAt: #storeDirtyOnCommitNo put: (self newRadioButton label: 'No').
	self bridgeControlAt: #strictMutationProtectionEnabledYes put: (self newRadioButton label: 'Yes').
	self bridgeControlAt: #strictMutationProtectionEnabledNo put: (self newRadioButton label: 'No').
	self bridgeControlAt: #nativeStoreTraversalShapeValidationEnabledYes put: (self newRadioButton label: 'Yes').
	self bridgeControlAt: #nativeStoreTraversalShapeValidationEnabledNo put: (self newRadioButton label: 'No').
	self bridgeControlAt: #storeTraversalTransportDrop put: self newDropList.
	self bridgeControlAt: #serverMapModeDrop put: self newDropList.
	(self bridgeControlAt: #storeTraversalTransportDrop) items: (GbsReplicationPolicy legalValuesForSetting: #storeTraversalTransport).
	(self bridgeControlAt: #serverMapModeDrop) items: (GbsReplicationPolicy legalValuesForSetting: #serverMapMode).

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
	(self bridgeControlAt: #freeOopAllocationBatchSizeField) text: (self bridgeStringValueAt: #freeOopAllocationBatchSize default: 2000).
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
	self setYesNo: { (self bridgeControlAt: #strictMutationProtectionEnabledYes). (self bridgeControlAt: #strictMutationProtectionEnabledNo) }
		value: (self bridgeBooleanAt: #strictMutationProtectionEnabled default: false).
	self setYesNo: { blockReplicationEnabledYes. blockReplicationEnabledNo } value: (self bridgeBooleanAt: #blockReplicationEnabled default: true).
	self setYesNo: { freeSlotsOnStubbingYes. freeSlotsOnStubbingNo } value: (self bridgeBooleanAt: #freeSlotsOnStubbing default: true).
	self setYesNo: { (self bridgeControlAt: #storeDirtyOnCommitYes). (self bridgeControlAt: #storeDirtyOnCommitNo) }
		value: (self bridgeBooleanAt: #storeDirtyOnCommit default: false).
	self setYesNo: { (self bridgeControlAt: #nativeStoreTraversalShapeValidationEnabledYes). (self bridgeControlAt: #nativeStoreTraversalShapeValidationEnabledNo) }
		value: (self bridgeBooleanAt: #nativeStoreTraversalShapeValidationEnabled default: true).
	self setYesNo: { (self bridgeControlAt: #asyncSignalPollingEnabledYes). (self bridgeControlAt: #asyncSignalPollingEnabledNo) }
		value: (self bridgeBooleanAt: #asyncSignalPollingEnabled default: false).
	self setYesNo: { blockingProtocolRpcYes. blockingProtocolRpcNo } value: (self bridgeBooleanAt: #blockingProtocolRpc default: false).
	self setYesNo: { fullCompressionYes. fullCompressionNo } value: (self bridgeBooleanAt: #fullCompression default: false).
	self setYesNo: { confirmYes. confirmNo } value: (self bridgeBooleanAt: #confirm default: true).
	self setYesNo: { verboseYes. verboseNo } value: (self bridgeBooleanAt: #verbose default: true)
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSettingsPresenter >> integerFromField: aField default: anInteger label: labelString minimum: minimumInteger messages: messages [
	| raw value |
	raw := (aField text ifNil: [ '' ]) asString copyWithout: $,.
	raw := raw trimBoth.
	raw isEmpty ifTrue: [ ^ anInteger ].
	value := [ raw asInteger ] on: Error do: [
		messages add: labelString, ' must be an integer.'.
		^ anInteger ].
	value ifNil: [
		messages add: labelString, ' must be an integer.'.
		^ anInteger ].
	value < minimumInteger ifTrue: [
		messages add: labelString, ' must be at least ', minimumInteger asString, '.' ].
	^ value
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSettingsPresenter >> saveSettings [
	| validationMessage |
	configuration ifNil: [ configuration := GbsConfiguration current ].
	validationMessage := self validationErrorMessage.
	validationMessage ifNotNil: [
		UIManager default inform: validationMessage.
		^ false ].
	self updateConfigurationFromPresenters.

	GbsConfiguration current: configuration.
	[ GbsServerInterface uniqueInstance libraryPath: (libraryField text asString) ] on: Error do: [ ].
	UIManager default inform: 'GemBuilder settings saved.'.
	self closeWindow.
	^ true
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSettingsPresenter >> updateConfigurationFromPresenters [
	configuration ifNil: [ configuration := GbsConfiguration current ].
	self
		bridgeSetConfigurationValueAt: #libraryName put: libraryField text asString;
		bridgeSetConfigurationValueAt: #clientMapCapacity put: (self integerFromField: initialCacheSizeField default: 5003);
		bridgeSetConfigurationValueAt: #initialDirtyPoolSize put: (self integerFromField: initialDirtyPoolField default: 157);
		bridgeSetConfigurationValueAt: #faultLevelLnk put: (self integerFromField: haltOnErrorField default: -1);
		bridgeSetConfigurationValueAt: #faultLevelRpc put: (self integerFromField: faultLevelRpcField default: 4);
		bridgeSetConfigurationValueAt: #socketWaitTimeout put: (self integerFromField: delayInterruptField default: 10);
		bridgeSetConfigurationValueAt: #traversalBufferSize put: (self integerFromField: traversalBufferField default: 250000);
		bridgeSetConfigurationValueAt: #freeOopAllocationBatchSize put: (self integerFromField: (self bridgeControlAt: #freeOopAllocationBatchSizeField) default: 2000);
		bridgeSetConfigurationValueAt: #freeOopBatchSize put: (self integerFromField: (self bridgeControlAt: #freeOopBatchSizeField) default: 256);
		bridgeSetConfigurationValueAt: #eventPollingFrequency put: (self integerFromField: eventPollingField default: 300);
		bridgeSetConfigurationValueAt: #eventPriority put: (self integerFromField: eventPriorityField default: 3);
		bridgeSetConfigurationValueAt: #blockReplicationPolicy put: (self selectedDropText: blockReplicationPolicyDrop default: 'replicate');
		bridgeSetConfigurationValueAt: #defaultFaultPolicy put: (self selectedDropText: defaultFaultPolicyDrop default: 'lazy');
		bridgeSetConfigurationValueAt: #serverMapMode put: (self selectedDropText: (self bridgeControlAt: #serverMapModeDrop) default: 'weak');
		bridgeSetConfigurationValueAt: #storeTraversalTransport put: (self selectedDropText: (self bridgeControlAt: #storeTraversalTransportDrop) default: 'script');
		bridgeSetConfigurationValueAt: #bulkLoad put: (self yesNoValueFor: { bulkLoadYes. bulkLoadNo });
		bridgeSetConfigurationValueAt: #generateClassConnectors put: (self yesNoValueFor: { generateClassConnectorsYes. generateClassConnectorsNo });
		bridgeSetConfigurationValueAt: #generateClientClasses put: (self yesNoValueFor: { generateClientClassesYes. generateClientClassesNo });
		bridgeSetConfigurationValueAt: #generateServerClasses put: (self yesNoValueFor: { generateServerClassesYes. generateServerClassesNo });
		bridgeSetConfigurationValueAt: #connectorNilling put: (self yesNoValueFor: { connectorNillingYes. connectorNillingNo });
		bridgeSetConfigurationValueAt: #connectVerification put: (self yesNoValueFor: { connectVerificationYes. connectVerificationNo });
		bridgeSetConfigurationValueAt: #removeInvalidConnectors put: (self yesNoValueFor: { removeInvalidConnectorsYes. removeInvalidConnectorsNo });
		bridgeSetConfigurationValueAt: #assertionChecks put: (self yesNoValueFor: { assertionChecksYes. assertionChecksNo });
		bridgeSetConfigurationValueAt: #forwarderDebugging put: (self yesNoValueFor: { forwarderDebuggingYes. forwarderDebuggingNo });
		bridgeSetConfigurationValueAt: #stubDebugging put: (self yesNoValueFor: { stubDebuggingYes. stubDebuggingNo });
		bridgeSetConfigurationValueAt: #autoMarkDirty put: (self yesNoValueFor: { autoMarkDirtyYes. autoMarkDirtyNo });
		bridgeSetConfigurationValueAt: #strictMutationProtectionEnabled put: (self yesNoValueFor: { (self bridgeControlAt: #strictMutationProtectionEnabledYes). (self bridgeControlAt: #strictMutationProtectionEnabledNo) });
		bridgeSetConfigurationValueAt: #blockReplicationEnabled put: (self yesNoValueFor: { blockReplicationEnabledYes. blockReplicationEnabledNo });
		bridgeSetConfigurationValueAt: #storeDirtyOnCommit put: (self yesNoValueFor: { (self bridgeControlAt: #storeDirtyOnCommitYes). (self bridgeControlAt: #storeDirtyOnCommitNo) });
		bridgeSetConfigurationValueAt: #nativeStoreTraversalShapeValidationEnabled put: (self yesNoValueFor: { (self bridgeControlAt: #nativeStoreTraversalShapeValidationEnabledYes). (self bridgeControlAt: #nativeStoreTraversalShapeValidationEnabledNo) });
		bridgeSetConfigurationValueAt: #asyncSignalPollingEnabled put: (self yesNoValueFor: { (self bridgeControlAt: #asyncSignalPollingEnabledYes). (self bridgeControlAt: #asyncSignalPollingEnabledNo) });
		bridgeSetConfigurationValueAt: #freeSlotsOnStubbing put: (self yesNoValueFor: { freeSlotsOnStubbingYes. freeSlotsOnStubbingNo });
		bridgeSetConfigurationValueAt: #blockingProtocolRpc put: (self yesNoValueFor: { blockingProtocolRpcYes. blockingProtocolRpcNo });
		bridgeSetConfigurationValueAt: #fullCompression put: (self yesNoValueFor: { fullCompressionYes. fullCompressionNo });
		bridgeSetConfigurationValueAt: #confirm put: (self yesNoValueFor: { confirmYes. confirmNo });
		bridgeSetConfigurationValueAt: #verbose put: (self yesNoValueFor: { verboseYes. verboseNo }).
	^ configuration
]

{ #category : '*GemStone-GBS-Core-Tools' }
GbsSettingsPresenter >> validationErrorMessage [
	| messages policy |
	messages := OrderedCollection new.
	self integerFromField: initialCacheSizeField default: 5003 label: 'clientMapCapacity' minimum: 1 messages: messages.
	self integerFromField: initialDirtyPoolField default: 157 label: 'initialDirtyPoolSize' minimum: 0 messages: messages.
	self integerFromField: haltOnErrorField default: -1 label: 'haltOnError' minimum: -1 messages: messages.
	self integerFromField: faultLevelRpcField default: 4 label: 'faultLevelRpc' minimum: -1 messages: messages.
	self integerFromField: delayInterruptField default: 10 label: 'delayInterruptPeriod' minimum: 0 messages: messages.
	self integerFromField: traversalBufferField default: 250000 label: 'traversalBufferSize' minimum: 1 messages: messages.
	self integerFromField: (self bridgeControlAt: #freeOopAllocationBatchSizeField) default: 2000 label: 'freeOopAllocationBatchSize' minimum: 1 messages: messages.
	self integerFromField: (self bridgeControlAt: #freeOopBatchSizeField) default: 256 label: 'freeOopBatchSize' minimum: 0 messages: messages.
	self integerFromField: eventPollingField default: 300 label: 'eventPollingFrequency' minimum: 0 messages: messages.
	self integerFromField: eventPriorityField default: 3 label: 'eventPriority' minimum: 0 messages: messages.
	policy := GbsReplicationPolicy default.
	[ policy blockReplicationPolicy: (self selectedDropText: blockReplicationPolicyDrop default: 'replicate') ]
		on: Error do: [ :ex | messages add: ex messageText ].
	[ policy defaultFaultPolicy: (self selectedDropText: defaultFaultPolicyDrop default: 'lazy') ]
		on: Error do: [ :ex | messages add: ex messageText ].
	[ policy serverMapMode: (self selectedDropText: (self bridgeControlAt: #serverMapModeDrop) default: 'weak') ]
		on: Error do: [ :ex | messages add: ex messageText ].
	[ policy storeTraversalTransport: (self selectedDropText: (self bridgeControlAt: #storeTraversalTransportDrop) default: 'script') ]
		on: Error do: [ :ex | messages add: ex messageText ].
	messages isEmpty ifTrue: [ ^ nil ].
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Cannot save GemBuilder settings:'; cr.
		messages do: [ :message |
			stream nextPutAll: '- '; nextPutAll: message; cr ] ]
]
