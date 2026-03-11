Class {
	#name : 'GbxBrowser',
	#superclass : 'Model',
	#instVars : [
		'session',
		'userProfile',
		'methodTabSetting',
		'textMode',
		'dictionaryList',
		'classList',
		'protocolList',
		'methodList',
		'textValue',
		'stepPoint',
		'tabs',
		'metaClass',
		'left',
		'right',
		'methodSymbols',
		'classIsModifiable',
		'sourceText',
		'breakPointList'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'breakpoint support' }
GbxBrowser class >> setBreakInView: aView model: aModel method: aSelector class: aClassName [
	| bpClass step existing |
	bpClass := Smalltalk at: #GbxBreakPoint ifAbsent: [ ^ self ].
	step := self stepPointForBreakInView: aView model: aModel.
	(step isNumber and: [ step > 0 ]) ifFalse: [ step := 1 ].
	existing := (bpClass breakPointListFor: nil)
		detect: [ :bp |
			(bp respondsTo: #selector)
				and: [ (bp respondsTo: #remoteClass)
				and: [ (bp respondsTo: #stepPoint)
				and: [ bp selector = aSelector
				and: [ bp remoteClass = aClassName
				and: [ bp stepPoint = step ] ] ] ] ] ]
		ifNone: [ nil ].
	existing ifNotNil: [ ^ self ].
	bpClass selector: aSelector remoteClass: aClassName stepPoint: step
]

{ #category : 'breakpoint support' }
GbxBrowser class >> stepPointForBreakInView: aView model: aModel [
	| selection offsets found |
	selection := (aView notNil and: [ aView respondsTo: #selectionInterval ])
		ifTrue: [ [ aView selectionInterval ] on: Error do: [ nil ] ]
		ifFalse: [ nil ].
	offsets := (aModel notNil and: [ aModel respondsTo: #sourceOffsets ])
		ifTrue: [ [ aModel sourceOffsets ] on: Error do: [ #() ] ]
		ifFalse: [ #() ].
	(selection isInterval and: [ offsets isCollection and: [ offsets isEmpty not ] ]) ifTrue: [
		found := 1 to: offsets size detect: [ :idx |
			| off |
			off := [ offsets at: idx ] on: Error do: [ nil ].
			off isNumber and: [ selection first <= off and: [ selection last >= off ] ] ] ifNone: [ nil ].
		found ifNotNil: [ ^ found ]
	].
	(aModel notNil and: [ aModel respondsTo: #quickStepPoint ]) ifTrue: [
		^ [ aModel quickStepPoint ] on: Error do: [ 1 ]
	].
	^ 1
]
