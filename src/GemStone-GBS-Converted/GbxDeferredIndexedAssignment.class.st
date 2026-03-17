Class {
	#name : 'GbxDeferredIndexedAssignment',
	#superclass : 'GbxDeferredAssignment',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'resolving' }
GbxDeferredIndexedAssignment >> assignValue: val 
[
	buffer indexableValueAt: clientOffset put: val
]

