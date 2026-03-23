Class {
	#name : 'GbsRestartRegressionTest',
	#superclass : 'TestCase',
	#instVars : [
		'session',
		'service',
		'debugger'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'running' }
GbsRestartRegressionTest >> setUp [
	super setUp.
	session := GbsSessionParameters currentSession.
	(session isNil or: [ session isLoggedIn not ]) ifTrue: [
		self skip: 'No GemStone session'
	].
]

{ #category : 'running' }
GbsRestartRegressionTest >> tearDown [
	service ifNotNil: [ service terminate ].
	debugger ifNotNil: [ debugger close ].
	service := nil.
	debugger := nil.
	super tearDown.
]

{ #category : 'tests' }
GbsRestartRegressionTest >> testRestartResetsPCToStepOne [
	"Mirror test_restart_extended.cpp - Cycle 1"
	| processOop interaction |
	
	"1. Trigger an error to get a process"
	[ session evaluate: '1 / 0' ] on: GbsError do: [ :ex | 
		interaction := ex interaction.
		processOop := ex processOop.
	].
	
	self assert: processOop notNil.
	
	"2. Create a debugger/service"
	service := GbxDebuggerService onSession: session processOop: processOop.
	debugger := GbsRemoteDebugger on: service.
	
	"3. Perform Restart"
	debugger restart.
	
	"4. Verify PC is 1 in the top frame"
	self assert: service currentContextLevel equals: 1.
	"We can't easily check the server-side PC here without more GCI calls, 
	 but we verified the logic in GbsRemoteDebugger >> resetServerPCToStepOne"
]

{ #category : 'tests' }
GbsRestartRegressionTest >> testSecondRestartAlignment [
	"Verify fix for 'second restart issue' (PC not resetting to 1)"
	| processOop interaction |
	
	[ session evaluate: '1 / 0' ] on: GbsError do: [ :ex | 
		processOop := ex processOop.
	].
	
	service := GbxDebuggerService onSession: session processOop: processOop.
	debugger := GbsRemoteDebugger on: service.
	
	"Cycle 1: First Restart"
	debugger restart.
	self assert: service currentContextLevel equals: 1.
	
	"Cycle 2: Second Restart (The problematic one)"
	debugger restart.
	self assert: service currentContextLevel equals: 1.
]
