Class {
	#name : 'GemStonePharoDocRenderer',
	#superclass : 'Object',
	#instVars : [
		'contract'
	],
	#category : 'BaselineOfGemStonePharo',
	#package : 'BaselineOfGemStonePharo'
}

{ #category : 'instance creation' }
GemStonePharoDocRenderer class >> on: aContract [
	^ self new
		contract: aContract;
		yourself
]

{ #category : 'accessing' }
GemStonePharoDocRenderer >> contract [
	^ contract
]

{ #category : 'accessing' }
GemStonePharoDocRenderer >> contract: aContract [
	contract := aContract
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> activeRootApiSpecs [
	^ contract activeRootApiSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> boundaryGuardSpecs [
	^ contract boundaryGuardSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> forbiddenPackageRequirementSpecs [
	^ contract forbiddenPackageRequirementSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> groupDescriptionSpecs [
	^ contract groupDescriptionSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> groupMemberSpecs [
	^ contract groupMemberSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> livePreflightCodeSpecs [
	^ contract livePreflightCodeSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> livePreflightEnvironmentVariableSpecs [
	^ contract livePreflightEnvironmentVariableSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> livePreflightStepSpecs [
	^ contract livePreflightStepSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> livePreflightSummaryFields [
	^ contract livePreflightSummaryFields
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> loadMatrixGroupNames [
	^ contract loadMatrixGroupNames
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> loadMatrixMarkerFor: aBoolean [
	^ contract loadMatrixMarkerFor: aBoolean
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> noCompatibilitySecondarySourceScanFiles [
	^ contract noCompatibilitySecondarySourceScanFiles
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> noCompatibilitySecondarySourceScanSnippets [
	^ contract noCompatibilitySecondarySourceScanSnippets
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> noCompatibilitySourceScanRoots [
	^ contract noCompatibilitySourceScanRoots
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> originalLayerExpectedExceptionSpecs [
	^ contract originalLayerExpectedExceptionSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> packageOwnershipAllowedPackagesByFamily [
	^ contract packageOwnershipAllowedPackagesByFamily
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> packageOwnershipBehaviorFamilySpecs [
	^ contract packageOwnershipBehaviorFamilySpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> packageOwnershipExplicitClassSpecs [
	^ contract packageOwnershipExplicitClassSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> packageOwnershipSelectorSpecs [
	^ contract packageOwnershipSelectorSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> packageRequirementSpecs [
	^ contract packageRequirementSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> regressionIntegrationProtocols [
	^ contract regressionIntegrationProtocols
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> regressionLaneSpecs [
	^ contract regressionLaneSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> reloadCheckModeSpecs [
	^ contract reloadCheckModeSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> reloadEnvironmentVariableSpecs [
	^ contract reloadEnvironmentVariableSpecs
]

{ #category : 'forwarding' }
GemStonePharoDocRenderer >> verificationLaneSpecs [
	^ contract verificationLaneSpecs
]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedContractArtifactSpecs [
	^ {
		{ 'doc/LOAD-MATRIX.md'. self generatedLoadMatrixMarkdown }.
		{ 'doc/MAGLEV-BRANCH-USAGE.md'. self generatedMaglevBranchUsageMarkdown }.
		{ 'doc/PACKAGE-GRAPH.md'. self generatedPackageGraphMarkdown }.
		{ 'doc/PACKAGE-GRAPH.dot'. self generatedPackageGraphDot }.
		{ 'doc/PACKAGE-GRAPH.svg'. self generatedPackageGraphSvg }.
		{ 'doc/LIVE-PREFLIGHT-POLICY.md'. self generatedLivePreflightPolicyMarkdown }.
		{ 'doc/RELOAD-POLICY.md'. self generatedReloadPolicyMarkdown }.
		{ 'doc/USER-MANUAL-REFERENCE.html'. self generatedUserManualReferenceHtml }.
		{ 'doc/OWNERSHIP-CONTRACT.md'. self generatedOwnershipContractMarkdown }.
		{ 'doc/VERIFICATION-LANES.md'. self generatedVerificationLanesMarkdown } }
]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedDocumentationSectionSpecs [
	^ {
		{ 'README.md'.
			'<!-- BEGIN GENERATED:README-BODY -->'.
			'<!-- END GENERATED:README-BODY -->'.
			self generatedReadmeBodyMarkdown }.
		{ 'doc/TESTING.md'.
			'<!-- BEGIN GENERATED:TESTING-BODY -->'.
			'<!-- END GENERATED:TESTING-BODY -->'.
			self generatedTestingBodyMarkdown }.
		{ 'doc/ARCHITECTURE.md'.
			'<!-- BEGIN GENERATED:ARCHITECTURE-BODY -->'.
			'<!-- END GENERATED:ARCHITECTURE-BODY -->'.
			self generatedArchitectureBodyMarkdown }.
		{ 'doc/GemStone-Pharo-Bridge-User-Manual.html'.
			'<!-- BEGIN GENERATED:USER-MANUAL-OVERVIEW -->'.
			'<!-- END GENERATED:USER-MANUAL-OVERVIEW -->'.
			self generatedUserManualOverviewHtml }.
		{ 'doc/GemStone-Pharo-Bridge-User-Manual.html'.
			'<!-- BEGIN GENERATED:USER-MANUAL-TESTING -->'.
			'<!-- END GENERATED:USER-MANUAL-TESTING -->'.
			self generatedUserManualTestingHtml } }
]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedDocumentationSectionPaths [
	^ #(
		'README.md'
		'doc/TESTING.md'
		'doc/ARCHITECTURE.md'
		'doc/GemStone-Pharo-Bridge-User-Manual.html')
]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedPackageGraphDot [
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
GemStonePharoDocRenderer >> generatedPackageGraphMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '# Package Graph'; cr; cr;
			nextPutAll: 'Generated from `GemStonePharoContract` package and lane contracts.'; cr; cr;
			nextPutAll: 'Rendered SVG: [PACKAGE-GRAPH.svg](./PACKAGE-GRAPH.svg)'; cr; cr;
			nextPutAll: '## Packages'; cr; cr.
		self packageRequirementSpecs do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each first;
				nextPutAll: '`';
				cr.
			each second isEmpty
				ifTrue: [ stream nextPutAll: '  requires: `(none)`'; cr ]
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
GemStonePharoDocRenderer >> generatedLoadMatrixMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '# Load Matrix'; cr; cr;
			nextPutAll: 'Generated from `GemStonePharoContract` group and lane contracts.'; cr; cr;
			nextPutAll: '| Load group | Base prod | Base tests | Core overlay | Core tools | Core tests | MagLev overlay | MagLev tools | MagLev tests | Typical use |'; cr;
			nextPutAll: '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |'; cr.
		self loadMatrixGroupNames do: [ :groupName |
			| members description |
			members := (self groupMemberSpecs detect: [ :each | each first = groupName ]) second asSet.
			description := self groupDescriptionSpecs at: groupName ifAbsent: [ 'load group' ].
			stream
				nextPutAll: '| `';
				nextPutAll: groupName;
				nextPutAll: '` | ';
				nextPutAll: (self loadMatrixMarkerFor: (members includes: 'GemStone-GBS-Converted'));
				nextPutAll: ' | ';
				nextPutAll: (self loadMatrixMarkerFor: (members includes: 'GemStone-Pharo-Tests'));
				nextPutAll: ' | ';
				nextPutAll: (self loadMatrixMarkerFor: (members includes: 'GemStone-GBS-Core'));
				nextPutAll: ' | ';
				nextPutAll: (self loadMatrixMarkerFor: (members includes: 'GemStone-GBS-Core-Tools'));
				nextPutAll: ' | ';
				nextPutAll: (self loadMatrixMarkerFor: (members includes: 'GemStone-Pharo-Core-Tests'));
				nextPutAll: ' | ';
				nextPutAll: (self loadMatrixMarkerFor: (members includes: 'GemStone-GBS-MagLev'));
				nextPutAll: ' | ';
				nextPutAll: (self loadMatrixMarkerFor: (members includes: 'GemStone-GBS-MagLev-Tools'));
				nextPutAll: ' | ';
				nextPutAll: (self loadMatrixMarkerFor: (members includes: 'GemStone-Pharo-MagLev-Tests'));
				nextPutAll: ' | ';
				nextPutAll: description;
				nextPutAll: ' |';
				cr ].
		stream cr;
			nextPutAll: '## Switch Recipes'; cr; cr;
			nextPutAll: '- base/original bridge: `Original`'; cr;
			nextPutAll: '- base/original bridge with base tests: `Original-Tests`'; cr;
			nextPutAll: '- base plus generic Smalltalk overlay: `Core`, `Core-Tools`, `Core-Tests`'; cr;
			nextPutAll: '- base plus generic overlay plus optional MagLev runtime: `MagLev`'; cr;
			nextPutAll: '- MagLev runtime plus interactive developer tools: `MagLev-Tools`'; cr;
			nextPutAll: '- full developer load: `Full` / `default`'; cr; cr;
			nextPutAll: 'See [PACKAGE-GRAPH.md](./PACKAGE-GRAPH.md) for exact package membership and [VERIFICATION-LANES.md](./VERIFICATION-LANES.md) for the proof lanes that exercise these loads.'; cr ]
]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedPackageGraphSvg [
	| layoutByPackage colorByPackage boxWidth boxHeight |
	layoutByPackage := Dictionary newFromPairs: {
		'GemStone-GBS-Converted'. (40@40).
		'GemStone-GBS-Core'. (430@40).
		'GemStone-GBS-Core-Tools'. (430@220).
		'GemStone-GBS-Tools'. (40@220).
		'GemStone-GBS-MagLev'. (820@40).
		'GemStone-GBS-MagLev-Tools'. (820@220).
		'GemStone-Pharo-Core-Tests'. (1210@40).
		'GemStone-Pharo-Tests'. (1210@220).
		'GemStone-Pharo-MagLev-Tests'. (1210@300) }.
	colorByPackage := Dictionary newFromPairs: {
		'GemStone-GBS-Converted'. '#d8ecff'.
		'GemStone-GBS-Core'. '#dff4ff'.
		'GemStone-GBS-Core-Tools'. '#dff4ff'.
		'GemStone-GBS-Tools'. '#d8ecff'.
		'GemStone-GBS-MagLev'. '#ffe6c7'.
		'GemStone-GBS-MagLev-Tools'. '#ffe6c7'.
		'GemStone-Pharo-Core-Tests'. '#e4f7df'.
		'GemStone-Pharo-Tests'. '#f0e0ff'.
		'GemStone-Pharo-MagLev-Tests'. '#f7ddf4' }.
	boxWidth := 300.
	boxHeight := 56.
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '<svg xmlns="http://www.w3.org/2000/svg" width="1550" height="410" viewBox="0 0 1550 410">'; cr;
			nextPutAll: '  <defs>'; cr;
			nextPutAll: '    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse">'; cr;
			nextPutAll: '      <path d="M 0 0 L 10 5 L 0 10 z" fill="#5a6470"/>'; cr;
			nextPutAll: '    </marker>'; cr;
			nextPutAll: '  </defs>'; cr;
			nextPutAll: '  <rect width="1550" height="410" fill="#ffffff"/>'; cr;
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
GemStonePharoDocRenderer >> generatedOwnershipContractMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '# Ownership Contract'; cr; cr;
			nextPutAll: 'Generated from `GemStonePharoContract` ownership, lane, and no-compatibility contracts.'; cr; cr;
			nextPutAll: '## Regression Lane Policy'; cr; cr.
		self regressionLaneSpecs do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each first;
				nextPutAll: '`';
				cr;
				nextPutAll: '  label: `';
				nextPutAll: each second;
				nextPutAll: '`';
				cr;
				nextPutAll: '  selection: `';
				nextPutAll: each third asString;
				nextPutAll: '`';
				cr;
				nextPutAll: '  live lane: `';
				nextPutAll: each fourth asString;
				nextPutAll: '`';
				cr ].
		stream
			cr;
			nextPutAll: '- integration protocols: ';
			nextPutAll: (String streamContents: [ :inner |
				self regressionIntegrationProtocols
					do: [ :protocol | inner nextPutAll: '`'; nextPutAll: protocol; nextPutAll: '`' ]
					separatedBy: [ inner nextPutAll: ', ' ] ]);
			cr; cr;
			nextPutAll: '## Ownership Families'; cr; cr.
		self packageOwnershipAllowedPackagesByFamily keys asSortedCollection do: [ :family |
			stream
				nextPutAll: '- `';
				nextPutAll: family asString;
				nextPutAll: '` -> ';
				nextPutAll: (String streamContents: [ :inner |
					(self packageOwnershipAllowedPackagesByFamily at: family)
						do: [ :packageName | inner nextPutAll: '`'; nextPutAll: packageName; nextPutAll: '`' ]
						separatedBy: [ inner nextPutAll: ', ' ] ]);
				cr ].
		stream cr; nextPutAll: '## Split Behavior Ownership'; cr; cr.
		self packageOwnershipBehaviorFamilySpecs do: [ :each |
			| allowedPackages |
			allowedPackages := self packageOwnershipAllowedPackagesByFamily at: each third.
			stream
				nextPutAll: '- `';
				nextPutAll: each first asString;
				nextPutAll: '` ';
				nextPutAll: (each second = #class ifTrue: [ 'class side' ] ifFalse: [ 'instance side' ]);
				nextPutAll: ' -> `';
				nextPutAll: each third asString;
				nextPutAll: '` -> ';
				nextPutAll: (String streamContents: [ :inner |
					allowedPackages
						do: [ :packageName | inner nextPutAll: '`'; nextPutAll: packageName; nextPutAll: '`' ]
						separatedBy: [ inner nextPutAll: ', ' ] ]);
				cr ].
		stream cr; nextPutAll: '## Explicit Class Ownership'; cr; cr.
		self packageOwnershipExplicitClassSpecs do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each first asString;
				nextPutAll: '` -> `';
				nextPutAll: each second;
				nextPutAll: '`';
				cr ].
		stream cr; nextPutAll: '## Explicit Selector Ownership'; cr; cr.
		self packageOwnershipSelectorSpecs do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each first asString;
				nextPutAll: (each second = #class ifTrue: [ ' class>>#' ] ifFalse: [ '>>#' ]);
				nextPutAll: each third asString;
				nextPutAll: '` -> `';
				nextPutAll: each fourth;
				nextPutAll: '`';
				cr ].
		stream cr; nextPutAll: '## No-compatibility Static Scan'; cr; cr;
			nextPutAll: 'Production source roots:'; cr.
		self noCompatibilitySourceScanRoots do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each;
				nextPutAll: '`';
				cr ].
		stream cr; nextPutAll: 'Secondary source files:'; cr.
		self noCompatibilitySecondarySourceScanFiles do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each;
				nextPutAll: '`';
				cr ].
		stream cr; nextPutAll: 'Representative forbidden snippets:'; cr.
		self noCompatibilitySecondarySourceScanSnippets do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each;
				nextPutAll: '`';
				cr ] ]
]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedLivePreflightPolicyMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '# Live Preflight Policy'; cr; cr;
			nextPutAll: 'Generated from `GemStonePharoContract` live preflight policy.'; cr; cr;
			nextPutAll: '## Purpose'; cr; cr;
			nextPutAll: 'The live preflight classifies local GemStone connectivity before the live regression lane runs.'; cr;
			nextPutAll: 'Both the standalone preflight script and the in-process full verification lane delegate to `GemStonePharoVerificationRunner`.'; cr; cr;
			nextPutAll: '## Required Environment'; cr; cr.
		self livePreflightEnvironmentVariableSpecs do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each first;
				nextPutAll: '`';
				cr;
				nextPutAll: '  ';
				nextPutAll: each second;
				cr ].
		stream cr; nextPutAll: '## Probe Steps'; cr; cr.
		self livePreflightStepSpecs do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each first;
				nextPutAll: '`';
				cr;
				nextPutAll: '  ';
				nextPutAll: each second;
				cr ].
		stream cr; nextPutAll: '## Summary Fields'; cr; cr.
		self livePreflightSummaryFields do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each;
				nextPutAll: '`';
				cr ].
		stream cr; nextPutAll: '## Result Codes'; cr; cr.
		self livePreflightCodeSpecs do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each first;
				nextPutAll: '`';
				cr;
				nextPutAll: '  ';
				nextPutAll: each second;
				cr ] ]
]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedMaglevBranchUsageMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '# Using the MagLev Branch'; cr; cr;
			nextPutAll: 'Generated from `GemStonePharoContract` load-group and steady-state API contracts.'; cr; cr;
			nextPutAll: '## Which Load Group To Use'; cr; cr;
			nextPutAll: '- `Original`'; cr;
			nextPutAll: '  original/base production packages only'; cr;
			nextPutAll: '- `Original-Tests`'; cr;
			nextPutAll: '  original/base production plus the original/base tests'; cr;
			nextPutAll: '- `MagLev`'; cr;
			nextPutAll: '  the MagLev production runtime: base/original + generic core + MagLev runtime, without debugger/tool UI packages'; cr;
			nextPutAll: '- `MagLev-Tools`'; cr;
			nextPutAll: '  the interactive developer stack for GemStone workspace, GbsRemoteDebugger, inspectors, transcript, ObjectLog, and MagLev method tools'; cr;
			nextPutAll: '- `Full`'; cr;
			nextPutAll: '  the full developer stack, including MagLev-aware test packages'; cr; cr;
			nextPutAll: '## Load From Local Disk'; cr; cr;
			nextPutAll: '```smalltalk'; cr;
			nextPutAll: 'Metacello new'; cr;
			nextPutAll: '  baseline: ''GemStonePharo'';'; cr;
			nextPutAll: '  repository: ''tonel:///absolute/path/to/GemStone-Pharo-Bridge/src'';'; cr;
			nextPutAll: '  load: ''MagLev''.'; cr;
			nextPutAll: '```'; cr; cr;
			nextPutAll: 'Use `load: ''MagLev-Tools''` if you want interactive debugging tools. Use `load: ''Full''` if you also want the full developer/test stack.'; cr; cr;
			nextPutAll: '## Load From GitHub'; cr; cr;
			nextPutAll: '```smalltalk'; cr;
			nextPutAll: 'Metacello new'; cr;
			nextPutAll: '  baseline: ''GemStonePharo'';'; cr;
			nextPutAll: '  repository: ''github://unicompute/GemStone-Pharo-Bridge:maglev/src'';'; cr;
			nextPutAll: '  load: ''MagLev''.'; cr;
			nextPutAll: '```'; cr; cr;
			nextPutAll: 'Use `load: ''MagLev-Tools''` from the same repository if you want interactive debugging tools, or `load: ''Full''` if you want the MagLev-aware test packages as well.'; cr; cr;
			nextPutAll: '## Clean Switching'; cr; cr;
			nextPutAll: 'Use a fresh image or the clean-reload path each time. Do not incrementally load `Original` and then `MagLev` into the same already-mutated image.'; cr; cr;
			nextPutAll: 'Common wrapper entry points:'; cr;
			nextPutAll: '- `make original PHARO_IMAGE="..." PHARO_WORK_DIR="..."`'; cr;
			nextPutAll: '- `make original-tests PHARO_IMAGE="..." PHARO_WORK_DIR="..."`'; cr;
			nextPutAll: '- `make full PHARO_IMAGE="..." PHARO_WORK_DIR="..." GS_USER=... GS_PASS=... GS_NETLDI_HOST=... GS_NETLDI_NAME_OR_PORT=... GEMSTONE=...`'; cr; cr;
			nextPutAll: '## Does The Classic Session Example Still Work?'; cr; cr;
			nextPutAll: 'Yes.'; cr; cr;
			nextPutAll: '- `GbsSessionParameters>>login` still returns a `GbsSession`'; cr;
			nextPutAll: '- `GbsSession>>userGlobals` still exists'; cr;
			nextPutAll: '- `GbsSession>>commit` is still present as a compatibility alias for `commitTransaction`'; cr;
			nextPutAll: '- `GbsSession>>disconnect` still exists'; cr; cr;
			nextPutAll: 'This classic example still works on the MagLev branch:'; cr; cr;
			nextPutAll: '```smalltalk'; cr;
			nextPutAll: '| session dict |'; cr;
			nextPutAll: 'session := GbsSessionParameters new'; cr;
			nextPutAll: '            name: ''Simple Session'';'; cr;
			nextPutAll: '            gemStoneName: ''gs64stone'';'; cr;
			nextPutAll: '            username: ''DataCurator'';'; cr;
			nextPutAll: '            password: ''...'';'; cr;
			nextPutAll: '            login.'; cr; cr;
			nextPutAll: 'dict := Dictionary new.'; cr;
			nextPutAll: 'dict at: ''name'' put: ''Tariq''.'; cr;
			nextPutAll: 'dict at: ''amount'' put: 100.'; cr;
			nextPutAll: 'dict at: ''currency'' put: ''GBP''.'; cr; cr;
			nextPutAll: 'session userGlobals at: #MyTestDict put: dict.'; cr;
			nextPutAll: 'session commit.'; cr; cr;
			nextPutAll: 'session disconnect.'; cr;
			nextPutAll: '```'; cr; cr;
			nextPutAll: 'A better MagLev-oriented version for new code is:'; cr; cr;
			nextPutAll: '```smalltalk'; cr;
			nextPutAll: '| session payload |'; cr;
			nextPutAll: 'session := GbsSessionParameters new'; cr;
			nextPutAll: '    name: ''MagLev Session'';'; cr;
			nextPutAll: '    gemStoneName: ''gs64stone'';'; cr;
			nextPutAll: '    username: ''DataCurator'';'; cr;
			nextPutAll: '    password: ''...'';'; cr;
			nextPutAll: '    "Optional but clearer for explicit routing:"'; cr;
			nextPutAll: '    netldiHostOrIp: ''localhost'';'; cr;
			nextPutAll: '    netldiNameOrPort: ''50377'';'; cr;
			nextPutAll: '    login.'; cr; cr;
			nextPutAll: '['; cr;
			nextPutAll: '    payload := Dictionary new'; cr;
			nextPutAll: '        at: ''name'' put: ''Tariq'';'; cr;
			nextPutAll: '        at: ''amount'' put: 100;'; cr;
			nextPutAll: '        at: ''currency'' put: ''GBP'';'; cr;
			nextPutAll: '        yourself.'; cr; cr;
			nextPutAll: '    session bridgeRoot at: #MyTestDict put: payload.'; cr;
			nextPutAll: '    session commitTransactionOrSignalConflict'; cr;
			nextPutAll: '] ensure: ['; cr;
			nextPutAll: '    session disconnect'; cr;
			nextPutAll: '].'; cr;
			nextPutAll: '```'; cr; cr;
			nextPutAll: 'For new code, prefer `bridgeRoot` over direct `UserGlobals` writes, and prefer `commitTransactionOrSignalConflict` or `commitTransactionWithRetryCount:` over the older `commit` alias when you want explicit transaction behavior.'; cr ]
]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedReloadPolicyMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '# Reload Policy'; cr; cr;
			nextPutAll: 'Generated from `GemStonePharoContract` reload policy and lane contracts.'; cr; cr;
			nextPutAll: '## Purpose'; cr; cr;
			nextPutAll: 'The clean reload lane loads the helper package, hands bootstrap unload/cache-warm/load work to `GemStonePharoReloadBootstrapper`, runs architecture/ownership/no-compatibility/artifact checks through `GemStonePharoReloadRunner` and `GemStonePharoReloadGuards`, and can invoke `GemStonePharoVerificationRunner` in the same Smalltalk process when a verification lane is requested. Top-level `make verify` sequencing is owned by `GemStonePharoVerifyRunner`.'; cr; cr;
			nextPutAll: '## Environment'; cr; cr.
		self reloadEnvironmentVariableSpecs do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each first;
				nextPutAll: '`';
				cr;
				nextPutAll: '  ';
				nextPutAll: each second;
				cr ].
		stream cr; nextPutAll: '## Reload Modes'; cr; cr.
		self reloadCheckModeSpecs do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each first;
				nextPutAll: '`';
				cr;
				nextPutAll: '  ';
				nextPutAll: each second;
				cr ].
		stream cr; nextPutAll: '## Verification Lanes'; cr; cr.
		self verificationLaneSpecs do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each first;
				nextPutAll: '`';
				cr;
				nextPutAll: '  ';
				nextPutAll: each second;
				cr ] ]
]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedUserManualReferenceHtml [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '<!DOCTYPE html>'; cr;
			nextPutAll: '<html lang="en">'; cr;
			nextPutAll: '<head>'; cr;
			nextPutAll: '  <meta charset="utf-8">'; cr;
			nextPutAll: '  <title>GemStone-Pharo-Bridge Operator Reference</title>'; cr;
			nextPutAll: '  <style>'; cr;
			nextPutAll: '    body { font-family: Helvetica, Arial, sans-serif; margin: 2rem auto; max-width: 58rem; color: #17212b; line-height: 1.5; padding: 0 1.25rem; }'; cr;
			nextPutAll: '    h1, h2 { color: #102a43; }'; cr;
			nextPutAll: '    code { background: #eef2f6; padding: 0.1rem 0.3rem; border-radius: 0.2rem; }'; cr;
			nextPutAll: '    pre { background: #f8fafc; border: 1px solid #d9e2ec; border-radius: 0.4rem; padding: 0.9rem; overflow-x: auto; }'; cr;
			nextPutAll: '    ul { padding-left: 1.3rem; }'; cr;
			nextPutAll: '    .callout { background: #f8fafc; border-left: 0.35rem solid #486581; padding: 0.9rem 1rem; margin: 1rem 0; }'; cr;
			nextPutAll: '  </style>'; cr;
			nextPutAll: '</head>'; cr;
			nextPutAll: '<body>'; cr;
			nextPutAll: '  <h1>GemStone-Pharo-Bridge Operator Reference</h1>'; cr;
			nextPutAll: '  <p>Generated from <code>GemStonePharoContract</code>. This is the contract-driven steady-state reference for the active root API, load groups, verification lanes, and live GemStone environment.</p>'; cr;
			nextPutAll: '  <h2>Active Root API</h2>'; cr;
			nextPutAll: '  <div class="callout"><strong>Use <code>bridgeRoot</code>.</strong> The bridge steady state no longer carries the deleted legacy root aliases.</div>'; cr;
			nextPutAll: '  <h2>Active Load Groups</h2>'; cr;
			nextPutAll: '  <ul>'; cr.
		self groupMemberSpecs do: [ :each |
			stream
				nextPutAll: '    <li><code>';
				nextPutAll: each first;
				nextPutAll: '</code> -> ';
				nextPutAll: (String streamContents: [ :inner |
					each second
						do: [ :member |
							inner
								nextPutAll: '<code>';
								nextPutAll: member;
								nextPutAll: '</code>' ]
						separatedBy: [ inner nextPutAll: ', ' ] ]);
				nextPutAll: '</li>';
				cr ].
		stream
			nextPutAll: '  </ul>'; cr;
			nextPutAll: '  <h2>Load Matrix</h2>'; cr;
			nextPutAll: '  <p>A generated switch matrix for the layered model is available at <code>doc/LOAD-MATRIX.md</code>.</p>'; cr;
			nextPutAll: '  <h2>Using the MagLev Branch</h2>'; cr;
			nextPutAll: '  <p>See <code>doc/MAGLEV-BRANCH-USAGE.md</code> for supported Metacello load snippets from local disk and GitHub, clean-switch guidance, and the classic session example.</p>'; cr;
			nextPutAll: '  <h2>Verification Lanes</h2>'; cr;
			nextPutAll: '  <ul>'; cr.
		self verificationLaneSpecs do: [ :each |
			stream
				nextPutAll: '    <li><strong><code>';
				nextPutAll: each first;
				nextPutAll: '</code></strong>: ';
				nextPutAll: each second;
				nextPutAll: '</li>';
				cr ].
		stream
			nextPutAll: '  </ul>'; cr;
			nextPutAll: '  <h2>Expected Original-layer Test Exceptions</h2>'; cr;
			nextPutAll: '  <p><code>make original-drift</code> reports the original/base production layer as clean and currently accepts only these test-layer exceptions:</p>'; cr;
			nextPutAll: '  <ul>'; cr.
		self originalLayerExpectedExceptionSpecs do: [ :each |
			stream
				nextPutAll: '    <li><code>';
				nextPutAll: each first;
				nextPutAll: '</code>: ';
				nextPutAll: each second;
				nextPutAll: '</li>';
				cr ].
		stream
			nextPutAll: '  </ul>'; cr;
			nextPutAll: '  <h2>Recommended Entry Points</h2>'; cr;
			nextPutAll: '  <pre><code>make help'; cr;
			nextPutAll: 'make original-drift'; cr;
			nextPutAll: 'make core-only'; cr;
			nextPutAll: 'make original'; cr;
			nextPutAll: 'make original-tests'; cr;
			nextPutAll: 'make full'; cr;
			nextPutAll: 'make verify'; cr;
			nextPutAll: 'make artifact-freshness</code></pre>'; cr;
			nextPutAll: '  <p><code>make verify</code> is sequenced by <code>GemStonePharoVerifyRunner</code>; the live/preflight path inside <code>full</code> is handled by <code>GemStonePharoVerificationRunner</code>.</p>'; cr;
			nextPutAll: '  <h2>Live GemStone Environment</h2>'; cr;
			nextPutAll: '  <ul>'; cr.
		self livePreflightEnvironmentVariableSpecs do: [ :each |
			stream
				nextPutAll: '    <li><code>';
				nextPutAll: each first;
				nextPutAll: '</code>: ';
				nextPutAll: each second;
				nextPutAll: '</li>';
				cr ].
		stream
			nextPutAll: '  </ul>'; cr;
			nextPutAll: '  <pre><code>GS_USER=''DataCurator'' \'; cr;
			nextPutAll: 'GS_PASS=''...'' \'; cr;
			nextPutAll: 'GS_NETLDI_HOST=''localhost'' \'; cr;
			nextPutAll: 'GS_NETLDI_NAME_OR_PORT=''50377'' \'; cr;
			nextPutAll: 'GEMSTONE=''/Users/tariq/GemStone64Bit3.7.5-arm64.Darwin'' \'; cr;
			nextPutAll: 'make full</code></pre>'; cr;
			nextPutAll: '  <h2>No-compatibility Proof</h2>'; cr;
			nextPutAll: '  <p>The clean reload lane proves that deleted package, class, selector, and method-package ownership surface stays absent from the image and the active source roots.</p>'; cr;
			nextPutAll: '  <ul>'; cr;
			nextPutAll: '    <li>deleted package names stay absent</li>'; cr;
			nextPutAll: '    <li>deleted class names stay absent</li>'; cr;
			nextPutAll: '    <li>deleted selector surface stays absent</li>'; cr;
			nextPutAll: '    <li>deleted method-package ownership stays absent</li>'; cr;
			nextPutAll: '  </ul>'; cr;
			nextPutAll: '</body>'; cr;
			nextPutAll: '</html>'; cr ]
	]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedVerificationLanesMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '# Verification Lanes'; cr; cr;
			nextPutAll: 'Generated from `GemStonePharoContract` lane contracts.'; cr; cr.
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
				cr; cr ].
		stream
			nextPutAll: '## Expected Original-layer Test Exceptions'; cr; cr;
			nextPutAll: '`make original-drift` currently reports the original/base production layer as clean and accepts only these test-layer exceptions:'; cr.
		self originalLayerExpectedExceptionSpecs do: [ :each |
			stream
				nextPutAll: '- `';
				nextPutAll: each first;
				nextPutAll: '`';
				cr;
				nextPutAll: '  ';
				nextPutAll: each second;
				cr ] ]
]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedArchitectureBodyMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'This section is generated from `GemStonePharoContract`.'; cr; cr;
			nextPutAll: '## Design Goal'; cr; cr;
			nextPutAll: '- `56b6db3...` original production/test packages remain the base layer'; cr;
			nextPutAll: '- `Pharo <-> GemStone Smalltalk` is the primary layer'; cr;
			nextPutAll: '- MagLev/Ruby behavior is optional'; cr;
			nextPutAll: '- legacy alias surface stays absent from production'; cr; cr;
			nextPutAll: '## Package Layers'; cr; cr;
			nextPutAll: '- original/base production: `GemStone-GBS-Converted`, `GemStone-GBS-Tools`'; cr;
			nextPutAll: '- generic core runtime: `GemStone-GBS-Core`'; cr;
			nextPutAll: '- generic developer tooling: `GemStone-GBS-Tools`, `GemStone-GBS-Core-Tools`'; cr;
			nextPutAll: '- optional MagLev runtime: `GemStone-GBS-MagLev`'; cr;
			nextPutAll: '- optional MagLev developer tooling: `GemStone-GBS-MagLev-Tools`'; cr;
			nextPutAll: '- test layers: `GemStone-Pharo-Tests`, `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-MagLev-Tests`'; cr; cr;
			nextPutAll: '## Active Root API'; cr; cr.
		self activeRootApiSpecs do: [ :each |
			stream nextPutAll: '- `'; nextPutAll: each; nextPutAll: '`'; cr ].
		stream cr; nextPutAll: '## Verification Guards'; cr; cr.
		self boundaryGuardSpecs do: [ :each |
			stream nextPutAll: '- `'; nextPutAll: each first; nextPutAll: '`'; cr ].
		stream cr; nextPutAll: '## Expected Original-layer Test Exceptions'; cr; cr;
			nextPutAll: 'The original/base production layer is clean. `make original-drift` currently reports only these accepted test-layer exceptions:'; cr.
		self originalLayerExpectedExceptionSpecs do: [ :each |
			stream
				nextPutAll: '- `'; nextPutAll: each first; nextPutAll: '`'; cr;
				nextPutAll: '  '; nextPutAll: each second; cr ].
		stream cr; nextPutAll: '## Layered Load Matrix'; cr; cr;
			nextPutAll: '- [LOAD-MATRIX.md](./LOAD-MATRIX.md)'; cr;
			nextPutAll: '  generated group-by-group view of the base/original, generic core, and optional MagLev loading model'; cr.
		stream cr; nextPutAll: '## MagLev Usage Guide'; cr; cr;
			nextPutAll: '- [MAGLEV-BRANCH-USAGE.md](./MAGLEV-BRANCH-USAGE.md)'; cr;
			nextPutAll: '  generated guide for loading the MagLev branch from local disk or GitHub and for using the classic session API on the layered branch'; cr.
		stream cr; nextPutAll: '## Review Artifacts'; cr; cr;
			nextPutAll: '- [LOAD-MATRIX.md](./LOAD-MATRIX.md)'; cr;
			nextPutAll: '- [MAGLEV-BRANCH-USAGE.md](./MAGLEV-BRANCH-USAGE.md)'; cr;
			nextPutAll: '- [PACKAGE-GRAPH.md](./PACKAGE-GRAPH.md)'; cr;
			nextPutAll: '- [OWNERSHIP-CONTRACT.md](./OWNERSHIP-CONTRACT.md)'; cr;
			nextPutAll: '- [RELOAD-POLICY.md](./RELOAD-POLICY.md)'; cr;
			nextPutAll: '- [LIVE-PREFLIGHT-POLICY.md](./LIVE-PREFLIGHT-POLICY.md)'; cr ]
]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedReadmeBodyMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '## Quick Start'; cr; cr;
			nextPutAll: 'Load the MagLev production stack from a local checkout:'; cr; cr;
			nextPutAll: '```smalltalk'; cr;
			nextPutAll: 'Metacello new'; cr;
			nextPutAll: '  baseline: ''GemStonePharo'';'; cr;
			nextPutAll: '  repository: ''tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src'';'; cr;
			nextPutAll: '  load: ''MagLev''.'; cr;
			nextPutAll: '```'; cr; cr;
			nextPutAll: 'Load the same stack from GitHub:'; cr; cr;
			nextPutAll: '```smalltalk'; cr;
			nextPutAll: 'Metacello new'; cr;
			nextPutAll: '  baseline: ''GemStonePharo'';'; cr;
			nextPutAll: '  repository: ''github://unicompute/GemStone-Pharo-Bridge:maglev/src'';'; cr;
			nextPutAll: '  load: ''MagLev''.'; cr;
			nextPutAll: '```'; cr; cr;
			nextPutAll: 'Use `load: ''MagLev-Tools''` for interactive developer tooling, including'; cr;
			nextPutAll: 'the GemStone workspace, remote debugger, inspectors, transcript, ObjectLog,'; cr;
			nextPutAll: 'and MagLev-aware method browsers. Use `load: ''Full''` when you also want'; cr;
			nextPutAll: 'the developer/test stack, including the MagLev-aware test packages.'; cr; cr;
			nextPutAll: '## Load Groups'; cr; cr;
			nextPutAll: '- `Original`: original/base production packages only'; cr;
			nextPutAll: '- `Original-Tests`: original/base production plus original/base tests'; cr;
			nextPutAll: '- `Core`, `Core-Tools`, `Core-Tests`: original/base plus the generic Smalltalk overlay'; cr;
			nextPutAll: '- `MagLev`: production MagLev runtime, excluding debugger/tool UI packages'; cr;
			nextPutAll: '- `MagLev-Tools`: MagLev runtime plus workspace, debugger, inspectors, ObjectLog, and developer UI tools'; cr;
			nextPutAll: '- `Full`: full developer stack, including all tests'; cr; cr;
			nextPutAll: 'The active root API is `bridgeRoot`, `#GbsBridgeRoot`, and'; cr;
			nextPutAll: '`GbsBridgeRootFacade`.'; cr; cr;
			nextPutAll: 'See [doc/LOAD-MATRIX.md](doc/LOAD-MATRIX.md) for exact group membership and'; cr;
			nextPutAll: '[doc/PACKAGE-GRAPH.md](doc/PACKAGE-GRAPH.md) for package ownership.'; cr; cr;
			nextPutAll: '## Clean Switching'; cr; cr;
			nextPutAll: 'Use a fresh image or the clean-reload scripts when switching between Original,'; cr;
			nextPutAll: 'Core, and MagLev loads. Do not incrementally load `Original` and then `MagLev`'; cr;
			nextPutAll: 'into the same already-mutated image.'; cr; cr;
			nextPutAll: 'Common entry points:'; cr; cr;
			nextPutAll: '```bash'; cr;
			nextPutAll: 'make original PHARO_IMAGE="..." PHARO_WORK_DIR="..."'; cr;
			nextPutAll: 'make original-tests PHARO_IMAGE="..." PHARO_WORK_DIR="..."'; cr;
			nextPutAll: 'make full PHARO_IMAGE="..." PHARO_WORK_DIR="..." GS_USER=... GS_PASS=... GS_NETLDI_HOST=... GS_NETLDI_NAME_OR_PORT=... GEMSTONE=...'; cr;
			nextPutAll: 'make verify PHARO_IMAGE="..." PHARO_WORK_DIR="..."'; cr;
			nextPutAll: '```'; cr; cr;
			nextPutAll: '## Session Examples'; cr; cr;
			nextPutAll: 'The classic GBS session style still works:'; cr; cr;
			nextPutAll: '```smalltalk'; cr;
			nextPutAll: '| session dict |'; cr;
			nextPutAll: 'session := GbsSessionParameters new'; cr;
			nextPutAll: '            name: ''Simple Session'';'; cr;
			nextPutAll: '            gemStoneName: ''gs64stone'';'; cr;
			nextPutAll: '            username: ''DataCurator'';'; cr;
			nextPutAll: '            password: ''...'';'; cr;
			nextPutAll: '            login.'; cr; cr;
			nextPutAll: 'dict := Dictionary new.'; cr;
			nextPutAll: 'dict at: ''name'' put: ''Tariq''.'; cr;
			nextPutAll: 'dict at: ''amount'' put: 100.'; cr;
			nextPutAll: 'dict at: ''currency'' put: ''GBP''.'; cr; cr;
			nextPutAll: 'session userGlobals at: #MyTestDict put: dict.'; cr;
			nextPutAll: 'session commit.'; cr; cr;
			nextPutAll: 'session disconnect.'; cr;
			nextPutAll: '```'; cr; cr;
			nextPutAll: 'For new code, prefer the bridge root and explicit transaction behavior:'; cr; cr;
			nextPutAll: '```smalltalk'; cr;
			nextPutAll: '| session payload |'; cr;
			nextPutAll: 'session := GbsSessionParameters new'; cr;
			nextPutAll: '    name: ''MagLev Session'';'; cr;
			nextPutAll: '    gemStoneName: ''gs64stone'';'; cr;
			nextPutAll: '    username: ''DataCurator'';'; cr;
			nextPutAll: '    password: ''...'';'; cr;
			nextPutAll: '    netldiHostOrIp: ''localhost'';'; cr;
			nextPutAll: '    netldiNameOrPort: ''50377'';'; cr;
			nextPutAll: '    login.'; cr; cr;
			nextPutAll: '['; cr;
			nextPutAll: '    payload := Dictionary new'; cr;
			nextPutAll: '        at: ''name'' put: ''Tariq'';'; cr;
			nextPutAll: '        at: ''amount'' put: 100;'; cr;
			nextPutAll: '        at: ''currency'' put: ''GBP'';'; cr;
			nextPutAll: '        yourself.'; cr; cr;
			nextPutAll: '    session bridgeRoot at: #MyTestDict put: payload.'; cr;
			nextPutAll: '    session commitTransactionOrSignalConflict'; cr;
			nextPutAll: '] ensure: ['; cr;
			nextPutAll: '    session disconnect'; cr;
			nextPutAll: '].'; cr;
			nextPutAll: '```'; cr; cr;
			nextPutAll: 'Prefer `commitTransactionOrSignalConflict` or'; cr;
			nextPutAll: '`commitTransactionWithRetryCount:` over the older `commit` alias when you want'; cr;
			nextPutAll: 'explicit transaction behavior.'; cr; cr;
			nextPutAll: '## Verification'; cr; cr;
			nextPutAll: '- `make core-only`: verify the Smalltalk core without optional MagLev packages'; cr;
			nextPutAll: '- `make original`: prove the original/base production layer reloads cleanly'; cr;
			nextPutAll: '- `make original-tests`: verify original/base production plus original/base tests'; cr;
			nextPutAll: '- `make full`: run the full developer load and live GemStone lane when credentials are present'; cr;
			nextPutAll: '- `make verify`: run all maintained lanes and artifact freshness checks'; cr; cr;
			nextPutAll: 'The live lanes use `GS_USER`, `GS_PASS`, `GS_STONE`, `GS_SERVICE`,'; cr;
			nextPutAll: '`GS_NETLDI_HOST`, `GS_NETLDI_NAME_OR_PORT`, and `GEMSTONE` when supplied.'; cr; cr;
			nextPutAll: '## More Documentation'; cr; cr;
			nextPutAll: '- [doc/MAGLEV-BRANCH-USAGE.md](doc/MAGLEV-BRANCH-USAGE.md): practical MagLev load and session examples'; cr;
			nextPutAll: '- [doc/LOAD-MATRIX.md](doc/LOAD-MATRIX.md): load groups and switch recipes'; cr;
			nextPutAll: '- [doc/VERIFICATION-LANES.md](doc/VERIFICATION-LANES.md): maintained verification lanes'; cr;
			nextPutAll: '- [doc/ARCHITECTURE.md](doc/ARCHITECTURE.md): architecture notes'; cr;
			nextPutAll: '- [doc/OWNERSHIP-CONTRACT.md](doc/OWNERSHIP-CONTRACT.md): package and selector ownership contract'; cr;
			nextPutAll: '- [doc/RELOAD-POLICY.md](doc/RELOAD-POLICY.md): reload policy and generated-artifact expectations'; cr ]
]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedTestingBodyMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'This section is generated from `GemStonePharoContract`.'; cr; cr;
			nextPutAll: '## Verification Entry Points'; cr; cr.
		self verificationLaneSpecs do: [ :each |
			stream
				nextPutAll: '- `'; nextPutAll: each first; nextPutAll: '`'; cr;
				nextPutAll: '  '; nextPutAll: each second; cr;
				nextPutAll: '  load group: `'; nextPutAll: each third; nextPutAll: '`'; cr;
				nextPutAll: '  targets: ';
				nextPutAll: (String streamContents: [ :inner |
					each fourth
						do: [ :target | inner nextPutAll: '`'; nextPutAll: target; nextPutAll: '`' ]
						separatedBy: [ inner nextPutAll: ', ' ] ]);
				cr;
				nextPutAll: '  success markers: ';
				nextPutAll: (String streamContents: [ :inner |
					each fifth
						do: [ :marker | inner nextPutAll: '`'; nextPutAll: marker; nextPutAll: '`' ]
						separatedBy: [ inner nextPutAll: ', ' ] ]);
				cr ].
		stream cr; nextPutAll: '## Expected Original-layer Test Exceptions'; cr; cr;
			nextPutAll: '`make original-drift` currently reports the original/base production layer as clean and accepts only these test-layer exceptions:'; cr.
		self originalLayerExpectedExceptionSpecs do: [ :each |
			stream
				nextPutAll: '- `'; nextPutAll: each first; nextPutAll: '`'; cr;
				nextPutAll: '  '; nextPutAll: each second; cr ].
		stream cr; nextPutAll: '## Wrapper Entry Points'; cr; cr;
			nextPutAll: '```bash'; cr;
			nextPutAll: 'make help'; cr;
			nextPutAll: 'make core-only'; cr;
			nextPutAll: 'make original-drift'; cr;
			nextPutAll: 'make original'; cr;
			nextPutAll: 'make original-tests'; cr;
			nextPutAll: 'make full'; cr;
			nextPutAll: 'make verify'; cr;
			nextPutAll: 'make graph-artifacts'; cr;
			nextPutAll: 'make artifact-freshness'; cr;
			nextPutAll: '```'; cr; cr;
			nextPutAll: 'Top-level verify sequencing is owned by `GemStonePharoVerifyRunner`. Requested unit/live/preflight orchestration within the full lane is owned by `GemStonePharoVerificationRunner` and can run in the same process as the clean reload proof.'; cr; cr;
			nextPutAll: 'Accepted environment variables:'; cr.
		(self reloadEnvironmentVariableSpecs , self livePreflightEnvironmentVariableSpecs)
			do: [ :each |
				stream
					nextPutAll: '- `'; nextPutAll: each first; nextPutAll: '`'; cr;
					nextPutAll: '  '; nextPutAll: each second; cr ].
		stream cr; nextPutAll: '## Generated Contract Artifacts'; cr; cr;
			nextPutAll: '- [LOAD-MATRIX.md](./LOAD-MATRIX.md)'; cr;
			nextPutAll: '- [MAGLEV-BRANCH-USAGE.md](./MAGLEV-BRANCH-USAGE.md)'; cr;
			nextPutAll: '- [PACKAGE-GRAPH.md](./PACKAGE-GRAPH.md)'; cr;
			nextPutAll: '- [PACKAGE-GRAPH.dot](./PACKAGE-GRAPH.dot)'; cr;
			nextPutAll: '- [PACKAGE-GRAPH.svg](./PACKAGE-GRAPH.svg)'; cr;
			nextPutAll: '- [LIVE-PREFLIGHT-POLICY.md](./LIVE-PREFLIGHT-POLICY.md)'; cr;
			nextPutAll: '- [RELOAD-POLICY.md](./RELOAD-POLICY.md)'; cr;
			nextPutAll: '- [USER-MANUAL-REFERENCE.html](./USER-MANUAL-REFERENCE.html)'; cr;
			nextPutAll: '- [OWNERSHIP-CONTRACT.md](./OWNERSHIP-CONTRACT.md)'; cr;
			nextPutAll: '- [VERIFICATION-LANES.md](./VERIFICATION-LANES.md)'; cr.
		stream cr; nextPutAll: '## Machine-readable Summaries'; cr; cr;
			nextPutAll: '- set `GBS_JSON_SUMMARY=1` to emit JSON summaries from the lane scripts and `make verify`'; cr;
			nextPutAll: '- set `GBS_JSON_SUMMARY_DIR=/path/to/output` to persist per-lane JSON files'; cr; cr;
			nextPutAll: '## Steady-state Guards'; cr; cr.
		self boundaryGuardSpecs do: [ :each |
			stream
				nextPutAll: '- `'; nextPutAll: each first; nextPutAll: '`'; cr;
				nextPutAll: '  '; nextPutAll: each second; cr ].
		stream cr; nextPutAll: 'The active root API throughout the test and reload lanes is `bridgeRoot`.'; cr ]
]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedUserManualOverviewHtml [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '    <p>'; cr;
			nextPutAll: '      GemStone-Pharo-Bridge gives Pharo a user-facing toolset for logging into GemStone and working with'; cr;
			nextPutAll: '      GemStone objects and code from a Pharo UI. The codebase is split into a Smalltalk-first core'; cr;
			nextPutAll: '      and optional MagLev/Ruby extension packages.'; cr;
			nextPutAll: '    </p>'; cr;
			nextPutAll: '    <table>'; cr;
			nextPutAll: '      <thead>'; cr;
			nextPutAll: '        <tr><th>Load group</th><th>What it contains</th><th>Typical use</th></tr>'; cr;
			nextPutAll: '      </thead>'; cr;
			nextPutAll: '      <tbody>'; cr.
		#('Original' 'Original-Tests' 'Core' 'Core-Tests' 'MagLev' 'Tests' 'default') do: [ :groupName |
			| members description |
			members := (self groupMemberSpecs detect: [ :each | each first = groupName ]) second.
			description := self groupDescriptionSpecs at: groupName ifAbsent: [ 'load group' ].
			stream
				nextPutAll: '        <tr>'; cr;
				nextPutAll: '          <td><code>'; nextPutAll: groupName; nextPutAll: '</code></td>'; cr;
				nextPutAll: '          <td>';
				nextPutAll: (String streamContents: [ :inner |
					members
						do: [ :member | inner nextPutAll: '<code>'; nextPutAll: member; nextPutAll: '</code>' ]
						separatedBy: [ inner nextPutAll: ', ' ] ]);
				nextPutAll: '</td>'; cr;
				nextPutAll: '          <td>'; nextPutAll: description; nextPutAll: '</td>'; cr;
				nextPutAll: '        </tr>'; cr ].
		stream
			nextPutAll: '      </tbody>'; cr;
			nextPutAll: '    </table>'; cr;
			nextPutAll: '    <p>A generated switch matrix is also available at <code>doc/LOAD-MATRIX.md</code> for the base/original, core, and MagLev load combinations.</p>'; cr;
			nextPutAll: '    <p>For the practical loading and usage guide, including local disk and GitHub Metacello snippets plus the classic session example, see <code>doc/MAGLEV-BRANCH-USAGE.md</code>.</p>'; cr;
			nextPutAll: '    <p>The active core root API is <code>bridgeRoot</code>, backed by <code>#GbsBridgeRoot</code> and <code>GbsBridgeRootFacade</code>.</p>'; cr ]
]

{ #category : 'contracts' }
GemStonePharoDocRenderer >> generatedUserManualTestingHtml [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '    <h3>Steady-state verification lanes</h3>'; cr;
			nextPutAll: '    <p>The current bridge keeps a small steady-state verification surface:</p>'; cr;
			nextPutAll: '    <ul>'; cr.
		self verificationLaneSpecs do: [ :each |
			stream
				nextPutAll: '      <li><strong><code>';
				nextPutAll: each first;
				nextPutAll: '</code></strong>: ';
				nextPutAll: each second;
				nextPutAll: '</li>'; cr ].
		stream
			nextPutAll: '    </ul>'; cr;
			nextPutAll: '    <h3>Expected Original-layer Test Exceptions</h3>'; cr;
			nextPutAll: '    <p><code>make original-drift</code> reports the original/base production layer as clean and currently accepts only these test-layer exceptions:</p>'; cr;
			nextPutAll: '    <ul>'; cr.
		self originalLayerExpectedExceptionSpecs do: [ :each |
			stream
				nextPutAll: '      <li><code>';
				nextPutAll: each first;
				nextPutAll: '</code>: ';
				nextPutAll: each second;
				nextPutAll: '</li>'; cr ].
		stream
			nextPutAll: '    </ul>'; cr;
			nextPutAll: '    <h3>Generated operator reference</h3>'; cr;
			nextPutAll: '    <p>'; cr;
			nextPutAll: '      The contract generates a human-facing steady-state operator reference at'; cr;
			nextPutAll: '      <code>doc/USER-MANUAL-REFERENCE.html</code>. Use that file as the authoritative quick reference for'; cr;
			nextPutAll: '      active load groups, verification lanes, live GemStone environment variables, the'; cr;
			nextPutAll: '      <code>bridgeRoot</code> API, and the no-compatibility proof.'; cr;
			nextPutAll: '    </p>'; cr;
			nextPutAll: '    <p>A generated layered switch matrix is available at <code>doc/LOAD-MATRIX.md</code>.</p>'; cr;
			nextPutAll: '    <h3>Recommended entry point</h3>'; cr;
			nextPutAll: '    <pre><code>make help'; cr;
			nextPutAll: 'make original-drift'; cr;
			nextPutAll: 'make core-only'; cr;
			nextPutAll: 'make original'; cr;
			nextPutAll: 'make original-tests'; cr;
			nextPutAll: 'make full'; cr;
			nextPutAll: 'make verify'; cr;
			nextPutAll: 'make artifact-freshness</code></pre>'; cr;
			nextPutAll: '    <h3>Known-good live example</h3>'; cr;
			nextPutAll: '    <pre><code>GS_USER=''DataCurator'' \'; cr;
			nextPutAll: 'GS_PASS=''...'' \'; cr;
			nextPutAll: 'GS_NETLDI_HOST=''localhost'' \'; cr;
			nextPutAll: 'GS_NETLDI_NAME_OR_PORT=''50377'' \'; cr;
			nextPutAll: 'GEMSTONE=''/Users/tariq/GemStone64Bit3.7.5-arm64.Darwin'' \'; cr;
			nextPutAll: 'make full</code></pre>'; cr;
			nextPutAll: '    <h3>No-compatibility proof</h3>'; cr;
			nextPutAll: '    <p>'; cr;
			nextPutAll: '      The clean reload lane proves that deleted legacy package, class, selector, and method-package'; cr;
			nextPutAll: '      ownership surface stays absent from the image and the active source roots. If that proof fails,'; cr;
			nextPutAll: '      the reload lane reports <code>NO_COMPATIBILITY_PROOF_FAILED</code>.'; cr;
			nextPutAll: '    </p>'; cr ]
]
