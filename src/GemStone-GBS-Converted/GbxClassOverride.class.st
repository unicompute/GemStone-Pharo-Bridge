Class {
	#name : #'GbxClassOverride',
	#superclass : #'GbxOverridesWithEdits',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'applying' }
GbxClassOverride >> apply

	| basePackage originalInstVarNameString messageSend |
	basePackage := behavior package.
	basePackage = parent package
		ifTrue: 
			[^OverrideFailureWarning
				raiseSignal: 'Cannot apply class override to ' , behavior printString
						, ', because it is already in destination package '
							, basePackage printString].
	messageSend := behavior definitionMessage.
	originalInstVarNameString := self instVarStringOf: messageSend.

	"The version from which the override spec was generated might be different from the version
	 in which we are running, so we need to be certain the code is the same."
	crc = (self crcForString: originalInstVarNameString)
		ifFalse: 
			[^OverrideFailureWarning
				raiseSignal: 'Cannot apply class override to ' , behavior printString
						, ', override does not match existing instance variable signature'].

	"Edit the original string to create the override version."
	self editOriginal: originalInstVarNameString
		andApplyUsing: 
			[:newString |
			self instVarStringOf: messageSend put: newString.
			[messageSend value]
				on: RedefinitionNotification
				do: [:ex | ex installOverrideIfNecessary]]

{ #category : #'initialize-release' }
GbxClassOverride >> initializeFromOverriddenClass: overriddenClass forParent: anOverrideSet

	parent := anOverrideSet.
	behavior := overriddenClass object.
	self
		setCrcFrom: overriddenClass;
		setEditsFrom: overriddenClass

{ #category : #'printing' }
GbxClassOverride >> printOn: aStream

	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		print: self behavior;
		nextPutAll: ')'

{ #category : #'storing' }
GbxClassOverride >> storeOn: aStream

	aStream
		nextPutAll: self class fullName;
		nextPutAll: ' behavior: ';
		nextPutAll: behavior fullName;
		nextPutAll: ' crc: ';
		store: crc;
		nextPutAll: ' edits: '.
	self storeArray: edits on: aStream.

{ #category : #'private' }
GbxClassOverride >> instVarStringOf: aMessageSend put: replacementString

	| index |
	index := self instVarArgumentIndexIn: aMessageSend.
	^aMessageSend arguments at: index put: replacementString

{ #category : #'private' }
GbxClassOverride >> instVarStringOf: aMessageSend

	| index |
	index := self instVarArgumentIndexIn: aMessageSend.
	^aMessageSend arguments at: index

{ #category : #'private' }
GbxClassOverride >> setEditsFrom: overriddenClass

	self
		setEditsFromOriginal: (self originalInstVarNameStringFrom: overriddenClass)
		toOverride: (self overridingInstVarNameStringFrom: overriddenClass)

{ #category : #'private' }
GbxClassOverride >> instVarArgumentIndexIn: aMessageSend

	| index |
	index := (aMessageSend selector tokensBasedOn: $:)
				indexOf: 'instanceVariableNames'.
	index > 0
		ifFalse: [self error: 'Keyword "instanceVariableNames" not found'].
	^index

{ #category : #'private' }
GbxClassOverride >> overridingInstVarNameStringFrom: overriddenClass

	^self instVarStringOf: overriddenClass object definitionMessage

{ #category : #'private' }
GbxClassOverride >> setCrcFrom: overriddenClass

	self setCrcFromOriginal: (self originalInstVarNameStringFrom: overriddenClass)

{ #category : #'private' }
GbxClassOverride >> originalInstVarNameStringFrom: overriddenClass

	^self instVarStringOf: overriddenClass definitionMessage

{ #category : #'instance creation' }
GbxClassOverride class >> behavior: aBehavior  crc: anInteger edits: editsArray

	^(self new)
		behavior: aBehavior;
		crc: anInteger;
		edits: editsArray;
		yourself

{ #category : #'instance creation' }
GbxClassOverride class >> fromOverriddenClass: overriddenClass forParent: anOverrideSet

	^(self new)
		initializeFromOverriddenClass: overriddenClass forParent: anOverrideSet;
		yourself

