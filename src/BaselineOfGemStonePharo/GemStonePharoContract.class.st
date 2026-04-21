Class {
	#name : 'GemStonePharoContract',
	#superclass : 'Object',
	#category : 'BaselineOfGemStonePharo',
	#package : 'BaselineOfGemStonePharo'
}

{ #category : 'contracts' }
GemStonePharoContract >> coreOnlyLoadedPackageNames [
	^ (self groupMemberSpecs
		detect: [ :each | each first = 'Core-Tests' ]
		ifNone: [ self error: 'Missing Core-Tests group specification' ]) second
]

{ #category : 'contracts' }
GemStonePharoContract >> coreOnlyClassChecks [
	| loadedPackages checks seen |
	loadedPackages := self coreOnlyLoadedPackageNames asSet.
	checks := OrderedCollection new.
	seen := Set new.
	self packageOwnershipClassSpecs do: [ :spec |
		(seen includes: spec first) ifFalse: [
			checks add: { spec first. (loadedPackages includes: spec second) }.
			seen add: spec first ] ].
	^ checks asArray
]

{ #category : 'contracts' }
GemStonePharoContract >> coreOnlyPackageChecks [
	| loadedPackages checks |
	loadedPackages := self coreOnlyLoadedPackageNames asSet.
	checks := OrderedCollection new.
	self packageRequirementSpecs do: [ :spec |
		checks add: { spec first. (loadedPackages includes: spec first) } ].
	^ checks asArray
]

{ #category : 'contracts' }
GemStonePharoContract >> coreOnlySelectorChecks [
	^ self coreOnlyDerivedSelectorChecks
]

{ #category : 'contracts' }
GemStonePharoContract >> coreOnlyDerivedSelectorChecks [
	| loadedPackages checks seen classChecksByName |
	loadedPackages := self coreOnlyLoadedPackageNames asSet.
	checks := OrderedCollection new.
	seen := Set new.
	classChecksByName := Dictionary new.
	self coreOnlyClassChecks do: [ :each |
		classChecksByName at: each first put: each second ].
	self packageOwnershipSelectorSpecs do: [ :spec |
		| key shouldExist |
		key := { spec first. spec third }.
		shouldExist := loadedPackages includes: spec fourth.
		(seen includes: key) ifFalse: [
			((classChecksByName at: spec first ifAbsent: [ true ]) or: [ shouldExist ])
				ifTrue: [ checks add: { spec first. spec third. shouldExist } ].
			seen add: key ] ].
	^ checks asArray
]

{ #category : 'contracts' }
GemStonePharoContract >> forbiddenPackageRequirementSpecs [
	^ {
		{ 'GemStone-GBS-Tools'. #('GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools') }.
		{ 'GemStone-Pharo-Core-Tests'. #('GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools') }.
		{ 'GemStone-GBS-Converted'. #('GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools' 'GemStone-GBS-Tools') } }
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedContractArtifactSpecs [
	^ {
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
GemStonePharoContract >> generatedDocumentationSectionSpecs [
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
GemStonePharoContract >> generatedDocumentationSectionPaths [
	^ #(
		'README.md'
		'doc/TESTING.md'
		'doc/ARCHITECTURE.md'
		'doc/GemStone-Pharo-Bridge-User-Manual.html')
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedPackageGraphDot [
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
GemStonePharoContract >> generatedPackageGraphMarkdown [
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
GemStonePharoContract >> generatedPackageGraphSvg [
	| layoutByPackage colorByPackage boxWidth boxHeight |
	layoutByPackage := Dictionary newFromPairs: {
		'GemStone-GBS-Converted'. (40@40).
		'GemStone-GBS-Tools'. (40@220).
		'GemStone-GBS-MagLev'. (430@40).
		'GemStone-GBS-MagLev-Tools'. (430@220).
		'GemStone-Pharo-Core-Tests'. (820@40).
		'GemStone-Pharo-Tests'. (820@220) }.
	colorByPackage := Dictionary newFromPairs: {
		'GemStone-GBS-Converted'. '#d8ecff'.
		'GemStone-GBS-Tools'. '#d8ecff'.
		'GemStone-GBS-MagLev'. '#ffe6c7'.
		'GemStone-GBS-MagLev-Tools'. '#ffe6c7'.
		'GemStone-Pharo-Core-Tests'. '#e4f7df'.
		'GemStone-Pharo-Tests'. '#f0e0ff' }.
	boxWidth := 300.
	boxHeight := 56.
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '<svg xmlns="http://www.w3.org/2000/svg" width="1160" height="330" viewBox="0 0 1160 330">'; cr;
			nextPutAll: '  <defs>'; cr;
			nextPutAll: '    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse">'; cr;
			nextPutAll: '      <path d="M 0 0 L 10 5 L 0 10 z" fill="#5a6470"/>'; cr;
			nextPutAll: '    </marker>'; cr;
			nextPutAll: '  </defs>'; cr;
			nextPutAll: '  <rect width="1160" height="330" fill="#ffffff"/>'; cr;
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
GemStonePharoContract >> generatedOwnershipContractMarkdown [
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
GemStonePharoContract >> generatedLivePreflightPolicyMarkdown [
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
GemStonePharoContract >> generatedReloadPolicyMarkdown [
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
GemStonePharoContract >> generatedUserManualReferenceHtml [
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
			nextPutAll: '  <h2>Recommended Entry Points</h2>'; cr;
			nextPutAll: '  <pre><code>make help'; cr;
			nextPutAll: 'make core-only'; cr;
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
			nextPutAll: 'GS_PASS=''swordfish'' \'; cr;
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
GemStonePharoContract >> generatedVerificationLanesMarkdown [
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
				cr; cr ] ]
]

{ #category : 'contracts' }
GemStonePharoContract >> groupMemberSpecs [
	^ {
		{ 'Core'. #('GemStone-GBS-Converted') }.
		{ 'Core-Only'. #('GemStone-GBS-Converted') }.
		{ 'Core-Tools'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools') }.
		{ 'Core-Tests'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools' 'GemStone-Pharo-Core-Tests') }.
		{ 'MagLev-Core'. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev') }.
		{ 'MagLev-Tools'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools' 'GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools') }.
		{ 'MagLev'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools' 'GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools') }.
		{ 'Tools'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools') }.
		{ 'All-Tests'. #('GemStone-Pharo-Core-Tests' 'GemStone-Pharo-Tests') }.
		{ 'Tests'. #('GemStone-Pharo-Core-Tests' 'GemStone-Pharo-Tests') }.
		{ 'Full'. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev' 'GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools' 'GemStone-Pharo-Core-Tests' 'GemStone-Pharo-Tests') }.
		{ 'default'. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev' 'GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools' 'GemStone-Pharo-Core-Tests' 'GemStone-Pharo-Tests') } }
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilityClassNames [
	^ #(
		GbsPersistentRootFacade
		GbsRootCompatibilityTest)
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilityMethodPackageNames [
	^ #(
		'GemStone-GBS-Compatibility'
		'GemStone-Pharo-Compatibility-Tests')
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilityPackageNames [
	^ #(
		'GemStone-GBS-Compatibility'
		'GemStone-Pharo-Compatibility-Tests')
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilitySecondarySourceScanFiles [
	^ #(
		'.github/workflows/verify.yml'
		'README.md'
		'doc/ARCHITECTURE.md'
		'doc/GemStone-Pharo-Bridge-User-Manual.html'
		'doc/LIVE-PREFLIGHT-POLICY.md'
		'doc/PACKAGE-GRAPH.dot'
		'doc/PACKAGE-GRAPH.md'
		'doc/PACKAGE-GRAPH.svg'
		'doc/RELOAD-POLICY.md'
		'doc/TESTING.md'
		'doc/USER-MANUAL-REFERENCE.html'
		'doc/VERIFICATION-LANES.md'
		'Makefile'
		'scripts/lane_common.sh'
		'scripts/check_bootstrap_smoke_group.st'
		'scripts/generate_contract_artifacts.st'
		'scripts/micro_bootstrap_reload.st'
		'scripts/probe_live_login.st'
		'scripts/run_all_package_regressions.st'
		'scripts/run_bootstrap_smoke.sh'
		'scripts/run_clean_reload_and_regressions.sh'
		'scripts/run_core_only_clean_reload.sh'
		'scripts/run_generate_contract_artifacts.sh'
		'scripts/run_live_preflight.sh'
		'scripts/run_live_preflight_via_runner.st'
		'scripts/render_lane_json_summaries.sh'
		'scripts/test_render_lane_json_summaries.sh'
		'scripts/run_verify.sh'
		'scripts/run_verify_via_runner.st'
		'scripts/run_verify_contract_artifacts.sh')
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilitySecondarySourceScanSnippets [
	^ (self noCompatibilityPackageNames
		, (self noCompatibilityClassNames collect: #asString)
		, #('persistentRoot' 'rootAt:' 'GbsPersistentRootFacade')) asSet asSortedCollection asArray
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilitySourceScanRoots [
	^ #(
		'src/GemStone-GBS-Converted'
		'src/GemStone-GBS-Tools'
		'src/GemStone-GBS-MagLev'
		'src/GemStone-GBS-MagLev-Tools')
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilitySelectorChecks [
	^ {
		{ #GbsSession. #instance. #commit }.
		{ #GbsSession. #instance. #persistentRoot }.
		{ #GbsSession. #instance. #root }.
		{ #GbsSession. #instance. #rootAt: }.
		{ #GbsSession. #instance. #rootAt:ifAbsent: }.
		{ #GbsSession. #instance. #rootAt:put: }.
		{ #GbsSmalltalkFacade. #instance. #persistentRoot }.
		{ #GbsSmalltalkFacade. #instance. #root }.
		{ #GbsMaglevFacade. #instance. #persistentRoot }.
		{ #GbsMaglevFacade. #instance. #root }.
		{ #GBSM. #class. #persistentRoot }.
		{ #GBSM. #class. #root }.
		{ #GBSM. #class. #rootAt: }.
		{ #GBSM. #class. #rootAt:ifAbsent: }.
		{ #GBSM. #class. #rootAt:put: } }
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilitySourceScanSnippets [
	| selectorSnippets |
	selectorSnippets := self noCompatibilitySelectorChecks collect: [ :spec |
		self noCompatibilitySourceSnippetForBehavior: spec first side: spec second selector: spec third ].
	^ (self noCompatibilityPackageNames
		, (self noCompatibilityClassNames collect: #asString)
		, selectorSnippets) asSet asSortedCollection asArray
]

{ #category : 'contracts' }
GemStonePharoContract >> noCompatibilitySourceSnippetForBehavior: classSymbol side: side selector: selector [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: classSymbol asString;
			nextPutAll: (side = #class
				ifTrue: [ ' class >> ' ]
				ifFalse: [ ' >> ' ]);
			nextPutAll: selector asString;
			nextPutAll: ' [' ]
]

{ #category : 'contracts' }
GemStonePharoContract >> regressionIntegrationProtocols [
	^ #('integration tests')
]

{ #category : 'contracts' }
GemStonePharoContract >> regressionLaneSpecNamed: aString [
	^ self regressionLaneSpecs
		detect: [ :each | each first = aString ]
		ifNone: [ self regressionLaneSpecs first ]
]

{ #category : 'contracts' }
GemStonePharoContract >> regressionLaneSpecs [
	^ {
		{ 'all'. 'BRIDGE_REGRESSION'. #all. false }.
		{ 'unit'. 'BRIDGE_UNIT_REGRESSION'. #excludeIntegration. false }.
		{ 'live'. 'BRIDGE_LIVE_REGRESSION'. #onlyIntegration. true } }
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipAllowedPackagesByFamily [
	^ Dictionary newFromPairs: {
		#coreTestsOnly. #('GemStone-Pharo-Core-Tests').
		#convertedOnly. #('GemStone-GBS-Converted').
		#convertedWithMaglev. #('GemStone-GBS-Converted' 'GemStone-GBS-MagLev').
		#maglevOnly. #('GemStone-GBS-MagLev').
		#maglevToolsOnly. #('GemStone-GBS-MagLev-Tools').
		#toolsOnly. #('GemStone-GBS-Tools').
		#toolsWithMaglevTools. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev-Tools') }
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipBehaviorFamilySpecs [
	^ self packageOwnershipInstanceBehaviorFamilySpecs
		, self packageOwnershipDerivedClassSideBehaviorFamilySpecs
		, self packageOwnershipExplicitBehaviorFamilySpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipDerivedClassSideBehaviorFamilySpecs [
	^ self packageOwnershipInstanceBehaviorFamilySpecs collect: [ :spec |
		{ spec first. #class. spec third } ]
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipExplicitBehaviorFamilySpecs [
	^ {
		{ #GBSM. #class. #convertedWithMaglev }.
		{ #GbsPlaygroundActions. #class. #toolsWithMaglevTools } }
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipInstanceBehaviorFamilySpecs [
	^ {
		{ #GbsBridgeRootFacade. #instance. #convertedOnly }.
		{ #GbsBrowser. #instance. #toolsWithMaglevTools }.
		{ #GbsClassicLauncher. #instance. #toolsWithMaglevTools }.
		{ #GbsFinalizerRegistrySessionStateSlot. #instance. #maglevOnly }.
		{ #GbsInspector. #instance. #toolsWithMaglevTools }.
		{ #GbsMaglevFacade. #instance. #maglevOnly }.
		{ #GbsMaglevRuntimeProxy. #instance. #maglevOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #toolsWithMaglevTools }.
		{ #GbsNamespaceScopedMethodQuery. #instance. #convertedOnly }.
		{ #GbsNamespacesPresenter. #instance. #maglevToolsOnly }.
		{ #GbsObjectSpaceDiagnosticsFacade. #instance. #convertedWithMaglev }.
		{ #GbsObjectSpaceFacade. #instance. #convertedWithMaglev }.
		{ #GbsObjectLogEntry. #instance. #maglevOnly }.
		{ #GbsObjectLogFacade. #instance. #maglevOnly }.
		{ #GbsRemoteAutoloadMirror. #instance. #maglevOnly }.
		{ #GbsRemoteClassMirror. #instance. #convertedOnly }.
		{ #GbsRemoteConstantMirror. #instance. #convertedWithMaglev }.
		{ #GbsRemoteDebugger. #instance. #toolsWithMaglevTools }.
		{ #GbsRemoteMethodMirror. #instance. #convertedOnly }.
		{ #GbsRemoteMethodObject. #instance. #convertedWithMaglev }.
		{ #GbsRemoteNamespaceMirror. #instance. #convertedWithMaglev }.
		{ #GbsRepositoryFacade. #instance. #convertedOnly }.
		{ #GbsRepositoryRootFacade. #instance. #convertedOnly }.
		{ #GbsRubyRuntimeFacade. #instance. #maglevOnly }.
		{ #GbsSession. #instance. #convertedWithMaglev }.
		{ #GbsSmalltalkFacade. #instance. #convertedWithMaglev }.
		{ #GbxActivationTest. #instance. #coreTestsOnly }.
		{ #GciErrorTest. #instance. #coreTestsOnly }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #toolsWithMaglevTools }.
		{ #GbsSymbolListBrowserPresenter. #instance. #toolsWithMaglevTools }.
		{ #GbsWorkspace. #instance. #toolsWithMaglevTools }.
		{ #GbxDebuggerService. #instance. #toolsWithMaglevTools }.
		{ #GbxTrippy. #instance. #toolsWithMaglevTools } }
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipBehaviorSpecs [
	| packagesByFamily |
	packagesByFamily := self packageOwnershipAllowedPackagesByFamily.
	^ self packageOwnershipBehaviorFamilySpecs collect: [ :spec |
		{ spec first. spec second. (packagesByFamily at: spec third) } ]
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipClassSpecs [
	^ self packageOwnershipDerivedClassSpecs , self packageOwnershipExplicitClassSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipDerivedClassSpecs [
	| packagesByFamily primaryClassPackagesByFamily |
	packagesByFamily := self packageOwnershipAllowedPackagesByFamily.
	primaryClassPackagesByFamily := self packageOwnershipPrimaryClassPackagesByFamily.
	^ (self packageOwnershipBehaviorFamilySpecs
		select: [ :spec | spec second = #instance ])
		collect: [ :spec |
			| allowedPackages expectedPackage |
			allowedPackages := packagesByFamily at: spec third.
			expectedPackage := allowedPackages size = 1
				ifTrue: [ allowedPackages first ]
				ifFalse: [ primaryClassPackagesByFamily at: spec third ifAbsent: [
					self error: 'Missing primary class package for ownership family: ', spec third asString ] ].
			{ spec first. expectedPackage } ]
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipExplicitClassSpecs [
	| packagesByFamily |
	packagesByFamily := self packageOwnershipAllowedPackagesByFamily.
	^ self packageOwnershipExplicitClassFamilySpecs collect: [ :spec |
		| allowedPackages |
		allowedPackages := packagesByFamily at: spec second.
		allowedPackages size = 1 ifFalse: [
			self error: 'Class ownership family must resolve to a single package: ', spec second asString ].
		{ spec first. allowedPackages first } ]
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipExplicitClassFamilySpecs [
	^ self packageOwnershipExplicitClassGroupSpecs flatCollect: [ :spec |
		spec second collect: [ :suffix |
			{ (spec first asString , suffix) asSymbol. spec third } ] ]
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipExplicitClassGroupSpecs [
	^ {
		{ #GbsRemoteUnboundMethodObject. #(''). #convertedOnly }.
		{ #GbsRc. #('Counter' 'Hash' 'Queue'). #maglevOnly }.
		{ #GbsSharedCounter. #(''). #maglevOnly }.
		{ #GbsGs. #('Object' 'Dictionary'). #maglevOnly }.
		{ #GbxExecBlock. #('' '0' '1' '2' '3' '4' '5' 'N'). #maglevOnly }.
		{ #GbsStDB. #('badAtRuby' 'noRuby'). #maglevOnly }.
		{ #GbsErrRubySystemExitErr. #(''). #maglevOnly } }
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipExplicitSelectorSpecs [
	^ #()
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipPrimaryClassPackagesByFamily [
	^ Dictionary newFromPairs: {
		#convertedWithMaglev. 'GemStone-GBS-Converted'.
		#toolsWithMaglevTools. 'GemStone-GBS-Tools' }
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipCorePackages [
	^ #(
		'GemStone-GBS-Converted'
		'GemStone-GBS-Tools')
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipForbiddenCoreClassPatterns [
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
GemStonePharoContract >> packageOwnershipForbiddenCoreSelectorPatterns [
	^ #(
		'addmaglev'
		'autoloadmirrors'
		'browseruby'
		'configuremaglev'
		'loadedfeatures'
		'loadpath'
		'maglevfinalizerregistry'
		'objectlog'
		'persistentloadedfeatures'
		'persistentroot'
		'registerautoload'
		'removeautoload'
		'requirefilenamed'
		'retryautoload'
		'rubyruntime'
		'sessionmethods'
		'supportsautoload')
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipSelectorSpecs [
	| packagesByFamily derived |
	packagesByFamily := self packageOwnershipAllowedPackagesByFamily.
	derived := self packageOwnershipSelectorFamilySpecs collect: [ :spec |
		| allowedPackages |
		allowedPackages := packagesByFamily at: spec fourth.
		allowedPackages size = 1 ifFalse: [
			self error: 'Selector ownership family must resolve to a single package: ', spec fourth asString ].
		{ spec first. spec second. spec third. allowedPackages first } ].
	^ derived , self packageOwnershipExplicitSelectorSpecs
]

{ #category : 'contracts' }
GemStonePharoContract >> packageOwnershipSelectorFamilySpecs [
	^ {
		{ #GbsSession. #instance. #bridgeRoot. #convertedOnly }.
		{ #GbsSession. #instance. #commitTransactionWithRetryCount:. #convertedOnly }.
		{ #GbsSession. #instance. #objectSpaceDiagnostics. #convertedOnly }.
		{ #GbsSmalltalkFacade. #instance. #bridgeRoot. #convertedOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #constantEntries. #convertedOnly }.
		{ #GbsRemoteMethodMirror. #instance. #asMethodObject. #convertedOnly }.
		{ #GbsRemoteMethodMirror. #instance. #asUnboundMethodObject. #convertedOnly }.
		{ #GbsRemoteClassMirror. #instance. #methodObjectAt:. #convertedOnly }.
		{ #GbsRemoteClassMirror. #instance. #classMethodObjectAt:. #convertedOnly }.
		{ #GbsNamespaceScopedMethodQuery. #instance. #methodObjectForReference:. #convertedOnly }.
		{ #GbsNamespaceScopedMethodQuery. #instance. #methodObjects. #convertedOnly }.
		{ #GbsBrowser. #instance. #browseNamedObjectCacheReport. #toolsOnly }.
		{ #GbsInspector. #instance. #browseTypedWrapperLifecycleReport. #toolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #browseObjectsInMemoryReport. #toolsOnly }.
		{ #GbxDebuggerService. #instance. #basicReenterServerContext. #toolsOnly }.
		{ #GbsSession. #instance. #objectLog. #maglevOnly }.
		{ #GbsSession. #instance. #sessionMethods. #maglevOnly }.
		{ #GbsSession. #instance. #materializeMaglevRuntimeValue:. #maglevOnly }.
		{ #GbsSession. #instance. #gsDictionaryForOop:. #maglevOnly }.
		{ #GbsSession. #instance. #gsObjectForOop:. #maglevOnly }.
		{ #GbsSession. #instance. #rcCounterForOop:. #maglevOnly }.
		{ #GbsSession. #instance. #rcHashForOop:. #maglevOnly }.
		{ #GbsSession. #instance. #rcQueueForOop:. #maglevOnly }.
		{ #GbsSession. #instance. #rubyRuntime. #maglevOnly }.
		{ #GbsSmalltalkFacade. #instance. #objectLog. #maglevOnly }.
		{ #GbsObjectSpaceFacade. #instance. #maglevFinalizerRegistry. #maglevOnly }.
		{ #GbsObjectSpaceDiagnosticsFacade. #instance. #maglevFinalizerRegistry. #maglevOnly }.
		{ #GbsObjectSpaceDiagnosticsFacade. #instance. #finalizerRegistryReport. #maglevOnly }.
		{ #GbsObjectSpaceDiagnosticsFacade. #instance. #finalizerRegistrySlot. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #autoloadMirrors. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #autoloadEntries. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #autoloadFileFor:. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #loadFileNamed:. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #loadedFeatures. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #loadPath. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #persistentLoadedFeatures. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #registerAutoload:file:. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #removeAutoload:. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #requireFileNamed:. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #retryAutoload:. #maglevOnly }.
		{ #GbsRemoteNamespaceMirror. #instance. #supportsAutoload. #maglevOnly }.
		{ #GbsRemoteConstantMirror. #instance. #autoloadFile. #maglevOnly }.
		{ #GbsRemoteConstantMirror. #instance. #isAutoload. #maglevOnly }.
		{ #GbsBrowser. #instance. #addExtensionSessionMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsBrowser. #instance. #browseRubyLoadPathReport. #maglevToolsOnly }.
		{ #GbsClassicLauncher. #instance. #addExtensionSessionMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsInspector. #instance. #addExtensionReportOptionsToLabels:actions:. #maglevToolsOnly }.
		{ #GbsMethodQueryResultsPresenter. #instance. #addExtensionSessionMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #addExtensionMethodMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #addExtensionSessionMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsRemoteDebugger. #instance. #browseRubyLoadPathReport. #maglevToolsOnly }.
		{ #GbsWorkspace. #instance. #addExtensionWorkspaceMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsStructuredValueInspectorPresenter. #instance. #addExtensionEntryMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #addExtensionEntryMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #addExtensionPreviewMenuItemsTo:. #maglevToolsOnly }.
		{ #GbsSymbolListBrowserPresenter. #instance. #configureExtensionStructuredInspector:. #maglevToolsOnly }.
		{ #GbxTrippy. #instance. #addExtensionReportOptionsToLabels:actions:. #maglevToolsOnly } }
]

{ #category : 'contracts' }
GemStonePharoContract >> livePreflightCodeSpecs [
	^ {
		{ 'LIVE_PREFLIGHT_OK'. 'Both Topaz and GCI probes succeeded.' }.
		{ 'LIVE_PREFLIGHT_SKIPPED'. 'The live lane was skipped because login credentials were not supplied.' }.
		{ 'LIVE_PREFLIGHT_AUTH_FAILED'. 'Topaz login failed due to invalid credentials.' }.
		{ 'LIVE_PREFLIGHT_ROUTE_FAILED'. 'Topaz could not route through the configured host/netldi combination.' }.
		{ 'LIVE_PREFLIGHT_STONE_NOT_FOUND'. 'The target stone was not visible through the configured route.' }.
		{ 'LIVE_PREFLIGHT_TOPAZ_LOGIN_FAILED'. 'Topaz login failed for a non-routing, non-auth reason.' }.
		{ 'LIVE_PREFLIGHT_GCI_AUTH_FAILED'. 'The Pharo GCI login failed due to invalid credentials.' }.
		{ 'LIVE_PREFLIGHT_GCI_ROUTE_FAILED'. 'The Pharo GCI login could not route through the configured host/netldi combination.' }.
		{ 'LIVE_PREFLIGHT_GCI_STONE_NOT_FOUND'. 'The Pharo GCI login could not find the target stone.' }.
		{ 'LIVE_PREFLIGHT_GCI_LOGIN_FAILED'. 'The Pharo GCI login failed for a non-routing, non-auth reason.' } }
]

{ #category : 'contracts' }
GemStonePharoContract >> livePreflightEnvironmentVariableSpecs [
	^ {
		{ 'GS_USER'. 'GemStone login user used by both the Topaz and GCI probes.' }.
		{ 'GS_PASS'. 'GemStone login password used by both the Topaz and GCI probes.' }.
		{ 'GS_STONE'. 'Optional stone name override. Defaults to `gs64stone`.' }.
		{ 'GS_SERVICE'. 'Optional service name override. Defaults to `gemnetobject`.' }.
		{ 'GS_NETLDI_HOST'. 'Optional explicit host for netldi routing.' }.
		{ 'GS_NETLDI_NAME_OR_PORT'. 'Optional explicit netldi name or port, for example `gs64ldi` or `50377`.' }.
		{ 'GEMSTONE'. 'Optional explicit GemStone client home used by the GCI probe.' } }
]

{ #category : 'contracts' }
GemStonePharoContract >> reloadCheckModeSpecs [
	^ {
		{ 'default'. 'Run the steady-state reload proof, including no-compatibility checks after the requested load group is loaded.' }.
		{ 'core-only'. 'Run the core-only package/class/selector proof after loading `Core-Tests`, plus the no-compatibility image proof.' } }
]

{ #category : 'contracts' }
GemStonePharoContract >> reloadEnvironmentVariableSpecs [
	^ {
		{ 'GBS_LOAD_GROUP'. 'Metacello load group to reload before post-load checks run. Defaults to `default`.' }.
		{ 'GBS_RELOAD_CHECK_MODE'. 'Reload proof mode. Defaults to `default` and supports `core-only`.' }.
		{ 'GBS_VERIFY_LANE'. 'Optional verification lane to run in the same Smalltalk process after the reload proof. Supports `core-only` and `full`.' }.
		{ 'GBS_GENERATE_CONTRACT_ARTIFACTS'. 'When `1`, regenerate the contract-driven documentation after reload.' }.
		{ 'GBS_VERIFY_CONTRACT_ARTIFACTS'. 'When `1`, verify that the contract-driven documentation is already fresh.' } }
]

{ #category : 'contracts' }
GemStonePharoContract >> livePreflightStepSpecs [
	^ {
		{ 'stone-status'. 'Inspect the local stone and netldi state with `gslist -lcv` when available.' }.
		{ 'topaz-login'. 'Attempt a Topaz login using the configured stone, service, host, and netldi route.' }.
		{ 'gci-login'. 'Attempt a direct GCI login from Pharo using the same route and client library.' }.
		{ 'summary'. 'Emit `LIVE_PREFLIGHT_SUMMARY` and optional JSON with the final classification.' } }
]

{ #category : 'contracts' }
GemStonePharoContract >> livePreflightSummaryFields [
	^ #('result' 'code' 'stone' 'service' 'host' 'net' 'stone_status' 'netldi_status' 'topaz' 'gci')
]

{ #category : 'contracts' }
GemStonePharoContract >> packageRequirementSpecs [
	^ {
		{ 'GemStone-GBS-Converted'. #() }.
		{ 'GemStone-GBS-MagLev'. #('GemStone-GBS-Converted') }.
		{ 'GemStone-GBS-Tools'. #('GemStone-GBS-Converted') }.
		{ 'GemStone-GBS-MagLev-Tools'. #('GemStone-GBS-Tools' 'GemStone-GBS-MagLev') }.
		{ 'GemStone-Pharo-Core-Tests'. #('GemStone-GBS-Converted' 'GemStone-GBS-Tools') }.
		{ 'GemStone-Pharo-Tests'. #('GemStone-Pharo-Core-Tests' 'GemStone-GBS-MagLev' 'GemStone-GBS-MagLev-Tools') } }
]

{ #category : 'contracts' }
GemStonePharoContract >> verificationLaneSpecs [
	^ {
		{ 'core-only'. 'Verify the Smalltalk core without optional MagLev production packages and without deleted legacy surface.'. 'Core-Tests'. #('GemStone-Pharo-Core-Tests'). #('ARCHITECTURE_BOUNDARY_OK' 'PACKAGE_OWNERSHIP_DRIFT_OK' 'NO_COMPAT_SOURCE_SCAN_OK' 'NO_COMPATIBILITY_PROOF_OK' 'BRIDGE_UNIT_REGRESSION_OK' 'BRIDGE_CORE_ONLY_CHECK_OK') }.
		{ 'bootstrap-smoke'. 'Prove that a clean image can micro-bootstrap the helper package and load the requested group before post-load checks run.'. 'Core-Tests'. #('GemStonePharoReloadBootstrapper' 'GemStonePharoReloadRunner' 'GemStone-Pharo-Core-Tests'). #('CORE_ONLY_CLEAN_RELOAD_DONE' 'BOOTSTRAP_SMOKE_OK' 'BOOTSTRAP_SMOKE_DONE') }.
		{ 'full'. 'Verify the steady-state developer load plus the live GemStone lane.'. 'Full'. #('GemStone-Pharo-Core-Tests' 'GemStone-Pharo-Tests'). #('ARCHITECTURE_BOUNDARY_OK' 'PACKAGE_OWNERSHIP_DRIFT_OK' 'NO_COMPAT_SOURCE_SCAN_OK' 'NO_COMPATIBILITY_PROOF_OK' 'BRIDGE_UNIT_REGRESSION_OK' 'BRIDGE_LIVE_REGRESSION_OK' 'CLEAN_RELOAD_AND_REGRESSION_RUN_DONE') }.
		{ 'artifact-freshness'. 'Verify that the generated contract artifacts and marker-managed doc sections are already up to date.'. 'default'. #('README.md' 'doc/ARCHITECTURE.md' 'doc/GemStone-Pharo-Bridge-User-Manual.html' 'doc/PACKAGE-GRAPH.md' 'doc/PACKAGE-GRAPH.dot' 'doc/PACKAGE-GRAPH.svg' 'doc/LIVE-PREFLIGHT-POLICY.md' 'doc/RELOAD-POLICY.md' 'doc/TESTING.md' 'doc/USER-MANUAL-REFERENCE.html' 'doc/OWNERSHIP-CONTRACT.md' 'doc/VERIFICATION-LANES.md'). #('NO_COMPAT_SOURCE_SCAN_OK' 'CONTRACT_ARTIFACTS_FRESH_OK') }.
		{ 'verify'. 'Run core-only, bootstrap-smoke, full, artifact-freshness, then the summary-renderer smoke check.'. 'composite'. #('core-only' 'bootstrap-smoke' 'full' 'artifact-freshness' 'summary-renderer'). #('All lane success markers above') } }
]

{ #category : 'contracts' }
GemStonePharoContract >> activeRootApiSpecs [
	^ #('bridgeRoot' '#GbsBridgeRoot' 'GbsBridgeRootFacade')
]

{ #category : 'contracts' }
GemStonePharoContract >> boundaryGuardSpecs [
	^ {
		{ 'ARCHITECTURE_BOUNDARY_OK'. 'Package graph, load-group membership, and forbidden reverse dependencies match the contract.' }.
		{ 'PACKAGE_OWNERSHIP_DRIFT_OK'. 'Representative class, selector, and split-behavior ownership stay in their allowed packages.' }.
		{ 'NO_COMPAT_SOURCE_SCAN_OK'. 'Deleted legacy surface is absent from the active source roots, scripts, and selected docs.' }.
		{ 'NO_COMPATIBILITY_PROOF_OK'. 'Deleted package, class, selector, and method-package ownership surface is absent from the loaded image.' } }
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedArchitectureBodyMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'This section is generated from `GemStonePharoContract`.'; cr; cr;
			nextPutAll: '## Design Goal'; cr; cr;
			nextPutAll: '- `Pharo <-> GemStone Smalltalk` is the primary layer'; cr;
			nextPutAll: '- MagLev/Ruby behavior is optional'; cr;
			nextPutAll: '- legacy alias surface stays absent from production'; cr; cr;
			nextPutAll: '## Package Layers'; cr; cr;
			nextPutAll: '- core production: `GemStone-GBS-Converted`, `GemStone-GBS-Tools`'; cr;
			nextPutAll: '- optional MagLev production: `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`'; cr;
			nextPutAll: '- active tests: `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-Tests`'; cr; cr;
			nextPutAll: '## Active Root API'; cr; cr.
		self activeRootApiSpecs do: [ :each |
			stream nextPutAll: '- `'; nextPutAll: each; nextPutAll: '`'; cr ].
		stream cr; nextPutAll: '## Verification Guards'; cr; cr.
		self boundaryGuardSpecs do: [ :each |
			stream nextPutAll: '- `'; nextPutAll: each first; nextPutAll: '`'; cr ].
		stream cr; nextPutAll: '## Review Artifacts'; cr; cr;
			nextPutAll: '- [PACKAGE-GRAPH.md](./PACKAGE-GRAPH.md)'; cr;
			nextPutAll: '- [OWNERSHIP-CONTRACT.md](./OWNERSHIP-CONTRACT.md)'; cr;
			nextPutAll: '- [RELOAD-POLICY.md](./RELOAD-POLICY.md)'; cr;
			nextPutAll: '- [LIVE-PREFLIGHT-POLICY.md](./LIVE-PREFLIGHT-POLICY.md)'; cr ]
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedReadmeBodyMarkdown [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: '## Steady-state Contract Summary'; cr; cr;
			nextPutAll: 'This section is generated from `GemStonePharoContract` and rewritten by `make graph-artifacts`.'; cr; cr;
			nextPutAll: '### Package Layout'; cr; cr;
			nextPutAll: '- core production: `GemStone-GBS-Converted`, `GemStone-GBS-Tools`'; cr;
			nextPutAll: '- optional MagLev production: `GemStone-GBS-MagLev`, `GemStone-GBS-MagLev-Tools`'; cr;
			nextPutAll: '- active tests: `GemStone-Pharo-Core-Tests`, `GemStone-Pharo-Tests`'; cr; cr;
			nextPutAll: '### Active Root API'; cr; cr.
		self activeRootApiSpecs do: [ :each |
			stream nextPutAll: '- `'; nextPutAll: each; nextPutAll: '`'; cr ].
		stream cr; nextPutAll: '### Baseline Groups'; cr; cr;
			nextPutAll: '- `Core-Only`, `Core`, `Core-Tools`, `Core-Tests`'; cr;
			nextPutAll: '- `MagLev-Core`, `MagLev-Tools`, `MagLev`'; cr;
			nextPutAll: '- `Tools`, `All-Tests`, `Tests`, `Full`, `default`'; cr;
			cr;
			nextPutAll: 'See [doc/PACKAGE-GRAPH.md](doc/PACKAGE-GRAPH.md) for the exact package graph and group membership.'; cr.
		stream cr; nextPutAll: '### Verification Lanes'; cr; cr;
			nextPutAll: 'Top-level `make verify` sequencing is owned by `GemStonePharoVerifyRunner`; lane-local unit/live/preflight execution is owned by `GemStonePharoVerificationRunner`.'; cr; cr.
		self verificationLaneSpecs do: [ :each |
			stream
				nextPutAll: '- `'; nextPutAll: each first; nextPutAll: '`'; cr;
				nextPutAll: '  '; nextPutAll: each second; cr;
				nextPutAll: '  load group: `'; nextPutAll: each third; nextPutAll: '`'; cr ].
		stream cr; nextPutAll: '### Generated Contract Artifacts'; cr; cr;
			nextPutAll: 'Standalone generated artifacts:'; cr;
			nextPutAll: '- [doc/PACKAGE-GRAPH.md](doc/PACKAGE-GRAPH.md)'; cr;
			nextPutAll: '- [doc/PACKAGE-GRAPH.dot](doc/PACKAGE-GRAPH.dot)'; cr;
			nextPutAll: '- [doc/PACKAGE-GRAPH.svg](doc/PACKAGE-GRAPH.svg)'; cr;
			nextPutAll: '- [doc/LIVE-PREFLIGHT-POLICY.md](doc/LIVE-PREFLIGHT-POLICY.md)'; cr;
			nextPutAll: '- [doc/RELOAD-POLICY.md](doc/RELOAD-POLICY.md)'; cr;
			nextPutAll: '- [doc/USER-MANUAL-REFERENCE.html](doc/USER-MANUAL-REFERENCE.html)'; cr;
			nextPutAll: '- [doc/OWNERSHIP-CONTRACT.md](doc/OWNERSHIP-CONTRACT.md)'; cr;
			nextPutAll: '- [doc/VERIFICATION-LANES.md](doc/VERIFICATION-LANES.md)'; cr;
			cr;
			nextPutAll: 'In-place generated doc sections:'; cr.
		self generatedDocumentationSectionPaths do: [ :each |
			stream
				nextPutAll: '- [`'; nextPutAll: each; nextPutAll: '`]('; nextPutAll: each; nextPutAll: ')'; cr ].
		stream cr; nextPutAll: '### Boundary Guards'; cr; cr.
		self boundaryGuardSpecs do: [ :each |
			stream
				nextPutAll: '- `'; nextPutAll: each first; nextPutAll: '`'; cr;
				nextPutAll: '  '; nextPutAll: each second; cr ].
		stream cr; nextPutAll: 'CI uses the same steady-state gate through `make verify` in `.github/workflows/verify.yml`.'; cr ]
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedTestingBodyMarkdown [
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
		stream cr; nextPutAll: '## Wrapper Entry Points'; cr; cr;
			nextPutAll: '```bash'; cr;
			nextPutAll: 'make help'; cr;
			nextPutAll: 'make core-only'; cr;
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
GemStonePharoContract >> generatedUserManualOverviewHtml [
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
		#('Core' 'Core-Tests' 'MagLev' 'Tests' 'default') do: [ :groupName |
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
			nextPutAll: '    <p>The active core root API is <code>bridgeRoot</code>, backed by <code>#GbsBridgeRoot</code> and <code>GbsBridgeRootFacade</code>.</p>'; cr ]
]

{ #category : 'contracts' }
GemStonePharoContract >> generatedUserManualTestingHtml [
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
			nextPutAll: '    <h3>Generated operator reference</h3>'; cr;
			nextPutAll: '    <p>'; cr;
			nextPutAll: '      The contract generates a human-facing steady-state operator reference at'; cr;
			nextPutAll: '      <code>doc/USER-MANUAL-REFERENCE.html</code>. Use that file as the authoritative quick reference for'; cr;
			nextPutAll: '      active load groups, verification lanes, live GemStone environment variables, the'; cr;
			nextPutAll: '      <code>bridgeRoot</code> API, and the no-compatibility proof.'; cr;
			nextPutAll: '    </p>'; cr;
			nextPutAll: '    <h3>Recommended entry point</h3>'; cr;
			nextPutAll: '    <pre><code>make help'; cr;
			nextPutAll: 'make core-only'; cr;
			nextPutAll: 'make full'; cr;
			nextPutAll: 'make verify'; cr;
			nextPutAll: 'make artifact-freshness</code></pre>'; cr;
			nextPutAll: '    <h3>Known-good live example</h3>'; cr;
			nextPutAll: '    <pre><code>GS_USER=''DataCurator'' \'; cr;
			nextPutAll: 'GS_PASS=''swordfish'' \'; cr;
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

{ #category : 'contracts' }
GemStonePharoContract >> groupDescriptionSpecs [
	^ Dictionary newFromPairs: {
		'Core-Only'. 'strict converted-core load for boundary checks'.
		'Core'. 'Smalltalk core bridge only'.
		'Core-Tools'. 'Smalltalk core plus generic Pharo tools'.
		'Core-Tests'. 'Smalltalk core, generic tools, and the core-only test suite'.
		'MagLev-Core'. 'optional MagLev runtime without MagLev-specific tools'.
		'MagLev-Tools'. 'optional MagLev runtime plus MagLev-specific tool integration'.
		'MagLev'. 'convenience alias for the MagLev production stack'.
		'Tools'. 'convenience alias for the generic tools-capable load'.
		'All-Tests'. 'all active test packages'.
		'Tests'. 'convenience alias for all active test packages'.
		'Full'. 'full developer load'.
		'default'. 'alias for `Full`' }
]

{ #category : 'contracts' }
GemStonePharoContract >> productionPackageSummarySpecs [
	^ {
		{ 'GemStone-GBS-Converted'. 'Smalltalk core bridge, session transport, repository access, generic mirrors, root facades, and bridge support code.' }.
		{ 'GemStone-GBS-Tools'. 'Generic Pharo tools and presenters for the Smalltalk core.' }.
		{ 'GemStone-GBS-MagLev'. 'Optional MagLev/Ruby runtime surface: runtime loading, autoload, proc/binding support, ObjectLog, RC wrappers, and MagLev facades.' }.
		{ 'GemStone-GBS-MagLev-Tools'. 'Optional MagLev/Ruby tool integration for browsers, workspaces, debuggers, and inspectors.' } }
]

{ #category : 'contracts' }
GemStonePharoContract >> testPackageSummarySpecs [
	^ {
		{ 'GemStone-Pharo-Core-Tests'. 'Smalltalk-core-only tests.' }.
		{ 'GemStone-Pharo-Tests'. 'Active full bridge tests, including MagLev-aware behavior.' } }
]
