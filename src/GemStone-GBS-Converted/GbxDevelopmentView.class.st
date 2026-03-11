Class {
	#name : 'GbxDevelopmentView',
	#superclass : 'Object',
	#instVars : [
		'windowTitleString'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'initialization' }
GbxDevelopmentView >> finalInitialize [
	self decorateWindowTitle.
	^ self
]

{ #category : 'accessing' }
GbxDevelopmentView >> decorateWindowTitle [
	self windowTitle: self windowTitleString
]

{ #category : 'accessing' }
GbxDevelopmentView >> windowTitle [
	^ windowTitleString ifNil: [ '' ]
]

{ #category : 'accessing' }
GbxDevelopmentView >> windowTitle: aString [
	windowTitleString := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	(self respondsTo: #applyImageTag:)
		ifTrue: [ windowTitleString := self applyImageTag: windowTitleString ].
]
