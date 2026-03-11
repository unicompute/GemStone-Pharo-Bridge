Class {
	#name : 'PlbMethodOverrideManager',
	#superclass : 'Object',
	#instVars : [
		'currentlyInstalling',
		'debugging'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
PlbMethodOverrideManager class >> debugging: aBoolean [
	^ self new
		initializeDebugging: aBoolean;
		yourself
]

{ #category : 'private' }
PlbMethodOverrideManager >> initializeDebugging: aBoolean [
	debugging := aBoolean == true
]

{ #category : 'private' }
PlbMethodOverrideManager >> isDebugging [
	^ debugging == true
]

{ #category : 'private' }
PlbMethodOverrideManager >> debugLog: aString [
	self isDebugging ifFalse: [ ^ self ].
	Transcript cr; show: aString
]

{ #category : 'private' }
PlbMethodOverrideManager >> overrideSelectorPrefix [
	^ 'override_'
]

{ #category : 'private' }
PlbMethodOverrideManager >> overriddenSelectorPrefix [
	^ 'overridden_'
]

{ #category : 'private' }
PlbMethodOverrideManager >> is: aSelector prefixedWith: prefixString [
	| s |
	s := aSelector asString.
	^ s beginsWith: prefixString
]

{ #category : 'private' }
PlbMethodOverrideManager >> removePrefixFrom: aSelector [
	| s |
	s := aSelector asString.
	(self is: s prefixedWith: self overrideSelectorPrefix)
		ifTrue: [
			^ (s allButFirst: self overrideSelectorPrefix size) asSymbol ].
	(self is: s prefixedWith: self overriddenSelectorPrefix)
		ifTrue: [
			^ (s allButFirst: self overriddenSelectorPrefix size) asSymbol ].
	^ aSelector
]

{ #category : 'private' }
PlbMethodOverrideManager >> isCurrentlyInstalling [
	^ currentlyInstalling == true
]

{ #category : 'private' }
PlbMethodOverrideManager >> beInstallingDuring: aBlock [
	currentlyInstalling := true.
	^ aBlock ensure: [ currentlyInstalling := false ]
]

{ #category : 'private' }
PlbMethodOverrideManager >> allOverrideMethods [
	| answer |
	answer := OrderedCollection new.
	SystemNavigation default allClassesDo: [ :aClass |
		aClass selectors do: [ :sel |
			(self is: sel prefixedWith: self overrideSelectorPrefix)
				ifTrue: [ answer add: (aClass >> sel) ] ].
		aClass class selectors do: [ :sel |
			(self is: sel prefixedWith: self overrideSelectorPrefix)
				ifTrue: [ answer add: (aClass class >> sel) ] ] ].
	^ answer
]

{ #category : 'private' }
PlbMethodOverrideManager >> allOverrideMethodsFor: aClass [
	| answer |
	answer := OrderedCollection new.
	aClass selectors do: [ :sel |
		(self is: sel prefixedWith: self overrideSelectorPrefix)
			ifTrue: [ answer add: (aClass >> sel) ] ].
	^ answer
]

{ #category : 'private' }
PlbMethodOverrideManager >> isPermittedToInstall [
	^ (Smalltalk globals at: #MethodOverrideManager ifAbsent: [ nil ]) notNil
]

{ #category : 'actions' }
PlbMethodOverrideManager >> installOverrideClass: aClass selector: normalSelector [
	| overrideSelector overriddenSelector normalSource overrideSource category |
	self isPermittedToInstall ifFalse: [ ^ self ].
	overrideSelector := (self overrideSelectorPrefix, normalSelector asString) asSymbol.
	(aClass includesSelector: overrideSelector) ifFalse: [ ^ self ].
	(aClass includesSelector: normalSelector) ifFalse: [ ^ self ].
	overriddenSelector := (self overriddenSelectorPrefix, normalSelector asString) asSymbol.
	category := [ aClass organization categoryOfElement: normalSelector ] on: Error do: [ 'as yet unclassified' ].
	normalSource := [ aClass sourceCodeAt: normalSelector ] on: Error do: [ '' ].
	overrideSource := [ aClass sourceCodeAt: overrideSelector ] on: Error do: [ '' ].
	(normalSource isEmpty or: [ overrideSource isEmpty ]) ifTrue: [ ^ self ].

	self beInstallingDuring: [
		(aClass includesSelector: overriddenSelector) ifFalse: [
			aClass
				compile: (self source: normalSource withSelectorPrefix: self overriddenSelectorPrefix)
				classified: category ].
		aClass
			compile: (self source: overrideSource droppingSelectorPrefix: self overrideSelectorPrefix)
			classified: category ].
	self debugLog: 'Installed override for ', aClass name, '>>', normalSelector asString
]

{ #category : 'actions' }
PlbMethodOverrideManager >> refreshOverriddenForClass: aClass selector: normalSelector [
	| overriddenSelector overriddenSource category |
	overriddenSelector := (self overriddenSelectorPrefix, normalSelector asString) asSymbol.
	(aClass includesSelector: overriddenSelector) ifTrue: [
		overriddenSource := [ aClass sourceCodeAt: overriddenSelector ] on: Error do: [ '' ].
		category := [ aClass organization categoryOfElement: normalSelector ] on: Error do: [ 'as yet unclassified' ].
		overriddenSource isEmpty ifFalse: [
			self beInstallingDuring: [
				aClass
					compile: (self source: overriddenSource droppingSelectorPrefix: self overriddenSelectorPrefix)
					classified: category.
				[ aClass removeSelector: overriddenSelector ] on: Error do: [ :ex | ] ] ] ].
	^ self installOverrideClass: aClass selector: normalSelector
]

{ #category : 'actions' }
PlbMethodOverrideManager >> refreshAllOverrides [
	self allOverrideMethods do: [ :cm |
		self
			refreshOverriddenForClass: cm methodClass
			selector: (self removePrefixFrom: cm selector) ]
]

{ #category : 'actions' }
PlbMethodOverrideManager >> refreshAllOverridesFor: aClass [
	(self allOverrideMethodsFor: aClass) do: [ :cm |
		self
			refreshOverriddenForClass: cm methodClass
			selector: (self removePrefixFrom: cm selector) ]
]

{ #category : 'actions' }
PlbMethodOverrideManager >> class: aClass changedSelector: selector [
	self isCurrentlyInstalling ifTrue: [ ^ self ].
	(self is: selector prefixedWith: self overriddenSelectorPrefix) ifTrue: [ ^ self ].
	(self is: selector prefixedWith: self overrideSelectorPrefix)
		ifTrue: [ self refreshOverriddenForClass: aClass selector: (self removePrefixFrom: selector) ]
		ifFalse: [ self installOverrideClass: aClass selector: selector ]
]

{ #category : 'private' }
PlbMethodOverrideManager >> source: sourceString droppingSelectorPrefix: prefixString [
	| lines first rest |
	lines := sourceString lines.
	lines isEmpty ifTrue: [ ^ sourceString ].
	first := lines first.
	(first beginsWith: prefixString)
		ifTrue: [ first := first allButFirst: prefixString size ].
	rest := lines allButFirst.
	^ String streamContents: [ :s |
		s nextPutAll: first.
		rest do: [ :line | s cr; nextPutAll: line ] ]
]

{ #category : 'private' }
PlbMethodOverrideManager >> source: sourceString withSelectorPrefix: prefixString [
	| lines first rest |
	lines := sourceString lines.
	lines isEmpty ifTrue: [ ^ sourceString ].
	first := lines first.
	first := prefixString, first.
	rest := lines allButFirst.
	^ String streamContents: [ :s |
		s nextPutAll: first.
		rest do: [ :line | s cr; nextPutAll: line ] ]
]
