Class {
	#name : 'GemStonePharoVerificationRunnerTest',
	#superclass : 'TestCase',
	#instVars : [
		'runner',
		'logLines',
		'laneCalls'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'running' }
GemStonePharoVerificationRunnerTest >> setUp [
	super setUp.
	logLines := OrderedCollection new.
	laneCalls := OrderedCollection new.
	runner := GemStonePharoVerificationRunner
		onEnvironment: Dictionary new
		log: [ :line | logLines add: line ].
	runner imagePathBlock: [ '/tmp/test.image' ]
]

{ #category : 'tests' }
GemStonePharoVerificationRunnerTest >> testCoreOnlyLaneRunsUnitLaneWithCorePackageFilterAndEmitsSuccessSummary [
	runner
		environment: (Dictionary newFromPairs: { 'GBS_VERIFY_LANE'. 'core-only' });
		laneRunBlock: [ :laneName :packageFilter |
			laneCalls add: { laneName. packageFilter }.
			true ].

	self assert: runner runVerificationLane.
	self assert: laneCalls asArray equals: #(#('unit' 'GemStone-Pharo-Core-Tests')).
	self assert: (logLines anySatisfy: [ :each |
		each includesSubstring: 'CORE_ONLY_VERIFICATION_SUMMARY result=OK code=BRIDGE_CORE_ONLY_CHECK_OK unit=ok' ]).
	self assert: (logLines includes: 'BRIDGE_CORE_ONLY_CHECK_OK')
]

{ #category : 'tests' }
GemStonePharoVerificationRunnerTest >> testFullLaneFailsWhenPreflightFails [
	runner
		environment: (Dictionary newFromPairs: {
			'GBS_VERIFY_LANE'. 'full'.
			'GS_USER'. 'DataCurator'.
			'GS_PASS'. 'swordfish' });
		laneRunBlock: [ :laneName :packageFilter |
			laneCalls add: { laneName. packageFilter }.
			true ];
		preflightRunBlock: [ { #failed. 'LIVE_PREFLIGHT_GCI_ROUTE_FAILED' } ].

	self deny: runner runVerificationLane.
	self assert: laneCalls asArray equals: #(#('unit' nil)).
	self assert: (logLines anySatisfy: [ :each |
		each includesSubstring: 'CLEAN_RELOAD_AND_REGRESSION_SUMMARY result=FAIL code=LIVE_PREFLIGHT_GCI_ROUTE_FAILED reload=ok unit=ok preflight=failed live=skipped' ]).
	self assert: (logLines includes: 'CLEAN_RELOAD_AND_REGRESSION_FAILED')
]

{ #category : 'tests' }
GemStonePharoVerificationRunnerTest >> testFullLaneRunsUnitPreflightAndLiveWhenCredentialsExist [
	runner
		environment: (Dictionary newFromPairs: {
			'GBS_VERIFY_LANE'. 'full'.
			'GS_USER'. 'DataCurator'.
			'GS_PASS'. 'swordfish' });
		laneRunBlock: [ :laneName :packageFilter |
			laneCalls add: { laneName. packageFilter }.
			true ];
		preflightRunBlock: [ { #ok. 'LIVE_PREFLIGHT_OK' } ].

	self assert: runner runVerificationLane.
	self
		assert: laneCalls asArray
		equals: #(#('unit' nil) #('live' nil)).
	self assert: (logLines anySatisfy: [ :each |
		each includesSubstring: 'CLEAN_RELOAD_AND_REGRESSION_SUMMARY result=OK code=CLEAN_RELOAD_AND_REGRESSION_RUN_DONE reload=ok unit=ok preflight=ok live=ok' ]).
	self assert: (logLines includes: 'CLEAN_RELOAD_AND_REGRESSION_RUN_DONE')
]

{ #category : 'tests' }
GemStonePharoVerificationRunnerTest >> testFullLaneSkipsPreflightAndLiveWithoutCredentials [
	runner
		environment: (Dictionary newFromPairs: { 'GBS_VERIFY_LANE'. 'full' });
		laneRunBlock: [ :laneName :packageFilter |
			laneCalls add: { laneName. packageFilter }.
			true ].

	self assert: runner runVerificationLane.
	self assert: laneCalls asArray equals: #(#('unit' nil)).
	self assert: (logLines includes: 'LIVE_REGRESSION_SKIPPED: set GS_USER and GS_PASS to run integration lane').
	self assert: (logLines anySatisfy: [ :each |
		each includesSubstring: 'CLEAN_RELOAD_AND_REGRESSION_SUMMARY result=OK code=CLEAN_RELOAD_AND_REGRESSION_RUN_DONE reload=ok unit=ok preflight=skipped live=skipped' ])
]

{ #category : 'tests' }
GemStonePharoVerificationRunnerTest >> testLaneNameDefaultsToFull [
	self
		assert: (GemStonePharoVerificationRunner laneNameFromEnvironment: Dictionary new)
		equals: 'full'
]

{ #category : 'tests' }
GemStonePharoVerificationRunnerTest >> testImagePathPrefersExplicitWorkImageEnvironment [
	runner environment: (Dictionary newFromPairs: { 'GBS_WORK_IMAGE'. '/tmp/work.image' }).

	self assert: runner imagePath equals: '/tmp/work.image'
]

{ #category : 'tests' }
GemStonePharoVerificationRunnerTest >> testStandalonePreflightFailsWhenTopazLoginFails [
	| gciCalled result |
	gciCalled := false.
	runner
		environment: (Dictionary newFromPairs: {
			'GS_USER'. 'DataCurator'.
			'GS_PASS'. 'wrong' });
		gslistOutputBlock: [ '' ];
		topazOutputBlock: [ 'Login failed: the userId/password combination is invalid or expired.' ];
		gciProbeOutputBlock: [ gciCalled := true. 'PROBE_LOGIN_OK sessionId=1' ].

	result := runner runStandalonePreflight.

	self assert: result first equals: #failed.
	self assert: result second equals: 'LIVE_PREFLIGHT_AUTH_FAILED'.
	self deny: gciCalled.
	self assert: (logLines includes: 'LIVE_PREFLIGHT_AUTH_FAILED').
	self assert: (logLines anySatisfy: [ :each |
		each includesSubstring: 'LIVE_PREFLIGHT_SUMMARY result=FAIL code=LIVE_PREFLIGHT_AUTH_FAILED' ])
]

{ #category : 'tests' }
GemStonePharoVerificationRunnerTest >> testStandalonePreflightReturnsOkWhenTopazAndGciSucceed [
	| result |
	runner
		environment: (Dictionary newFromPairs: {
			'GS_STONE'. 'gs64stone'.
			'GS_SERVICE'. 'gemnetobject'.
			'GS_USER'. 'DataCurator'.
			'GS_PASS'. 'swordfish' });
		gslistOutputBlock: [ 'OK 3.7.5 tariq 84598 50377 Apr 16 14:57 Netldi gs64ldi', String lf, 'OK 3.7.5 tariq 84672 54551 Apr 16 14:59 Stone gs64stone' ];
		topazOutputBlock: [ 'successful topaz login' ];
		gciProbeOutputBlock: [ 'PROBE_LOGIN_OK sessionId=1' ].

	result := runner runStandalonePreflight.

	self assert: result first equals: #ok.
	self assert: result second equals: 'LIVE_PREFLIGHT_OK'.
	self assert: (logLines includes: 'LIVE_PREFLIGHT_STONE_OK gs64stone').
	self assert: (logLines includes: 'LIVE_PREFLIGHT_NETLDI_OK').
	self assert: (logLines includes: 'LIVE_PREFLIGHT_TOPAZ_LOGIN_OK').
	self assert: (logLines includes: 'LIVE_PREFLIGHT_GCI_LOGIN_OK').
	self assert: (logLines anySatisfy: [ :each |
		each includesSubstring: 'LIVE_PREFLIGHT_SUMMARY result=OK code=LIVE_PREFLIGHT_OK stone=gs64stone service=gemnetobject host=implicit net=implicit stone_status=ok netldi_status=ok topaz=ok gci=ok' ])
]

{ #category : 'tests' }
GemStonePharoVerificationRunnerTest >> testStandalonePreflightSkipsWithoutCredentials [
	| result |
	result := runner runStandalonePreflight.

	self assert: result first equals: #skipped.
	self assert: result second equals: 'LIVE_PREFLIGHT_SKIPPED'.
	self assert: (logLines includes: 'LIVE_PREFLIGHT_SKIPPED: set GS_USER and GS_PASS to run preflight').
	self assert: (logLines anySatisfy: [ :each |
		each includesSubstring: 'LIVE_PREFLIGHT_SUMMARY result=SKIP code=LIVE_PREFLIGHT_SKIPPED' ])
]
