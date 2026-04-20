Extension { #name : 'GbsWorkspace' }

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsWorkspace >> addExtensionWorkspaceMenuItemsTo: aMenuGroup [
	aMenuGroup addItem: [ :item |
		item name: 'GS-$LOAD_PATH Report'; icon: (self iconNamed: #smallInspectIt);
		action: [ UIManager default defer: [ self browseRubyLoadPathReport ] ] ].
	aMenuGroup addItem: [ :item |
		item name: 'GS-Loaded Features Report'; icon: (self iconNamed: #smallInspectIt);
		action: [ UIManager default defer: [ self browseRubyLoadedFeaturesReport ] ] ].
	aMenuGroup addItem: [ :item |
		item name: 'GS-Persistent Features Report'; icon: (self iconNamed: #smallInspectIt);
		action: [ UIManager default defer: [ self browseRubyPersistentLoadedFeaturesReport ] ] ].
	aMenuGroup addItem: [ :item |
		item name: 'GS-Top-Level Autoload Report'; icon: (self iconNamed: #smallInspectIt);
		action: [ UIManager default defer: [ self browseTopLevelAutoloadRegistrationsReport ] ] ].
	aMenuGroup addItem: [ :item |
		item name: 'GS-MagLev Finalizer Registry Report'; icon: (self iconNamed: #smallInspectIt);
		action: [ UIManager default defer: [ self browseMaglevFinalizerRegistryReport ] ] ]
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsWorkspace >> browseRubyLoadPathReport [
	| activeSession |
	activeSession := self activeSessionForRemoteExecution.
	activeSession ifNil: [ ^ self inform: 'No Session' ].
	self inform: activeSession rubyRuntime loadPathReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsWorkspace >> browseRubyLoadedFeaturesReport [
	| activeSession |
	activeSession := self activeSessionForRemoteExecution.
	activeSession ifNil: [ ^ self inform: 'No Session' ].
	self inform: activeSession rubyRuntime loadedFeaturesReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsWorkspace >> browseRubyPersistentLoadedFeaturesReport [
	| activeSession |
	activeSession := self activeSessionForRemoteExecution.
	activeSession ifNil: [ ^ self inform: 'No Session' ].
	self inform: activeSession rubyRuntime persistentLoadedFeaturesReportText.
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsWorkspace >> browseTopLevelAutoloadRegistrationsReport [
	| activeSession |
	activeSession := self activeSessionForRemoteExecution.
	activeSession ifNil: [ ^ self inform: 'No Session' ].
	self inform: (activeSession rubyRuntime
		autoloadRegistrationsReportTextForNamespace: activeSession topLevelNamespaceMirror).
	^ true
]

{ #category : '*GemStone-GBS-MagLev-Tools' }
GbsWorkspace >> browseMaglevFinalizerRegistryReport [
	| activeSession |
	activeSession := self activeSessionForRemoteExecution.
	activeSession ifNil: [ ^ self inform: 'No Session' ].
	self inform: activeSession objectSpaceDiagnostics finalizerRegistryReport text.
	^ true
]
