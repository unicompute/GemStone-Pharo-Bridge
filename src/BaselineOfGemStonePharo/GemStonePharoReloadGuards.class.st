Class {
	#name : 'GemStonePharoReloadGuards',
	#superclass : 'Object',
	#category : 'BaselineOfGemStonePharo',
	#package : 'BaselineOfGemStonePharo'
}

{ #category : 'artifact support' }
GemStonePharoReloadGuards >> generateContractArtifactsFor: baselineContract repoRoot: repoRoot log: logBlock [
	| writeArtifact failures |
	writeArtifact := [ :relativePath :contents |
		| file |
		file := repoRoot / relativePath.
		file parent ensureCreateDirectory.
		file exists ifTrue: [ file delete ].
		file writeStreamDo: [ :stream |
			stream nextPutAll: (self normalizeContents: contents) ] ].
	failures := false.
	baselineContract generatedContractArtifactSpecs do: [ :spec |
		writeArtifact value: spec first value: spec second ].
	failures := (self generateDocumentationSectionsFor: baselineContract repoRoot: repoRoot log: logBlock) not or: [ failures ].
	self log: (failures
		ifTrue: [ 'GENERATED_CONTRACT_ARTIFACTS_FAILED' ]
		ifFalse: [ 'GENERATED_CONTRACT_ARTIFACTS_OK' ]) to: logBlock.
	^ failures not
]

{ #category : 'checks' }
GemStonePharoReloadGuards >> checkArchitectureFor: baselineContract loadGroup: loadGroup loadedPackages: loadedPackages log: logBlock [
	| failures packageSpecs groupSpecs packageNamesBySpec groupNamesBySpec activeGroupSpec activeGroupMembers missingLoaded unexpectedLoaded |
	failures := false.
	packageSpecs := baselineContract packageRequirementSpecs.
	groupSpecs := baselineContract groupMemberSpecs.
	packageNamesBySpec := (packageSpecs collect: [ :each | each first ]) asSet.
	groupNamesBySpec := (groupSpecs collect: [ :each | each first ]) asSet.

	packageSpecs do: [ :spec |
		| packageName expected unknownRequirements |
		packageName := spec first.
		expected := spec second asSet.
		unknownRequirements := expected difference: packageNamesBySpec.
		unknownRequirements isEmpty
			ifTrue: [ self log: 'ARCHITECTURE_BOUNDARY_OK package ', packageName to: logBlock ]
			ifFalse: [
				failures := true.
				self
					log: 'ARCHITECTURE_BOUNDARY_FAIL package ', packageName, ' has unknown requires ', unknownRequirements asArray printString
					to: logBlock ] ].

	groupSpecs do: [ :spec |
		| groupName members unknownMembers |
		groupName := spec first.
		members := spec second asSet.
		unknownMembers := members difference: packageNamesBySpec.
		(members isEmpty or: [ unknownMembers notEmpty ])
			ifTrue: [
				failures := true.
				self
					log: 'ARCHITECTURE_BOUNDARY_FAIL group ', groupName,
						(members isEmpty
							ifTrue: [ ' has no members' ]
							ifFalse: [ ' has unknown members ', unknownMembers asArray printString ])
					to: logBlock ]
			ifFalse: [ self log: 'ARCHITECTURE_BOUNDARY_OK group ', groupName to: logBlock ] ].

	baselineContract forbiddenPackageRequirementSpecs do: [ :spec |
		| packageName forbidden actualRequirements offenders |
		packageName := spec first.
		forbidden := spec second asSet.
		actualRequirements := ((packageSpecs
			detect: [ :each | each first = packageName ]
			ifNone: [ { packageName. #() } ]) second) asSet.
		offenders := actualRequirements intersection: forbidden.
		offenders isEmpty
			ifTrue: [ self log: 'ARCHITECTURE_BOUNDARY_OK no forbidden requires in ', packageName to: logBlock ]
			ifFalse: [
				failures := true.
				self
					log: 'ARCHITECTURE_BOUNDARY_FAIL ', packageName, ' has forbidden requires ', offenders asArray printString
					to: logBlock ] ].

	activeGroupSpec := groupSpecs
		detect: [ :each | each first = loadGroup ]
		ifNone: [ nil ].
	activeGroupSpec
		ifNil: [
			(groupNamesBySpec includes: loadGroup)
				ifFalse: [
					failures := true.
					self log: 'ARCHITECTURE_BOUNDARY_FAIL unknown load group ', loadGroup to: logBlock ] ]
		ifNotNil: [
			| pendingPackages |
			activeGroupMembers := Set new.
			pendingPackages := activeGroupSpec second asOrderedCollection.
			[ pendingPackages isEmpty ] whileFalse: [
				| packageName dependencies |
				packageName := pendingPackages removeFirst.
				(activeGroupMembers includes: packageName) ifFalse: [
					activeGroupMembers add: packageName.
					dependencies := ((packageSpecs
						detect: [ :each | each first = packageName ]
						ifNone: [ { packageName. #() } ]) second) asArray.
					dependencies do: [ :dependency |
						(activeGroupMembers includes: dependency)
							ifFalse: [ pendingPackages addLast: dependency ] ] ] ].
			missingLoaded := activeGroupMembers difference: loadedPackages.
			unexpectedLoaded := (loadedPackages intersection: packageNamesBySpec) difference: activeGroupMembers.
			(missingLoaded isEmpty and: [ unexpectedLoaded isEmpty ])
				ifTrue: [ self log: 'ARCHITECTURE_BOUNDARY_OK load group ', loadGroup to: logBlock ]
				ifFalse: [
					failures := true.
					self
						log: 'ARCHITECTURE_BOUNDARY_FAIL load group ', loadGroup, ' missing ', missingLoaded asArray printString,
							' unexpected ', unexpectedLoaded asArray printString
						to: logBlock ] ].

	self
		log: (failures
			ifTrue: [ 'ARCHITECTURE_BOUNDARY_FAILED' ]
			ifFalse: [ 'ARCHITECTURE_BOUNDARY_OK' ])
		to: logBlock.
	^ failures not
]

{ #category : 'checks' }
GemStonePharoReloadGuards >> checkNoCompatibilityFor: baselineContract loadedPackages: loadedPackages log: logBlock [
	| failures |
	failures := false.

	baselineContract noCompatibilityPackageNames do: [ :packageName |
		(loadedPackages includes: packageName)
			ifTrue: [
				failures := true.
				self log: 'NO_COMPATIBILITY_PROOF_FAIL loaded package ', packageName to: logBlock ]
			ifFalse: [
				self log: 'NO_COMPATIBILITY_PROOF_OK package ', packageName, ' absent' to: logBlock ] ].

	baselineContract noCompatibilityClassNames do: [ :classSymbol |
		(Smalltalk at: classSymbol ifAbsent: [ nil ])
			ifNil: [
				self log: 'NO_COMPATIBILITY_PROOF_OK class ', classSymbol asString, ' absent' to: logBlock ]
			ifNotNil: [
				failures := true.
				self log: 'NO_COMPATIBILITY_PROOF_FAIL class ', classSymbol asString, ' still present' to: logBlock ] ].

	baselineContract noCompatibilitySelectorChecks do: [ :spec |
		| classSymbol side selector cls behavior |
		classSymbol := spec first.
		side := spec second.
		selector := spec third.
		cls := Smalltalk at: classSymbol ifAbsent: [ nil ].
		behavior := cls
			ifNil: [ nil ]
			ifNotNil: [ side = #class ifTrue: [ cls class ] ifFalse: [ cls ] ].
		(behavior isNil or: [ (behavior includesSelector: selector) not ])
			ifTrue: [
				self
					log: 'NO_COMPATIBILITY_PROOF_OK selector ', classSymbol asString, '>>#', selector asString, ' absent'
					to: logBlock ]
			ifFalse: [
				failures := true.
				self
					log: 'NO_COMPATIBILITY_PROOF_FAIL selector ', behavior name, '>>#', selector asString, ' still present'
					to: logBlock ] ].

	baselineContract noCompatibilityMethodPackageNames do: [ :packageName |
		| offenders |
		offenders := OrderedCollection new.
		Smalltalk allClasses do: [ :eachClass |
			{ eachClass. eachClass class } do: [ :behavior |
				behavior methodDict values do: [ :compiledMethod |
					| methodPackage |
					methodPackage := [ compiledMethod package name ] on: Error do: [ nil ].
					methodPackage = packageName
						ifTrue: [ offenders add: { behavior name. compiledMethod selector } ] ] ] ].
		offenders isEmpty
			ifTrue: [
				self log: 'NO_COMPATIBILITY_PROOF_OK no methods in package ', packageName to: logBlock ]
			ifFalse: [
				failures := true.
				offenders do: [ :entry |
					self
						log: 'NO_COMPATIBILITY_PROOF_FAIL method package ', packageName, ' still owns ',
							entry first, '>>#', entry second asString
						to: logBlock ] ] ].

	self
		log: (failures
			ifTrue: [ 'NO_COMPATIBILITY_PROOF_FAILED' ]
			ifFalse: [ 'NO_COMPATIBILITY_PROOF_OK' ])
		to: logBlock.
	^ failures not
]

{ #category : 'checks' }
GemStonePharoReloadGuards >> checkNoCompatibilitySourceFor: baselineContract repoRoot: repoRoot log: logBlock [
	| failures |
	failures := false.

	baselineContract noCompatibilitySourceScanRoots do: [ :relativeRoot |
		| root matchingFiles |
		root := repoRoot / relativeRoot.
		root exists
			ifFalse: [
				failures := true.
				self log: 'NO_COMPAT_SOURCE_SCAN_FAIL missing root ', relativeRoot to: logBlock ]
			ifTrue: [
				matchingFiles := root allChildren select: [ :each |
					each isFile and: [ each extension = 'st' ] ].
				matchingFiles do: [ :file |
					| contents |
					contents := [ self normalizeContents: file contents ] on: Error do: [ '' ].
					baselineContract noCompatibilitySourceScanSnippets do: [ :snippet |
						(contents includesSubstring: snippet)
							ifTrue: [
								failures := true.
								self
									log: 'NO_COMPAT_SOURCE_SCAN_FAIL ', file pathString, ' contains ', snippet
									to: logBlock ] ] ].
				failures
					ifFalse: [ self log: 'NO_COMPAT_SOURCE_SCAN_OK root ', relativeRoot to: logBlock ] ] ].

	baselineContract noCompatibilitySecondarySourceScanFiles do: [ :relativePath |
		| file contents |
		file := repoRoot / relativePath.
		file exists
			ifFalse: [
				failures := true.
				self log: 'NO_COMPAT_SOURCE_SCAN_FAIL missing file ', relativePath to: logBlock ]
			ifTrue: [
				contents := [ self normalizeContents: file contents ] on: Error do: [ '' ].
				baselineContract noCompatibilitySecondarySourceScanSnippets do: [ :snippet |
					(contents includesSubstring: snippet)
						ifTrue: [
							failures := true.
							self
								log: 'NO_COMPAT_SOURCE_SCAN_FAIL ', file pathString, ' contains ', snippet
								to: logBlock ] ].
				failures
					ifFalse: [ self log: 'NO_COMPAT_SOURCE_SCAN_OK file ', relativePath to: logBlock ] ] ].

	self
		log: (failures
			ifTrue: [ 'NO_COMPAT_SOURCE_SCAN_FAILED' ]
			ifFalse: [ 'NO_COMPAT_SOURCE_SCAN_OK' ])
		to: logBlock.
	^ failures not
]

{ #category : 'checks' }
GemStonePharoReloadGuards >> checkCoreOnlyFor: baselineContract workingCopyNamed: workingCopyBlock log: logBlock [
	| failures |
	failures := false.
	baselineContract coreOnlyPackageChecks do: [ :spec |
		| packageName shouldExist workingCopy |
		packageName := spec first.
		shouldExist := spec second.
		workingCopy := workingCopyBlock value: packageName.
		((workingCopy notNil) = shouldExist)
			ifTrue: [ self log: 'CORE_ONLY_CHECK_OK package ', packageName to: logBlock ]
			ifFalse: [
				failures := true.
				self
					log: 'CORE_ONLY_CHECK_FAIL package ', packageName,
						(shouldExist ifTrue: [ ' should be loaded' ] ifFalse: [ ' should not be loaded' ])
					to: logBlock ] ].

	baselineContract coreOnlyClassChecks do: [ :spec |
		| classSymbol shouldExist cls |
		classSymbol := spec first.
		shouldExist := spec second.
		cls := Smalltalk at: classSymbol ifAbsent: [ nil ].
		((cls notNil) = shouldExist)
			ifTrue: [ self log: 'CORE_ONLY_CHECK_OK class ', classSymbol asString to: logBlock ]
			ifFalse: [
				failures := true.
				self
					log: 'CORE_ONLY_CHECK_FAIL class ', classSymbol asString,
						(shouldExist ifTrue: [ ' should exist' ] ifFalse: [ ' should be absent' ])
					to: logBlock ] ].

	baselineContract coreOnlySelectorChecks do: [ :spec |
		| classSymbol selector shouldExist cls |
		classSymbol := spec first.
		selector := spec second.
		shouldExist := spec third.
		cls := Smalltalk at: classSymbol ifAbsent: [ nil ].
		cls
			ifNil: [
				failures := true.
				self
					log: 'CORE_ONLY_CHECK_FAIL selector ', classSymbol asString, '>>#', selector asString, ' class missing'
					to: logBlock ]
			ifNotNil: [
				((cls includesSelector: selector) = shouldExist)
					ifTrue: [ self log: 'CORE_ONLY_CHECK_OK selector ', classSymbol asString, '>>#', selector asString to: logBlock ]
					ifFalse: [
						failures := true.
						self
							log: 'CORE_ONLY_CHECK_FAIL selector ', classSymbol asString, '>>#', selector asString,
								(shouldExist ifTrue: [ ' should exist' ] ifFalse: [ ' should be absent' ])
							to: logBlock ] ] ].

	self
		log: (failures
			ifTrue: [ 'CORE_ONLY_CLEAN_RELOAD_FAILED' ]
			ifFalse: [ 'CORE_ONLY_CLEAN_RELOAD_DONE' ])
		to: logBlock.
	^ failures not
]

{ #category : 'checks' }
GemStonePharoReloadGuards >> checkPackageOwnershipFor: baselineContract loadedPackages: loadedPackages log: logBlock [
	| failures |
	failures := false.

	baselineContract packageOwnershipClassSpecs do: [ :spec |
		| classSymbol expectedPackage expectedLoaded cls actualPackage |
		classSymbol := spec first.
		expectedPackage := spec second.
		expectedLoaded := loadedPackages includes: expectedPackage.
		cls := Smalltalk at: classSymbol ifAbsent: [ nil ].
		expectedLoaded
			ifTrue: [
				cls
					ifNil: [
						failures := true.
						self
							log: 'PACKAGE_OWNERSHIP_DRIFT_FAIL missing class ', classSymbol asString,
								' for loaded package ', expectedPackage
							to: logBlock ]
					ifNotNil: [
						actualPackage := [ cls package name ] on: Error do: [ nil ].
						actualPackage = expectedPackage
							ifTrue: [ self log: 'PACKAGE_OWNERSHIP_DRIFT_OK class ', classSymbol asString, ' in ', expectedPackage to: logBlock ]
							ifFalse: [
								failures := true.
								self
									log: 'PACKAGE_OWNERSHIP_DRIFT_FAIL class ', classSymbol asString, ' expected package ',
										expectedPackage, ' but was ',
										(actualPackage ifNil: [ '<unknown>' ] ifNotNil: [ actualPackage ])
									to: logBlock ] ] ]
			ifFalse: [
				cls
					ifNil: [ self log: 'PACKAGE_OWNERSHIP_DRIFT_OK class ', classSymbol asString, ' absent with unloaded package ', expectedPackage to: logBlock ]
					ifNotNil: [
						failures := true.
						self
							log: 'PACKAGE_OWNERSHIP_DRIFT_FAIL class ', classSymbol asString, ' leaked from unloaded package ', expectedPackage
							to: logBlock ] ] ].

	baselineContract packageOwnershipSelectorSpecs do: [ :spec |
		| classSymbol side selector expectedPackage expectedLoaded cls behavior compiledMethod methodPackage |
		classSymbol := spec first.
		side := spec second.
		selector := spec third.
		expectedPackage := spec fourth.
		expectedLoaded := loadedPackages includes: expectedPackage.
		cls := Smalltalk at: classSymbol ifAbsent: [ nil ].
		behavior := cls
			ifNil: [ nil ]
			ifNotNil: [ side = #class ifTrue: [ cls class ] ifFalse: [ cls ] ].
		compiledMethod := behavior
			ifNil: [ nil ]
			ifNotNil: [ [ behavior >> selector ] on: Error do: [ nil ] ].
		expectedLoaded
			ifTrue: [
				compiledMethod
					ifNil: [
						failures := true.
						self
							log: 'PACKAGE_OWNERSHIP_DRIFT_FAIL missing selector ', behavior name, '>>#', selector asString,
								' for loaded package ', expectedPackage
							to: logBlock ]
					ifNotNil: [
						methodPackage := [ compiledMethod package name ] on: Error do: [ nil ].
						methodPackage = expectedPackage
							ifTrue: [ self log: 'PACKAGE_OWNERSHIP_DRIFT_OK selector ', behavior name, '>>#', selector asString, ' in ', expectedPackage to: logBlock ]
							ifFalse: [
								failures := true.
								self
									log: 'PACKAGE_OWNERSHIP_DRIFT_FAIL selector ', behavior name, '>>#', selector asString,
										' expected package ', expectedPackage, ' but was ',
										(methodPackage ifNil: [ '<unknown>' ] ifNotNil: [ methodPackage ])
									to: logBlock ] ] ]
			ifFalse: [
				compiledMethod
					ifNil: [ self log: 'PACKAGE_OWNERSHIP_DRIFT_OK selector ',
						((behavior ifNil: [ classSymbol asString ] ifNotNil: [ behavior name ])),
						'>>#', selector asString, ' absent with unloaded package ', expectedPackage to: logBlock ]
					ifNotNil: [
						failures := true.
						self
							log: 'PACKAGE_OWNERSHIP_DRIFT_FAIL selector ', behavior name, '>>#', selector asString,
								' leaked from unloaded package ', expectedPackage
							to: logBlock ] ] ].

	baselineContract packageOwnershipBehaviorSpecs do: [ :spec |
		| classSymbol side allowedPackages loadedAllowedPackages cls behavior invalidMethods |
		classSymbol := spec first.
		side := spec second.
		allowedPackages := spec third asSet.
		loadedAllowedPackages := allowedPackages intersection: loadedPackages.
		loadedAllowedPackages isEmpty ifFalse: [
			cls := Smalltalk at: classSymbol ifAbsent: [ nil ].
			cls
				ifNil: [
					failures := true.
					self
						log: 'PACKAGE_OWNERSHIP_DRIFT_FAIL missing behavior owner ', classSymbol asString,
							' for allowed packages ', loadedAllowedPackages asArray printString
						to: logBlock ]
				ifNotNil: [
					behavior := side = #class
						ifTrue: [ cls class ]
						ifFalse: [ cls ].
					invalidMethods := OrderedCollection new.
					behavior methodDict values do: [ :compiledMethod |
						| methodPackage |
						methodPackage := [ compiledMethod package name ] on: Error do: [ nil ].
						(allowedPackages includes: methodPackage)
							ifFalse: [ invalidMethods add: { compiledMethod selector. methodPackage } ] ].
					invalidMethods isEmpty
						ifTrue: [
							self
								log: 'PACKAGE_OWNERSHIP_DRIFT_OK behavior ', behavior name, ' packages ', allowedPackages asArray printString
								to: logBlock ]
						ifFalse: [
							failures := true.
							invalidMethods do: [ :entry |
								self
									log: 'PACKAGE_OWNERSHIP_DRIFT_FAIL behavior ', behavior name, '>>#', entry first asString,
										' package ',
										(entry second ifNil: [ '<unknown>' ] ifNotNil: [ entry second ]),
										' not in ', allowedPackages asArray printString
									to: logBlock ] ] ] ] ].

	baselineContract packageOwnershipCorePackages do: [ :packageName |
		(Smalltalk allClasses select: [ :each | each package name = packageName ]) do: [ :eachClass |
			baselineContract packageOwnershipForbiddenCoreClassPatterns do: [ :pattern |
				(eachClass name includesSubstring: pattern)
					ifTrue: [
						failures := true.
						self
							log: 'PACKAGE_OWNERSHIP_DRIFT_FAIL forbidden class pattern ', pattern, ' in ',
								eachClass name, ' package ', packageName
							to: logBlock ] ] ].
		Smalltalk allClasses do: [ :eachClass |
			{ eachClass. eachClass class } do: [ :behavior |
				behavior methodDict values do: [ :compiledMethod |
					| methodPackage selectorLower |
					methodPackage := [ compiledMethod package name ] on: Error do: [ nil ].
					methodPackage = packageName ifTrue: [
						selectorLower := compiledMethod selector asString asLowercase.
						baselineContract packageOwnershipForbiddenCoreSelectorPatterns do: [ :pattern |
							(selectorLower includesSubstring: pattern)
								ifTrue: [
									failures := true.
									self
										log: 'PACKAGE_OWNERSHIP_DRIFT_FAIL forbidden selector pattern ', pattern, ' in ',
											behavior name, '>>#', compiledMethod selector asString, ' package ', packageName
										to: logBlock ] ] ] ] ] ] ].

	self
		log: (failures
			ifTrue: [ 'PACKAGE_OWNERSHIP_DRIFT_FAILED' ]
			ifFalse: [ 'PACKAGE_OWNERSHIP_DRIFT_OK' ])
		to: logBlock.
	^ failures not
]

{ #category : 'artifact support' }
GemStonePharoReloadGuards >> log: aString to: logBlock [
	logBlock value: aString
]

{ #category : 'artifact support' }
GemStonePharoReloadGuards >> mergeGeneratedSection: contents between: beginMarker and: endMarker in: existingContents [
	| normalizedContents normalizedExisting startIndex endIndex replacement prefix suffix |
	normalizedContents := self normalizeContents: contents.
	normalizedExisting := self normalizeContents: existingContents.
	startIndex := normalizedExisting findString: beginMarker startingAt: 1.
	startIndex = 0 ifTrue: [ ^ nil ].
	endIndex := normalizedExisting findString: endMarker startingAt: startIndex + beginMarker size.
	endIndex = 0 ifTrue: [ ^ nil ].
	prefix := normalizedExisting copyFrom: 1 to: startIndex - 1.
	suffix := normalizedExisting copyFrom: endIndex + endMarker size to: normalizedExisting size.
	replacement := String streamContents: [ :stream |
		stream nextPutAll: beginMarker; nextPut: Character lf.
		normalizedContents isEmpty ifFalse: [
			stream nextPutAll: normalizedContents.
			(normalizedContents last = Character lf) ifFalse: [ stream nextPut: Character lf ] ].
		stream nextPutAll: endMarker ].
	^ prefix , replacement , suffix
]

{ #category : 'artifact support' }
GemStonePharoReloadGuards >> normalizeContents: contents [
	^ (contents ifNil: [ '' ])
		copyReplaceAll: (String with: Character cr)
		with: (String with: Character lf)
]

{ #category : 'artifact support' }
GemStonePharoReloadGuards >> generateDocumentationSectionsFor: baselineContract repoRoot: repoRoot log: logBlock [
	| failures |
	failures := false.
	baselineContract generatedDocumentationSectionSpecs do: [ :spec |
		| relativePath beginMarker endMarker generatedContents file existing merged |
		relativePath := spec first.
		beginMarker := spec second.
		endMarker := spec third.
		generatedContents := spec fourth.
		file := repoRoot / relativePath.
		file exists
			ifFalse: [
				failures := true.
				self log: 'GENERATED_DOC_SECTION_FAIL missing file ', relativePath to: logBlock ]
			ifTrue: [
				existing := self normalizeContents: file contents.
				merged := self
					mergeGeneratedSection: generatedContents
					between: beginMarker
					and: endMarker
					in: existing.
				merged
					ifNil: [
						failures := true.
						self log: 'GENERATED_DOC_SECTION_FAIL missing markers ', relativePath to: logBlock ]
					ifNotNil: [
						file writeStreamDo: [ :stream | stream nextPutAll: merged ].
						self log: 'GENERATED_DOC_SECTION_OK ', relativePath to: logBlock ] ] ].
	^ failures not
]

{ #category : 'artifact support' }
GemStonePharoReloadGuards >> verifyContractArtifactFreshnessFor: baselineContract repoRoot: repoRoot log: logBlock [
	| failures |
	failures := false.
	baselineContract generatedContractArtifactSpecs do: [ :spec |
		| relativePath expected file actual |
		relativePath := spec first.
		expected := self normalizeContents: spec second.
		file := repoRoot / relativePath.
		actual := file exists
			ifTrue: [ self normalizeContents: file contents ]
			ifFalse: [ nil ].
		(actual = expected)
			ifTrue: [ self log: 'CONTRACT_ARTIFACT_FRESH_OK ', relativePath to: logBlock ]
			ifFalse: [
				failures := true.
				self
					log: 'CONTRACT_ARTIFACT_FRESH_FAIL ', relativePath,
						(actual isNil ifTrue: [ ' missing' ] ifFalse: [ ' stale' ])
					to: logBlock ] ].
	baselineContract generatedDocumentationSectionSpecs do: [ :spec |
		| relativePath beginMarker endMarker generatedContents file actual expected |
		relativePath := spec first.
		beginMarker := spec second.
		endMarker := spec third.
		generatedContents := spec fourth.
		file := repoRoot / relativePath.
		actual := file exists
			ifTrue: [ self normalizeContents: file contents ]
			ifFalse: [ nil ].
		expected := actual ifNil: [ nil ] ifNotNil: [
			self
				mergeGeneratedSection: generatedContents
				between: beginMarker
				and: endMarker
				in: actual ].
		(actual notNil and: [ expected notNil and: [ actual = expected ] ])
			ifTrue: [ self log: 'CONTRACT_ARTIFACT_FRESH_OK ', relativePath, ' section ', beginMarker to: logBlock ]
			ifFalse: [
				failures := true.
				self
					log: 'CONTRACT_ARTIFACT_FRESH_FAIL ', relativePath,
						(actual isNil
							ifTrue: [ ' missing' ]
							ifFalse: [ expected isNil
								ifTrue: [ ' missing markers' ]
								ifFalse: [ ' stale generated section' ] ])
					to: logBlock ] ].
	self
		log: (failures
			ifTrue: [ 'CONTRACT_ARTIFACTS_FRESH_FAILED' ]
			ifFalse: [ 'CONTRACT_ARTIFACTS_FRESH_OK' ])
		to: logBlock.
	^ failures not
]
