Class {
	#name : 'GbxFakeBrowserForService',
	#superclass : 'Object',
	#classVars : [
		'LastBreakView',
		'LastModel',
		'LastMethod',
		'LastClass'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'breakpoint support' }
GbxFakeBrowserForService class >> setBreakInView: aView model: aModel method: aSelector class: aClassName [
	LastBreakView := aView.
	LastModel := aModel.
	LastMethod := aSelector.
	LastClass := aClassName.
]

{ #category : 'accessing' }
GbxFakeBrowserForService class >> lastBreakView [
	^ LastBreakView
]

{ #category : 'accessing' }
GbxFakeBrowserForService class >> lastModel [
	^ LastModel
]

{ #category : 'accessing' }
GbxFakeBrowserForService class >> lastMethod [
	^ LastMethod
]

{ #category : 'accessing' }
GbxFakeBrowserForService class >> lastClass [
	^ LastClass
]

{ #category : 'accessing' }
GbxFakeBrowserForService class >> reset [
	LastBreakView := nil.
	LastModel := nil.
	LastMethod := nil.
	LastClass := nil
]
