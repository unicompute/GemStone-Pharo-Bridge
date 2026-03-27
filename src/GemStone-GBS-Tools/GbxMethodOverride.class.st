Class {
	#name : 'GbxMethodOverride',
	#superclass : 'GbxOverridesWithEdits',
	#instVars : [
		'selector'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'storing' }
GbxMethodOverride >> storeOn: aStream
[
	aStream
		nextPutAll: self class fullName;
		nextPutAll: ' behavior: ';
		nextPutAll: behavior fullName;
		nextPutAll: ' selector: ';
		store: selector;
		nextPutAll: ' crc: ';
		store: crc;
		nextPutAll: ' edits: '.
	self storeArray: edits on: aStream.
]

{ #category : 'comparing' }
GbxMethodOverride >> hash
[

	^super hash
		+ self selector hash
]

{ #category : 'comparing' }
GbxMethodOverride >> = anotherOverride
[

	^super = anotherOverride
		and: [self selector = anotherOverride selector]
]

{ #category : 'comparing' }
GbxMethodOverride >> equalOtherThanEditsTo: anotherOverride
[
	^(super equalOtherThanEditsTo: anotherOverride)
		and: [self selector = anotherOverride selector]
]

{ #category : 'accessing' }
GbxMethodOverride >> selector
[

	^selector
]

{ #category : 'accessing' }
GbxMethodOverride >> selector: anObject
[
	selector := anObject
]

{ #category : 'private' }
GbxMethodOverride >> setCrcFrom: overriddenMethod
[
	self setCrcFromOriginal: (self originalSourceFrom: overriddenMethod)
]

{ #category : 'private' }
GbxMethodOverride >> originalSourceFrom: overriddenMethod
[
	^overriddenMethod definitionObject getSource asString
]

{ #category : 'private' }
GbxMethodOverride >> overridingSourceFrom: overriddenMethod
[
	^overriddenMethod object getSource asString
]

{ #category : 'private' }
GbxMethodOverride >> setEditsFrom: overriddenMethod
[
	self
		setEditsFromOriginal: (self originalSourceFrom: overriddenMethod)
		toOverride: (self overridingSourceFrom: overriddenMethod)
]

{ #category : 'applying' }
GbxMethodOverride >> apply
[

	| methodDef method basePackage sourceString override vwVersion |
	vwVersion := GbxVwVersion current.	"GAH!"
	methodDef := MethodDefinition class: behavior selector: selector.
	method := methodDef method.
	method
		ifNil: 
			[^OverrideFailureWarning
				raiseSignal: 'Cannot apply method override, base method '
						, methodDef printString , ' not found'].
	sourceString := methodDef sourceCode asString.
	basePackage := methodDef package.
	basePackage = parent package
		ifTrue: 
			[^OverrideFailureWarning
				raiseSignal: 'Cannot apply method override to ' , methodDef printString
						, ', because it is already in destination package '
							, basePackage printString].

	"The version from which the override spec was generated might be different from the version
	 in which we are running, so we need to be certain the code is the same."
	crc = (self crcForString: sourceString)
		ifFalse: 
			[^OverrideFailureWarning
				raiseSignal: 'Cannot apply method override to ' , methodDef printString
						, ', override does not match existing source signature found'].

	"Edit the original string to create the override version."
	override := Override forMethod: method selector: method selector.
	self editOriginal: sourceString
		andApplyUsing: 
			[:newString |
			| compileResult |
			vwVersion >= '9.3' ifTrue: [override install].	"The override needs to be installed *before* compiling the overriding method in 9.3+"
			compileResult := behavior
						compile: newString
						classified: methodDef protocol
						notifying: nil
						attributes: nil
						environment: nil.
			compileResult
				ifNil: 
					[^OverrideFailureWarning
						raiseSignal: 'Method override for ' , methodDef printString
								, ' failed to compile']].
	vwVersion < '9.3' ifTrue: [override install].	"The override needs to be installed *after* compiling the overriding method prior to 9.3"
]

{ #category : 'initialize-release' }
GbxMethodOverride >> initializeFromOverriddenMethod: overriddenMethod forParent: anOverrideSet
[
	parent := anOverrideSet.
	behavior := overriddenMethod implementingClass.
	selector := overriddenMethod selector.
	self
		setCrcFrom: overriddenMethod;
		setEditsFrom: overriddenMethod
]

{ #category : 'printing' }
GbxMethodOverride >> printOn: aStream
[
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: self behavior;
		nextPutAll: '>>#';
		nextPutAll: (self selector ifNil: ['']);
		nextPutAll: ')'
]

{ #category : 'instance creation' }
GbxMethodOverride class >> fromOverriddenMethod: overriddenMethod forParent: anOverrideSet
[
	^(self new)
		initializeFromOverriddenMethod: overriddenMethod forParent: anOverrideSet;
		yourself
]

{ #category : 'instance creation' }
GbxMethodOverride class >> behavior: behaviorOfMethod selector: selectorSymbol crc: anInteger edits: editsSequence
[
	^(self new)
		behavior: behaviorOfMethod;
		selector: selectorSymbol;
		crc: anInteger;
		edits: editsSequence;
		yourself
]

