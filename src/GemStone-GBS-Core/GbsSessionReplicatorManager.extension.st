Extension { #name : 'GbsSession' }

{ #category : '*GemStone-GBS-Core' }
GbsSession >> clientClassConnectorForClientBehavior: clientBehavior serverBehavior: serverBehavior [
	^ self replicatorManager
		clientClassConnectorForClientBehavior: clientBehavior
		serverBehavior: serverBehavior
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> connectReplicator: aReplicator toClientBehavior: clientBehavior andServerBehavior: serverBehavior [
	^ self replicatorManager
		atClient: clientBehavior
		andServer: serverBehavior
		put: aReplicator
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> connectReplicator: aReplicator toServerBehavior: serverBehavior [
	^ self replicatorManager connectReplicator: aReplicator toServerBehavior: serverBehavior
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> disconnectReplicatorForClientBehavior: clientBehavior andServerBehavior: serverBehavior [
	^ self replicatorManager
		removeReplicatorForClientBehavior: clientBehavior
		andServerBehavior: serverBehavior
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> disconnectReplicatorForServerBehavior: serverBehavior [
	^ self replicatorManager removeReplicatorForServerBehavior: serverBehavior
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> connectorDiagnosticsReport [
	^ self replicatorManager connectorDiagnosticsReport
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> connectorDiagnosticsReportText [
	^ self replicatorManager connectorDiagnosticsReportText
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> connectorDiffPreviewReport [
	^ self replicatorManager connectorDiffPreviewReport
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> connectorDiffPreviewReportText [
	^ self replicatorManager connectorDiffPreviewReportText
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> connectorLoginReportArtifact [
	| artifact eventController storeCapability materializationCapability |
	storeCapability := [ self nativeStoreTraversalCapabilityReport ]
		on: Error
		do: [ :ex |
			Dictionary new
				at: #error put: ex messageText;
				yourself ].
	materializationCapability := [ self nativeMaterializationTraversalCapabilityReport ]
		on: Error
		do: [ :ex |
			Dictionary new
				at: #error put: ex messageText;
				yourself ].
	eventController := [ GbsSessionEventController forSession: self ]
		on: Error
		do: [ nil ].
	artifact := Dictionary new
		at: #generatedAt put: DateAndTime now asString;
		at: #sessionKey put: (GbsSessionManager sessionKeyForSessionObject: self);
		at: #replicatorManagerReport put: ([ self replicatorManagerReport ] on: Error do: [ Dictionary new ]);
		at: #connectorDiagnostics put: ([ self connectorDiagnosticsReport ] on: Error do: [ Dictionary new ]);
		at: #connectorDiffPreview put: ([ self connectorDiffPreviewReport ] on: Error do: [ Dictionary new ]);
		at: #nativeStoreTraversalCapabilityReport put: storeCapability;
		at: #nativeMaterializationTraversalCapabilityReport put: materializationCapability;
		at: #eventReport put: (eventController ifNil: [ Dictionary new ] ifNotNil: [ eventController eventReport ]);
		yourself.
	^ artifact
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> connectorLoginReportArtifactText [
	| artifact diagnostics preview |
	artifact := self connectorLoginReportArtifact.
	diagnostics := artifact at: #connectorDiagnostics ifAbsent: [ Dictionary new ].
	preview := artifact at: #connectorDiffPreview ifAbsent: [ Dictionary new ].
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'Connector Login Report';
			cr;
			cr;
			nextPutAll: 'generatedAt=';
			nextPutAll: (artifact at: #generatedAt ifAbsent: [ '' ]);
			cr;
			nextPutAll: 'sessionKey=';
			nextPutAll: (artifact at: #sessionKey ifAbsent: [ '' ]);
			cr;
			nextPutAll: 'connectorRows=';
			nextPutAll: (diagnostics at: #rowCount ifAbsent: [ 0 ]) asString;
			cr;
			nextPutAll: 'connectorInvalid=';
			nextPutAll: (diagnostics at: #invalidCount ifAbsent: [ 0 ]) asString;
			cr;
			nextPutAll: 'connectorWarnings=';
			nextPutAll: (diagnostics at: #warningCount ifAbsent: [ 0 ]) asString;
			cr;
			nextPutAll: 'previewActions=';
			nextPutAll: (preview at: #actionCount ifAbsent: [ 0 ]) asString;
			cr ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> lastConnectorLoginReportArtifact [
	^ (self class weakRegistryNamed: #GbsSessionConnectorLoginReports)
		at: self
		ifAbsent: [ nil ]
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> installClientClassConnectorForClientBehavior: clientBehavior serverBehavior: serverBehavior replicationSpec: aReplicationSpec serverInstVarNames: instVarNames [
	^ self replicatorManager
		installClientClassConnectorForClientBehavior: clientBehavior
		serverBehavior: serverBehavior
		replicationSpec: aReplicationSpec
		serverInstVarNames: instVarNames
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> mappedClientClass: clientBehavior toServer: serverBehavior [
	^ self replicatorManager
		mapReplicatorForClientBehavior: clientBehavior
		serverBehavior: serverBehavior
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> replicatorManagerReport [
	^ self replicatorManager connectorManagerReport
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> replicatorManagerReportText [
	^ self replicatorManager connectorManagerReportText
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> recordConnectorLoginReportArtifact [
	| artifact |
	artifact := self connectorLoginReportArtifact.
	(self class weakRegistryNamed: #GbsSessionConnectorLoginReports)
		at: self
		put: artifact.
	^ artifact
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> replicatorForClient: anObject ifAbsent: aBlock [
	^ self
		replicatorForClientBehavior: anObject class
		ifAbsent: aBlock
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> setReplicatorForClient: secondaryBehavior sameAsReplicatorForClient: primaryBehavior [
	^ self replicatorManager
		setReplicatorForClient: secondaryBehavior
		sameAsReplicatorForClient: primaryBehavior
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> updateClassClampForReplicator: aReplicator [
	^ self replicatorManager updateClassClampForReplicator: aReplicator
]

{ #category : '*GemStone-GBS-Core' }
GbsSession >> updateInstVarNamesAndClamps [
	^ self replicatorManager updateInstVarNamesAndClamps
]
