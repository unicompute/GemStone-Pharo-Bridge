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
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'storing' }
GbxOverrideSet >> storeOn: aStream
[
	aStream
		nextPutAll: self class fullName;
		nextPutAll: ' destinationPackageName: '.
	packageName storeOn: aStream.
	self
		storeOverrides: classOverrides
		withKeyword: #classOverrides:
		on: aStream.
	self
		storeOverrides: variableOverrides
		withKeyword: #variableOverrides:
		on: aStream.
	self
		storeOverrides: methodOverrides
		withKeyword: #methodOverrides:
		on: aStream.
]

{ #category : 'comparing' }
GbxOverrideSet >> hash
[

	^self classOverrides hash
		+ self methodOverrides hash
		+ self variableOverrides hash
		+ self packageName hash
]

{ #category : 'comparing' }
GbxOverrideSet >> = anotherOverrideSet
[

	^self class = anotherOverrideSet class
		and: [self packageName = anotherOverrideSet packageName
		and: [self classOverrides = anotherOverrideSet classOverrides
		and: [self methodOverrides = anotherOverrideSet methodOverrides
		and: [self variableOverrides = anotherOverrideSet variableOverrides]]]]
]

{ #category : 'comparing' }
GbxOverrideSet >> differencesFrom: anotherOverrideSet
[
	"Compose the differences into a Dictionary and answer that."

	| result |
	result := (Dictionary new)
				at: #packageName put: self packageName;
				at: #status put: 'No differences';
				yourself.
	(self contentDiffersFrom: anotherOverrideSet) ifFalse: [^result].
	result at: #status put: 'Differences found'.
	self packageName = anotherOverrideSet packageName
		ifFalse: [result at: #otherPackageName put: anotherOverrideSet packageName].
	self classOverrides = anotherOverrideSet classOverrides
		ifFalse: 
			[result at: #classOverrides
				put: (self differencesBetweenOverrides: self classOverrides
						and: anotherOverrideSet classOverrides)].
	self methodOverrides = anotherOverrideSet methodOverrides
		ifFalse: 
			[result at: #methodOverrides
				put: (self differencesBetweenOverrides: self methodOverrides
						and: anotherOverrideSet methodOverrides)].
	self variableOverrides = anotherOverrideSet variableOverrides
		ifFalse: 
			[result at: #variableOverrides
				put: (self differencesBetweenOverrides: self variableOverrides
						and: anotherOverrideSet variableOverrides)].
	^result
]

{ #category : 'comparing' }
GbxOverrideSet >> differencesBetweenOverrides: someOverrides and: otherOverrides
[
	"Subsequences probably aren't sufficient.
	 It seems like two overides for the same method can differ in their edits,
	 and the subsequence will be delete one and add the other."

	| rawSubsequences insertions deletions keys editsOnlyConflicts complexConflicts results |
	rawSubsequences := someOverrides differences: otherOverrides.
	insertions := Dictionary new.
	deletions := Dictionary new.
	editsOnlyConflicts := Dictionary new.
	complexConflicts := Dictionary new.
	rawSubsequences do: [:eachSubSeq | 
		eachSubSeq isInsert ifTrue: [eachSubSeq do: [:each | insertions at: each printString put: each]].
		eachSubSeq isDelete ifTrue: [eachSubSeq do: [:each | deletions at: each printString put: each]]].
	keys := Set new
			addAll: deletions keys;
			addAll: insertions keys;
			yourself.
	keys do: [:eachKey |
		|  del ins |
		del := deletions removeKey: eachKey ifAbsent: [].
		ins := insertions removeKey: eachKey ifAbsent: [].
		(del notNil and: [ins notNil])
			ifTrue: [((del equalOtherThanEditsTo: ins)
							ifTrue: [editsOnlyConflicts]
							ifFalse: [complexConflicts])
								at: eachKey put: del -> ins -> (del edits differences: ins edits)]].
		
	results := Dictionary new.
	insertions notEmpty ifTrue: [results at: #insertions put: insertions].
	deletions notEmpty ifTrue: [results at: #deletions put: deletions].
	editsOnlyConflicts notEmpty ifTrue: [results at: #editsOnlyConflicts put: editsOnlyConflicts].
	complexConflicts notEmpty ifTrue: [results at: #complexConflicts put: complexConflicts].
	^results
]

{ #category : 'accessing' }
GbxOverrideSet >> variableOverrides
[

	^variableOverrides
]

{ #category : 'accessing' }
GbxOverrideSet >> packageName
[

	^packageName
]

{ #category : 'accessing' }
GbxOverrideSet >> methodOverrides: aCollection
[
	methodOverrides := self setupOverrides: aCollection
]

{ #category : 'accessing' }
GbxOverrideSet >> methodOverrides
[

	^methodOverrides
]

{ #category : 'accessing' }
GbxOverrideSet >> packageName: aString
[
	packageName := aString
]

{ #category : 'accessing' }
GbxOverrideSet >> classOverrides: aCollection
[
	classOverrides := self setupOverrides: aCollection
]

{ #category : 'accessing' }
GbxOverrideSet >> package
[

	^package
		ifNil: 
			[self resolvePackageIfFail: [^nil	"Cannot continue"].
			package]
]

{ #category : 'accessing' }
GbxOverrideSet >> classOverrides
[

	^classOverrides
]

{ #category : 'accessing' }
GbxOverrideSet >> variableOverrides: aCollection
[
	variableOverrides := self setupOverrides: aCollection
]

{ #category : 'testing' }
GbxOverrideSet >> hasNoEffect
[

	classOverrides isEmpty ifFalse: [^false].
	variableOverrides isEmpty ifFalse: [^false].
	methodOverrides isEmpty ifFalse: [^false].
	^true
]

{ #category : 'testing' }
GbxOverrideSet >> hasEffect
[

	^self hasNoEffect not
]

{ #category : 'testing' }
GbxOverrideSet >> contentDiffersFrom: anotherOverrideSet
[
	^self ~= anotherOverrideSet
]

{ #category : 'private' }
GbxOverrideSet >> addMethodOverrides
[

	| overriddenMethods |
	overriddenMethods := self allOverridesInPackage
				select: [:each | each isForMethod].
				
	overriddenMethods do: 
			[:each |
			methodOverrides
				add: (GbxMethodOverride fromOverriddenMethod: each forParent: self)].
	self sortOverrides: methodOverrides.
]

{ #category : 'private' }
GbxOverrideSet >> addClassOverrides
[

	| overriddenClasses |
	overriddenClasses := self allOverridesInPackage
				select: [:each | each isForClass].
	overriddenClasses do: 
			[:each |
			classOverrides
				add: (GbxClassOverride fromOverriddenClass: each forParent: self)].
	self sortOverrides: classOverrides.
]

{ #category : 'private' }
GbxOverrideSet >> sortOverrides: anOrderedCollection
[
	anOrderedCollection sort: [:a :b | a printString <= b printString]
]

{ #category : 'private' }
GbxOverrideSet >> resolvePackageIfFail: failBlock
[
	package := GbxOverrideUtility
				resolvePackageName: packageName
				ifFail: failBlock
]

{ #category : 'private' }
GbxOverrideSet >> allOverridesInPackage
[

	^GbxOverrideUtility allOverridesInPackage: self package
]

{ #category : 'private' }
GbxOverrideSet >> addVariableOverrides
[

	| overridesInPackage |
	overridesInPackage := self allOverridesInPackage
				select: [:each | each isForGeneral ].
	overridesInPackage isEmpty
		ifFalse: [self error: 'Variable overrides not yet implemented'].
	self sortOverrides: variableOverrides.
]

{ #category : 'applying' }
GbxOverrideSet >> apply
[
	"Answer true if all overrides succeeded, false if any failed."

	| report |
	self hasNoEffect ifTrue: [^true].
	self resolvePackageIfFail: [^false	"Cannot continue"].
	report := WriteStream on: String new.
	
	[classOverrides do: [:each | each apply].
	variableOverrides do: [:each | each apply].
	methodOverrides do: [:each | each apply]]
			on: OverrideFailureWarning
			do: 
				[:ex |
				report
					cr;
					nextPutAll: ex messageText.
				ex resume].
	report position > 0
		ifTrue: 
			[OverrideFailureWarning raiseSignal: report contents.
			^false].
	^true
]

{ #category : 'initialize-release' }
GbxOverrideSet >> initialize
[
	classOverrides := OrderedCollection new.
	variableOverrides := OrderedCollection new.
	methodOverrides := OrderedCollection new
]

{ #category : 'initialize-release' }
GbxOverrideSet >> addAllOverridesInPackage: aPackage
[
	package := aPackage.
	packageName := aPackage name.
	self
		addClassOverrides;
		addVariableOverrides;
		addMethodOverrides
]

{ #category : 'initialize-release' }
GbxOverrideSet >> setupOverrides: aCollection
[
	"Make sure the overrides are of the correct class with their parent set
	 and sorted so that comparisons are useful."

	| overrides |
	overrides := aCollection asOrderedCollection.
	self sortOverrides: overrides.
	overrides do: [:each | each parent: self].
	^overrides
]

{ #category : 'printing' }
GbxOverrideSet >> printOn: aStream
[
	aStream
		nextPutAll: self class name;
		nextPutAll: '(';
		nextPutAll: (self packageName ifNil: ['']);
		space;
		print: self classOverrides size;
		nextPutAll: '/';
		print: self methodOverrides size;
		nextPutAll: '/';
		print: self variableOverrides size;
		nextPutAll: ')'
]

{ #category : 'instance creation' }
GbxOverrideSet class >> destinationPackageName: nameString classOverrides: classOverrideArray variableOverrides: variableOverrideArray methodOverrides: methodOverrideArray
[
	"Used when applying overrides at GBS load time."

	^(self new)
		packageName: nameString;
		classOverrides: classOverrideArray;
		variableOverrides: variableOverrideArray;
		methodOverrides: methodOverrideArray;
		yourself
]

{ #category : 'instance creation' }
GbxOverrideSet class >> fromPackage: overridesPackage
[
	"Used for generating information about existing overrides before making parcels.
	These overrides will then be removed, then re-created at load time."
	"Answer an instance that specifies all of the overrides that the named package contains,
	without containing any of the overridden code."

	^(self new)
		initialize;
		addAllOverridesInPackage: overridesPackage;
		yourself
]

{ #category : 'instance creation' }
GbxOverrideSet class >> new
[
	^ self basicNew initialize
]

