Class {
	#name : 'GemStonePharoVerifyRunner',
	#superclass : 'Object',
	#instVars : [
		'environment',
		'baselineContract',
		'logBlock',
		'stepRunBlock',
		'stepStatuses'
	],
	#category : 'BaselineOfGemStonePharo',
	#package : 'BaselineOfGemStonePharo'
}

{ #category : 'instance creation' }
GemStonePharoVerifyRunner class >> defaultSourceImagePath [
	^ '/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image'
]

{ #category : 'instance creation' }
GemStonePharoVerifyRunner class >> defaultWorkDirectoryPath [
	^ '/Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean'
]

{ #category : 'instance creation' }
GemStonePharoVerifyRunner class >> onEnvironment: anEnvironment log: aBlock [
	^ self new
		environment: anEnvironment;
		baselineContract: GemStonePharoContract new;
		logBlock: aBlock;
		yourself
]

{ #category : 'instance creation' }
GemStonePharoVerifyRunner class >> repoRootPath [
	^ GemStonePharoReloadRunner repoRootPath
]

{ #category : 'instance creation' }
GemStonePharoVerifyRunner class >> runOnEnvironment: anEnvironment log: aBlock [
	^ (self onEnvironment: anEnvironment log: aBlock)
		runVerify
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> baselineContract [
	^ baselineContract ifNil: [ GemStonePharoContract new ]
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> baselineContract: aContract [
	baselineContract := aContract
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> commandOutputForBashScript: aString onErrorLabel: errorLabel [
	| outputFile command output |
	outputFile := ('/tmp/gbs-verify-', Time millisecondClockValue printString, '.log') asFileReference.
	command := String streamContents: [ :stream |
		stream
			nextPutAll: 'bash -lc ';
			nextPutAll: (self shellQuoted: aString);
			nextPutAll: ' > ';
			nextPutAll: (self shellQuoted: outputFile pathString);
			nextPutAll: ' 2>&1' ].
	[ LibC system: command ] on: Error do: [ :ex |
		self log: errorLabel, ': ', ex messageText ].
	output := outputFile exists
		ifTrue: [
			[ outputFile contents ]
				ensure: [ outputFile delete ] ]
		ifFalse: [ '' ].
	^ output
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> defaultRunStepNamed: stepName [
	| output |
	output := self
		commandOutputForBashScript: (self shellCommandForStepNamed: stepName)
		onErrorLabel: 'VERIFY_RUNNER_STEP_FAILED'.
	self logOutput: output.
	^ output includesSubstring: (self successMarkerForStepNamed: stepName)
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> emitSummaryJsonResult: result code: code [
	| payload |
	payload := String streamContents: [ :stream |
		stream
			nextPutAll: '{"result":"';
			nextPutAll: (self jsonEscape: result);
			nextPutAll: '","code":"';
			nextPutAll: (self jsonEscape: code);
			nextPutAll: '","core_only":"';
			nextPutAll: (self jsonEscape: (self statusForStepNamed: 'core-only'));
			nextPutAll: '","bootstrap_smoke":"';
			nextPutAll: (self jsonEscape: (self statusForStepNamed: 'bootstrap-smoke'));
			nextPutAll: '","original_tests":"';
			nextPutAll: (self jsonEscape: (self statusForStepNamed: 'original-tests'));
			nextPutAll: '","full":"';
			nextPutAll: (self jsonEscape: (self statusForStepNamed: 'full'));
			nextPutAll: '","artifact_freshness":"';
			nextPutAll: (self jsonEscape: (self statusForStepNamed: 'artifact-freshness'));
			nextPutAll: '","summary_renderer":"';
			nextPutAll: (self jsonEscape: (self statusForStepNamed: 'summary-renderer'));
			nextPutAll: '"}' ].
	self log: 'VERIFY_SUMMARY_JSON ', payload
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> emitSummaryResult: result code: code [
	self
		log: 'VERIFY_SUMMARY result=', result,
			' code=', code,
			' core_only=', (self statusForStepNamed: 'core-only'),
			' bootstrap_smoke=', (self statusForStepNamed: 'bootstrap-smoke'),
			' original_tests=', (self statusForStepNamed: 'original-tests'),
			' full=', (self statusForStepNamed: 'full'),
			' artifact_freshness=', (self statusForStepNamed: 'artifact-freshness'),
			' summary_renderer=', (self statusForStepNamed: 'summary-renderer').
	self summaryJsonEnabled ifTrue: [
		self emitSummaryJsonResult: result code: code ]
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> environment [
	^ environment ifNil: [ Smalltalk os environment ]
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> environment: anEnvironment [
	environment := anEnvironment
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> environmentAt: aString ifAbsent: aBlock [
	^ [ self environment at: aString ifAbsent: aBlock ]
		on: Error
		do: [ aBlock value ]
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> failureCodeForStepNamed: stepName [
	stepName = 'core-only' ifTrue: [ ^ 'CORE_ONLY_FAILED' ].
	stepName = 'bootstrap-smoke' ifTrue: [ ^ 'BOOTSTRAP_SMOKE_FAILED' ].
	stepName = 'original-tests' ifTrue: [ ^ 'ORIGINAL_TESTS_FAILED' ].
	stepName = 'full' ifTrue: [ ^ 'FULL_FAILED' ].
	stepName = 'artifact-freshness' ifTrue: [ ^ 'ARTIFACT_FRESHNESS_FAILED' ].
	stepName = 'summary-renderer' ifTrue: [ ^ 'SUMMARY_RENDERER_FAILED' ].
	^ 'VERIFY_STEP_FAILED'
]

{ #category : 'initialization' }
GemStonePharoVerifyRunner >> initialize [
	super initialize.
	logBlock := [ :line | Transcript show: line; cr ].
	stepStatuses := Dictionary new
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> jsonEscape: aString [
	| escaped |
	escaped := aString asString.
	escaped := escaped copyReplaceAll: '\' with: '\\'.
	escaped := escaped copyReplaceAll: '"' with: '\"'.
	escaped := escaped copyReplaceAll: (String with: Character cr) with: '\n'.
	escaped := escaped copyReplaceAll: (String with: Character lf) with: '\n'.
	escaped := escaped copyReplaceAll: (String with: Character tab) with: '\t'.
	^ escaped
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> log: aString [
	logBlock value: aString
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> logBlock: aBlock [
	logBlock := aBlock
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> logOutput: output [
	| normalized |
	normalized := (output ifNil: [ '' ])
		copyReplaceAll: (String with: Character cr)
		with: (String with: Character lf).
	(normalized findTokens: (String with: Character lf))
		do: [ :line | line isEmpty ifFalse: [ self log: line ] ]
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> markRemainingStepsSkippedAfter: stepName [
	| skipping |
	skipping := false.
	self verifyStepNames do: [ :each |
		skipping
			ifTrue: [ self stepStatuses at: each put: 'skipped' ].
		each = stepName ifTrue: [ skipping := true ] ]
]

{ #category : 'running' }
GemStonePharoVerifyRunner >> runStepNamed: stepName [
	^ stepRunBlock
		ifNil: [ self defaultRunStepNamed: stepName ]
		ifNotNil: [ stepRunBlock value: stepName ]
]

{ #category : 'running' }
GemStonePharoVerifyRunner >> runVerify [
	self verifyStepNames do: [ :each | self stepStatuses at: each put: 'pending' ].
	self verifyStepNames do: [ :stepName |
		(self runStepNamed: stepName)
			ifTrue: [ self stepStatuses at: stepName put: 'ok' ]
			ifFalse: [
				self stepStatuses at: stepName put: 'failed'.
				self markRemainingStepsSkippedAfter: stepName.
				self
					emitSummaryResult: 'FAIL'
					code: (self failureCodeForStepNamed: stepName).
				^ false ] ].
	self emitSummaryResult: 'OK' code: 'VERIFY_OK'.
	^ true
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> shellCommandForStepNamed: stepName [
	| repoRoot imagePath workDir |
	repoRoot := self class repoRootPath.
	imagePath := self sourceImagePath.
	workDir := self workDirectoryPath.
	stepName = 'core-only' ifTrue: [
		^ 'cd ', (self shellQuoted: repoRoot),
			' && bash ./scripts/run_core_only_clean_reload.sh ',
			(self shellQuoted: imagePath), ' ',
			(self shellQuoted: workDir) ].
	stepName = 'bootstrap-smoke' ifTrue: [
		^ 'cd ', (self shellQuoted: repoRoot),
			' && bash ./scripts/run_bootstrap_smoke.sh ',
			(self shellQuoted: imagePath), ' ',
			(self shellQuoted: workDir) ].
	stepName = 'original-tests' ifTrue: [
		^ 'cd ', (self shellQuoted: repoRoot),
			' && bash ./scripts/run_original_tests_clean_reload.sh ',
			(self shellQuoted: imagePath), ' ',
			(self shellQuoted: workDir) ].
	stepName = 'full' ifTrue: [
		^ 'cd ', (self shellQuoted: repoRoot),
			' && bash ./scripts/run_clean_reload_and_regressions.sh ',
			(self shellQuoted: imagePath), ' ',
			(self shellQuoted: workDir) ].
	stepName = 'artifact-freshness' ifTrue: [
		^ 'cd ', (self shellQuoted: repoRoot),
			' && bash ./scripts/run_verify_contract_artifacts.sh ',
			(self shellQuoted: imagePath), ' ',
			(self shellQuoted: workDir) ].
	stepName = 'summary-renderer' ifTrue: [
		^ 'cd ', (self shellQuoted: repoRoot),
			' && bash ./scripts/test_render_lane_json_summaries.sh' ].
	^ 'printf "UNKNOWN_VERIFY_STEP ', stepName, '\n"'
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> shellQuoted: aString [
	| escaped |
	escaped := aString.
	escaped := escaped copyReplaceAll: '\' with: '\\'.
	escaped := escaped copyReplaceAll: '"' with: '\"'.
	escaped := escaped copyReplaceAll: '$' with: '\$'.
	escaped := escaped copyReplaceAll: '`' with: '\`'.
	^ '"' , escaped , '"'
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> sourceImagePath [
	^ self environmentAt: 'GBS_VERIFY_IMAGE' ifAbsent: [ self class defaultSourceImagePath ]
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> statusForStepNamed: stepName [
	^ self stepStatuses at: stepName ifAbsent: [ 'pending' ]
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> stepRunBlock: aBlock [
	stepRunBlock := aBlock
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> stepStatuses [
	^ stepStatuses
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> successMarkerForStepNamed: stepName [
	stepName = 'core-only' ifTrue: [ ^ 'BRIDGE_CORE_ONLY_CHECK_OK' ].
	stepName = 'bootstrap-smoke' ifTrue: [ ^ 'BOOTSTRAP_SMOKE_DONE' ].
	stepName = 'original-tests' ifTrue: [ ^ 'ORIGINAL_TESTS_CHECK_OK' ].
	stepName = 'full' ifTrue: [ ^ 'CLEAN_RELOAD_AND_REGRESSION_RUN_DONE' ].
	stepName = 'artifact-freshness' ifTrue: [ ^ 'CONTRACT_ARTIFACT_FRESHNESS_CHECK_OK' ].
	stepName = 'summary-renderer' ifTrue: [ ^ 'SUMMARY_RENDERER_TEST_OK' ].
	^ 'VERIFY_STEP_OK'
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> summaryJsonEnabled [
	^ GemStonePharoReloadRunner
		booleanFlagNamed: 'GBS_JSON_SUMMARY'
		fromEnvironment: self environment
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> verifyStepNames [
	^ (self baselineContract verificationLaneSpecs
		detect: [ :each | each first = 'verify' ]
		ifNone: [ ^ #() ]) fourth
]

{ #category : 'private' }
GemStonePharoVerifyRunner >> workDirectoryPath [
	^ self environmentAt: 'GBS_VERIFY_WORK_DIR' ifAbsent: [ self class defaultWorkDirectoryPath ]
]
