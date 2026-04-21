Class {
	#name : 'GemStonePharoVerifyRunnerTest',
	#superclass : 'TestCase',
	#instVars : [
		'runner',
		'logLines',
		'stepCalls'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'running' }
GemStonePharoVerifyRunnerTest >> setUp [
	super setUp.
	logLines := OrderedCollection new.
	stepCalls := OrderedCollection new.
	runner := GemStonePharoVerifyRunner
		onEnvironment: Dictionary new
		log: [ :line | logLines add: line ]
]

{ #category : 'tests' }
GemStonePharoVerifyRunnerTest >> testRunVerifyRunsStepsInContractOrderAndEmitsSuccessSummary [
	runner stepRunBlock: [ :stepName |
		stepCalls add: stepName.
		true ].

	self assert: runner runVerify.
	self assert: stepCalls asArray equals: #('core-only' 'bootstrap-smoke' 'full' 'artifact-freshness' 'summary-renderer').
	self assert: (logLines anySatisfy: [ :each |
		each includesSubstring: 'VERIFY_SUMMARY result=OK code=VERIFY_OK core_only=ok bootstrap_smoke=ok full=ok artifact_freshness=ok summary_renderer=ok' ])
]

{ #category : 'tests' }
GemStonePharoVerifyRunnerTest >> testRunVerifyStopsAfterFailureAndSkipsRemainingSteps [
	runner stepRunBlock: [ :stepName |
		stepCalls add: stepName.
		stepName ~= 'bootstrap-smoke' ].

	self deny: runner runVerify.
	self assert: stepCalls asArray equals: #('core-only' 'bootstrap-smoke').
	self assert: (runner statusForStepNamed: 'core-only') equals: 'ok'.
	self assert: (runner statusForStepNamed: 'bootstrap-smoke') equals: 'failed'.
	self assert: (runner statusForStepNamed: 'full') equals: 'skipped'.
	self assert: (runner statusForStepNamed: 'artifact-freshness') equals: 'skipped'.
	self assert: (runner statusForStepNamed: 'summary-renderer') equals: 'skipped'.
	self assert: (logLines anySatisfy: [ :each |
		each includesSubstring: 'VERIFY_SUMMARY result=FAIL code=BOOTSTRAP_SMOKE_FAILED core_only=ok bootstrap_smoke=failed full=skipped artifact_freshness=skipped summary_renderer=skipped' ])
]

{ #category : 'tests' }
GemStonePharoVerifyRunnerTest >> testSourceImageAndWorkDirectoryReadEnvironmentOverrides [
	runner := GemStonePharoVerifyRunner
		onEnvironment: (Dictionary newFromPairs: {
			'GBS_VERIFY_IMAGE'. '/tmp/custom.image'.
			'GBS_VERIFY_WORK_DIR'. '/tmp/custom-dir' })
		log: [ :line | logLines add: line ].

	self assert: runner sourceImagePath equals: '/tmp/custom.image'.
	self assert: runner workDirectoryPath equals: '/tmp/custom-dir'
]
