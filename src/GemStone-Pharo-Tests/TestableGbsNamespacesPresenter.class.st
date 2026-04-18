Class {
	#name : 'TestableGbsNamespacesPresenter',
	#superclass : 'GbsNamespacesPresenter',
	#instVars : [
		'lastBrowserClassName',
		'lastInfoMessage',
		'lastMethodQueryReferences',
		'lastMethodQueryTitle',
		'lastOpenedOop',
		'lastOpenedNamespaceMirror',
		'requestAnswers'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'initialization' }
TestableGbsNamespacesPresenter >> initialize [
	super initialize.
	requestAnswers := OrderedCollection new
]

{ #category : 'testing' }
TestableGbsNamespacesPresenter >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'ui' }
TestableGbsNamespacesPresenter >> inform: aString [
	lastInfoMessage := aString asString.
	^ lastInfoMessage
]

{ #category : 'accessing' }
TestableGbsNamespacesPresenter >> lastBrowserClassName [
	^ lastBrowserClassName
]

{ #category : 'accessing' }
TestableGbsNamespacesPresenter >> lastInfoMessage [
	^ lastInfoMessage
]

{ #category : 'accessing' }
TestableGbsNamespacesPresenter >> lastMethodQueryReferences [
	^ lastMethodQueryReferences
]

{ #category : 'accessing' }
TestableGbsNamespacesPresenter >> lastMethodQueryTitle [
	^ lastMethodQueryTitle
]

{ #category : 'accessing' }
TestableGbsNamespacesPresenter >> lastOpenedOop [
	^ lastOpenedOop
]

{ #category : 'accessing' }
TestableGbsNamespacesPresenter >> lastOpenedNamespaceMirror [
	^ lastOpenedNamespaceMirror
]

{ #category : 'ui' }
TestableGbsNamespacesPresenter >> openBrowserOnClassNamed: aClassName [
	lastBrowserClassName := aClassName.
	^ true
]

{ #category : 'ui' }
TestableGbsNamespacesPresenter >> openInspectorOnOop: anOop [
	lastOpenedOop := anOop.
	^ true
]

{ #category : 'ui' }
TestableGbsNamespacesPresenter >> openMethodQueryReferences: aCollection title: aString [
	lastMethodQueryReferences := aCollection asArray.
	lastMethodQueryTitle := aString.
	^ true
]

{ #category : 'ui' }
TestableGbsNamespacesPresenter >> openNamespaceMirror: aNamespaceMirror [
	lastOpenedNamespaceMirror := aNamespaceMirror.
	^ true
]

{ #category : 'ui' }
TestableGbsNamespacesPresenter >> requestInput: prompt initialAnswer: defaultString [
	^ requestAnswers
		ifEmpty: [ defaultString ]
		ifNotEmpty: [ requestAnswers removeFirst ]
]
