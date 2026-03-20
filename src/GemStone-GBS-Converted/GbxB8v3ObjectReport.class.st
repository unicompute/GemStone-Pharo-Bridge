Class {
	#name : 'GbxB8v3ObjectReport',
	#superclass : 'Gbx8v3ObjectReport',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing header' }
GbxB8v3ObjectReport >> namedSize
[

	namedSize == nil
		ifTrue: 
			[namedSize := (data basicAt: offset + 4) * 16r100
				+ (data basicAt: offset + 5)].
	^namedSize
]

{ #category : 'accessing header' }
GbxB8v3ObjectReport >> objImpl
[

	objImpl == nil ifTrue: [objImpl := (data basicAt: offset + 39) bitAnd: 3].
	^objImpl
]

{ #category : 'accessing header' }
GbxB8v3ObjectReport >> isClamped
[

	^((data basicAt: offset + 39) bitAnd: 16r80) ~= 0
]

{ #category : 'accessing header' }
GbxB8v3ObjectReport >> namedSize: aSize
[
	"Specific to big-endian."

	namedSize := aSize.
	data
		basicAt: offset + 5 put: (aSize bitAnd: 16rFF);
		basicAt: offset + 4 put: (aSize bitShift: -8)
]

{ #category : 'accessing header' }
GbxB8v3ObjectReport >> segment
[

	segment == nil
		ifTrue: 
			[segment := (data basicAt: offset + 6) * 16r100
				+ (data basicAt: offset + 7)].
	^segment
]

{ #category : 'accessing header' }
GbxB8v3ObjectReport >> isInvariant
[

	^((data basicAt: offset + 39) bitAnd: 8) ~= 0
]

{ #category : 'accessing header' }
GbxB8v3ObjectReport >> isOverlayed
[

	^((data basicAt: offset + 39) bitAnd: 16r20) ~= 0
]

{ #category : 'accessing header' }
GbxB8v3ObjectReport >> lacksReadAuth
[

	^((data basicAt: offset + 39) bitAnd: 16r40) ~= 0
]

{ #category : 'accessing header' }
GbxB8v3ObjectReport >> segment: aSegment
[

	segment := aSegment.
	data
		basicAt: offset + 7 put: (aSegment bitAnd: 16rFF);
		basicAt: offset + 6 put: (aSegment bitShift: -8)
]

{ #category : 'accessing header' }
GbxB8v3ObjectReport >> isIndexable
[

	^((data basicAt: offset + 39) bitAnd: 4) ~= 0
]

{ #category : 'private-addressing' }
GbxB8v3ObjectReport >> oopArrayClass
[

	^GbxB8OopArray
]
