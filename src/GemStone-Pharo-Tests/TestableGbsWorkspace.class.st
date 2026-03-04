Class {
	#name : 'TestableGbsWorkspace',
	#superclass : 'GbsWorkspace',
	#instVars : [
		'debuggerOpened',
		'lastOpenedProcessOop'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'initialization' }
TestableGbsWorkspace >> debuggerOpened [

  ^ debuggerOpened ifNil: [ false ]
]

{ #category : 'initialization' }
TestableGbsWorkspace >> openRemoteDebuggerOn: anException processOop: processOop session: aSession [
  "Instead of opening the physical window, just flip our test flag to true!"

  debuggerOpened := true.
  lastOpenedProcessOop := processOop
]

{ #category : 'initialization' }
TestableGbsWorkspace >> lastOpenedProcessOop [

  ^ lastOpenedProcessOop
]
