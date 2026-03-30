Class {
	#name : 'GbxOverrideSet',
	#superclass : 'GbxOverrideSpec',
	#instVars : [
		'packageName',
		'classOverrides',
		'variableOverrides',
		'methodOverrides',
		'package'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxOverrideSet class >> destinationPackageName: nameString classOverrides: classOverrideArray variableOverrides: variableOverrideArray methodOverrides: methodOverrideArray [
	^ self new
		packageName: nameString;
		classOverrides: classOverrideArray;
		variableOverrides: variableOverrideArray;
		methodOverrides: methodOverrideArray;
		yourself
]

{ #category : 'instance creation' }
GbxOverrideSet class >> fromPackage: overridesPackage [
	^ self new
		addAllOverridesInPackage: overridesPackage;
		yourself
]

{ #category : 'instance creation' }
GbxOverrideSet class >> new [
	^ self basicNew initialize
]

{ #category : 'initialize-release' }
GbxOverrideSet >> addAllOverridesInPackage: aPackage [
	package := aPackage.
	packageName := (aPackage respondsTo: #name)
		ifTrue: [ aPackage name asString ]
		ifFalse: [ aPackage asString ].
	self
		addClassOverrides;
		addVariableOverrides;
		addMethodOverrides
]

{ #category : 'private' }
GbxOverrideSet >> addClassOverrides [
	self sortOverrides: classOverrides
]

{ #category : 'private' }
GbxOverrideSet >> addMethodOverrides [
	self sortOverrides: methodOverrides
]

{ #category : 'private' }
GbxOverrideSet >> addVariableOverrides [
	self sortOverrides: variableOverrides
]

{ #category : 'applying' }
GbxOverrideSet >> apply [
	| report |
	self hasNoEffect ifTrue: [ ^ true ].
	report := WriteStream on: String new.
	[
		classOverrides do: [ :each | each apply ].
		variableOverrides do: [ :each | each apply ].
		methodOverrides do: [ :each | each apply ] ]
		on: OverrideFailureWarning
		do: [ :ex |
			report
				cr;
				nextPutAll: ex messageText.
			ex resume ].
	report position > 0 ifTrue: [
		OverrideFailureWarning raiseSignal: report contents.
		^ false ].
	^ true
]

{ #category : 'accessing' }
GbxOverrideSet >> classOverrides [
	^ classOverrides
]

{ #category : 'accessing' }
GbxOverrideSet >> classOverrides: aCollection [
	classOverrides := self setupOverrides: aCollection
]

{ #category : 'testing' }
GbxOverrideSet >> contentDiffersFrom: anotherOverrideSet [
	^ self ~= anotherOverrideSet
]

{ #category : 'comparing' }
GbxOverrideSet >> = anotherOverrideSet [
	^ self class = anotherOverrideSet class
		and: [
			self packageName = anotherOverrideSet packageName
				and: [
					self classOverrides = anotherOverrideSet classOverrides
						and: [
							self methodOverrides = anotherOverrideSet methodOverrides
								and: [ self variableOverrides = anotherOverrideSet variableOverrides ] ] ] ]
]

{ #category : 'comparing' }
GbxOverrideSet >> differencesBetweenOverrides: someOverrides and: otherOverrides [
	| leftByKey rightByKey onlyLeft onlyRight editsOnlyConflicts complexConflicts results |
	leftByKey := Dictionary new.
	rightByKey := Dictionary new.
	someOverrides do: [ :each | leftByKey at: each printString put: each ].
	otherOverrides do: [ :each | rightByKey at: each printString put: each ].
	onlyLeft := Dictionary new.
	onlyRight := Dictionary new.
	editsOnlyConflicts := Dictionary new.
	complexConflicts := Dictionary new.
	leftByKey keysAndValuesDo: [ :key :left |
		| right |
		right := rightByKey removeKey: key ifAbsent: [ nil ].
		right
			ifNil: [ onlyLeft at: key put: left ]
			ifNotNil: [
				left = right ifFalse: [
					(left respondsTo: #equalOtherThanEditsTo:)
						ifTrue: [
							((left equalOtherThanEditsTo: right)
								ifTrue: [ editsOnlyConflicts ]
								ifFalse: [ complexConflicts ])
									at: key
									put: (Dictionary new
										at: #left put: left;
										at: #right put: right;
										yourself) ]
						ifFalse: [
							complexConflicts
								at: key
								put: (Dictionary new
									at: #left put: left;
									at: #right put: right;
									yourself) ] ] ] ].
	rightByKey keysAndValuesDo: [ :key :right | onlyRight at: key put: right ].
	results := Dictionary new.
	onlyRight isEmpty ifFalse: [ results at: #insertions put: onlyRight ].
	onlyLeft isEmpty ifFalse: [ results at: #deletions put: onlyLeft ].
	editsOnlyConflicts isEmpty ifFalse: [ results at: #editsOnlyConflicts put: editsOnlyConflicts ].
	complexConflicts isEmpty ifFalse: [ results at: #complexConflicts put: complexConflicts ].
	^ results
]

{ #category : 'comparing' }
GbxOverrideSet >> differencesFrom: anotherOverrideSet [
	| result |
	result := Dictionary new
		at: #packageName put: self packageName;
		at: #status put: 'No differences';
		yourself.
	(self contentDiffersFrom: anotherOverrideSet) ifFalse: [ ^ result ].
	result at: #status put: 'Differences found'.
	self packageName = anotherOverrideSet packageName ifFalse: [
		result at: #otherPackageName put: anotherOverrideSet packageName ].
	self classOverrides = anotherOverrideSet classOverrides ifFalse: [
		result
			at: #classOverrides
			put: (self differencesBetweenOverrides: self classOverrides and: anotherOverrideSet classOverrides) ].
	self methodOverrides = anotherOverrideSet methodOverrides ifFalse: [
		result
			at: #methodOverrides
			put: (self differencesBetweenOverrides: self methodOverrides and: anotherOverrideSet methodOverrides) ].
	self variableOverrides = anotherOverrideSet variableOverrides ifFalse: [
		result
			at: #variableOverrides
			put: (self differencesBetweenOverrides: self variableOverrides and: anotherOverrideSet variableOverrides) ].
	^ result
]

{ #category : 'printing' }
GbxOverrideSet >> format [
	^ GbxSpecFormatter format: self
]

{ #category : 'testing' }
GbxOverrideSet >> hasEffect [
	^ self hasNoEffect not
]

{ #category : 'testing' }
GbxOverrideSet >> hasNoEffect [
	classOverrides isEmpty ifFalse: [ ^ false ].
	variableOverrides isEmpty ifFalse: [ ^ false ].
	methodOverrides isEmpty ifFalse: [ ^ false ].
	^ true
]

{ #category : 'comparing' }
GbxOverrideSet >> hash [
	^ self classOverrides hash
		bitXor: self methodOverrides hash
		bitXor: self variableOverrides hash
		bitXor: self packageName hash
]

{ #category : 'initialize-release' }
GbxOverrideSet >> initialize [
	classOverrides := OrderedCollection new.
	variableOverrides := OrderedCollection new.
	methodOverrides := OrderedCollection new.
	^ self
]

{ #category : 'accessing' }
GbxOverrideSet >> methodOverrides [
	^ methodOverrides
]

{ #category : 'accessing' }
GbxOverrideSet >> methodOverrides: aCollection [
	methodOverrides := self setupOverrides: aCollection
]

{ #category : 'accessing' }
GbxOverrideSet >> package [
	^ package ifNil: [ packageName ]
]

{ #category : 'accessing' }
GbxOverrideSet >> packageName [
	^ packageName
]

{ #category : 'accessing' }
GbxOverrideSet >> packageName: aString [
	packageName := aString
]

{ #category : 'printing' }
GbxOverrideSet >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		nextPutAll: (self packageName ifNil: [ '' ]);
		space;
		print: self classOverrides size;
		nextPutAll: '/';
		print: self methodOverrides size;
		nextPutAll: '/';
		print: self variableOverrides size;
		nextPut: $)
]

{ #category : 'initialize-release' }
GbxOverrideSet >> setupOverrides: aCollection [
	| overrides |
	overrides := aCollection asOrderedCollection.
	self sortOverrides: overrides.
	overrides do: [ :each | each parent: self ].
	^ overrides
]

{ #category : 'private' }
GbxOverrideSet >> sortOverrides: anOrderedCollection [
	anOrderedCollection sort: [ :a :b | a printString <= b printString ]
]

{ #category : 'printing' }
GbxOverrideSet >> storeOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPutAll: ' destinationPackageName: '.
	packageName storeOn: aStream.
	aStream
		nextPutAll: ' classOverrides: '.
	self storeCollection: classOverrides on: aStream.
	aStream
		nextPutAll: ' variableOverrides: '.
	self storeCollection: variableOverrides on: aStream.
	aStream
		nextPutAll: ' methodOverrides: '.
	self storeCollection: methodOverrides on: aStream
]

{ #category : 'accessing' }
GbxOverrideSet >> variableOverrides [
	^ variableOverrides
]

{ #category : 'accessing' }
GbxOverrideSet >> variableOverrides: aCollection [
	variableOverrides := self setupOverrides: aCollection
]
