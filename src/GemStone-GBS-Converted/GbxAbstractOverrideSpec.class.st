Class {
	#name : 'GbxAbstractOverrideSpec',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> spec
[
	"Answer the result of evaluating the spec* method which is closest to the current VisualWorks version, but not newer."

	^self perform: self specMethodSelector
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> specMethodPragma
[

	| vwVersion versionPragmas |
	vwVersion := GbxVwVersion current.
	versionPragmas := self versionPragmas.
	^versionPragmas
		detect: [:each | vwVersion >= each arguments first]
		ifNone: [self error: 'No available override spec for VisualWorks version ', vwVersion printString]
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> versionPragmas
[

	^(Pragma allNamed: #version: in: self class)
		asSortedCollection: [:a :b | a arguments first > b arguments first]
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> sourceStringFor: aSelector
[
	"Caution: This is not a general purpose method.
	 Override Spec classes only use class-side behavior."

	^(self class sourceCodeAt: aSelector) asString
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> specsPackage
[

	^self package
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> overridesPackageName
[
	"Answer the name of the packing in which the overrides will be installed from the spec."

	^self subclassResponsibility
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> specMethodVersion
[

	^self specMethodPragma arguments first
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> overridesPackage
[
	"Answer the name of the packing in which the overrides will be installed from the spec."

	^GbxOverrideUtility
		resolvePackageName: self overridesPackageName
		ifFail: [^nil]
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> specMethodSource
[
	"Answer the source code for the spec* method which is closest to the current VisualWorks version, but not newer."

	^self sourceStringFor: self specMethodSelector
]

{ #category : 'accessing' }
GbxAbstractOverrideSpec class >> specMethodSelector
[

	^self specMethodPragma selector
]

{ #category : 'testing' }
GbxAbstractOverrideSpec class >> differencesBetweenInstalledOverridesAndSpec
[
	"Answer a Dictionary identifying the spec attribute differences between a
	 spec derived from the installed overrides and the version specific spec."

	| installedOverridesSpec |
	installedOverridesSpec := GbxOverrideSet fromPackage: self overridesPackage.
	installedOverridesSpec hasNoEffect
		ifTrue: 
			[^Dictionary new
				at: #packageName put: self overridesPackageName;
				at: #status put: 'No installed overrides';
				yourself].
	^installedOverridesSpec differencesFrom: self spec
]

{ #category : 'testing' }
GbxAbstractOverrideSpec class >> areInstalledOverridesUnsaved
[
	"If the installed overrides have been cleared out, there is nothing to save.
	 If they match what has been saved, nothing more need be done.
	 If they don't match, we have a problem that the developer needs to address
	 (as in generated the updated spec)"
	"Note for the near future. We probably will want to be able to report what's added, changed, or removed between the two specs."

	| installedOverridesSpec |
	installedOverridesSpec := GbxOverrideSet fromPackage: self overridesPackage.
	^installedOverridesSpec hasEffect
		and: [self specContentDiffersFromInstalledSpec: installedOverridesSpec]
]

{ #category : 'testing' }
GbxAbstractOverrideSpec class >> specContentDiffersFromInstalledSpec: installedOverridesSpec
[

	| definedSpec |
	definedSpec := [self spec]
					on: Error
					do: 
						[:ex |
						(ex messageText beginsWith: 'No available override spec for VisualWorks version ')
							ifTrue: [^true].
						ex pass].
	^installedOverridesSpec contentDiffersFrom: definedSpec
]

{ #category : 'testing' }
GbxAbstractOverrideSpec class >> canInstalledOverridesBeSafelyRemoved
[
	"If the installed overrides have not been cleared out, they can be if they match the spec.
	 We sometimes find some packages have overrides installed with others empty.
	 If they all are empty (no effect) or match the spec, the installed overrides can be removed."

	| installedOverridesSpec |
	installedOverridesSpec := GbxOverrideSet fromPackage: self overridesPackage.
	^installedOverridesSpec hasNoEffect
		or: [(self specContentDiffersFromInstalledSpec: installedOverridesSpec) not]
]

{ #category : 'installing' }
GbxAbstractOverrideSpec class >> undeclaredNamesArisingFrom: aBlock
[

	| existingUndeclaredNames newlyUndeclaredNames undeclaredNames |
	existingUndeclaredNames := self undeclaredNames.
	aBlock value.
	undeclaredNames := self undeclaredNames.
	newlyUndeclaredNames := undeclaredNames asSortedCollection.
	existingUndeclaredNames do: 
			[:each |
			newlyUndeclaredNames remove: each
				ifAbsent: 
					["We don't care"
					]].
	^newlyUndeclaredNames
]

{ #category : 'installing' }
GbxAbstractOverrideSpec class >> apply
[
	"Apply the version appropriate spec only if my override package is empty, so it only happens once."

	| result spec effect newlyUndeclaredNames |
	spec := self spec.
	Transcript cr; print: spec; nextPutAll: ' apply starting (version '; nextPutAll: self specMethodVersion; nextPutAll: ')'.
	
	InputState default altDown
		ifTrue: [self halt: 'ALT key pressed; halting overrides installation'].

	newlyUndeclaredNames := self undeclaredNamesArisingFrom: [result := GbxOverrideUtility applyOverrideSet: spec].

	effect := result notNil
				ifTrue: [' successfully applied']
				ifFalse: [' had no effect; nothing applied'].
	Transcript cr; print: spec; nextPutAll: effect.
	
	newlyUndeclaredNames notEmpty ifTrue: [
		Transcript nextPutAll: '; newly undeclared: '.
		newlyUndeclaredNames
			do: [:each | Transcript nextPutAll: each]
			separatedBy: [Transcript nextPutAll: ', ']]
]

{ #category : 'installing' }
GbxAbstractOverrideSpec class >> undeclaredNames
[
	"Voodoo lies here. It seemed #purgedUnusedBindings and #globalGarbageCollect were insufficient.
	 Adding #yield in the hope that it helps."

	Undeclared keys isEmpty ifTrue: [^#()].
	Undeclared purgeUnusedBindings.
	Processor yield.
	ObjectMemory globalGarbageCollect.
	Processor yield.
	^Undeclared keys
]

{ #category : 'private' }
GbxAbstractOverrideSpec class >> versionPragma
[
	"Define the pragma used to specify the VisualWorks version that a given spec* method first applies to."
	<pragmas: #class>

	^#(#version:)
]

