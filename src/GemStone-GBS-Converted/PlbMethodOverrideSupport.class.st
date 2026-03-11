Class {
	#name : 'PlbMethodOverrideSupport',
	#superclass : 'Object',
	#classInstVars : [
		'debugging'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'logging' }
PlbMethodOverrideSupport class >> debugLog: aString [
	self isDebugging ifFalse: [ ^ self ].
	Transcript cr; show: aString
]

{ #category : 'accessing' }
PlbMethodOverrideSupport class >> isDebugging [
	| cmd |
	cmd := [ SmalltalkImage current vm getSystemAttribute: 1 ] on: Error do: [ '' ].
	^ (cmd isString and: [ cmd includesSubstring: '-debug' ]) or: [ debugging == true ]
]

{ #category : 'accessing' }
PlbMethodOverrideSupport class >> debugging: aBoolean [
	debugging := aBoolean == true
]

{ #category : 'documentation' }
PlbMethodOverrideSupport class >> documentation [
	^ 'Transient method override framework: methods prefixed with override_ can shadow normal methods.'
]

{ #category : 'actions' }
PlbMethodOverrideSupport class >> installOverrideMethods [
	| mgr |
	mgr := PlbMethodOverrideManager debugging: self isDebugging.
	Smalltalk globals at: #MethodOverrideManager put: mgr.
	mgr refreshAllOverrides.
]

{ #category : 'actions' }
PlbMethodOverrideSupport class >> uninstallOverrideMethods [
	| old |
	old := Smalltalk globals at: #MethodOverrideManager ifAbsent: [ nil ].
	Smalltalk globals at: #MethodOverrideManager put: nil.
	old ifNotNil: [ old refreshAllOverrides ].
]

{ #category : 'lifecycle' }
PlbMethodOverrideSupport class >> loaded [
	self debugLog: 'PlbMethodOverrideSupport loaded'.
	self installOverrideMethods
]

{ #category : 'lifecycle' }
PlbMethodOverrideSupport class >> removing [
	self debugLog: 'PlbMethodOverrideSupport removing'.
	self uninstallOverrideMethods
]

{ #category : 'lifecycle' }
PlbMethodOverrideSupport class >> restart [
	self debugLog: 'PlbMethodOverrideSupport restart'.
	self installOverrideMethods
]

{ #category : 'lifecycle' }
PlbMethodOverrideSupport class >> saving [
	self debugLog: 'PlbMethodOverrideSupport saving'.
	self uninstallOverrideMethods
]

{ #category : 'lifecycle' }
PlbMethodOverrideSupport class >> startUp [
	self debugLog: 'PlbMethodOverrideSupport startUp'.
	self installOverrideMethods
]

{ #category : 'packaging' }
PlbMethodOverrideSupport class >> packagingRulesFor: aCollector [
	(aCollector respondsTo: #ignoreNoImplementorErrorsForMessageSend:)
		ifTrue: [
			aCollector ignoreNoImplementorErrorsForMessageSend: #applicationFor:.
			aCollector ignoreNoImplementorErrorsForMessageSend: #applicationFor:is: ]
]
