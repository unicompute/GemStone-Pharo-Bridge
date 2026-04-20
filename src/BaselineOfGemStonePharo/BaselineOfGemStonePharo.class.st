Class {
	#name : 'BaselineOfGemStonePharo',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfGemStonePharo',
	#package : 'BaselineOfGemStonePharo'
}

{ #category : 'baselines' }
BaselineOfGemStonePharo >> baseline: spec [
	| packageSpecs groupSpecs |
	<baseline>
	spec for: #common do: [ 
		spec
			preLoadDoIt: #preload:package:;
			postLoadDoIt: #postload:package:.
		
		packageSpecs := self packageRequirementSpecs.
		packageSpecs do: [ :each |
			| packageName requiredPackages |
			packageName := each first.
			requiredPackages := each second.
			requiredPackages isEmpty
				ifTrue: [ spec package: packageName ]
				ifFalse: [
					spec package: packageName
						with: [ spec requires: requiredPackages ] ] ].
			
		groupSpecs := self groupMemberSpecs.
		groupSpecs do: [ :each |
			spec group: each first with: each second ].
	]
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> coreOnlyClassChecks [
	^ {
		{ #GbsSession. true }.
		{ #GbsRepositoryFacade. true }.
		{ #GbsBrowser. true }.
		{ #GbsInspector. true }.
		{ #GbsMethodQueryResultsPresenter. true }.
		{ #GbxDebuggerService. true }.
		{ #GbsRemoteConstantMirror. true }.
		{ #GbsRemoteNamespaceMirror. true }.
		{ #GbsRemoteMethodMirror. true }.
		{ #GbsRemoteClassMirror. true }.
		{ #GbsNamespaceScopedMethodQuery. true }.
		{ #GbsBridgeRootFacade. true }.
		{ #GbsPersistentRootFacade. true }.
		{ #GbsSmalltalkFacade. true }.
		{ #GciErrorTest. true }.
		{ #GbxActivationTest. true }.
		{ #GbsMaglevFacade. false }.
		{ #GbsMaglevPersistentRootFacade. false }.
		{ #GbsRubyRuntimeFacade. false }.
		{ #GbsRemoteAutoloadMirror. false }.
		{ #GbsObjectLogFacade. false }.
		{ #GbsObjectLogEntry. false }.
		{ #GbsFinalizerRegistrySessionStateSlot. false }.
		{ #GbsMaglevRuntimeProxy. false }.
		{ #GbsRcCounter. false }.
		{ #GbsRcHash. false }.
		{ #GbsRcQueue. false }.
		{ #GbsSharedCounter. false }.
		{ #GbsGsObject. false }.
		{ #GbsGsDictionary. false }.
		{ #GbxExecBlock. false }.
		{ #GbxExecBlock0. false }.
		{ #GbxExecBlock1. false }.
		{ #GbxExecBlock2. false }.
		{ #GbxExecBlock3. false }.
		{ #GbxExecBlock4. false }.
		{ #GbxExecBlock5. false }.
		{ #GbxExecBlockN. false }.
		{ #GbsStDBbadAtRuby. false }.
		{ #GbsStDBnoRuby. false }.
		{ #GbsErrRubySystemExitErr. false }.
		{ #GbsRemoteMethodObject. true }.
		{ #GbsRemoteUnboundMethodObject. true } }
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> coreOnlyPackageChecks [
	^ {
		{ 'GemStone-GBS-Converted'. true }.
		{ 'GemStone-GBS-Tools'. true }.
		{ 'GemStone-Pharo-Core-Tests'. true }.
		{ 'GemStone-Pharo-Compatibility-Tests'. false }.
		{ 'GemStone-Pharo-Tests'. false }.
		{ 'GemStone-GBS-MagLev'. false }.
		{ 'GemStone-GBS-MagLev-Tools'. false } }
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> coreOnlySelectorChecks [
	^ {
		{ #GbsSession. #rubyRuntime. false }.
		{ #GbsSession. #bridgeRoot. true }.
		{ #GbsSession. #objectLog. false }.
		{ #GbsSession. #sessionMethods. false }.
		{ #GbsSession. #materializeMaglevRuntimeValue:. false }.
		{ #GbsSession. #gsDictionaryForOop:. false }.
		{ #GbsSession. #gsObjectForOop:. false }.
		{ #GbsSession. #rcCounterForOop:. false }.
		{ #GbsSession. #rcHashForOop:. false }.
		{ #GbsSession. #rcQueueForOop:. false }.
		{ #GbsObjectSpaceFacade. #maglevFinalizerRegistry. false }.
		{ #GbsObjectSpaceDiagnosticsFacade. #maglevFinalizerRegistry. false }.
		{ #GbsObjectSpaceDiagnosticsFacade. #finalizerRegistryReport. false }.
		{ #GbsObjectSpaceDiagnosticsFacade. #finalizerRegistrySlot. false }.
		{ #GbsRemoteConstantMirror. #autoloadFile. false }.
		{ #GbsRemoteConstantMirror. #isAutoload. false }.
		{ #GbsBrowser. #addMaglevSessionMenuItemsTo:. false }.
		{ #GbsBrowser. #browseRubyLoadPathReport. false }.
		{ #GbsClassicLauncher. #addMaglevSessionMenuItemsTo:. false }.
		{ #GbsInspector. #addMaglevReportOptionsToLabels:actions:. false }.
		{ #GbsInspector. #addExtensionReportOptionsToLabels:actions:. false }.
		{ #GbsMethodQueryResultsPresenter. #addMaglevSessionMenuItemsTo:. false }.
		{ #GbsMethodQueryResultsPresenter. #addExtensionSessionMenuItemsTo:. false }.
		{ #GbsRemoteDebugger. #addMaglevMethodMenuItemsTo:. false }.
		{ #GbsRemoteDebugger. #addMaglevSessionMenuItemsTo:. false }.
		{ #GbsRemoteDebugger. #addExtensionMethodMenuItemsTo:. false }.
		{ #GbsRemoteDebugger. #addExtensionSessionMenuItemsTo:. false }.
		{ #GbsWorkspace. #addMaglevWorkspaceMenuItemsTo:. false }.
		{ #GbsWorkspace. #addExtensionWorkspaceMenuItemsTo:. false }.
		{ #GbsStructuredValueInspectorPresenter. #addMaglevEntryMenuItemsTo:. false }.
		{ #GbsStructuredValueInspectorPresenter. #addExtensionEntryMenuItemsTo:. false }.
		{ #GbsSymbolListBrowserPresenter. #addMaglevEntryMenuItemsTo:. false }.
		{ #GbsSymbolListBrowserPresenter. #addMaglevPreviewMenuItemsTo:. false }.
		{ #GbsSymbolListBrowserPresenter. #configureMaglevStructuredInspector:. false }.
		{ #GbsSymbolListBrowserPresenter. #addExtensionEntryMenuItemsTo:. false }.
		{ #GbsSymbolListBrowserPresenter. #addExtensionPreviewMenuItemsTo:. false }.
		{ #GbsSymbolListBrowserPresenter. #configureExtensionStructuredInspector:. false }.
		{ #GbxTrippy. #addMaglevReportOptionsToLabels:actions:. false }.
		{ #GbxTrippy. #addExtensionReportOptionsToLabels:actions:. false }.
		{ #GbsSmalltalkFacade. #bridgeRoot. true }.
		{ #GbsSmalltalkFacade. #sessionMethods. false }.
		{ #GbsSmalltalkFacade. #objectLog. false }.
		{ #GbsRemoteNamespaceMirror. #autoloadMirrors. false }.
		{ #GbsRemoteNamespaceMirror. #autoloadEntries. false }.
		{ #GbsRemoteNamespaceMirror. #autoloadFileFor:. false }.
		{ #GbsRemoteNamespaceMirror. #loadFileNamed:. false }.
		{ #GbsRemoteNamespaceMirror. #loadedFeatures. false }.
		{ #GbsRemoteNamespaceMirror. #loadPath. false }.
		{ #GbsRemoteNamespaceMirror. #persistentLoadedFeatures. false }.
		{ #GbsRemoteNamespaceMirror. #registerAutoload:file:. false }.
		{ #GbsRemoteNamespaceMirror. #removeAutoload:. false }.
		{ #GbsRemoteNamespaceMirror. #requireFileNamed:. false }.
		{ #GbsRemoteNamespaceMirror. #retryAutoload:. false }.
		{ #GbsRemoteNamespaceMirror. #supportsAutoload. false }.
		{ #GbsRemoteMethodMirror. #asMethodObject. true }.
		{ #GbsRemoteMethodMirror. #asUnboundMethodObject. true }.
		{ #GbsRemoteClassMirror. #methodObjectAt:. true }.
		{ #GbsRemoteClassMirror. #classMethodObjectAt:. true }.
		{ #GbsNamespaceScopedMethodQuery. #methodObjectForReference:. true }.
		{ #GbsNamespaceScopedMethodQuery. #methodObjects. true }.
		{ #GbsSession. #objectSpaceDiagnostics. true }.
		{ #GbsBrowser. #browseNamedObjectCacheReport. true }.
		{ #GbsInspector. #browseTypedWrapperLifecycleReport. true }.
		{ #GbsMethodQueryResultsPresenter. #browseObjectsInMemoryReport. true } }
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> forbiddenPackageRequirementSpecs [
	^ {
		{ 'GemStone-GBS-Tools'. #('GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools') }.
		{ 'GemStone-Pharo-Core-Tests'. #('GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools') }.
		{ 'GemStone-GBS-Converted'. #('GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools' 'GemStone-GBS-Tools') } }
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> deprecatedAliasSpecs [
	^ {
		{ 'GbsSession>>commit'. 'commitTransaction'. 'compatibility-only' . 'Warn on use now; remove after another stable window.' }.
		{ 'GbsSession>>persistentRoot'. 'bridgeRoot'. 'compatibility-only' . 'Warn on use now; keep only for compatibility callers.' }.
		{ 'GbsSession>>root'. 'repository root'. 'compatibility-only' . 'Warn on use now; active tests must not call it.' }.
		{ 'GbsSession>>rootAt:'. 'repository rootAt:'. 'compatibility-only' . 'Warn on use now; active tests must not call it.' }.
		{ 'GbsSession>>rootAt:ifAbsent:'. 'repository rootAt:ifAbsent:'. 'compatibility-only' . 'Warn on use now; active tests must not call it.' }.
		{ 'GbsSession>>rootAt:put:'. 'repository rootAt:put:'. 'compatibility-only' . 'Warn on use now; active tests must not call it.' }.
		{ 'GbsSmalltalkFacade>>root'. 'bridgeRoot'. 'compatibility-only' . 'Warn on use now; keep only for compatibility callers.' }.
		{ 'GbsSmalltalkFacade>>persistentRoot'. 'bridgeRoot'. 'compatibility-only' . 'Warn on use now; keep only for compatibility callers.' }.
		{ 'GbsMaglevFacade>>root'. 'bridgeRoot'. 'compatibility-only' . 'Warn on use now; keep only for compatibility callers.' }.
		{ 'GbsMaglevFacade>>persistentRoot'. 'bridgeRoot'. 'compatibility-only' . 'Warn on use now; keep only for compatibility callers.' }.
		{ 'GBSM class>>persistentRoot'. 'bridgeRoot'. 'compatibility-only' . 'Warn on use now; keep only for compatibility callers.' }.
		{ 'GBSM class>>root'. 'repository root'. 'compatibility-only' . 'Warn on use now; active tests must not call it.' }.
		{ 'GBSM class>>rootAt:'. 'repository rootAt:'. 'compatibility-only' . 'Warn on use now; active tests must not call it.' }.
		{ 'GBSM class>>rootAt:ifAbsent:'. 'repository rootAt:ifAbsent:'. 'compatibility-only' . 'Warn on use now; active tests must not call it.' }.
		{ 'GBSM class>>rootAt:put:'. 'repository rootAt:put:'. 'compatibility-only' . 'Warn on use now; active tests must not call it.' }.
		{ 'GbsPersistentRootFacade'. 'GbsBridgeRootFacade'. 'legacy-compatibility-class' . 'Keep only until selector aliases are retired.' }.
		{ '#GbsPersistentRoot'. '#GbsBridgeRoot'. 'legacy-compatibility-key' . 'Keep only until the compatibility facade is retired.' } }
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> deprecatedCompatibilitySelectorSendSpecs [
	^ {
		{ 'GemStone-Pharo-Core-Tests'. #persistentRoot }.
		{ 'GemStone-Pharo-Core-Tests'. #commit }.
		{ 'GemStone-Pharo-Tests'. #persistentRoot }.
		{ 'GemStone-Pharo-Tests'. #commit } }
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> deprecatedCompatibilitySnippetSpecs [
	^ {
		{ 'GemStone-Pharo-Core-Tests'. 'persistentRoot'. }.
		{ 'GemStone-Pharo-Core-Tests'. 'GbsPersistentRootFacade'. }.
		{ 'GemStone-Pharo-Core-Tests'. '#GbsPersistentRoot'. }.
		{ 'GemStone-Pharo-Core-Tests'. 'resumeDeprecationsDuring: [ GBSM root'. }.
		{ 'GemStone-Pharo-Core-Tests'. 'resumeDeprecationsDuring: [ GBSM rootAt:'. }.
		{ 'GemStone-Pharo-Core-Tests'. 'resumeDeprecationsDuring: [ mockSession root'. }.
		{ 'GemStone-Pharo-Core-Tests'. 'resumeDeprecationsDuring: [ mockSession rootAt:'. }.
		{ 'GemStone-Pharo-Core-Tests'. 'resumeDeprecationsDuring: [ smalltalk root'. }.
		{ 'GemStone-Pharo-Core-Tests'. 'resumeDeprecationsDuring: [ maglev root'. }.
		{ 'GemStone-Pharo-Tests'. 'persistentRoot'. }.
		{ 'GemStone-Pharo-Tests'. 'GbsPersistentRootFacade'. }.
		{ 'GemStone-Pharo-Tests'. '#GbsPersistentRoot'. }.
		{ 'GemStone-Pharo-Tests'. 'resumeDeprecationsDuring: [ GBSM root'. }.
		{ 'GemStone-Pharo-Tests'. 'resumeDeprecationsDuring: [ GBSM rootAt:'. }.
		{ 'GemStone-Pharo-Tests'. 'resumeDeprecationsDuring: [ mockSession root'. }.
		{ 'GemStone-Pharo-Tests'. 'resumeDeprecationsDuring: [ mockSession rootAt:'. }.
		{ 'GemStone-Pharo-Tests'. 'resumeDeprecationsDuring: [ smalltalk root'. }.
		{ 'GemStone-Pharo-Tests'. 'resumeDeprecationsDuring: [ maglev root'. } }
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> generatedContractArtifactSpecs [
	^ {
		{ 'doc/PACKAGE-GRAPH.md'. self generatedPackageGraphMarkdown }.
		{ 'doc/PACKAGE-GRAPH.dot'. self generatedPackageGraphDot }.
		{ 'doc/PACKAGE-GRAPH.svg'. self generatedPackageGraphSvg }.
		{ 'doc/VERIFICATION-LANES.md'. self generatedVerificationLanesMarkdown }.
		{ 'doc/DEPRECATED-ALIASES.md'. self generatedDeprecatedAliasesMarkdown } }
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> generatedPackageGraphDot [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'digraph GemStonePharoBridge {'; cr;
			nextPutAll: '  rankdir=LR;'; cr;
			nextPutAll: '  node [shape=box];'; cr; cr.
		self packageRequirementSpecs do: [ :each |
			stream
				nextPutAll: '  "';
				nextPutAll: each first;
				nextPutAll: '";';
				cr ].
		stream cr.
		self packageRequirementSpecs do: [ :each |
			each second do: [ :dependency |
				stream
					nextPutAll: '  "';
					nextPutAll: dependency;
					nextPutAll: '" -> "';
					nextPutAll: each first;
					nextPutAll: '";';
					cr ] ].
		stream nextPutAll: '}'; cr ]
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> generatedPackageGraphSvg [
	| layoutByPackage colorByPackage boxWidth boxHeight |
	layoutByPackage := Dictionary newFromPairs: {
		'GemStone-GBS-Converted'. (40@40).
		'GemStone-GBS-Tools'. (40@160).
		'GemStone-Pharo-Core-Tests'. (40@280).
		'GemStone-GBS-MagLev'. (420@40).
		'GemStone-GBS-MagLev-Tools'. (420@160).
		'GemStone-Pharo-Compatibility-Tests'. (420@280).
		'GemStone-Pharo-Tests'. (800@280) }.
	colorByPackage := Dictionary newFromPairs: {
		'GemStone-GBS-Converted'. '#d8ecff'.
		'GemStone-GBS-Tools'. '#d8ecff'.
		'GemStone-Pharo-Core-Tests'. '#e4f7df'.
		'GemStone-GBS-MagLev'. '#ffe6c7'.
		'GemStone-GBS-MagLev-Tools'. '#ffe6c7'.
		'GemStone-Pharo-Compatibility-Tests'. '#fff4bf'.
		'GemStone-Pharo-Tests'. '#f0e0ff' }.
	boxWidth := 300.
	boxHeight := 56.
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '<svg xmlns="http://www.w3.org/2000/svg" width="1140" height="390" viewBox="0 0 1140 390">'; cr;
			nextPutAll: '  <defs>'; cr;
			nextPutAll: '    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse">'; cr;
			nextPutAll: '      <path d="M 0 0 L 10 5 L 0 10 z" fill="#5a6470"/>'; cr;
			nextPutAll: '    </marker>'; cr;
			nextPutAll: '  </defs>'; cr;
			nextPutAll: '  <rect width="1140" height="390" fill="#ffffff"/>'; cr;
			nextPutAll: '  <text x="40" y="24" font-family="Helvetica, Arial, sans-serif" font-size="18" font-weight="700" fill="#1f2933">GemStone-Pharo-Bridge Package Graph</text>'; cr.
		self packageRequirementSpecs do: [ :each |
			| packageName targetOrigin |
			packageName := each first.
			targetOrigin := layoutByPackage at: packageName ifAbsent: [ 40@40 ].
			each second do: [ :dependency |
				| dependencyOrigin |
				dependencyOrigin := layoutByPackage at: dependency ifAbsent: [ 40@40 ].
				stream
					nextPutAll: '  <path d="M ';
					nextPutAll: (dependencyOrigin x + boxWidth) printString;
					nextPutAll: ' ';
					nextPutAll: (dependencyOrigin y + (boxHeight / 2)) printString;
					nextPutAll: ' C ';
					nextPutAll: (dependencyOrigin x + boxWidth + 40) printString;
					nextPutAll: ' ';
					nextPutAll: (dependencyOrigin y + (boxHeight / 2)) printString;
					nextPutAll: ', ';
					nextPutAll: (targetOrigin x - 40) printString;
					nextPutAll: ' ';
					nextPutAll: (targetOrigin y + (boxHeight / 2)) printString;
					nextPutAll: ', ';
					nextPutAll: targetOrigin x printString;
					nextPutAll: ' ';
					nextPutAll: (targetOrigin y + (boxHeight / 2)) printString;
					nextPutAll: '" fill="none" stroke="#5a6470" stroke-width="2" marker-end="url(#arrow)"/>';
					cr ] ].
		self packageRequirementSpecs do: [ :each |
			| packageName origin fillColor |
			packageName := each first.
			origin := layoutByPackage at: packageName ifAbsent: [ 40@40 ].
			fillColor := colorByPackage at: packageName ifAbsent: [ '#eeeeee' ].
			stream
				nextPutAll: '  <rect x="';
				nextPutAll: origin x printString;
				nextPutAll: '" y="';
				nextPutAll: origin y printString;
				nextPutAll: '" width="';
				nextPutAll: boxWidth printString;
				nextPutAll: '" height="';
				nextPutAll: boxHeight printString;
				nextPutAll: '" rx="10" ry="10" fill="';
				nextPutAll: fillColor;
				nextPutAll: '" stroke="#334155" stroke-width="2"/>';
				cr;
				nextPutAll: '  <text x="';
				nextPutAll: (origin x + 16) printString;
				nextPutAll: '" y="';
				nextPutAll: (origin y + 31) printString;
				nextPutAll: '" font-family="Helvetica, Arial, sans-serif" font-size="15" font-weight="600" fill="#102a43">';
				nextPutAll: packageName;
				nextPutAll: '</text>';
				cr ].
		stream nextPutAll: '</svg>'; cr ]
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> generatedPackageGraphMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '# Package Graph'; cr; cr;
			nextPutAll: 'Generated from `BaselineOfGemStonePharo` package and lane contracts.'; cr; cr;
			nextPutAll: 'Rendered SVG: [PACKAGE-GRAPH.svg](./PACKAGE-GRAPH.svg)'; cr; cr;
			nextPutAll: '## Packages'; cr; cr.
		self packageRequirementSpecs do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each first;
				nextPutAll: '`';
				cr.
			each second isEmpty
				ifTrue: [
					stream nextPutAll: '  requires: `(none)`'; cr ]
				ifFalse: [
					stream
						nextPutAll: '  requires: ';
						nextPutAll: (String streamContents: [ :inner |
							each second
								do: [ :dependency | inner nextPutAll: '`'; nextPutAll: dependency; nextPutAll: '`' ]
								separatedBy: [ inner nextPutAll: ', ' ] ]);
						cr ] ].
		stream cr; nextPutAll: '## Load Groups'; cr; cr.
		self groupMemberSpecs do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each first;
				nextPutAll: '` -> ';
				nextPutAll: (String streamContents: [ :inner |
					each second
						do: [ :member | inner nextPutAll: '`'; nextPutAll: member; nextPutAll: '`' ]
						separatedBy: [ inner nextPutAll: ', ' ] ]);
				cr ].
		stream cr; nextPutAll: '## Forbidden Reverse Dependencies'; cr; cr.
		self forbiddenPackageRequirementSpecs do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each first;
				nextPutAll: '` must not require ';
				nextPutAll: (String streamContents: [ :inner |
					each second
						do: [ :member | inner nextPutAll: '`'; nextPutAll: member; nextPutAll: '`' ]
						separatedBy: [ inner nextPutAll: ', ' ] ]);
				cr ] ]
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> generatedDeprecatedAliasesMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '# Deprecated Aliases'; cr; cr;
			nextPutAll: 'Generated from `BaselineOfGemStonePharo` deprecated alias contracts.'; cr; cr;
			nextPutAll: '| Alias | Replacement | Stage | Removal plan |'; cr;
			nextPutAll: '| --- | --- | --- | --- |'; cr.
		self deprecatedAliasSpecs do: [ :each |
			stream
				nextPutAll: '| `';
				nextPutAll: each first;
				nextPutAll: '` | `';
				nextPutAll: each second;
				nextPutAll: '` | `';
				nextPutAll: each third;
				nextPutAll: '` | ';
				nextPutAll: each fourth;
				nextPutAll: ' |';
				cr ] ]
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> generatedVerificationLanesMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '# Verification Lanes'; cr; cr;
			nextPutAll: 'Generated from `BaselineOfGemStonePharo` lane contracts.'; cr; cr.
		self verificationLaneSpecs do: [ :each |
			stream
				nextPutAll: '## ';
				nextPutAll: each first;
				cr; cr;
				nextPutAll: each second;
				cr; cr;
				nextPutAll: '- load group: `';
				nextPutAll: each third;
				nextPutAll: '`';
				cr;
				nextPutAll: '- targets: ';
				nextPutAll: (String streamContents: [ :inner |
					each fourth
						do: [ :packageName | inner nextPutAll: '`'; nextPutAll: packageName; nextPutAll: '`' ]
						separatedBy: [ inner nextPutAll: ', ' ] ]);
				cr;
				nextPutAll: '- success markers: ';
				nextPutAll: (String streamContents: [ :inner |
					each fifth
						do: [ :marker | inner nextPutAll: '`'; nextPutAll: marker; nextPutAll: '`' ]
						separatedBy: [ inner nextPutAll: ', ' ] ]);
				cr; cr ] ]
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> groupMemberSpecs [
	^ {
		{ 'Core'. #('GemStone-GBS-Converted') }.
		{ 'Core-Only'. #('GemStone-GBS-Converted') }.
		{ 'Core-Tools'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools') }.
		{ 'Core-Tests'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools' 'GemStone-Pharo-Core-Tests') }.
		{ 'Compatibility-Tests'. #('GemStone-Pharo-Compatibility-Tests') }.
		{ 'MagLev-Core'. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev') }.
		{ 'MagLev-Tools'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools' 'GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools') }.
		{ 'MagLev'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools' 'GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools') }.
		{ 'Tools'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools') }.
		{ 'All-Tests'. #('GemStone-Pharo-Core-Tests' 'GemStone-Pharo-Compatibility-Tests' 'GemStone-Pharo-Tests') }.
		{ 'Tests'. #('GemStone-Pharo-Core-Tests' 'GemStone-Pharo-Compatibility-Tests' 'GemStone-Pharo-Tests') }.
		{ 'Full'. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev' 'GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools' 'GemStone-Pharo-Core-Tests' 'GemStone-Pharo-Compatibility-Tests' 'GemStone-Pharo-Tests') }.
		{ 'default'. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev' 'GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools' 'GemStone-Pharo-Core-Tests' 'GemStone-Pharo-Compatibility-Tests' 'GemStone-Pharo-Tests') } }
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageOwnershipClassSpecs [
	^ {
		{ #GbsSession. 'GemStone-GBS-Converted' }.
		{ #GbsSmalltalkFacade. 'GemStone-GBS-Converted' }.
		{ #GbsBridgeRootFacade. 'GemStone-GBS-Converted' }.
		{ #GbsRepositoryFacade. 'GemStone-GBS-Converted' }.
		{ #GbsRemoteNamespaceMirror. 'GemStone-GBS-Converted' }.
		{ #GbsRemoteMethodObject. 'GemStone-GBS-Converted' }.
		{ #GbsBrowser. 'GemStone-GBS-Tools' }.
		{ #GbxDebuggerService. 'GemStone-GBS-Tools' }.
		{ #GbsMethodQueryResultsPresenter. 'GemStone-GBS-Tools' }.
		{ #GciErrorTest. 'GemStone-Pharo-Core-Tests' }.
		{ #GbsRootCompatibilityTest. 'GemStone-Pharo-Compatibility-Tests' }.
		{ #GbsMaglevFacade. 'GemStone-GBS-MagLev' }.
		{ #GbsRemoteAutoloadMirror. 'GemStone-GBS-MagLev' }.
		{ #GbsObjectLogFacade. 'GemStone-GBS-MagLev' }.
		{ #GbsRcCounter. 'GemStone-GBS-MagLev' }.
		{ #GbsFinalizerRegistrySessionStateSlot. 'GemStone-GBS-MagLev' }.
		{ #GbsNamespacesPresenter. 'GemStone-GBS-MagLev-Tools' } }
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageOwnershipBehaviorSpecs [
	^ {
		{ #GBSM. #class. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev') }.
		{ #GbsBridgeRootFacade. #instance. #('GemStone-GBS-Converted') }.
		{ #GbsBrowser. #instance. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools') }.
		{ #GbsClassicLauncher. #instance. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools') }.
		{ #GbsInspector. #instance. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools') }.
		{ #GbsMethodQueryResultsPresenter. #instance. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools') }.
		{ #GbsNamespaceScopedMethodQuery. #instance. #('GemStone-GBS-Converted') }.
		{ #GbsObjectSpaceDiagnosticsFacade. #class. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev') }.
		{ #GbsObjectSpaceDiagnosticsFacade. #instance. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev') }.
		{ #GbsObjectSpaceFacade. #instance. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev') }.
		{ #GbsPlaygroundActions. #class. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools') }.
		{ #GbsRemoteClassMirror. #instance. #('GemStone-GBS-Converted') }.
		{ #GbsRemoteConstantMirror. #instance. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev') }.
		{ #GbsRemoteDebugger. #instance. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools') }.
		{ #GbsRemoteMethodMirror. #instance. #('GemStone-GBS-Converted') }.
		{ #GbsRemoteMethodObject. #instance. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev') }.
		{ #GbsRemoteNamespaceMirror. #class. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev') }.
		{ #GbsRemoteNamespaceMirror. #instance. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev') }.
		{ #GbsRepositoryFacade. #instance. #('GemStone-GBS-Converted') }.
		{ #GbsRepositoryRootFacade. #instance. #('GemStone-GBS-Converted') }.
		{ #GbsSession. #instance. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev') }.
		{ #GbsSmalltalkFacade. #instance. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev') }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools') }.
		{ #GbsSymbolListBrowserPresenter. #instance. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools') }.
		{ #GbsWorkspace. #instance. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools') }.
		{ #GbxDebuggerService. #instance. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools') }.
		{ #GbxTrippy. #instance. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools') } }
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageOwnershipCorePackages [
	^ #(
		'GemStone-GBS-Converted'
		'GemStone-GBS-Tools')
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageOwnershipForbiddenCoreClassPatterns [
	^ #(
		'GbsMaglev'
		'GbsRuby'
		'GbsObjectLog'
		'GbxExecBlock'
		'GbsFinalizerRegistrySessionStateSlot'
		'GbsRcCounter'
		'GbsRcHash'
		'GbsRcQueue'
		'GbsSharedCounter'
		'GbsRemoteAutoload'
		'GbsRemoteProcObject'
		'GbsRemoteBindingObject'
		'GbsRemoteExecBlockObject')
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageOwnershipForbiddenCoreSelectorPatterns [
	^ #(
		'rubyruntime'
		'browseruby'
		'addmaglev'
		'configuremaglev'
		'maglevfinalizerregistry'
		'objectlog'
		'sessionmethods'
		'autoloadmirrors'
		'loadedfeatures'
		'loadpath'
		'registerautoload'
		'removeautoload'
		'requirefilenamed'
		'retryautoload'
		'supportsautoload'
		'persistentloadedfeatures')
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageOwnershipSelectorSpecs [
	^ {
		{ #GbsSession. #bridgeRoot. 'GemStone-GBS-Converted' }.
		{ #GbsSession. #commitTransactionWithRetryCount:. 'GemStone-GBS-Converted' }.
		{ #GbsSmalltalkFacade. #bridgeRoot. 'GemStone-GBS-Converted' }.
		{ #GbsRemoteNamespaceMirror. #constantEntries. 'GemStone-GBS-Converted' }.
		{ #GbsBrowser. #browseNamedObjectCacheReport. 'GemStone-GBS-Tools' }.
		{ #GbxDebuggerService. #basicReenterServerContext. 'GemStone-GBS-Tools' }.
		{ #GbsSession. #rubyRuntime. 'GemStone-GBS-MagLev' }.
		{ #GbsSmalltalkFacade. #objectLog. 'GemStone-GBS-MagLev' }.
		{ #GbsRemoteNamespaceMirror. #autoloadMirrors. 'GemStone-GBS-MagLev' }.
		{ #GbsRemoteConstantMirror. #autoloadFile. 'GemStone-GBS-MagLev' }.
		{ #GbsBrowser. #browseRubyLoadPathReport. 'GemStone-GBS-MagLev-Tools' }.
		{ #GbsRemoteDebugger. #browseRubyLoadPathReport. 'GemStone-GBS-MagLev-Tools' } }
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageRequirementSpecs [
	^ {
		{ 'GemStone-GBS-Converted'. #() }.
		{ 'GemStone-GBS-MagLev'. #('GemStone-GBS-Converted') }.
		{ 'GemStone-GBS-Tools'. #('GemStone-GBS-Converted') }.
		{ 'GemStone-GBS-MagLev-Tools'. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev') }.
		{ 'GemStone-Pharo-Core-Tests'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools') }.
		{ 'GemStone-Pharo-Compatibility-Tests'. #('GemStone-Pharo-Core-Tests' 'GemStone-GBS-MagLev') }.
		{ 'GemStone-Pharo-Tests'. #('GemStone-Pharo-Core-Tests' 'GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools') } }
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> verificationLaneSpecs [
	^ {
		{ 'core-only'. 'Verify the Smalltalk core without MagLev packages.'. 'Core-Tests'. #('GemStone-Pharo-Core-Tests'). #('ARCHITECTURE_BOUNDARY_OK' 'PACKAGE_OWNERSHIP_DRIFT_OK' 'BRIDGE_UNIT_REGRESSION_OK' 'BRIDGE_CORE_ONLY_CHECK_OK') }.
		{ 'compatibility-only'. 'Verify deprecated alias coverage in isolation.'. 'Compatibility-Tests'. #('GemStone-Pharo-Compatibility-Tests'). #('ARCHITECTURE_BOUNDARY_OK' 'PACKAGE_OWNERSHIP_DRIFT_OK' 'COMPATIBILITY_DRIFT_OK' 'BRIDGE_UNIT_REGRESSION_OK' 'BRIDGE_COMPATIBILITY_CHECK_OK') }.
		{ 'full'. 'Verify the full bridge, including MagLev packages and the live GemStone lane.'. 'Full'. #('GemStone-Pharo-Core-Tests' 'GemStone-Pharo-Compatibility-Tests' 'GemStone-Pharo-Tests'). #('ARCHITECTURE_BOUNDARY_OK' 'PACKAGE_OWNERSHIP_DRIFT_OK' 'COMPATIBILITY_DRIFT_OK' 'BRIDGE_UNIT_REGRESSION_OK' 'BRIDGE_LIVE_REGRESSION_OK' 'CLEAN_RELOAD_AND_REGRESSION_RUN_DONE') }.
		{ 'artifact-freshness'. 'Verify that the generated contract artifacts are already up to date.'. 'default'. #('doc/PACKAGE-GRAPH.md' 'doc/PACKAGE-GRAPH.dot' 'doc/PACKAGE-GRAPH.svg' 'doc/VERIFICATION-LANES.md' 'doc/DEPRECATED-ALIASES.md'). #('CONTRACT_ARTIFACTS_FRESH_OK') }.
		{ 'verify'. 'Run core-only, compatibility-only, full, then artifact-freshness.'. 'composite'. #('core-only' 'compatibility-only' 'full' 'artifact-freshness'). #('All lane success markers above') } }
]

{ #category : 'actions' }
BaselineOfGemStonePharo >> postload: loader package: packageSpec [
	self class environment
		at: #GbxRuntimeOverrideSpec
		ifPresent: [ :runtimeSpec | runtimeSpec apply ].
	self class environment
		at: #GbxToolsOverrideSpec
		ifPresent: [ :toolsSpec | toolsSpec apply ].
	self repairUndeclaredGlobals
]

{ #category : 'actions' }
BaselineOfGemStonePharo >> preload: loader package: packageSpec [
	self class environment
		at: #GbxOverrideUtility
		ifPresent: [ :overrideUtility |
			[ overrideUtility removeOverridesForRelease ]
				on: MessageNotUnderstood
				do: [ "Method removed or renamed in newer versions - safely skip" ] ]
]

{ #category : 'actions' }
BaselineOfGemStonePharo >> repairUndeclaredGlobals [
	(self class environment at: #Undeclared ifAbsent: [ nil ]) ifNotNil: [ :undeclared |
		[ undeclared fixUndeclaredVariables ]
			on: MessageNotUnderstood
			do: [ "Older/newer image may not provide this selector" ].
		[ Smalltalk image cleanOutUndeclared ]
			on: MessageNotUnderstood
			do: [ "Selector differs across image versions" ] ]
]
