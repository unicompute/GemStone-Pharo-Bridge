Class {
	#name : 'TestableGbsNamespacesPresenter',
	#superclass : 'GbsNamespacesPresenter',
	#instVars : [
		'lastBrowserClassName',
		'chooseAnswers',
		'lastInfoMessage',
		'lastMethodQueryReferences',
		'lastMethodQueryTitle',
		'lastOpenedOop',
		'lastOpenedNamespaceMirror',
		'requestAnswers'
	],
	#category : 'GemStone-Pharo-MagLev-Tests',
	#package : 'GemStone-Pharo-MagLev-Tests'
}

{ #category : 'initialization' }
TestableGbsNamespacesPresenter >> initialize [
	super initialize.
	requestAnswers := OrderedCollection new.
	chooseAnswers := OrderedCollection new
]

{ #category : 'testing' }
TestableGbsNamespacesPresenter >> enqueueRequestAnswer: aStringOrNil [
	requestAnswers add: aStringOrNil
]

{ #category : 'testing' }
TestableGbsNamespacesPresenter >> enqueueChooseAnswer: anInteger [
	chooseAnswers add: anInteger
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
TestableGbsNamespacesPresenter >> openMethodQuery: aMethodQuery [
	lastMethodQueryReferences := aMethodQuery references asArray.
	lastMethodQueryTitle := aMethodQuery title.
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

{ #category : 'ui' }
TestableGbsNamespacesPresenter >> uiChooseFrom: labels title: aTitle [
	^ chooseAnswers
		ifEmpty: [ 0 ]
		ifNotEmpty: [ chooseAnswers removeFirst ]
]
