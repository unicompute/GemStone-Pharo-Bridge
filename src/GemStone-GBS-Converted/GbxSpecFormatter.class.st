Class {
	#name : 'GbxSpecFormatter',
	#superclass : 'Object',
	#instVars : [
		'spec',
		'stream',
		'version'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'formatting - class overrides' }
GbxSpecFormatter >> formatClassOverridesIndenting: indentation
[

	self formatClassOverridesArrayKeyword: #classOverrides: with: spec classOverrides indenting: indentation + 1
]

{ #category : 'formatting - class overrides' }
GbxSpecFormatter >> formatClassOverrideArrayElement: aClassOverride indenting: indentation
[

	stream print: aClassOverride class.
	self formatBehaviorKeywordForOverride: aClassOverride indenting: indentation + 3.
	self formatCRCKeywordForOverride: aClassOverride indenting: indentation + 3.
	self formatEditsKeywordForOverride: aClassOverride indenting: indentation + 3.
]

{ #category : 'formatting - class overrides' }
GbxSpecFormatter >> formatClassOverridesArrayKeyword: aSymbol with: anArray indenting: indentation
[

	self
		formatArrayKeyword: aSymbol
		with: anArray
		indenting: indentation
		using: [:eachElement :indent | self formatClassOverrideArrayElement: eachElement indenting: indent]
]

{ #category : 'accessing - constants' }
GbxSpecFormatter >> arrayPrefix
[

	^self shouldUseComputedArray
		ifTrue: ['{']
		ifFalse: ['(OrderedCollection new']
]

{ #category : 'accessing - constants' }
GbxSpecFormatter >> arrayElementSuffix
[

	^self shouldUseComputedArray
		ifTrue: [').']
		ifFalse: [');']
]

{ #category : 'accessing - constants' }
GbxSpecFormatter >> arrayElementPrefix
[

	^self shouldUseComputedArray
		ifTrue: ['(']
		ifFalse: ['add: (']
]

{ #category : 'accessing - constants' }
GbxSpecFormatter >> initialIndentation
[
	"Method source is indented compared to a bare spec creation string."

	^self isBareSpec
		ifTrue: [0]
		ifFalse: [1]
]

{ #category : 'accessing - constants' }
GbxSpecFormatter >> emptyArrayLiteral
[

	^self shouldUseComputedArray
		ifTrue: ['{}']
		ifFalse: ['#()']
]

{ #category : 'accessing - constants' }
GbxSpecFormatter >> arraySuffix
[

	^self shouldUseComputedArray
		ifTrue: ['}']
		ifFalse: ['yourself)']
]

{ #category : 'formatting - arrays' }
GbxSpecFormatter >> formatOverrideEditArrayElement: anOverrideEdit indenting: aSmallInteger
[

	anOverrideEdit storeOn: stream
]

{ #category : 'formatting - arrays' }
GbxSpecFormatter >> formatArrayKeyword: aSymbol with: anArray indenting: indentation using: aTwoArgBlock
[

	| elementIndentation |
	anArray isEmpty ifTrue: [^self formatEmptyArrayKeyword: aSymbol indenting: indentation].
	elementIndentation := indentation + 2.
	self formatKeyword: aSymbol as: self arrayPrefix indenting: indentation.
	anArray do: [:eachElement | 
		self format: self arrayElementPrefix indenting: elementIndentation.
		aTwoArgBlock value: eachElement value: elementIndentation.
		stream nextPutAll: self arrayElementSuffix].
	self format: self arraySuffix indenting: elementIndentation
]

{ #category : 'formatting - arrays' }
GbxSpecFormatter >> formatEditsKeywordForOverride: anOverride indenting: indentation
[

	self
		formatEditsArrayForMethodOverride: #edits:
		with: anOverride edits
		indenting: indentation
]

{ #category : 'formatting - arrays' }
GbxSpecFormatter >> formatEmptyArrayKeyword: aSymbol indenting: indentation
[

	self
		formatKeyword: aSymbol
		as: self emptyArrayLiteral
		indenting: indentation
]

{ #category : 'formatting - arrays' }
GbxSpecFormatter >> formatEditsArrayForMethodOverride: aSymbol with: anArray indenting: indentation
[

	self
		formatArrayKeyword: aSymbol
		with: anArray
		indenting: indentation
		using: [:eachElement :indent | self formatOverrideEditArrayElement: eachElement indenting: indent]
]

{ #category : 'formatting - private' }
GbxSpecFormatter >> format: aString indenting: indentation
[

	stream
		cr;
		tab: indentation;
		nextPutAll: aString.
]

{ #category : 'formatting - private' }
GbxSpecFormatter >> formatBehaviorKeywordForOverride: anOverride indenting: indentation
[

	self
		formatKeyword: #behavior:
		as: anOverride behavior storeString
		indenting: indentation
]

{ #category : 'formatting - private' }
GbxSpecFormatter >> formatCRCKeywordForOverride: anOverride indenting: indentation
[

	self
		formatKeyword: #crc:
		as: anOverride crc printString
		indenting: indentation
]

{ #category : 'formatting - private' }
GbxSpecFormatter >> formatKeyword: aSymbol as: aString indenting: indentation
[

	stream
		cr;
		tab: indentation;
		nextPutAll: aSymbol;
		space;
		nextPutAll: aString.
]

{ #category : 'formatting - spec set' }
GbxSpecFormatter >> formatDestinationPackageNameIndenting: indentation
[

	self
		formatKeyword: #destinationPackageName:
		as: spec packageName printString
		indenting: indentation + 1
]

{ #category : 'formatting - spec set' }
GbxSpecFormatter >> formatOptionalVersion
[
	"A non-null version requires formatted spec method source.
	 A null version is used for just the formatted spec itself."

	self isBareSpec ifTrue: [^self].
	stream
		nextPutAll: 'spec';
		nextPutAll: version digits;
		cr;
		tab;
		nextPutAll: '"Generated code, hand edits may be overwritten"';
		cr;
		tab;
		nextPutAll: '<version: ';
		print: version printString;
		nextPutAll: '>';
		cr;
		cr;
		tab;
		nextPut: $^.
]

{ #category : 'formatting - spec set' }
GbxSpecFormatter >> formatSpec
[

	| initialIndentation |
	initialIndentation := self initialIndentation.
	stream store: spec class.
	self formatDestinationPackageNameIndenting: initialIndentation.
	self formatClassOverridesIndenting: initialIndentation.
	self formatVariableOverridesIndenting: initialIndentation.
	self formatMethodOverridesIndenting: initialIndentation.
]

{ #category : 'formatting - method overrides' }
GbxSpecFormatter >> formatMethodOverridesArrayKeyword: aSymbol with: anArray indenting: indentation
[

	self
		formatArrayKeyword: aSymbol
		with: anArray
		indenting: indentation
		using: [:eachElement :indent | self formatMethodOverrideArrayElement: eachElement indenting: indent]
]

{ #category : 'formatting - method overrides' }
GbxSpecFormatter >> formatMethodOverridesIndenting: indentation
[

	self formatMethodOverridesArrayKeyword: #methodOverrides: with: spec methodOverrides indenting: indentation + 1
]

{ #category : 'formatting - method overrides' }
GbxSpecFormatter >> formatMethodOverrideArrayElement: aMethodOverride indenting: indentation
[

	stream print: aMethodOverride class.
	self formatBehaviorKeywordForOverride: aMethodOverride indenting: indentation + 3.
	self formatSelectorKeywordForMethodOverride: aMethodOverride indenting: indentation + 3.
	self formatCRCKeywordForOverride: aMethodOverride indenting: indentation + 3.
	self formatEditsKeywordForOverride: aMethodOverride indenting: indentation + 3.
]

{ #category : 'formatting - method overrides' }
GbxSpecFormatter >> formatSelectorKeywordForMethodOverride: aMethodOverride indenting: indentation
[

	self
		formatKeyword: #selector:
		as: aMethodOverride selector storeString
		indenting: indentation
]

{ #category : 'formatting' }
GbxSpecFormatter >> format
[

	self formatOptionalVersion.
	self formatSpec.
	^stream contents
]

{ #category : 'formatting - variable overrides' }
GbxSpecFormatter >> formatVariableOverridesIndenting: indentation
[

	self formatVariableOverridesArrayKeyword: #variableOverrides: with: spec variableOverrides indenting: indentation + 1
]

{ #category : 'formatting - variable overrides' }
GbxSpecFormatter >> formatVariableOverrideArrayElement: eachElement indenting: indentation
[

	self error: 'Variable overrides not yet implemented'
]

{ #category : 'formatting - variable overrides' }
GbxSpecFormatter >> formatVariableOverridesArrayKeyword: aSymbol with: anArray indenting: indentation
[

	self
		formatArrayKeyword: aSymbol
		with: anArray
		indenting: indentation
		using: [:eachElement :indent | self formatVariableOverrideArrayElement: eachElement indenting: indent]
]

{ #category : 'initializing - private' }
GbxSpecFormatter >> initializeSpec: anOverrideSet version: aVersionNumber stream: aStream
[

	spec := anOverrideSet.
	version := aVersionNumber.
	stream := aStream.
]

{ #category : 'testing - private' }
GbxSpecFormatter >> isBareSpec
[

	^version isNull
]

{ #category : 'testing - private' }
GbxSpecFormatter >> shouldUseComputedArray
[
	"For now, unconditionally avoid the computed array construct so GBS can still support VW 8.3.2."

	"^self isBareSpec or: [version >= '9.0']"
	^false
]

{ #category : 'examples' }
GbxSpecFormatter class >> formatSimpleSpec
[

	^self formattedSpec: self simpleSpec
]

{ #category : 'examples' }
GbxSpecFormatter class >> formatSimpleSpecMethod
[

	^self methodSourceForSpec: self simpleSpec versionString: '9.1.1'
]

{ #category : 'examples' }
GbxSpecFormatter class >> formatLegacySimpleSpecMethod
[

	^self methodSourceForSpec: self simpleSpec versionString: '8.3.2'
]

{ #category : 'examples' }
GbxSpecFormatter class >> simpleSpec
[
	"Example spec for testing - uses fictional classes"

	^GbxOverrideSet
		destinationPackageName: 'FictionalPackage'
		classOverrides: (OrderedCollection new
				add: (GbxClassOverride
							behavior: Tools.AbstractWorkspace
							crc: 3207545579
							edits: (OrderedCollection new
									add: (GbxOverrideEditCopy count: 122);
									add: (GbxOverrideEditInsert string: 'toolbarHolder ');
									yourself));
				yourself)
		variableOverrides: #()
		methodOverrides: (OrderedCollection new
				add: (GbxMethodOverride
							behavior: Core.Bag
							selector: #add:withOccurrences:
							crc: 1268044848
							edits: (OrderedCollection new
									add: (GbxOverrideEditCopy count: 266);
									add: (GbxOverrideEditDelete count: 1);
									add: (GbxOverrideEditCopy count: 49);
									add: (GbxOverrideEditDelete count: 3);
									add: (GbxOverrideEditInsert string: ' ');
									add: (GbxOverrideEditCopy count: 13);
									add: (GbxOverrideEditDelete count: 3);
									add: (GbxOverrideEditInsert string: ' ');
									add: (GbxOverrideEditCopy count: 14);
									add: (GbxOverrideEditDelete count: 1);
									add: (GbxOverrideEditInsert string: '
				');
									add: (GbxOverrideEditCopy count: 97);
									add: (GbxOverrideEditInsert string: 'self gbxConsiderModified.	"Force self to be modified, thus marked dirty if it''s a GBS replicate"
	');
									add: (GbxOverrideEditCopy count: 10);
									yourself));
				yourself)
]

{ #category : 'instance creation - private' }
GbxSpecFormatter class >> spec: anOverrideSet version: aVersionNumber stream: aStream
[

	^self new
		initializeSpec: anOverrideSet
		version: aVersionNumber
		stream: aStream
]

{ #category : 'instance creation' }
GbxSpecFormatter class >> methodSourceForSpec: anOverrideSet versionString: aVersionString
[
	"Write the formatted representation of the specified override spec on aStream
	 with the preamble required to be a spec method
	 and answer the contents of the stream."

	^self
		methodSourceForSpec: anOverrideSet
		version: (GbxVersionNumber versionString: aVersionString)
]

{ #category : 'instance creation' }
GbxSpecFormatter class >> methodSourceForSpec: anOverrideSet version: aVersionNumber
[
	"Write the formatted representation of the specified override spec on aStream
	 with the preamble required to be a spec method
	 and answer the contents of the stream."

	^self methodSourceForSpec: anOverrideSet version: aVersionNumber on: String new writeStream
]

{ #category : 'instance creation' }
GbxSpecFormatter class >> formattedSpec: anOverrideSet
[
	"Write the formatted representation of the specified override spec on a stream
	 and answer the contents of the stream."

	^self formattedSpec: anOverrideSet on: String new writeStream
]

{ #category : 'instance creation' }
GbxSpecFormatter class >> formattedSpec: anOverrideSet on: aStream
[
	"Write the formatted representation of the specified override spec on aStream
	 and answer the contents of the stream."

	^(self spec: anOverrideSet version: GbxVersionNumber null stream: aStream) format
]

{ #category : 'instance creation' }
GbxSpecFormatter class >> methodSourceForSpec: anOverrideSet version: aVersionNumber on: aStream
[
	"Write the formatted representation of the specified override spec on aStream
	 with the preamble required to be a spec method
	 and answer the contents of the stream."

	aVersionNumber isNull ifTrue: [self gbsMessenger error: 'Spec methods require a valid version'].
	^(self spec: anOverrideSet version: aVersionNumber stream: aStream) format
]

