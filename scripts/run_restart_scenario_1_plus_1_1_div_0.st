| debugger service fakeText fakeList nonExecuted executed topFrame sourceString debuggerClass serviceClass textClass tableClass listClass activationClass |
[
	[ Metacello new
		baseline: 'GemStonePharo';
		repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
		load: 'default' ] on: Error do: [ :ex |
			Transcript show: 'LOAD_ERROR: ', ex messageText; cr ].

	debuggerClass := Smalltalk at: #GbsRemoteDebugger ifAbsent: [ Error signal: 'Missing class GbsRemoteDebugger' ].
	serviceClass := Smalltalk at: #GbxFakeServiceForRemoteDebugger ifAbsent: [ Error signal: 'Missing class GbxFakeServiceForRemoteDebugger' ].
	textClass := Smalltalk at: #GbxFakeTextPresenterForRemoteDebugger ifAbsent: [ Error signal: 'Missing class GbxFakeTextPresenterForRemoteDebugger' ].
	tableClass := Smalltalk at: #GbxFakeTablePresenterForRemoteDebugger ifAbsent: [ Error signal: 'Missing class GbxFakeTablePresenterForRemoteDebugger' ].
	listClass := Smalltalk at: #GbxFakeListPresenterForRemoteDebugger ifAbsent: [ Error signal: 'Missing class GbxFakeListPresenterForRemoteDebugger' ].
	activationClass := Smalltalk at: #GbxActivation ifAbsent: [ Error signal: 'Missing class GbxActivation' ].

	debugger := debuggerClass new.
	service := serviceClass new.
	debugger service: service.

	fakeText := textClass new.
	fakeText text: ''.
	debugger instVarNamed: 'sourceText' put: fakeText.
	debugger instVarNamed: 'variablesTable' put: tableClass new.
	debugger instVarNamed: 'receiverInfoTable' put: tableClass new.
	debugger instVarNamed: 'frameInfoTable' put: tableClass new.
	debugger instVarNamed: 'processInfoTable' put: tableClass new.
	fakeList := listClass new.
	debugger instVarNamed: 'stackList' put: fakeList.

	nonExecuted := activationClass new.
	nonExecuted
		processOop: 111;
		level: 1;
		initializeFromClass: 'SmallInteger'
			selector: #/
			source: '1+1.', String lf, String lf, '1/0'
			contextOop: 111;
		quickStepPoint: 3;
		sourceOffsets: #(1 6 7);
		ipOffset: 3.

	executed := activationClass new.
	executed
		processOop: 111;
		level: 2;
		initializeFromClass: 'nil'
			selector: #unboundMethod
			source: '1+1.', String lf, String lf, '1/0'
			contextOop: 111;
		quickStepPoint: 3;
		sourceOffsets: #(1 6 7);
		ipOffset: 3.

	service contextList: { nonExecuted. executed }.

	(debugger restart) ifFalse: [ Error signal: 'restart returned false' ].
	topFrame := (debugger instVarNamed: 'contextList') first printString.
	(topFrame = 'GS: Executed code @1 line 1')
		ifFalse: [ Error signal: 'top frame mismatch: ', topFrame ].
	(fakeText selectionInterval = (1 to: 1))
		ifFalse: [ Error signal: 'source selection not at start' ].
	sourceString := fakeText text asString.
	((sourceString includesSubstring: '1+1.') and: [ sourceString includesSubstring: '1/0' ])
		ifFalse: [ Error signal: 'source text missing expected code' ].

	Transcript show: 'RESTART_SCENARIO_OK top=', topFrame; cr.
] ensure: [ Smalltalk snapshot: false andQuit: true ].
