Class {
	#name : 'GbxOverridesWithEdits',
	#superclass : 'GbxOverride',
	#instVars : [
		'behavior',
		'crc',
		'edits'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'applying' }
GbxOverridesWithEdits >> apply [
	self subclassResponsibility
]

{ #category : 'accessing' }
GbxOverridesWithEdits >> behavior [
	^ behavior
]

{ #category : 'accessing' }
GbxOverridesWithEdits >> behavior: aBehavior [
	behavior := aBehavior
]

{ #category : 'accessing' }
GbxOverridesWithEdits >> crc [
	^ crc
]

{ #category : 'accessing' }
GbxOverridesWithEdits >> crc: anInteger [
	crc := anInteger
]

{ #category : 'private' }
GbxOverridesWithEdits >> crcForString: aString [
	^ GbxOverrideUtility crc32OfString: aString
]

{ #category : 'private' }
GbxOverridesWithEdits >> editOriginal: sourceString andApplyUsing: aBlock [
	^ aBlock value: (self editedSourceFrom: sourceString)
]

{ #category : 'private' }
GbxOverridesWithEdits >> editedSourceFrom: sourceString [
	| inputStream outputStream |
	inputStream := ReadStream on: sourceString.
	outputStream := WriteStream on: String new.
	self edits do: [ :each | each applyFrom: inputStream to: outputStream ].
	^ outputStream contents
]

{ #category : 'accessing' }
GbxOverridesWithEdits >> edits [
	^ edits ifNil: [ edits := OrderedCollection new ]
]

{ #category : 'accessing' }
GbxOverridesWithEdits >> edits: someOverrideEdits [
	edits := someOverrideEdits asOrderedCollection.
	edits do: [ :each | each parent: self ]
]

{ #category : 'comparing' }
GbxOverridesWithEdits >> = anOtherOverride [
	^ self class = anOtherOverride class
		and: [
			self behavior = anOtherOverride behavior
				and: [
					self crc = anOtherOverride crc
						and: [ self edits = anOtherOverride edits ] ] ]
]

{ #category : 'comparing' }
GbxOverridesWithEdits >> equalOtherThanEditsTo: anOtherOverride [
	^ self class = anOtherOverride class
		and: [
			self behavior = anOtherOverride behavior
				and: [ self crc = anOtherOverride crc ] ]
]

{ #category : 'comparing' }
GbxOverridesWithEdits >> hash [
	^ self behavior hash
		bitXor: self crc hash
		bitXor: self edits hash
]

{ #category : 'accessing' }
GbxOverridesWithEdits >> package [
	^ parent ifNil: [ nil ] ifNotNil: [ parent packageName ]
]

{ #category : 'private' }
GbxOverridesWithEdits >> setCrcFromOriginal: originalString [
	crc := self crcForString: originalString
]

{ #category : 'private' }
GbxOverridesWithEdits >> setEditsFromOriginal: originalSource toOverride: overridingSource [
	| prefix suffix originalLimit overrideLimit changesToDelete insertedString generated |
	prefix := 0.
	[
		(prefix < originalSource size)
			and: [
				prefix < overridingSource size
					and: [ (originalSource at: prefix + 1) = (overridingSource at: prefix + 1) ] ] ]
		whileTrue: [ prefix := prefix + 1 ].
	suffix := 0.
	originalLimit := originalSource size - prefix.
	overrideLimit := overridingSource size - prefix.
	[
		(suffix < originalLimit)
			and: [
				suffix < overrideLimit
					and: [
						(originalSource at: originalSource size - suffix)
							= (overridingSource at: overridingSource size - suffix) ] ] ]
		whileTrue: [ suffix := suffix + 1 ].
	changesToDelete := originalSource size - prefix - suffix.
	insertedString := overridingSource
		copyFrom: prefix + 1
		to: overridingSource size - suffix.
	generated := OrderedCollection new.
	prefix > 0 ifTrue: [ generated add: (GbxOverrideEditCopy count: prefix) ].
	changesToDelete > 0 ifTrue: [ generated add: (GbxOverrideEditDelete count: changesToDelete) ].
	insertedString ifNotEmpty: [ generated add: (GbxOverrideEditInsert string: insertedString) ].
	suffix > 0 ifTrue: [ generated add: (GbxOverrideEditCopy count: suffix) ].
	self edits: generated
]
