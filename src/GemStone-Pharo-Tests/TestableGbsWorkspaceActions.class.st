Class {
	#name : 'TestableGbsWorkspaceActions',
	#superclass : 'GbsWorkspace',
	#instVars : [
		'didDoIt',
		'didInspectIt',
		'didPrintIt'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'actions' }
TestableGbsWorkspaceActions >> doIt [
	didDoIt := true.
	^ true
]

{ #category : 'actions' }
TestableGbsWorkspaceActions >> inspectIt [
	didInspectIt := true.
	^ true
]

{ #category : 'actions' }
TestableGbsWorkspaceActions >> gemStonePrintIt [
	didPrintIt := true.
	^ true
]

{ #category : 'accessing' }
TestableGbsWorkspaceActions >> didDoIt [
	^ didDoIt = true
]

{ #category : 'accessing' }
TestableGbsWorkspaceActions >> didInspectIt [
	^ didInspectIt = true
]

{ #category : 'accessing' }
TestableGbsWorkspaceActions >> didPrintIt [
	^ didPrintIt = true
]
