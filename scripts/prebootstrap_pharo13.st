[
	Smalltalk at: #TwoByteString put: WideString.
	Smalltalk at: #FourByteString put: WideString.
	Smalltalk at: #Unicode16 put: WideString.
	Smalltalk at: #Unicode32 put: WideString.

	(Smalltalk at: #CannotReturn ifAbsent: [ nil ]) ifNotNil: [ :existing |
		((existing allInstVarNames includes: 'result') not)
			ifTrue: [ existing removeFromSystem ] ].

	(Smalltalk at: #GbsServerInterface ifAbsent: [ nil ]) ifNotNil: [ :existing |
		(((existing allInstVarNames includes: 'libraryPath') not)
			or: [ (existing class allInstVarNames includes: 'UniqueInstance') not ])
			ifTrue: [ existing removeFromSystem ] ].

	(Smalltalk at: #GbsSession ifAbsent: [ nil ]) ifNotNil: [ :existing |
		((((existing allInstVarNames includes: 'serverInterface') not)
			or: [ (existing allInstVarNames includes: 'sessionId') not ]))
			ifTrue: [ existing removeFromSystem ] ].

	(Smalltalk at: #GbxServerInterface ifAbsent: [ nil ]) ifNotNil: [ :existing |
		((existing allInstVarNames includes: 'callSequencer') not)
			ifTrue: [ existing removeFromSystem ] ].

	(Smalltalk includesKey: #CannotReturn) ifFalse: [
		Smalltalk classInstaller make: [ :builder |
			builder
				superclass: Error;
				name: #CannotReturn;
				slots: #(result);
				sharedVariables: #();
				package: 'GemStone-GBS-Converted' ] ].

	(Smalltalk includesKey: #GbsServerInterface) ifFalse: [
		Smalltalk classInstaller make: [ :builder |
			builder
				superclass: Object;
				name: #GbsServerInterface;
				slots: #(libraryPath);
				classSlots: #(UniqueInstance);
				sharedVariables: #();
				package: 'GemStone-GBS-Converted' ] ].

	(Smalltalk includesKey: #GbsSession) ifFalse: [
		Smalltalk classInstaller make: [ :builder |
			builder
				superclass: Object;
				name: #GbsSession;
				slots: #(serverInterface sessionId);
				sharedVariables: #();
				package: 'GemStone-GBS-Converted' ] ].

	#(GbsWorkspace GbsRemoteTranscript GbsSessionParametersEditor GbsX509ParametersEditor GbsLauncher) do: [ :className |
		(Smalltalk includesKey: className) ifFalse: [
			Smalltalk classInstaller make: [ :builder |
				builder
					superclass: SpPresenter;
					name: className;
					slots: #();
					sharedVariables: #();
					package: 'GemStone-GBS-Tools' ] ] ].

	(Smalltalk includesKey: #GbxServerInterface) ifFalse: [
		Smalltalk classInstaller make: [ :builder |
			builder
				superclass: Object;
				name: #GbxServerInterface;
				slots: #(alteredOopBuffer byteFetchBuffer callSequencer clampedTravArgsBuffer dirtyOopBuffer eventDetector gcedOopBuffer longHolderBuffer longHolderBuffer2 needMoreTraversal oopFetchBuffer oopsNoLongerReplicatedBuffer singleStepIsRequested storeTravDoArgsBuffer noLongerReplicatedOops thisSession traversalBufferManager);
				sharedVariables: #();
				package: 'GemStone-GBS-Converted' ] ].

	{
		#(#ContextEmergencyError #Error 'Kernel-Exceptions').
		#(#GbxAbstractException #Object 'GemStone-GBS-Converted').
		#(#GbxAbstractContextEmergencyError #GbxAbstractException 'GemStone-GBS-Converted').
		#(#GbxAbstractControlInterrupt #GbxAbstractException 'GemStone-GBS-Converted').
		#(#ControlInterrupt #Notification 'Kernel-Exceptions').
		#(#ImproperOperation #Error 'Kernel-Exceptions').
		#(#OutOfRange #Error 'GemStone-GBS-Converted').
		#(#SettingsManagerPage #Object 'GemStone-GBS-Converted').
		#(#ArrayInspector #Object 'GemStone-GBS-Converted').
		#(#DictionaryInspector #Object 'GemStone-GBS-Converted').
		#(#SetInspector #Object 'GemStone-GBS-Converted').
		#(#BasicInspector #Object 'GemStone-GBS-Converted').
		#(#GbsException #Error 'GemStone-GBS-Converted').
		#(#GbsError #Error 'GemStone-GBS-Converted').
		#(#GbsInterfaceError #GbsError 'GemStone-GBS-Converted').
		#(#GbsGemStoneError #GbsError 'GemStone-GBS-Converted').
		#(#GbsAbortingError #GbsGemStoneError 'GemStone-GBS-Converted').
		#(#GbsInterpreterError #GbsGemStoneError 'GemStone-GBS-Converted').
		#(#GbsFatalError #GbsGemStoneError 'GemStone-GBS-Converted').
		#(#MessageNotUnderstood #MessageNotUnderstood 'GemStone-GBS-Converted').
		#(#GbsMessageNotUnderstood #MessageNotUnderstood 'GemStone-GBS-Converted').
		#(#ZeroDivide #ZeroDivide 'GemStone-GBS-Converted').
		#(#GbsZeroDivide #ZeroDivide 'GemStone-GBS-Converted').
		#(#GbxHashTableSegment #Object 'GemStone-GBS-Converted').
		#(#GbxOopKeyedDictionary #Object 'GemStone-GBS-Converted').
		#(#GbxOopKeyedNode #Object 'GemStone-GBS-Converted').
		#(#GbxBehaviorOopMapNode #Object 'GemStone-GBS-Converted').
		#(#GbsConfiguration #Object 'GemStone-GBS-Converted').
		#(#GbsConnector #Object 'GemStone-GBS-Converted').
		#(#GbsNameConnector #GbsConnector 'GemStone-GBS-Converted').
		#(#GbsClassConnector #GbsNameConnector 'GemStone-GBS-Converted').
		#(#GbsClassVarConnector #Object 'GemStone-GBS-Converted').
		#(#GbsConnectorGroup #Object 'GemStone-GBS-Converted').
		#(#GbsSession #Object 'GemStone-GBS-Converted').
		#(#GbxSessionSpecification #Object 'GemStone-GBS-Converted').
		#(#GbsSessionParameters #GbxSessionSpecification 'GemStone-GBS-Converted').
		#(#GbsServerInterface #Object 'GemStone-GBS-Converted').
		#(#GciErrSType #FFIExternalObject 'GemStone-GBS-Converted').
		#(#WriteStreamPortable #Object 'GemStone-GBS-Converted').
		#(#GbxGciCallSequencer #Object 'GemStone-GBS-Converted').
		#(#GbxTimeZoneInfo #Object 'GemStone-GBS-Converted').
		#(#GbxB8OopArray #Object 'GemStone-GBS-Converted').
		#(#GbxB8BufferOop #Object 'GemStone-GBS-Converted').
		#(#GbxBufferOop #Object 'GemStone-GBS-Converted').
		#(#GbxStatAdaptor #Object 'GemStone-GBS-Converted').
		#(#GbxCollectionCache #Object 'GemStone-GBS-Converted').
		#(#GbxStatResource #Object 'GemStone-GBS-Converted').
		#(#GbxSessionStatResource #GbxStatResource 'GemStone-GBS-Converted').
		#(#GbxSessionManagerStatResource #GbxStatResource 'GemStone-GBS-Converted').
		#(#GbxObjectMemoryStatResource #GbxStatResource 'GemStone-GBS-Converted').
		#(#GbxObjectReport #Object 'GemStone-GBS-Converted').
		#(#Gbx8ObjectReport #GbxObjectReport 'GemStone-GBS-Converted').
		#(#Gbx8v3ObjectReport #Gbx8ObjectReport 'GemStone-GBS-Converted').
		#(#GbxB8v3ObjectReport #Gbx8v3ObjectReport 'GemStone-GBS-Converted').
		#(#GbxServerCallResult #Object 'GemStone-GBS-Converted').
		#(#GbxObjectWithDeferredAssignments #Object 'GemStone-GBS-Converted').
		#(#GbxAbstractReplicationScheme #Object 'GemStone-GBS-Converted').
		#(#GbxReplicator #Object 'GemStone-GBS-Converted').
		#(#GbxObjectReplicator #GbxReplicator 'GemStone-GBS-Converted').
		#(#GbxPointerObjectReplicator #GbxObjectReplicator 'GemStone-GBS-Converted').
		#(#GbxByteObjectReplicator #GbxObjectReplicator 'GemStone-GBS-Converted').
		#(#GbxForwarderReplicator #GbxPointerObjectReplicator 'GemStone-GBS-Converted').
		#(#GbxClassReplicator #GbxPointerObjectReplicator 'GemStone-GBS-Converted').
		#(#GbxMultiByteStringReplicator #GbxByteObjectReplicator 'GemStone-GBS-Converted').
		#(#GbxSymbolAssociationReplicator #GbxPointerObjectReplicator 'GemStone-GBS-Converted').
		#(#OverrideFailureWarning #Error 'GemStone-GBS-Converted').
		#(#RedefinitionNotification #Notification 'GemStone-GBS-Converted').
		#(#GbxDateAndTimeANSI #Object 'GemStone-GBS-Converted').
		#(#GbsServerClass #Object 'GemStone-GBS-Converted').
		#(#GbxOopArray64 #Object 'GemStone-GBS-Converted').
		#(#GbsSessionManager #Object 'GemStone-GBS-Converted').
		#(#GbxApplicationModel #Object 'GemStone-GBS-Converted').
		#(#GbxBrain #Object 'GemStone-GBS-Converted').
		#(#GbxAdminToolsBrain #GbxBrain 'GemStone-GBS-Converted').
		#(#GbxDbaToolsSupport #GbxApplicationModel 'GemStone-GBS-Converted').
		#(#GbxDbaBrain #GbxAdminToolsBrain 'GemStone-GBS-Converted').
		#(#GbxDbaUserBrain #GbxDbaBrain 'GemStone-GBS-Converted').
		#(#GbxConnectorBrowser #GbxDbaToolsSupport 'GemStone-GBS-Converted').
		#(#GbxDbaUserBrowser #GbxDbaToolsSupport 'GemStone-GBS-Converted').
		#(#GbxDelegate #Object 'GemStone-GBS-Converted').
		#(#CstMessageDispatcher #Object 'GemStone-GBS-Converted').
		#(#CstMessageHandler #Object 'GemStone-GBS-Converted').
		#(#CstMessageHandlerVa #CstMessageHandler 'GemStone-GBS-Converted').
		#(#CstMessageHandlerVw #CstMessageHandler 'GemStone-GBS-Converted').
		#(#GbxMessageDispatcher #CstMessageDispatcher 'GemStone-GBS-Converted').
		#(#GbxAbstractProxy #Object 'GemStone-GBS-Converted').
		#(#GbsForwarder #GbxAbstractProxy 'GemStone-GBS-Converted').
		#(#GbxObjectStub #GbxAbstractProxy 'GemStone-GBS-Converted').
		#(#GbxByteStub #GbxObjectStub 'GemStone-GBS-Converted').
		#(#GbxPointerStub #GbxObjectStub 'GemStone-GBS-Converted').
		#(#GbxUnknownStub #GbxObjectStub 'GemStone-GBS-Converted').
		#(#GbxUnauthorizedObjectStub #GbxObjectStub 'GemStone-GBS-Converted').
		#(#GbxInspector #Object 'GemStone-GBS-Converted').
		#(#GbxBasicInspector #Object 'GemStone-GBS-Converted').
		#(#GbxArrayInspector #Object 'GemStone-GBS-Converted').
		#(#GbxSetInspector #Object 'GemStone-GBS-Converted').
		#(#GbxDelegateInspector #GbxBasicInspector 'GemStone-GBS-Converted').
		#(#GbxIdentityBagInspector #GbxArrayInspector 'GemStone-GBS-Converted').
		#(#GbxTrippyDictionaryInspector #Object 'GemStone-GBS-Converted').
		#(#GbxClientBasicProxyInspector #Object 'GemStone-GBS-Converted').
		#(#GbxTextEditorInspector #Object 'GemStone-GBS-Converted').
		#(#GbxGsMethodDictionary #IdentityDictionary 'GemStone-GBS-Converted').
		#(#GbxFastIdentityKeyValueDictionary #GbxGsMethodDictionary 'GemStone-GBS-Converted').
		#(#GbxTraversal #Object 'GemStone-GBS-Converted').
		#(#GbxFetchTraversal #GbxTraversal 'GemStone-GBS-Converted').
		#(#GbxStoreTraversal #GbxTraversal 'GemStone-GBS-Converted').
		#(#GbxTraversalBuffer #Object 'GemStone-GBS-Converted').
		#(#GbxTraversalBuffer64 #GbxTraversalBuffer 'GemStone-GBS-Converted').
		#(#GbxLogger #Object 'GemStone-GBS-Converted').
		#(#GbxFileLogger #GbxLogger 'GemStone-GBS-Converted').
		#(#GbxMemoryLogger #GbxLogger 'GemStone-GBS-Converted').
		#(#GbxUnorderedCollectionReplicator #GbxObjectReplicator 'GemStone-GBS-Converted').
		#(#GbxStructure #Object 'GemStone-GBS-Converted').
		#(#GbxStructureSync #Object 'GemStone-GBS-Converted').
		#(#GbxLongHolderType #GbxStructure 'GemStone-GBS-Converted').
		#(#GbxGciStoreTravDoArgsSType #GbxStructure 'GemStone-GBS-Converted').
		#(#GbxGciClampedTravArgsSType #GbxStructure 'GemStone-GBS-Converted').
		#(#GbxX509LoginArg #GbxStructure 'GemStone-GBS-Converted').
		#(#LargeGrainMemoryPolicy #Object 'GemStone-GBS-Converted').
		#(#KeyValueDictionary #Dictionary 'GemStone-GBS-Converted').
		#(#AlphaBlendedIcons #Object 'GemStone-GBS-Converted').
		#(#GbxDuration #Object 'GemStone-GBS-Converted').
		#(#GciCallProtect #Object 'GemStone-GBS-Converted').
		#(#SpecialGemStoneObjects #Object 'GemStone-GBS-Converted').
		#(#PrimInterface #Object 'GemStone-GBS-Converted').
		#(#MemberNotFoundError #Object 'GemStone-GBS-Converted').
		#(#UninterpretedBytes #Object 'GemStone-GBS-Converted').
		#(#Subsystem #Object 'GemStone-GBS-Converted')
	} do: [ :spec |
		| name superclass package |
		name := spec first.
		superclass := Smalltalk at: spec second.
		package := spec third.
		(Smalltalk includesKey: name) ifFalse: [
			Smalltalk classInstaller make: [ :builder |
				builder
					superclass: superclass;
					name: name;
					slots: #();
					sharedVariables: #();
					package: package
			]
		]
	].

	Transcript show: 'PREBOOTSTRAP_OK'; cr.
] on: Error do: [ :ex |
	Transcript show: 'PREBOOTSTRAP_ERROR: ', ex messageText; cr
].
