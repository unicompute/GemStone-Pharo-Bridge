Class {
	#name : 'GemStonePharoVerificationRunner',
	#superclass : 'Object',
	#instVars : [
		'environment',
		'logBlock',
		'laneRunBlock',
		'originalTestsPreparationBlock',
		'preflightRunBlock',
		'imagePathBlock',
		'gslistOutputBlock',
		'topazOutputBlock',
		'gciProbeOutputBlock'
	],
	#category : 'BaselineOfGemStonePharo',
	#package : 'BaselineOfGemStonePharo'
}

{ #category : 'instance creation' }
GemStonePharoVerificationRunner class >> laneNameFromEnvironment: anEnvironment [
	^ (([ anEnvironment at: 'GBS_VERIFY_LANE' ifAbsent: [ 'full' ] ]
		on: Error
		do: [ 'full' ]) asString) asLowercase
]

{ #category : 'instance creation' }
GemStonePharoVerificationRunner class >> onEnvironment: anEnvironment log: aBlock [
	^ self new
		environment: anEnvironment;
		logBlock: aBlock;
		yourself
]

{ #category : 'instance creation' }
GemStonePharoVerificationRunner class >> repoRootPath [
	^ GemStonePharoReloadRunner repoRootPath
]

{ #category : 'instance creation' }
GemStonePharoVerificationRunner class >> runOnEnvironment: anEnvironment log: aBlock [
	^ (self onEnvironment: anEnvironment log: aBlock)
		runVerificationLane
]

{ #category : 'instance creation' }
GemStonePharoVerificationRunner class >> runPreflightOnEnvironment: anEnvironment log: aBlock imagePath: anImagePath [
	^ (self onEnvironment: anEnvironment log: aBlock)
		imagePathBlock: [ anImagePath ];
		runStandalonePreflight
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> credentialsAvailable [
	| user pass |
	user := (self environmentAt: 'GS_USER' ifAbsent: [ '' ]) trimBoth.
	pass := (self environmentAt: 'GS_PASS' ifAbsent: [ '' ]) trimBoth.
	^ user isNotEmpty and: [ pass isNotEmpty ]
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> defaultPreflightResult [
	^ self runStandalonePreflight
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> defaultPrepareOriginalTestsSession [
	| liveSessionSupportClass session |
	liveSessionSupportClass := Smalltalk
		at: #GbsLiveSessionTestSupport
		ifAbsent: [ nil ].
	liveSessionSupportClass ifNil: [ ^ true ].
	session := [ liveSessionSupportClass ensureSharedSession ]
		on: Error
		do: [ :ex |
			self log: 'ORIGINAL_TESTS_SESSION_PREP_ERROR: ', ex messageText.
			nil ].
	session ifNil: [ ^ true ].
	^ self ensureTranscriptProxyInstalledOn: session
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> defaultRunRegressionLaneNamed: laneName packageFilter: packageFilter [
	| laneEnvironment |
	laneEnvironment := Dictionary new.
	laneEnvironment at: 'GBS_TEST_LANE' put: laneName.
	(packageFilter notNil and: [ packageFilter isNotEmpty ]) ifTrue: [
		laneEnvironment at: 'GBS_TEST_PACKAGES' put: packageFilter ].
	^ GemStonePharoLaneRunner
		runOnEnvironment: laneEnvironment
		log: logBlock
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> emitCoreOnlySummaryResult: result code: code unitStatus: unitStatus [
	self
		log: 'CORE_ONLY_VERIFICATION_SUMMARY result=', result,
			' code=', code,
			' unit=', unitStatus,
			' work_image=', self imagePath.
	self log: (result = 'OK'
		ifTrue: [ 'BRIDGE_CORE_ONLY_CHECK_OK' ]
		ifFalse: [ 'BRIDGE_CORE_ONLY_CHECK_FAILED' ])
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> emitOriginalSummaryResult: result code: code unitStatus: unitStatus preflightStatus: preflightStatus liveStatus: liveStatus [
	self
		log: 'ORIGINAL_SUMMARY result=', result,
			' code=', code,
			' reload=ok',
			' unit=', unitStatus,
			' preflight=', preflightStatus,
			' live=', liveStatus,
			' work_image=', self imagePath.
	self log: (result = 'OK'
		ifTrue: [ 'ORIGINAL_CHECK_OK' ]
		ifFalse: [ 'ORIGINAL_CHECK_FAILED' ])
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> emitOriginalTestsSummaryResult: result code: code unitStatus: unitStatus preflightStatus: preflightStatus liveStatus: liveStatus [
	self
		log: 'ORIGINAL_TESTS_SUMMARY result=', result,
			' code=', code,
			' reload=ok',
			' unit=', unitStatus,
			' preflight=', preflightStatus,
			' live=', liveStatus,
			' work_image=', self imagePath.
	self log: (result = 'OK'
		ifTrue: [ 'ORIGINAL_TESTS_CHECK_OK' ]
		ifFalse: [ 'ORIGINAL_TESTS_CHECK_FAILED' ])
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> emitFullSummaryResult: result code: code unitStatus: unitStatus preflightStatus: preflightStatus liveStatus: liveStatus [
	self
		log: 'CLEAN_RELOAD_AND_REGRESSION_SUMMARY result=', result,
			' code=', code,
			' reload=ok',
			' unit=', unitStatus,
			' preflight=', preflightStatus,
			' live=', liveStatus,
			' work_image=', self imagePath.
	self log: (result = 'OK'
		ifTrue: [ 'CLEAN_RELOAD_AND_REGRESSION_RUN_DONE' ]
		ifFalse: [ 'CLEAN_RELOAD_AND_REGRESSION_FAILED' ])
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> environment [
	^ environment ifNil: [ Smalltalk os environment ]
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> environment: anEnvironment [
	environment := anEnvironment
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> environmentAt: aString ifAbsent: aBlock [
	^ [ self environment at: aString ifAbsent: aBlock ]
		on: Error
		do: [ aBlock value ]
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> ensureTranscriptProxyInstalledOn: aSession [
	^ [ (aSession evaluate: self transcriptProxyInstallScript) = true ]
		on: Error
		do: [ :ex |
			self log: 'ORIGINAL_TESTS_SESSION_PREP_ERROR: ', ex messageText.
			false ]
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> commandOutputForBashScript: aString onErrorLabel: errorLabel [
	| outputFile command output |
	outputFile := ('/tmp/gbs-verification-', Time millisecondClockValue printString, '.log') asFileReference.
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
GemStonePharoVerificationRunner >> classifyGciFailureOutput: output [
	| lowered |
	lowered := output asLowercase.
	((lowered includesSubstring: 'invalid or expired')
		or: [ (lowered includesSubstring: 'invalid password')
		or: [ lowered includesSubstring: 'invalid credentials' ] ])
		ifTrue: [ ^ 'LIVE_PREFLIGHT_GCI_AUTH_FAILED' ].
	((lowered includesSubstring: 'netldi')
		or: [ (lowered includesSubstring: 'gemnetobject')
		or: [ (lowered includesSubstring: 'cannot connect')
		or: [ lowered includesSubstring: 'not accessible' ] ] ])
		ifTrue: [ ^ 'LIVE_PREFLIGHT_GCI_ROUTE_FAILED' ].
	((lowered includesSubstring: 'stone')
		and: [ lowered includesSubstring: 'does not exist' ])
		ifTrue: [ ^ 'LIVE_PREFLIGHT_GCI_STONE_NOT_FOUND' ].
	^ 'LIVE_PREFLIGHT_GCI_LOGIN_FAILED'
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> classifyTopazFailureOutput: output [
	| lowered |
	lowered := output asLowercase.
	((lowered includesSubstring: 'invalid or expired')
		or: [ (lowered includesSubstring: 'invalid password')
		or: [ (lowered includesSubstring: 'invalid userid')
		or: [ lowered includesSubstring: 'invalid user' ] ] ])
		ifTrue: [ ^ 'LIVE_PREFLIGHT_AUTH_FAILED' ].
	((lowered includesSubstring: 'netldi')
		or: [ (lowered includesSubstring: 'unable to connect')
		or: [ (lowered includesSubstring: 'cannot connect')
		or: [ lowered includesSubstring: 'connection refused' ] ] ])
		ifTrue: [ ^ 'LIVE_PREFLIGHT_ROUTE_FAILED' ].
	((lowered includesSubstring: 'stone')
		and: [ lowered includesSubstring: 'does not exist' ])
		ifTrue: [ ^ 'LIVE_PREFLIGHT_STONE_NOT_FOUND' ].
	^ 'LIVE_PREFLIGHT_TOPAZ_LOGIN_FAILED'
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> defaultGciProbeOutput [
	^ self
		commandOutputForBashScript: (String streamContents: [ :stream |
			stream
				nextPutAll: 'VM=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'PHARO_VM' ifAbsent: [ '/Users/tariq/Documents/Pharo/vms/130-x64/Pharo.app/Contents/MacOS/Pharo' ]));
				nextPutAll: '; WORK_IMAGE=';
				nextPutAll: (self shellQuoted: self imagePath);
				nextPutAll: '; GS_STONE=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'GS_STONE' ifAbsent: [ 'gs64stone' ]));
				nextPutAll: '; GS_USER=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'GS_USER' ifAbsent: [ '' ]));
				nextPutAll: '; GS_PASS=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'GS_PASS' ifAbsent: [ '' ]));
				nextPutAll: '; GS_SERVICE=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'GS_SERVICE' ifAbsent: [ 'gemnetobject' ]));
				nextPutAll: '; GS_NETLDI_HOST=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'GS_NETLDI_HOST' ifAbsent: [ '' ]));
				nextPutAll: '; GS_NETLDI_NAME_OR_PORT=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'GS_NETLDI_NAME_OR_PORT' ifAbsent: [ '' ]));
				nextPutAll: '; GEMSTONE_HOME=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'GEMSTONE' ifAbsent: [ '' ]));
				nextPutAll: '; mkdir -p /tmp/pharo-clean-auto/home; HOME=/tmp/pharo-clean-auto/home ';
				nextPutAll: 'GS_STONE="${GS_STONE}" GS_USER="${GS_USER}" GS_PASS="${GS_PASS}" GS_SERVICE="${GS_SERVICE}" GS_NETLDI_HOST="${GS_NETLDI_HOST}" GS_NETLDI_NAME_OR_PORT="${GS_NETLDI_NAME_OR_PORT}" GEMSTONE="${GEMSTONE_HOME}" ';
				nextPutAll: '"${VM}" --headless "${WORK_IMAGE}" st ';
				nextPutAll: (self shellQuoted: self class repoRootPath , '/scripts/probe_live_login.st') ])
		onErrorLabel: 'LIVE_PREFLIGHT_GCI_PROBE_FAILED'
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> defaultGslistOutput [
	^ self
		commandOutputForBashScript: (String streamContents: [ :stream |
			stream
				nextPutAll: 'GEMSTONE_HOME=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'GEMSTONE' ifAbsent: [ '' ]));
				nextPutAll: '; gslist_bin="${GEMSTONE_HOME:+${GEMSTONE_HOME}/bin/gslist}"; ';
				nextPutAll: 'if [[ -z "${GEMSTONE_HOME}" || ! -x "${gslist_bin}" ]]; then gslist_bin="$(command -v gslist || true)"; fi; ';
				nextPutAll: 'if [[ -n "${gslist_bin}" ]]; then "${gslist_bin}" -lcv; else echo LIVE_PREFLIGHT_GSLIST_UNAVAILABLE; fi' ])
		onErrorLabel: 'LIVE_PREFLIGHT_GSLIST_FAILED'
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> defaultTopazOutput [
	^ self
		commandOutputForBashScript: (String streamContents: [ :stream |
			stream
				nextPutAll: 'USER_NAME=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'GS_USER' ifAbsent: [ '' ]));
				nextPutAll: '; PASSWORD=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'GS_PASS' ifAbsent: [ '' ]));
				nextPutAll: '; STONE=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'GS_STONE' ifAbsent: [ 'gs64stone' ]));
				nextPutAll: '; NETLDI_HOST=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'GS_NETLDI_HOST' ifAbsent: [ '' ]));
				nextPutAll: '; NETLDI_NAME_OR_PORT=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'GS_NETLDI_NAME_OR_PORT' ifAbsent: [ '' ]));
				nextPutAll: '; GEMSTONE_HOME=';
				nextPutAll: (self shellQuoted: (self environmentAt: 'GEMSTONE' ifAbsent: [ '' ]));
				nextPutAll: '; topaz_bin="${GEMSTONE_HOME:+${GEMSTONE_HOME}/bin/topaz}"; ';
				nextPutAll: 'if [[ -z "${GEMSTONE_HOME}" || ! -x "${topaz_bin}" ]]; then topaz_bin="$(command -v topaz || true)"; fi; ';
				nextPutAll: 'if [[ -n "${topaz_bin}" ]]; then ';
				nextPutAll: 'topaz_set_command="set user ${USER_NAME} pass ${PASSWORD} gems ${STONE}"; ';
				nextPutAll: 'if [[ -n "${NETLDI_HOST}" && -n "${NETLDI_NAME_OR_PORT}" ]]; then topaz_set_command="${topaz_set_command} netldi ${NETLDI_HOST}#${NETLDI_NAME_OR_PORT}"; fi; ';
				nextPutAll: 'printf ''%s\nlogin\nlogout\nquit\n'' "${topaz_set_command}" | "${topaz_bin}" -l; ';
				nextPutAll: 'else echo LIVE_PREFLIGHT_TOPAZ_UNAVAILABLE; fi' ])
		onErrorLabel: 'LIVE_PREFLIGHT_TOPAZ_FAILED'
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> emitPreflightSummaryJsonResult: result code: code stoneStatus: stoneStatus netldiStatus: netldiStatus topazStatus: topazStatus gciStatus: gciStatus [
	| payload |
	payload := String streamContents: [ :stream |
		stream
			nextPutAll: '{';
			nextPutAll: '"result":"';
			nextPutAll: (self jsonEscape: result);
			nextPutAll: '","code":"';
			nextPutAll: (self jsonEscape: code);
			nextPutAll: '","stone":"';
			nextPutAll: (self jsonEscape: (self environmentAt: 'GS_STONE' ifAbsent: [ 'gs64stone' ]));
			nextPutAll: '","service":"';
			nextPutAll: (self jsonEscape: (self environmentAt: 'GS_SERVICE' ifAbsent: [ 'gemnetobject' ]));
			nextPutAll: '","host":"';
			nextPutAll: (self jsonEscape: ((self environmentAt: 'GS_NETLDI_HOST' ifAbsent: [ '' ]) ifEmpty: [ 'implicit' ]));
			nextPutAll: '","net":"';
			nextPutAll: (self jsonEscape: ((self environmentAt: 'GS_NETLDI_NAME_OR_PORT' ifAbsent: [ '' ]) ifEmpty: [ 'implicit' ]));
			nextPutAll: '","stone_status":"';
			nextPutAll: (self jsonEscape: stoneStatus);
			nextPutAll: '","netldi_status":"';
			nextPutAll: (self jsonEscape: netldiStatus);
			nextPutAll: '","topaz":"';
			nextPutAll: (self jsonEscape: topazStatus);
			nextPutAll: '","gci":"';
			nextPutAll: (self jsonEscape: gciStatus);
			nextPutAll: '"}' ].
	self log: 'LIVE_PREFLIGHT_SUMMARY_JSON ', payload
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> emitPreflightSummaryResult: result code: code stoneStatus: stoneStatus netldiStatus: netldiStatus topazStatus: topazStatus gciStatus: gciStatus [
	self
		log: 'LIVE_PREFLIGHT_SUMMARY result=', result,
			' code=', code,
			' stone=', (self environmentAt: 'GS_STONE' ifAbsent: [ 'gs64stone' ]),
			' service=', (self environmentAt: 'GS_SERVICE' ifAbsent: [ 'gemnetobject' ]),
			' host=', ((self environmentAt: 'GS_NETLDI_HOST' ifAbsent: [ '' ]) ifEmpty: [ 'implicit' ]),
			' net=', ((self environmentAt: 'GS_NETLDI_NAME_OR_PORT' ifAbsent: [ '' ]) ifEmpty: [ 'implicit' ]),
			' stone_status=', stoneStatus,
			' netldi_status=', netldiStatus,
			' topaz=', topazStatus,
			' gci=', gciStatus.
	self summaryJsonEnabled ifTrue: [
		self
			emitPreflightSummaryJsonResult: result
			code: code
			stoneStatus: stoneStatus
			netldiStatus: netldiStatus
			topazStatus: topazStatus
			gciStatus: gciStatus ]
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> gciProbeOutput [
	^ gciProbeOutputBlock
		ifNil: [ self defaultGciProbeOutput ]
		ifNotNil: [ gciProbeOutputBlock value ]
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> gciProbeOutputBlock: aBlock [
	gciProbeOutputBlock := aBlock
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> gslistOutput [
	^ gslistOutputBlock
		ifNil: [ self defaultGslistOutput ]
		ifNotNil: [ gslistOutputBlock value ]
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> gslistOutputBlock: aBlock [
	gslistOutputBlock := aBlock
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> imagePath [
	| configuredPath |
	configuredPath := self environmentAt: 'GBS_WORK_IMAGE' ifAbsent: [ '' ].
	configuredPath isNotEmpty ifTrue: [ ^ configuredPath ].
	^ imagePathBlock
		ifNil: [
			[ Smalltalk image imageFile asString ]
				on: Error
				do: [ '<unknown-image>' ] ]
		ifNotNil: [ imagePathBlock value ]
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> imagePathBlock: aBlock [
	imagePathBlock := aBlock
]

{ #category : 'initialization' }
GemStonePharoVerificationRunner >> initialize [
	super initialize.
	logBlock := [ :line | Transcript show: line; cr ]
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> laneName [
	^ self class laneNameFromEnvironment: self environment
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> laneRunBlock: aBlock [
	laneRunBlock := aBlock
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> log: aString [
	logBlock value: aString
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> logBlock: aBlock [
	logBlock := aBlock
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> logOutput: output [
	| normalized |
	normalized := (output ifNil: [ '' ])
		copyReplaceAll: (String with: Character cr)
		with: (String with: Character lf).
	(normalized findTokens: (String with: Character lf))
		do: [ :line | line isEmpty ifFalse: [ self log: line ] ]
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> outputLinesFor: output [
	| normalized |
	normalized := (output ifNil: [ '' ])
		copyReplaceAll: (String with: Character cr)
		with: (String with: Character lf).
	^ normalized findTokens: (String with: Character lf)
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> jsonEscape: aString [
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
GemStonePharoVerificationRunner >> preflightRunBlock: aBlock [
	preflightRunBlock := aBlock
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> originalTestsPreparationBlock: aBlock [
	originalTestsPreparationBlock := aBlock
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> prepareOriginalTestsSession [
	^ originalTestsPreparationBlock
		ifNil: [ self defaultPrepareOriginalTestsSession ]
		ifNotNil: [ originalTestsPreparationBlock value ]
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> releaseOriginalTestsSession [
	| liveSessionSupportClass |
	liveSessionSupportClass := Smalltalk
		at: #GbsLiveSessionTestSupport
		ifAbsent: [ nil ].
	liveSessionSupportClass ifNil: [ ^ self ].
	[ liveSessionSupportClass releaseOwnedSession ]
		on: Error
		do: [ :ex | self log: 'ORIGINAL_TESTS_SESSION_RELEASE_ERROR: ', ex messageText ]
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> summaryJsonEnabled [
	^ GemStonePharoReloadRunner
		booleanFlagNamed: 'GBS_JSON_SUMMARY'
		fromEnvironment: self environment
]

{ #category : 'running' }
GemStonePharoVerificationRunner >> runCoreOnlyVerification [
	| unitOk |
	unitOk := self
		runRegressionLaneNamed: 'unit'
		packageFilter: 'GemStone-Pharo-Core-Tests'.
	unitOk
		ifTrue: [
			self
				emitCoreOnlySummaryResult: 'OK'
				code: 'BRIDGE_CORE_ONLY_CHECK_OK'
				unitStatus: 'ok' ]
		ifFalse: [
			self
				emitCoreOnlySummaryResult: 'FAIL'
				code: 'CORE_ONLY_UNIT_REGRESSION_FAILED'
				unitStatus: 'failed' ].
	^ unitOk
]

{ #category : 'running' }
GemStonePharoVerificationRunner >> runFullVerification [
	| unitOk preflightResult liveOk |
	unitOk := self
		runRegressionLaneNamed: 'unit'
		packageFilter: nil.
	unitOk ifFalse: [
		self
			emitFullSummaryResult: 'FAIL'
			code: 'UNIT_REGRESSION_FAILED'
			unitStatus: 'failed'
			preflightStatus: 'skipped'
			liveStatus: 'skipped'.
		^ false ].

	self credentialsAvailable ifFalse: [
		self log: 'LIVE_REGRESSION_SKIPPED: set GS_USER and GS_PASS to run integration lane'.
		self
			emitFullSummaryResult: 'OK'
			code: 'CLEAN_RELOAD_AND_REGRESSION_RUN_DONE'
			unitStatus: 'ok'
			preflightStatus: 'skipped'
			liveStatus: 'skipped'.
		^ true ].

	preflightResult := self runPreflight.
	preflightResult first = #ok ifFalse: [
		self
			emitFullSummaryResult: 'FAIL'
			code: preflightResult second
			unitStatus: 'ok'
			preflightStatus: 'failed'
			liveStatus: 'skipped'.
		^ false ].

	(self prepareOriginalTestsSession) ifFalse: [
		self
			emitFullSummaryResult: 'FAIL'
			code: 'LIVE_REGRESSION_SESSION_PREP_FAILED'
			unitStatus: 'ok'
			preflightStatus: 'ok'
			liveStatus: 'skipped'.
		^ false ].

	liveOk := [
		self
			runRegressionLaneNamed: 'live'
			packageFilter: nil ]
		ensure: [ self releaseOriginalTestsSession ].
	liveOk
		ifTrue: [
			self
				emitFullSummaryResult: 'OK'
				code: 'CLEAN_RELOAD_AND_REGRESSION_RUN_DONE'
				unitStatus: 'ok'
				preflightStatus: 'ok'
				liveStatus: 'ok' ]
		ifFalse: [
			self
				emitFullSummaryResult: 'FAIL'
				code: 'LIVE_REGRESSION_FAILED'
				unitStatus: 'ok'
				preflightStatus: 'ok'
				liveStatus: 'failed' ].
	^ liveOk
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> runOriginalVerification [
	self log: 'ORIGINAL_LIVE_SKIPPED: Original lane proves the base/original production load only.'.
	self
		emitOriginalSummaryResult: 'OK'
		code: 'ORIGINAL_CHECK_OK'
		unitStatus: 'skipped'
		preflightStatus: 'skipped'
		liveStatus: 'skipped'.
	^ true
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> runOriginalTestsVerification [
	| unitOk |
	^ [
		(self prepareOriginalTestsSession) ifFalse: [
			self
				emitOriginalTestsSummaryResult: 'FAIL'
				code: 'ORIGINAL_TESTS_SESSION_PREP_FAILED'
				unitStatus: 'skipped'
				preflightStatus: 'skipped'
				liveStatus: 'skipped'.
			^ false ].
		unitOk := self
			runRegressionLaneNamed: 'unit'
			packageFilter: 'GemStone-Pharo-Tests'.
		unitOk ifFalse: [
			self
				emitOriginalTestsSummaryResult: 'FAIL'
				code: 'ORIGINAL_TESTS_UNIT_REGRESSION_FAILED'
				unitStatus: 'failed'
				preflightStatus: 'skipped'
				liveStatus: 'skipped'.
			^ false ].
		self log: 'ORIGINAL_TESTS_LIVE_SKIPPED: Original-Tests lane proves the base/original unit layer only.'.
		self
			emitOriginalTestsSummaryResult: 'OK'
			code: 'ORIGINAL_TESTS_CHECK_OK'
			unitStatus: 'ok'
			preflightStatus: 'skipped'
			liveStatus: 'skipped'.
		true ]
		ensure: [ self releaseOriginalTestsSession ]
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> runPreflight [
	^ preflightRunBlock
		ifNil: [ self defaultPreflightResult ]
		ifNotNil: [ preflightRunBlock value ]
]

{ #category : 'running' }
GemStonePharoVerificationRunner >> runStandalonePreflight [
	| stoneName stoneStatus netldiStatus topazStatus gciStatus gslistOutput topazOutput gciOutput failureCode |
	stoneName := self environmentAt: 'GS_STONE' ifAbsent: [ 'gs64stone' ].
	stoneStatus := 'unknown'.
	netldiStatus := 'unknown'.
	topazStatus := 'skipped'.
	gciStatus := 'skipped'.

	self credentialsAvailable ifFalse: [
		self log: 'LIVE_PREFLIGHT_SKIPPED: set GS_USER and GS_PASS to run preflight'.
		self
			emitPreflightSummaryResult: 'SKIP'
			code: 'LIVE_PREFLIGHT_SKIPPED'
			stoneStatus: stoneStatus
			netldiStatus: netldiStatus
			topazStatus: topazStatus
			gciStatus: gciStatus.
		^ { #skipped. 'LIVE_PREFLIGHT_SKIPPED' } ].

	self
		log: 'LIVE_PREFLIGHT_BEGIN stone=', stoneName,
			' service=', (self environmentAt: 'GS_SERVICE' ifAbsent: [ 'gemnetobject' ]),
			' host=', ((self environmentAt: 'GS_NETLDI_HOST' ifAbsent: [ '' ]) ifEmpty: [ '(implicit)' ]),
			' net=', ((self environmentAt: 'GS_NETLDI_NAME_OR_PORT' ifAbsent: [ '' ]) ifEmpty: [ '(implicit)' ]).

	gslistOutput := self gslistOutput.
	self logOutput: gslistOutput.
	((self outputLinesFor: gslistOutput)
		anySatisfy: [ :line |
			(line beginsWith: 'OK')
				and: [ (line includesSubstring: 'Stone')
				and: [ line trimBoth endsWith: stoneName ] ] ])
		ifTrue: [
			stoneStatus := 'ok'.
			self log: 'LIVE_PREFLIGHT_STONE_OK ', stoneName ]
		ifFalse: [ self log: 'LIVE_PREFLIGHT_STONE_STATUS_UNKNOWN ', stoneName ].
	((self outputLinesFor: gslistOutput)
		anySatisfy: [ :line |
			(line beginsWith: 'OK')
				and: [ line includesSubstring: 'Netldi' ] ])
		ifTrue: [
			netldiStatus := 'ok'.
			self log: 'LIVE_PREFLIGHT_NETLDI_OK' ]
		ifFalse: [ self log: 'LIVE_PREFLIGHT_NETLDI_STATUS_UNKNOWN' ].

	topazOutput := self topazOutput.
	self logOutput: topazOutput.
	((topazOutput asLowercase includesSubstring: 'login failed'))
		ifTrue: [
			topazStatus := 'failed'.
			failureCode := self classifyTopazFailureOutput: topazOutput.
			self log: failureCode.
			self
				emitPreflightSummaryResult: 'FAIL'
				code: failureCode
				stoneStatus: stoneStatus
				netldiStatus: netldiStatus
				topazStatus: topazStatus
				gciStatus: gciStatus.
			^ { #failed. failureCode } ].
	(topazOutput includesSubstring: 'LIVE_PREFLIGHT_TOPAZ_UNAVAILABLE')
		ifTrue: [
			topazStatus := 'unavailable'.
			self log: 'LIVE_PREFLIGHT_TOPAZ_UNAVAILABLE' ]
		ifFalse: [
			topazStatus := 'ok'.
			self log: 'LIVE_PREFLIGHT_TOPAZ_LOGIN_OK' ].

	gciOutput := self gciProbeOutput.
	self logOutput: gciOutput.
	(gciOutput includesSubstring: 'PROBE_LOGIN_OK')
		ifTrue: [
			gciStatus := 'ok'.
			self log: 'LIVE_PREFLIGHT_GCI_LOGIN_OK'.
			self log: 'LIVE_PREFLIGHT_OK'.
			self
				emitPreflightSummaryResult: 'OK'
				code: 'LIVE_PREFLIGHT_OK'
				stoneStatus: stoneStatus
				netldiStatus: netldiStatus
				topazStatus: topazStatus
				gciStatus: gciStatus.
			^ { #ok. 'LIVE_PREFLIGHT_OK' } ].

	gciStatus := 'failed'.
	failureCode := self classifyGciFailureOutput: gciOutput.
	self log: failureCode.
	self
		emitPreflightSummaryResult: 'FAIL'
		code: failureCode
		stoneStatus: stoneStatus
		netldiStatus: netldiStatus
		topazStatus: topazStatus
		gciStatus: gciStatus.
	^ { #failed. failureCode }
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> runRegressionLaneNamed: laneName packageFilter: packageFilter [
	^ laneRunBlock
		ifNil: [ self defaultRunRegressionLaneNamed: laneName packageFilter: packageFilter ]
		ifNotNil: [ laneRunBlock value: laneName value: packageFilter ]
]

{ #category : 'running' }
GemStonePharoVerificationRunner >> runVerificationLane [
	self laneName = 'core-only' ifTrue: [ ^ self runCoreOnlyVerification ].
	self laneName = 'original' ifTrue: [ ^ self runOriginalVerification ].
	self laneName = 'original-tests' ifTrue: [ ^ self runOriginalTestsVerification ].
	self laneName = 'full' ifTrue: [ ^ self runFullVerification ].
	self
		log: 'VERIFY_LANE_FAILED unknown lane ', self laneName.
	^ false
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> shellQuoted: aString [
	| escaped |
	escaped := aString.
	escaped := escaped copyReplaceAll: '\' with: '\\'.
	escaped := escaped copyReplaceAll: '"' with: '\"'.
	escaped := escaped copyReplaceAll: '$' with: '\$'.
	escaped := escaped copyReplaceAll: '`' with: '\`'.
	^ '"' , escaped , '"'
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> transcriptProxyInstallScript [
	^ '
	| tempDict proxyClass |
	tempDict := System myUserProfile symbolList
		detect: [ :each |
			(each respondsTo: #name)
				and: [ each name = #PharoSessionGlobals ] ]
		ifNone: [ nil ].
	tempDict ifNil: [
		tempDict := SymbolDictionary new name: #PharoSessionGlobals.
		System myUserProfile insertDictionary: tempDict at: 1 ].
	proxyClass := tempDict at: #Transcript ifAbsent: [ nil ].
	(proxyClass isNil or: [ proxyClass isBehavior not ]) ifTrue: [
		proxyClass := Object subclass: <quote>PharoTranscriptProxy<quote>
			instVarNames: #()
			classVars: #()
			classInstVars: #(<quote>currentLine<quote>)
			poolDictionaries: #()
			inDictionary: tempDict
			options: #().
		tempDict at: #Transcript put: proxyClass ].
	proxyClass class compileMethod: <quote>show: aString
		currentLine := (currentLine ifNil: [ String new ]), aString asString.<quote> category: <quote>logging<quote>.
	proxyClass class compileMethod: <quote>cr
		| log |
		log := UserGlobals at: #PharoTranscriptLog ifAbsentPut: [ OrderedCollection new ].
		log add: (currentLine ifNil: [ String new ]).
		currentLine := String new.<quote> category: <quote>logging<quote>.
	proxyClass class compileMethod: <quote>fetchAndClear
		| log text |
		log := UserGlobals at: #PharoTranscriptLog ifAbsentPut: [ OrderedCollection new ].
		text := String streamContents: [ :stream |
			log do: [ :each |
				stream nextPutAll: each asString.
				stream cr ] ].
		UserGlobals at: #PharoTranscriptLog put: OrderedCollection new.
		^ text<quote> category: <quote>logging<quote>.
	UserGlobals at: #PharoTranscriptLog put: OrderedCollection new.
	true
	' copyReplaceAll: '<quote>' with: ''''
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> topazOutput [
	^ topazOutputBlock
		ifNil: [ self defaultTopazOutput ]
		ifNotNil: [ topazOutputBlock value ]
]

{ #category : 'private' }
GemStonePharoVerificationRunner >> topazOutputBlock: aBlock [
	topazOutputBlock := aBlock
]
