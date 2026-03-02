Class {
	#name : 'TestableGbsWorkspace',
	#superclass : 'GbsWorkspace',
	#instVars : [
		'debuggerOpened'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'initialization' }
TestableGbsWorkspace >> debuggerOpened [

  ^ debuggerOpened ifNil: [ false ]
]

{ #category : 'initialization' }
TestableGbsWorkspace >> openRemoteDebuggerOn: anException session: aSession [
  "Instead of opening the physical window, just flip our test flag to true!"

  debuggerOpened := true
]
