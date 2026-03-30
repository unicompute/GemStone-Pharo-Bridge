Class {
	#name : 'GbxAbstractOverrideSpec',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'testing' }
GbxAbstractOverrideSpec class >> areInstalledOverridesUnsaved [
	| installedOverridesSpec |
	installedOverridesSpec := GbxOverrideSet fromPackage: self overridesPackage.
	^ installedOverridesSpec hasEffect
		and: [ self specContentDiffersFromInstalledSpec: installedOverridesSpec ]
]

{ #category : 'testing' }
GbxAbstractOverrideSpec class >> canInstalledOverridesBeSafelyRemoved [
	| installedOverridesSpec |
	installedOverridesSpec := GbxOverrideSet fromPackage: self overridesPackage.
	^ installedOverridesSpec hasNoEffect
		or: [ (self specContentDiffersFromInstalledSpec: installedOverridesSpec) not ]
]

{ #category : 'testing' }
GbxAbstractOverrideSpec class >> differencesBetweenInstalledOverridesAndSpec [
	| installedOverridesSpec |
	installedOverridesSpec := GbxOverrideSet fromPackage: self overridesPackage.
	installedOverridesSpec hasNoEffect ifTrue: [
		^ Dictionary new
			at: #packageName put: self overridesPackageName;
			at: #status put: 'No installed overrides';
			yourself ].
	^ installedOverridesSpec differencesFrom: self spec
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> overridesPackage [
	^ GbxOverrideUtility
		resolvePackageName: self overridesPackageName
		ifFail: [ nil ]
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> overridesPackageName [
	self subclassResponsibility
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> sourceStringFor: aSelector [
	| compiledMethod |
	compiledMethod := self class compiledMethodAt: aSelector ifAbsent: [ nil ].
	compiledMethod ifNil: [ ^ '' ].
	^ compiledMethod sourceCode asString
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> spec [
	^ self perform: self specMethodSelector
]

{ #category : 'testing' }
GbxAbstractOverrideSpec class >> specContentDiffersFromInstalledSpec: installedOverridesSpec [
	| definedSpec |
	definedSpec := [ self spec ]
		on: Error
		do: [ :ex | ^ true ].
	^ installedOverridesSpec contentDiffersFrom: definedSpec
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> specMethodPragma [
	| pragmas |
	pragmas := self versionPragmas.
	pragmas ifEmpty: [
		self error: 'No available override spec on ', self name ].
	^ pragmas first
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> specMethodSelector [
	^ self specMethodPragma methodSelector
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> specMethodSource [
	^ self sourceStringFor: self specMethodSelector
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> specMethodVersion [
	^ self specMethodPragma arguments first
]

{ #category : 'private' }
GbxAbstractOverrideSpec class >> versionComponentsFrom: aVersionString [
	^ (aVersionString asString substrings: '.')
		collect: [ :each | each asInteger ]
]

{ #category : 'private' }
GbxAbstractOverrideSpec class >> versionIs: leftVersionString newerOrEqualTo: rightVersionString [
	| left right maxSize |
	left := self versionComponentsFrom: leftVersionString.
	right := self versionComponentsFrom: rightVersionString.
	maxSize := left size max: right size.
	1 to: maxSize do: [ :index |
		| leftPart rightPart |
		leftPart := left at: index ifAbsent: [ 0 ].
		rightPart := right at: index ifAbsent: [ 0 ].
		leftPart = rightPart ifFalse: [ ^ leftPart >= rightPart ] ].
	^ true
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> versionPragmas [
	| pragmaHolder pragmas |
	pragmaHolder := (self respondsTo: #classSide)
		ifTrue: [ self classSide ]
		ifFalse: [ self class ].
	pragmas := OrderedCollection new.
	pragmaHolder methods do: [ :method |
		(method selector asString beginsWith: 'spec') ifTrue: [
			method pragmas do: [ :pragma |
				pragma selector = #version: ifTrue: [ pragmas add: pragma ] ] ] ].
	^ pragmas asSortedCollection: [ :a :b |
		self
			versionIs: a arguments first
			newerOrEqualTo: b arguments first ]
]
