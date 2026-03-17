Class {
	#name : 'GbxOverridesWithEdits',
	#superclass : 'GbxOverride',
	#instVars : [
		'behavior',
		'crc',
		'edits'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'comparing' }
GbxOverridesWithEdits >> hash
[

	^self behavior hash
		+ self crc hash
		+ self edits hash
]

{ #category : 'comparing' }
GbxOverridesWithEdits >> = anOtherOverride
[

	^self class = anOtherOverride class
		and: [self behavior = anOtherOverride behavior
		and: [self crc = anOtherOverride crc
		and: [self edits = anOtherOverride edits]]]
]

{ #category : 'comparing' }
GbxOverridesWithEdits >> equalOtherThanEditsTo: anOtherOverride
[

	^self class = anOtherOverride class
		and: [self behavior = anOtherOverride behavior
		and: [self crc = anOtherOverride crc]]
]

{ #category : 'accessing' }
GbxOverridesWithEdits >> behavior: aBehavior
[

	behavior := aBehavior
]

{ #category : 'accessing' }
GbxOverridesWithEdits >> behavior
[

	^behavior
]

{ #category : 'accessing' }
GbxOverridesWithEdits >> crc
[

	^crc
]

{ #category : 'accessing' }
GbxOverridesWithEdits >> edits
[

	^edits
]

{ #category : 'accessing' }
GbxOverridesWithEdits >> package
[

	^parent package
]

{ #category : 'accessing' }
GbxOverridesWithEdits >> crc: anInteger
[

	crc := anInteger
]

{ #category : 'accessing' }
GbxOverridesWithEdits >> edits: someOverrideEdits
[

	edits := someOverrideEdits asOrderedCollection.
	edits do: [:each | each parent: self]
]

{ #category : 'private' }
GbxOverridesWithEdits >> setCrcFrom: overridden
[
	"Compute the CRC from the original/overridden source"
	
	self subclassResponsibility
]

{ #category : 'private' }
GbxOverridesWithEdits >> editOriginal: sourceString andApplyUsing: aBlock
[

	| toStream fromStream |
	fromStream := ReadStream on: sourceString.
	toStream := WriteStream on: String new.
	edits do: [:each | each applyFrom: fromStream to: toStream].
	Store.Policies packagePolicy
		forcePackage: parent package
		while: [aBlock value: toStream contents]
]

{ #category : 'private' }
GbxOverridesWithEdits >> crcForString: aString
[

	^CRC32Function crc32Of: (aString asByteArrayEncoding: #UTF8)
]

{ #category : 'private' }
GbxOverridesWithEdits >> setEditsFromOriginal: originalSource toOverride: overridingSource
[
	"Generate subsequences of TextFragmants so the override specs will be shorter
	 and more recognizable."

	| subsequences subSeqEdits |
	subsequences := originalSource smalltalkOrWordAndWhitespaceFragments
				differences: overridingSource smalltalkOrWordAndWhitespaceFragments.
	subSeqEdits := subsequences
				collect: [:each | GbxOverrideEdit fromSubSequence: each forParent: self].
	self edits: subSeqEdits asOrderedCollection
]

{ #category : 'private' }
GbxOverridesWithEdits >> setEditsFrom: overridden
[
	"Compute the edits from the original/overridden source to get to the overriding source."
	
	self subclassResponsibility
]

{ #category : 'private' }
GbxOverridesWithEdits >> setCrcFromOriginal: originalString
[

	crc := self crcForString: originalString
]

{ #category : 'applying' }
GbxOverridesWithEdits >> apply
[
	"Apply the edits to the original source (source code, instance variables list, etc.)
	 and install the override into the system."
	
	self subclassResponsibility
]

