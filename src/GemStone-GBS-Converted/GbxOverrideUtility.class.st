Class {
	#name : 'GbxOverrideUtility',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'private' }
GbxOverrideUtility class >> compileSpecMethodFor: overrideSet in: specClass
[

	| newSource oldSource |
	newSource := self specMethodSourceFor: overrideSet.
	oldSource := specClass specMethodSource.
	self compileSpecSource: newSource inClass: specClass oldSource: oldSource
]

{ #category : 'private' }
GbxOverrideUtility class >> specMethodSourceFor: anOverrideSet
[
	"Answer a formatted string so that version comparisons can be practical."

	^GbxSpecFormatter
		methodSourceForSpec: anOverrideSet
		version: GbxVwVersion current
]

{ #category : 'private' }
GbxOverrideUtility class >> allOverridesInPackage: package
[
	"We want only the *last* override for each class or method."

	| result iterator |
	result := OrderedCollection new.
	iterator :=
			[:overrideCollection |
			"There are edge cases where the collection can be empty. e.g. upgrading the GBS version rather that loading into a new image."
			| mostRecentOverride |
			overrideCollection notEmpty
				ifTrue: 
					[mostRecentOverride := overrideCollection last.
					(mostRecentOverride overwrittenBySource: package)
						ifTrue: [result add: mostRecentOverride]]
				ifFalse: ["Override collection *is* empty"]].
	Override overriddenClassesAndNameSpaces do: iterator.
	Override overriddenMethods
		do: [:dictionaryForSelector | dictionaryForSelector do: iterator].
	^result
]

{ #category : 'private' }
GbxOverrideUtility class >> resolvePackageName: packageName ifFail: failBlock
[

	| package |
	package := Store.Registry pundleNamed: packageName.
	^package
		ifNil: 
			[OverrideFailureWarning
				raiseSignal: 'Cannot apply overrides; destination package '
						, packageName , ' not found.'.
			failBlock value]
]

{ #category : 'private' }
GbxOverrideUtility class >> removeAllOverridesFromPackage: aPackage
[
	"After creating specs from existing overrides, we must remove the overrides."

	| overrides alreadyDone |
	overrides := Override overriddenByComponent: aPackage.
	"The above gives us every override that is eclipsed by GBS overriding something in VisualWorks.
	 In some cases, VisualWorks overrides itself and GBS is considered to override both.
	 Overrides are ordered with the newer following older.
	 GBS really only overrides the latest, so make sure we don't remove multiple overrides."
	alreadyDone := Set new.
	overrides reverseDo: 
			[:override |
			| overrider |
			overrider := override printString.
			(alreadyDone includes: overrider)
				ifTrue: 
					[Transcript
						cr;
						nextPutAll: 'Multiple overrides of ';
						print: override;
						nextPutAll: ' were found']
				ifFalse: 
					[alreadyDone add: overrider.
					"Copied from RestoreOverrideChange>>#primitiveExecute"
					override reinstall.
					Override removeOverrideAfterReinstall: override]]
]

{ #category : 'private' }
GbxOverrideUtility class >> overrideSpecClasses
[
	"We cannot explicitly reference the classes because they don't all exist while loading is in progress."

	^GemStone.Gbs.GbxAbstractOverrideSpec subclasses
]

{ #category : 'private' }
GbxOverrideUtility class >> compileSpecSource: newSource inClass: specClass oldSource: oldSource
[

	newSource = oldSource ifTrue: [^self	"Nothing to do"].
	Store.Policies packagePolicy forcePackage: specClass specsPackage
		while: 
			[| compileResult |
			compileResult := specClass class
						compile: newSource
						classified: #generated
						notifying: nil
						attributes: nil
						environment: nil.
			compileResult
				ifNil: 
					[self
						error: 'Spec method for ' , specClass printString , ' failed to compile.']]
]

{ #category : 'utilities' }
GbxOverrideUtility class >> differencesBetweenInstalledOverridesAndSpecs
[
	"Answer the differences between a spec derived from the installed overrides and the corresponding saved spec.
	 A collection of Dictionarys with the attributes with differences."

	^self overrideSpecClasses
		collect: [:specClass | specClass differencesBetweenInstalledOverridesAndSpec]
]

{ #category : 'utilities' }
GbxOverrideUtility class >> ensureNoOverridesRemainInPundle: aPundle
[

	| overrides packagesWithOverrides message |
	overrides := OrderedCollection new.
	packagesWithOverrides := aPundle leafItems select: 
					[:eachPackage |
					| packageOverrides |
					packageOverrides := Override overriddenByComponent: eachPackage.
					overrides addAll: packageOverrides.
					packageOverrides notEmpty].
	overrides isEmpty
		ifFalse: 
			[message := WriteStream on: String new.
			message
				nextPutAll: 'Overrides remain in ';
				nextPutAll: aPundle name;
				nextPutAll: ' (';
				print: overrides size;
				nextPutAll: ' in '.
			packagesWithOverrides
				do: [:eachPackage | message nextPutAll: eachPackage name]
				separatedBy: [message nextPutAll: ', '].
			message nextPutAll:')'.
			self error: message contents]
]

{ #category : 'utilities' }
GbxOverrideUtility class >> generateOverrideSpecs
[
	"self generateOverrideSpecs"

	self overrideSpecClasses do: 
			[:specClass |
			| overrideSet |
			overrideSet := GbxOverrideSet fromPackage: specClass overridesPackage.
			overrideSet hasNoEffect
				ifTrue: 
					[^OverrideFailureWarning
						raiseSignal: 'There are no overrides in ' , specClass overridesPackageName
								, '; cannot generate an override spec from it'].
			self compileSpecMethodFor: overrideSet in: specClass]
]

{ #category : 'utilities' }
GbxOverrideUtility class >> prepareOverridesForRelease
[
	"When preparing a release, we remove any override of VisualWorks code to avoid copyright infringement."
	"self prepareOverridesForRelease"

	self
		generateOverrideSpecs;
		removeOverridesForRelease
]

{ #category : 'utilities' }
GbxOverrideUtility class >> reformatOverrideSpecMethods
[
	"Use this method when there are changes to the formatter and we need to
	 update all the existing spec methods to reflect the consequences."

	"GbxOverrideUtility reformatOverrideSpecMethods"

	self overrideSpecClasses do: 
			[:eachSpecClass |
			eachSpecClass versionPragmas do: 
					[:eachPragma |
					| versionString spec newSource oldSource |
					versionString := eachPragma arguments first.
					spec := eachSpecClass perform: eachPragma selector.
					newSource := GbxSpecFormatter
								methodSourceForSpec: spec
								versionString: versionString.
					oldSource := eachSpecClass sourceStringFor: eachPragma selector.
					self compileSpecSource: newSource inClass: eachSpecClass  oldSource: oldSource]]
]

{ #category : 'utilities' }
GbxOverrideUtility class >> reinstallOverrides
[
	"After removing overrides, you might want to re-install them."

	self confirmReplacingUnsavedOverrides ifFalse: [^self].
	self removeOverridesForRelease.
	self overrideSpecClasses do: [:specClass | specClass apply]
]

{ #category : 'utilities' }
GbxOverrideUtility class >> removeOverridesForRelease
[
	"When preparing a release, we remove any override of VisualWorks code to avoid copyright infringement."
	"self removeOverridesForRelease"

	self overrideSpecClasses do: 
			[:specClass |
			self removeAllOverridesFromPackage: specClass overridesPackage]
]

{ #category : 'utilities' }
GbxOverrideUtility class >> applyOverrideSet: overrideSet
[
	"Only apply if the named package contains no overrides.
	 If it is not empty we assume overrides have already been applied.
	 There could also be unsaved overrides which we wouldn't want to obliterate."

	overrideSet hasNoEffect ifTrue: [^nil].
	overrideSet allOverridesInPackage isEmpty
		ifTrue: [overrideSet apply]
		ifFalse: [OverrideFailureWarning
				raiseSignal: 'Overrides not applied for ', overrideSet packageName, '. There are already overrides loaded in the image.'.
				^nil]
]

{ #category : 'utilities' }
GbxOverrideUtility class >> uninstalledOverridesSpecs
[
	"Answer the override spec classes that do not have overrides installed."

	^self overrideSpecClasses
		select: [:specClass | (GbxOverrideSet fromPackage: specClass overridesPackage) hasNoEffect]
]

{ #category : 'utilities' }
GbxOverrideUtility class >> areThereSavedOverridesInstalled
[
	"Answer whether there are override methods which can safely be deleted
	 since the override specs match them."

	^self overrideSpecClasses
		allSatisfy: [:specClass | specClass canInstalledOverridesBeSafelyRemoved]
]

{ #category : 'utilities' }
GbxOverrideUtility class >> unsavedOverrideSpecs
[

	^self overrideSpecClasses
		select: [:specClass | specClass areInstalledOverridesUnsaved]
]

{ #category : 'utilities' }
GbxOverrideUtility class >> checkForUnsavedOverrideChanges
[
	"Check whether override methods have been modified (added, changed, or deleted)
	 without the corresponding spec having been updated.
	 The overrides packages content is transient; they will be emptied when saving to Store.
	 (It's impossible to have the overrides for all versions of VW loaded at the same time,
	 only the specs can provide that.)"
	"self checkForUnsavedOverrideChanges"

	| unsavedSpecs |
	unsavedSpecs := self unsavedOverrideSpecs.
	unsavedSpecs notEmpty
		ifTrue: 
			[self error: 'There are unsaved overrides installed in '
						, (unsavedSpecs collect: [:each | each overridesPackage]) printString]
]

{ #category : 'utilities' }
GbxOverrideUtility class >> confirmReplacingUnsavedOverrides
[
	"Answer whether it is safe to reinstall override if any methods have been modified (added, changed, or deleted)
	 without the corresponding spec having been updated. If there are none, then it is safe by definition."
	"self confirmReplacingUnsavedOverrides"

	| unsavedSpecs messageStream |
	(unsavedSpecs := self unsavedOverrideSpecs) isEmpty ifTrue: [^true].

	messageStream := WriteStream on: String new.
	messageStream nextPutAll: 'There are unsaved overrides installed in:'; cr.
	unsavedSpecs do: [:each | messageStream tab; nextPutAll: each overridesPackage name; cr].
	messageStream cr; nextPutAll: 'Do you want to replace the overrides in them?'.

	^self gbsMessenger confirm: messageStream contents.
]

