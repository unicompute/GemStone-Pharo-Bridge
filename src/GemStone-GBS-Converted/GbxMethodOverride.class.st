Class {
	#name : 'GbxMethodOverride',
	#superclass : 'GbxOverridesWithEdits',
	#instVars : [
		'selector'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxMethodOverride class >> behavior: aBehavior selector: aSelector crc: anInteger edits: editsSequence [
	^ self new
		behavior: aBehavior;
		selector: aSelector;
		crc: anInteger;
		edits: editsSequence;
		yourself
]

{ #category : 'instance creation' }
GbxMethodOverride class >> behavior: aBehavior selector: aSelector from: originalSource to: overridingSource [
	^ self new
		behavior: aBehavior;
		selector: aSelector;
		setCrcFromOriginal: originalSource;
		setEditsFromOriginal: originalSource toOverride: overridingSource;
		yourself
]

{ #category : 'applying' }
GbxMethodOverride >> apply [
	| compiledMethod sourceString protocolName |
	compiledMethod := behavior compiledMethodAt: selector ifAbsent: [ nil ].
	compiledMethod ifNil: [
		^ OverrideFailureWarning
			raiseSignal: 'Cannot apply method override, base method ',
				behavior name asString, '>>#', selector asString, ' not found' ].
	sourceString := compiledMethod sourceCode asString.
	crc = (self crcForString: sourceString) ifFalse: [
		^ OverrideFailureWarning
			raiseSignal: 'Cannot apply method override to ',
				behavior name asString, '>>#', selector asString,
				', override does not match existing source signature found' ].
	protocolName := compiledMethod protocolName ifNil: [ 'as yet unclassified' ].
	^ self
		editOriginal: sourceString
		andApplyUsing: [ :newString |
			[ behavior compile: newString classified: protocolName ]
				on: Error
				do: [ :ex |
					^ OverrideFailureWarning
						raiseSignal: 'Method override for ',
							behavior name asString, '>>#', selector asString,
							' failed to compile: ', ex messageText ].
			newString ]
]

{ #category : 'comparing' }
GbxMethodOverride >> = anotherOverride [
	^ super = anotherOverride
		and: [ self selector = anotherOverride selector ]
]

{ #category : 'comparing' }
GbxMethodOverride >> equalOtherThanEditsTo: anotherOverride [
	^ (super equalOtherThanEditsTo: anotherOverride)
		and: [ self selector = anotherOverride selector ]
]

{ #category : 'comparing' }
GbxMethodOverride >> hash [
	^ super hash bitXor: self selector hash
]

{ #category : 'printing' }
GbxMethodOverride >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: self behavior;
		nextPutAll: '>>#';
		nextPutAll: (self selector ifNil: [ '' ]) asString;
		nextPut: $)
]

{ #category : 'accessing' }
GbxMethodOverride >> selector [
	^ selector
]

{ #category : 'accessing' }
GbxMethodOverride >> selector: anObject [
	selector := anObject
]

{ #category : 'printing' }
GbxMethodOverride >> storeOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: ' behavior: '.
	self storeBehavior: behavior on: aStream.
	aStream
		nextPutAll: ' selector: '.
	selector storeOn: aStream.
	aStream
		nextPutAll: ' crc: '.
	crc storeOn: aStream.
	aStream
		nextPutAll: ' edits: '.
	self storeCollection: self edits on: aStream
]
