Class {
	#name : 'GbxClassOverride',
	#superclass : 'GbxOverridesWithEdits',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxClassOverride class >> behavior: aBehavior crc: anInteger edits: editsArray [
	^ self new
		behavior: aBehavior;
		crc: anInteger;
		edits: editsArray;
		yourself
]

{ #category : 'instance creation' }
GbxClassOverride class >> behavior: aBehavior from: originalInstVarString to: overridingInstVarString [
	^ self new
		behavior: aBehavior;
		setCrcFromOriginal: originalInstVarString;
		setEditsFromOriginal: originalInstVarString toOverride: overridingInstVarString;
		yourself
]

{ #category : 'applying' }
GbxClassOverride >> apply [
	| sourceString originalPackageName packageName newBehavior newString |
	sourceString := self currentInstVarString.
	originalPackageName := (behavior respondsTo: #package)
		ifTrue: [ behavior package name asString ]
		ifFalse: [ self packageNameForCompilation ].
	crc = (self crcForString: sourceString) ifFalse: [
		^ OverrideFailureWarning
			raiseSignal: 'Cannot apply class override to ', behavior name asString,
				', override does not match existing instance variable signature' ].
	newString := self
		editOriginal: sourceString
		andApplyUsing: [ :newString |
			[ self redefineBehaviorWithInstVarString: newString ]
				on: Error
				do: [ :ex |
					^ OverrideFailureWarning
						raiseSignal: 'Cannot apply class override to ', behavior name asString,
							': ', ex messageText ].
			newString ].
	packageName := parent ifNil: [ '' ] ifNotNil: [ parent packageName ifNil: [ '' ] ].
	packageName isEmpty ifFalse: [
		GbxOverrideUtility
			noteInstalledClassOverride: self
			originalInstVarString: sourceString
			originalPackageName: originalPackageName.
		newBehavior := Smalltalk globals at: behavior name asSymbol ifAbsent: [ behavior ].
		newBehavior propertyAt: #gbxOverridePackageName put: packageName.
		newBehavior propertyAt: #gbxOverrideOriginalInstVarString put: sourceString.
		newBehavior propertyAt: #gbxOverrideOriginalPackageName put: originalPackageName.
		behavior := newBehavior ].
	^ newString
]

{ #category : 'private' }
GbxClassOverride >> currentInstVarString [
	^ self namesStringFrom: behavior instVarNames
]

{ #category : 'private' }
GbxClassOverride >> namesStringFrom: aCollection [
	^ String streamContents: [ :stream |
		aCollection
			do: [ :each | stream nextPutAll: each asString ]
			separatedBy: [ stream space ] ]
]

{ #category : 'private' }
GbxClassOverride >> packageNameForCompilation [
	parent ifNotNil: [
		parent packageName ifNotNil: [ ^ parent packageName asString ] ].
	(behavior respondsTo: #package) ifTrue: [ ^ behavior package name asString ].
	^ 'GemStone-GBS-Converted'
]

{ #category : 'private' }
GbxClassOverride >> redefineBehaviorWithInstVarString: instVarString [
	Smalltalk classInstaller make: [ :builder |
		builder
			superclass: behavior superclass;
			name: behavior name asSymbol;
			slots: (self slotSymbolsFromString: instVarString);
			package: self packageNameForCompilation ]
]

{ #category : 'printing' }
GbxClassOverride >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: self behavior;
		nextPut: $)
]

{ #category : 'printing' }
GbxClassOverride >> storeOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: ' behavior: '.
	self storeBehavior: behavior on: aStream.
	aStream
		nextPutAll: ' crc: '.
	crc storeOn: aStream.
	aStream
		nextPutAll: ' edits: '.
	self storeCollection: self edits on: aStream
]

{ #category : 'private' }
GbxClassOverride >> slotSymbolsFromString: instVarString [
	instVarString ifEmpty: [ ^ #() ].
	^ (instVarString substrings: ' ')
		collect: [ :each | each asSymbol ]
]
