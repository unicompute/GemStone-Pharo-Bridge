Class {
	#name : #'GbxVersionNumber',
	#superclass : #'Magnitude',
	#instVars : [ #'versionComponents' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'comparing' }
GbxVersionNumber >> > aStringOrServerVersion 
	^(aStringOrServerVersion isKindOf: String) 
		ifTrue: [self > (self class versionString: aStringOrServerVersion)]
		ifFalse: [(self compareWith: aStringOrServerVersion) == 1]

{ #category : #'comparing' }
GbxVersionNumber >> < aStringOrServerVersion 
	^(aStringOrServerVersion isKindOf: String) 
		ifTrue: [self < (self class versionString: aStringOrServerVersion)]
		ifFalse: [(self compareWith: aStringOrServerVersion) == -1]

{ #category : #'comparing' }
GbxVersionNumber >> hash
	"Since we are able to be equal to a string, we must use string as the basis of the hash."
	
	^ self versionString hash

{ #category : #'comparing' }
GbxVersionNumber >> = aStringOrServerVersion 
	^(aStringOrServerVersion isKindOf: String) 
		ifTrue: [self = (self class versionString: aStringOrServerVersion)]
		ifFalse: [(self compareWith: aStringOrServerVersion) == 0]

{ #category : #'printing' }
GbxVersionNumber >> printVersionOn: aStream

	versionComponents
		do: [:each | aStream print: each]
		separatedBy: [aStream nextPut: $.]

{ #category : #'printing' }
GbxVersionNumber >> printOn: aStream 
	self printVersionOn: aStream

{ #category : #'printing' }
GbxVersionNumber >> digits

	| stream |
	stream := String new writeStream.
	versionComponents
		do: [:each | stream print: each].
	^stream contents

{ #category : #'testing' }
GbxVersionNumber >> isNull
	"A null version has no components"
	
	^versionComponents isEmpty

{ #category : #'private' }
GbxVersionNumber >> compareWith: otherVersion 
	"Answer 1 if I am later than otherVersion, -1 if I am earlier than 
	otherVersion, and 0 if I am the same as otherVersion."

	| mySize itsSize |
	mySize := self componentSize.
	itsSize := otherVersion componentSize.
	1 to: (mySize min: itsSize)
		do: 
			[:i | 
			| my its |
			my := self componentAt: i.
			its := otherVersion componentAt: i.
			my > its ifTrue: [^1].
			my < its ifTrue: [^-1]].
	"All components in common are equal. Longer one is later."
	mySize > itsSize ifTrue: [^1].
	mySize < itsSize ifTrue: [^-1].
	^0

{ #category : #'private' }
GbxVersionNumber >> componentSize
	^versionComponents size

{ #category : #'private' }
GbxVersionNumber >> versionString: versionString 
	versionComponents := self parseVersionString: versionString

{ #category : #'private' }
GbxVersionNumber >> versionString

	| aStream |
	aStream := WriteStream on: (String new: 16).
	self printVersionOn: aStream.
	^aStream contents

{ #category : #'private' }
GbxVersionNumber >> componentAt: index 
	^versionComponents at: index

{ #category : #'private' }
GbxVersionNumber >> parseVersionString: versionString 
	"versionString is expected to be in the form of ii.jj.kk.ll, where ii, jj, etc are 
	each one or more decimal digits, and there can one to any number of groups, 
	and they are separated by periods, but no leading or trailing period."

	| components initialIndex |
	components := OrderedCollection new.
	initialIndex := 1.
	[initialIndex <= versionString size] whileTrue: 
			[| periodIndex |
			periodIndex := versionString 
						nextIndexOf: $.
						from: initialIndex
						to: versionString size.
			periodIndex == nil ifTrue: [periodIndex := versionString size + 1].
			components 
				add: (versionString copyFrom: initialIndex to: periodIndex - 1) asNumber.
			initialIndex := periodIndex + 1].
	^components

{ #category : #'private - instance creation' }
GbxVersionNumber class >> versionString: versionString 
	^self new versionString: versionString

{ #category : #'private - instance creation' }
GbxVersionNumber class >> null

	^self versionString: ''

