Class {
	#name : 'GbxDeferredNamedAssignment',
	#superclass : 'GbxDeferredAssignment',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'resolving' }
GbxDeferredNamedAssignment >> assignValue: val 
	buffer namedValueAt: clientOffset put: val

