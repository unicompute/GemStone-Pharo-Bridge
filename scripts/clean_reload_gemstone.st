| packageNames organizer classNamesToForceRemove tonelRepository loadGroup checkMode generateContractArtifacts verifyContractArtifacts coreOnlyFailures compatibilityDriftFailures architectureBoundaryFailures packageOwnershipFailures contractArtifactFreshnessFailures baselineContract checks workingCopyClass workingCopyNamed loadedPackages |
	loadGroup := ([ Smalltalk os environment at: 'GBS_LOAD_GROUP' ifAbsent: [ 'default' ] ]
		on: Error
		do: [ 'default' ]) asString.
	checkMode := (([ Smalltalk os environment at: 'GBS_RELOAD_CHECK_MODE' ifAbsent: [ 'default' ] ]
		on: Error
		do: [ 'default' ]) asString) asLowercase.
	generateContractArtifacts := (([ Smalltalk os environment at: 'GBS_GENERATE_CONTRACT_ARTIFACTS' ifAbsent: [ '0' ] ]
		on: Error
		do: [ '0' ]) asString) = '1'.
	verifyContractArtifacts := (([ Smalltalk os environment at: 'GBS_VERIFY_CONTRACT_ARTIFACTS' ifAbsent: [ '0' ] ]
		on: Error
		do: [ '0' ]) asString) = '1'.

	coreOnlyFailures := false.
	compatibilityDriftFailures := false.
	architectureBoundaryFailures := false.
	packageOwnershipFailures := false.
	contractArtifactFreshnessFailures := false.

	organizer := Smalltalk at: #RPackageOrganizer ifAbsent: [ nil ].
	workingCopyClass := Smalltalk at: #MCWorkingCopy ifAbsent: [ nil ].
	classNamesToForceRemove := OrderedCollection new.
	classNamesToForceRemove add: 'BaselineOfGemStonePharo'.
	packageNames := #(
		'BaselineOfGemStonePharo'
		'GemStone-Pharo-Core-Tests'
		'GemStone-Pharo-Compatibility-Tests'
		'GemStone-Pharo-Tests'
		'GemStone-GBS-MagLev-Tools'
		'GemStone-GBS-Tools'
		'GemStone-GBS-MagLev'
		'GemStone-GBS-Converted').

	workingCopyNamed := [ :packageName |
		workingCopyClass
			ifNil: [ nil ]
			ifNotNil: [
				[ workingCopyClass allWorkingCopies
					detect: [ :each | each packageName = packageName ]
					ifNone: [ nil ] ]
					on: Error
					do: [ nil ] ] ].

	(Smalltalk at: #GbxOverrideUtility ifAbsent: [ nil ]) ifNotNil: [ :overrideUtility |
		[ overrideUtility removeOverridesForRelease ]
			on: Error
			do: [ :ex |
				Transcript
					show: 'UNLOAD_WARN overrides :: ';
					show: ex messageText;
					cr ] ].

	organizer ifNotNil: [
		packageNames do: [ :pkgName |
			| pkg |
			pkg := [ organizer default packageNamed: pkgName ] on: Error do: [ nil ].
			pkg ifNotNil: [
				[ pkg definedClasses do: [ :eachClass | classNamesToForceRemove add: eachClass name ] ]
					on: Error
					do: [ :ex |
						Transcript
							show: 'UNLOAD_WARN ';
							show: pkgName;
							show: ' classes :: ';
							show: ex messageText;
							cr ].
				[ pkg removeFromSystem ]
					on: Error
					do: [ :ex |
						Transcript
							show: 'UNLOAD_WARN ';
							show: pkgName;
							show: ' :: ';
							show: ex messageText;
							cr ] ] ] ].

	classNamesToForceRemove asSet do: [ :className |
		| cls |
		cls := Smalltalk at: className asSymbol ifAbsent: [ nil ].
		cls ifNotNil: [
			[ cls removeFromSystem ]
				on: Error
				do: [ :ex |
					Transcript
						show: 'UNLOAD_WARN class ';
						show: className;
						show: ' :: ';
						show: ex messageText;
						cr ] ] ].

	workingCopyClass ifNotNil: [
		workingCopyClass allWorkingCopies do: [ :workingCopy |
			(packageNames includes: workingCopy packageName)
				ifTrue: [
					[ workingCopy unregister ]
						on: Error
						do: [ :ex |
							Transcript
								show: 'UNLOAD_WARN working copy ';
								show: workingCopy packageName;
								show: ' :: ';
								show: ex messageText;
								cr ] ] ] ].

	tonelRepository := [ MCRepository fromUrl: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src' ]
		on: Error
		do: [ :ex |
			Transcript
				show: 'CACHE_WARMUP_WARN repository :: ';
				show: ex messageText;
				cr.
			nil ].

	tonelRepository ifNotNil: [
		packageNames do: [ :pkgName |
			[ tonelRepository versionFrom: pkgName ]
				on: Error
				do: [ :ex |
					Transcript
						show: 'CACHE_WARMUP_WARN ';
						show: pkgName;
						show: ' :: ';
						show: ex messageText;
						cr ] ] ].

	[ Metacello new
		baseline: 'GemStonePharo';
		repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
		load: loadGroup ]
		on: Error
		do: [ :ex | Transcript show: 'LOAD_ERROR: ', ex messageText; cr ].

	baselineContract := (Smalltalk at: #BaselineOfGemStonePharo ifAbsent: [ nil ])
		ifNil: [ nil ]
		ifNotNil: [ :cls | cls new ].

	loadedPackages := Set new.
	workingCopyClass ifNotNil: [
		[ workingCopyClass allWorkingCopies do: [ :each | loadedPackages add: each packageName ] ]
			on: Error
			do: [ :ex |
				packageOwnershipFailures := true.
				Transcript
					show: 'PACKAGE_OWNERSHIP_DRIFT_FAIL unable to enumerate working copies :: ';
					show: ex messageText;
					cr ] ].

	baselineContract
		ifNil: [
			architectureBoundaryFailures := true.
			Transcript show: 'ARCHITECTURE_BOUNDARY_FAIL missing BaselineOfGemStonePharo'; cr ]
		ifNotNil: [
			| packageSpecs groupSpecs packageNamesBySpec groupNamesBySpec activeGroupSpec activeGroupMembers missingLoaded unexpectedLoaded |
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
					ifTrue: [
						Transcript show: 'ARCHITECTURE_BOUNDARY_OK package '; show: packageName; cr ]
					ifFalse: [
						architectureBoundaryFailures := true.
						Transcript
							show: 'ARCHITECTURE_BOUNDARY_FAIL package ';
							show: packageName;
							show: ' has unknown requires ';
							show: unknownRequirements asArray printString;
							cr ] ].

			groupSpecs do: [ :spec |
				| groupName members unknownMembers |
				groupName := spec first.
				members := spec second asSet.
				unknownMembers := members difference: packageNamesBySpec.
				(members isEmpty or: [ unknownMembers notEmpty ])
					ifTrue: [
						architectureBoundaryFailures := true.
						Transcript
							show: 'ARCHITECTURE_BOUNDARY_FAIL group ';
							show: groupName;
							show: (members isEmpty
								ifTrue: [ ' has no members' ]
								ifFalse: [ ' has unknown members ', unknownMembers asArray printString ]);
							cr ]
					ifFalse: [
						Transcript show: 'ARCHITECTURE_BOUNDARY_OK group '; show: groupName; cr ] ].

			baselineContract forbiddenPackageRequirementSpecs do: [ :spec |
				| packageName forbidden actualRequirements offenders |
				packageName := spec first.
				forbidden := spec second asSet.
				actualRequirements := ((packageSpecs
					detect: [ :each | each first = packageName ]
					ifNone: [ { packageName. #() } ]) second) asSet.
				offenders := actualRequirements intersection: forbidden.
				offenders isEmpty
					ifTrue: [
						Transcript show: 'ARCHITECTURE_BOUNDARY_OK no forbidden requires in '; show: packageName; cr ]
					ifFalse: [
						architectureBoundaryFailures := true.
						Transcript
							show: 'ARCHITECTURE_BOUNDARY_FAIL ';
							show: packageName;
							show: ' has forbidden requires ';
							show: offenders asArray printString;
							cr ] ].

			activeGroupSpec := groupSpecs
				detect: [ :each | each first = loadGroup ]
				ifNone: [ nil ].
			activeGroupSpec
				ifNil: [
					(groupNamesBySpec includes: loadGroup)
						ifFalse: [
							architectureBoundaryFailures := true.
							Transcript
								show: 'ARCHITECTURE_BOUNDARY_FAIL unknown load group ';
								show: loadGroup;
								cr ] ]
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
						ifTrue: [
							Transcript show: 'ARCHITECTURE_BOUNDARY_OK load group '; show: loadGroup; cr ]
						ifFalse: [
							architectureBoundaryFailures := true.
							Transcript
								show: 'ARCHITECTURE_BOUNDARY_FAIL load group ';
								show: loadGroup;
								show: ' missing ';
								show: missingLoaded asArray printString;
								show: ' unexpected ';
								show: unexpectedLoaded asArray printString;
								cr ] ] ].

	Transcript
		show: (architectureBoundaryFailures
			ifTrue: [ 'ARCHITECTURE_BOUNDARY_FAILED' ]
			ifFalse: [ 'ARCHITECTURE_BOUNDARY_OK' ]);
			cr.

	baselineContract ifNotNil: [
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
							packageOwnershipFailures := true.
							Transcript
								show: 'PACKAGE_OWNERSHIP_DRIFT_FAIL missing class ';
								show: classSymbol asString;
								show: ' for loaded package ';
								show: expectedPackage;
								cr ]
						ifNotNil: [
							actualPackage := [ cls package name ] on: Error do: [ nil ].
							actualPackage = expectedPackage
								ifTrue: [
									Transcript
										show: 'PACKAGE_OWNERSHIP_DRIFT_OK class ';
										show: classSymbol asString;
										show: ' in ';
										show: expectedPackage;
										cr ]
								ifFalse: [
									packageOwnershipFailures := true.
									Transcript
										show: 'PACKAGE_OWNERSHIP_DRIFT_FAIL class ';
										show: classSymbol asString;
										show: ' expected package ';
										show: expectedPackage;
										show: ' but was ';
										show: (actualPackage ifNil: [ '<unknown>' ] ifNotNil: [ actualPackage ]);
										cr ] ] ]
				ifFalse: [
					cls
						ifNil: [
							Transcript
								show: 'PACKAGE_OWNERSHIP_DRIFT_OK class ';
								show: classSymbol asString;
								show: ' absent with unloaded package ';
								show: expectedPackage;
								cr ]
						ifNotNil: [
							packageOwnershipFailures := true.
							Transcript
								show: 'PACKAGE_OWNERSHIP_DRIFT_FAIL class ';
								show: classSymbol asString;
								show: ' leaked from unloaded package ';
								show: expectedPackage;
								cr ] ] ].

		baselineContract packageOwnershipSelectorSpecs do: [ :spec |
			| classSymbol selector expectedPackage expectedLoaded cls compiledMethod methodPackage |
			classSymbol := spec first.
			selector := spec second.
			expectedPackage := spec third.
			expectedLoaded := loadedPackages includes: expectedPackage.
			cls := Smalltalk at: classSymbol ifAbsent: [ nil ].
			compiledMethod := cls
				ifNil: [ nil ]
				ifNotNil: [ [ cls >> selector ] on: Error do: [ nil ] ].
			expectedLoaded
				ifTrue: [
					compiledMethod
						ifNil: [
							packageOwnershipFailures := true.
							Transcript
								show: 'PACKAGE_OWNERSHIP_DRIFT_FAIL missing selector ';
								show: classSymbol asString;
								show: '>>#';
								show: selector asString;
								show: ' for loaded package ';
								show: expectedPackage;
								cr ]
						ifNotNil: [
							methodPackage := [ compiledMethod package name ] on: Error do: [ nil ].
							methodPackage = expectedPackage
								ifTrue: [
									Transcript
										show: 'PACKAGE_OWNERSHIP_DRIFT_OK selector ';
										show: classSymbol asString;
										show: '>>#';
										show: selector asString;
										show: ' in ';
										show: expectedPackage;
										cr ]
								ifFalse: [
									packageOwnershipFailures := true.
									Transcript
										show: 'PACKAGE_OWNERSHIP_DRIFT_FAIL selector ';
										show: classSymbol asString;
										show: '>>#';
										show: selector asString;
										show: ' expected package ';
										show: expectedPackage;
										show: ' but was ';
										show: (methodPackage ifNil: [ '<unknown>' ] ifNotNil: [ methodPackage ]);
										cr ] ] ]
				ifFalse: [
					compiledMethod
						ifNil: [
							Transcript
								show: 'PACKAGE_OWNERSHIP_DRIFT_OK selector ';
								show: classSymbol asString;
								show: '>>#';
								show: selector asString;
								show: ' absent with unloaded package ';
								show: expectedPackage;
								cr ]
						ifNotNil: [
							packageOwnershipFailures := true.
							Transcript
								show: 'PACKAGE_OWNERSHIP_DRIFT_FAIL selector ';
								show: classSymbol asString;
								show: '>>#';
								show: selector asString;
								show: ' leaked from unloaded package ';
								show: expectedPackage;
								cr ] ] ].

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
						packageOwnershipFailures := true.
						Transcript
							show: 'PACKAGE_OWNERSHIP_DRIFT_FAIL missing behavior owner ';
							show: classSymbol asString;
							show: ' for allowed packages ';
							show: loadedAllowedPackages asArray printString;
							cr ]
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
								Transcript
									show: 'PACKAGE_OWNERSHIP_DRIFT_OK behavior ';
									show: behavior name;
									show: ' packages ';
									show: allowedPackages asArray printString;
									cr ]
							ifFalse: [
								packageOwnershipFailures := true.
								invalidMethods do: [ :entry |
									Transcript
										show: 'PACKAGE_OWNERSHIP_DRIFT_FAIL behavior ';
										show: behavior name;
										show: '>>#';
										show: entry first asString;
										show: ' package ';
										show: (entry second ifNil: [ '<unknown>' ] ifNotNil: [ entry second ]);
										show: ' not in ';
										show: allowedPackages asArray printString;
										cr ] ] ] ] ].

		baselineContract packageOwnershipCorePackages do: [ :packageName |
			(Smalltalk allClasses select: [ :each | each package name = packageName ]) do: [ :eachClass |
				baselineContract packageOwnershipForbiddenCoreClassPatterns do: [ :pattern |
					(eachClass name includesSubstring: pattern)
						ifTrue: [
							packageOwnershipFailures := true.
							Transcript
								show: 'PACKAGE_OWNERSHIP_DRIFT_FAIL forbidden class pattern ';
								show: pattern;
								show: ' in ';
								show: eachClass name;
								show: ' package ';
								show: packageName;
								cr ] ].
			 ].
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
										packageOwnershipFailures := true.
										Transcript
										show: 'PACKAGE_OWNERSHIP_DRIFT_FAIL forbidden selector pattern ';
											show: pattern;
											show: ' in ';
											show: behavior name;
											show: '>>#';
											show: compiledMethod selector asString;
											show: ' package ';
											show: packageName;
											cr ] ] ] ] ] ] ].

		].

	Transcript
		show: (packageOwnershipFailures
			ifTrue: [ 'PACKAGE_OWNERSHIP_DRIFT_FAILED' ]
			ifFalse: [ 'PACKAGE_OWNERSHIP_DRIFT_OK' ]);
		cr.

	checkMode = 'core-only'
		ifTrue: [
			baselineContract ifNotNil: [
				baselineContract coreOnlyPackageChecks do: [ :spec |
					| packageName shouldExist workingCopy |
					packageName := spec first.
					shouldExist := spec second.
					workingCopy := workingCopyNamed value: packageName.
					((workingCopy notNil) = shouldExist)
						ifTrue: [
							Transcript show: 'CORE_ONLY_CHECK_OK package '; show: packageName; cr ]
						ifFalse: [
							coreOnlyFailures := true.
							Transcript
								show: 'CORE_ONLY_CHECK_FAIL package ';
								show: packageName;
								show: (shouldExist ifTrue: [ ' should be loaded' ] ifFalse: [ ' should not be loaded' ]);
								cr ] ].

				baselineContract coreOnlyClassChecks do: [ :spec |
					| classSymbol shouldExist cls |
					classSymbol := spec first.
					shouldExist := spec second.
					cls := Smalltalk at: classSymbol ifAbsent: [ nil ].
					((cls notNil) = shouldExist)
						ifTrue: [
							Transcript show: 'CORE_ONLY_CHECK_OK class '; show: classSymbol asString; cr ]
						ifFalse: [
							coreOnlyFailures := true.
							Transcript
								show: 'CORE_ONLY_CHECK_FAIL class ';
								show: classSymbol asString;
								show: (shouldExist ifTrue: [ ' should exist' ] ifFalse: [ ' should be absent' ]);
								cr ] ].

				baselineContract coreOnlySelectorChecks do: [ :spec |
					| classSymbol selector shouldExist cls |
					classSymbol := spec first.
					selector := spec second.
					shouldExist := spec third.
					cls := Smalltalk at: classSymbol ifAbsent: [ nil ].
					cls
						ifNil: [
							coreOnlyFailures := true.
							Transcript
								show: 'CORE_ONLY_CHECK_FAIL selector ';
								show: classSymbol asString;
								show: '>>#';
								show: selector asString;
								show: ' class missing';
								cr ]
						ifNotNil: [
							((cls includesSelector: selector) = shouldExist)
								ifTrue: [
									Transcript
										show: 'CORE_ONLY_CHECK_OK selector ';
										show: classSymbol asString;
										show: '>>#';
										show: selector asString;
										cr ]
								ifFalse: [
									coreOnlyFailures := true.
									Transcript
										show: 'CORE_ONLY_CHECK_FAIL selector ';
										show: classSymbol asString;
										show: '>>#';
										show: selector asString;
										show: (shouldExist ifTrue: [ ' should exist' ] ifFalse: [ ' should be absent' ]);
										cr ] ] ] ].

			Transcript
				show: (coreOnlyFailures
					ifTrue: [ 'CORE_ONLY_CLEAN_RELOAD_FAILED' ]
					ifFalse: [ 'CORE_ONLY_CLEAN_RELOAD_DONE' ]);
				cr ]
		ifFalse: [
			| compatibilityDriftChecks compatibilitySendChecks |
			checks := {
				{ #GbxDebuggerService. #basicReenterServerContext. 'self selectTopServerContext'. false }.
				{ #GbxDebuggerService. #restartLevelFromServerStack. 'respondsTo: #splitOn:'. false }.
				{ #GbxDebuggerService. #cutbackToGsProcessOf:. 'terminateProcess'. false }.
				{ #GbxDebuggerService. #restartLevelFromServerStack. 'respondsTo: [ #splitOn: ] asSymbol'. true }.
				{ #GbxDebuggerService. #basicReenterServerContext. 'Identify the target context for restart'. true } }.

			checks do: [ :triple |
				| cls sel snippet mustBeAbsent cm src hasSnippet |
				cls := Smalltalk at: triple first ifAbsent: [ nil ].
				sel := triple second.
				snippet := triple third.
				mustBeAbsent := triple fourth.
				(cls isNil or: [ (cls includesSelector: sel) not ])
					ifTrue: [
						Transcript show: 'CHECK_MISSING '; show: triple first asString; show: '>>#'; show: sel asString; cr ]
					ifFalse: [
						cm := cls >> sel.
						src := cm sourceCode ifNil: [ '' ].
						hasSnippet := src includesSubstring: snippet.
						((mustBeAbsent and: [ hasSnippet ]) or: [ mustBeAbsent not and: [ hasSnippet not ] ])
							ifTrue: [
								Transcript
									show: 'CHECK_FAIL ';
									show: triple first asString;
									show: '>>#';
									show: sel asString;
									show: (mustBeAbsent ifTrue: [ ' contains forbidden ' ] ifFalse: [ ' missing expected ' ]);
									show: snippet;
									cr ]
							ifFalse: [
								Transcript
									show: 'CHECK_OK ';
									show: triple first asString;
									show: '>>#';
									show: sel asString;
									cr ] ] ].

			compatibilityDriftChecks := baselineContract deprecatedCompatibilitySnippetSpecs.
			compatibilitySendChecks := baselineContract deprecatedCompatibilitySelectorSendSpecs.

			compatibilityDriftChecks do: [ :spec |
				| targetPackage forbiddenSnippet packageLoaded packageClasses |
				targetPackage := spec first.
				forbiddenSnippet := spec second.
				packageLoaded := loadedPackages includes: targetPackage.
				packageLoaded ifTrue: [
					packageClasses := Smalltalk allClasses select: [ :each | each package name = targetPackage ].
					packageClasses do: [ :eachClass |
						{ eachClass. eachClass class } do: [ :behavior |
							behavior methodDict values do: [ :compiledMethod |
								| source |
								source := compiledMethod sourceCode ifNil: [ '' ].
								(source includesSubstring: forbiddenSnippet)
									ifTrue: [
										compatibilityDriftFailures := true.
										Transcript
											show: 'COMPATIBILITY_DRIFT_FAIL ';
											show: targetPackage;
											show: ' ';
											show: behavior name;
											show: '>>#';
											show: compiledMethod selector asString;
											show: ' contains ';
											show: forbiddenSnippet;
											cr ] ] ] ] ] ].

			compatibilitySendChecks do: [ :spec |
				| targetPackage forbiddenSelector packageLoaded packageClasses |
				targetPackage := spec first.
				forbiddenSelector := spec second.
				packageLoaded := loadedPackages includes: targetPackage.
				packageLoaded ifTrue: [
					packageClasses := Smalltalk allClasses select: [ :each | each package name = targetPackage ].
					packageClasses do: [ :eachClass |
						{ eachClass. eachClass class } do: [ :behavior |
							behavior methodDict values do: [ :compiledMethod |
								([ compiledMethod sendsSelector: forbiddenSelector ] on: Error do: [ false ])
									ifTrue: [
										compatibilityDriftFailures := true.
										Transcript
											show: 'COMPATIBILITY_DRIFT_FAIL ';
											show: targetPackage;
											show: ' ';
											show: behavior name;
											show: '>>#';
											show: compiledMethod selector asString;
											show: ' sends #';
											show: forbiddenSelector asString;
											cr ] ] ] ] ] ].

				Transcript
					show: (compatibilityDriftFailures
						ifTrue: [ 'COMPATIBILITY_DRIFT_FAILED' ]
						ifFalse: [ 'COMPATIBILITY_DRIFT_OK' ]);
					cr.
				Transcript show: 'CLEAN_RELOAD_DONE'; cr ].

	(generateContractArtifacts or: [ verifyContractArtifacts ]) ifTrue: [
		baselineContract ifNil: [
			Transcript
				show: (generateContractArtifacts
					ifTrue: [ 'GENERATED_CONTRACT_ARTIFACTS_FAILED missing BaselineOfGemStonePharo' ]
					ifFalse: [ 'CONTRACT_ARTIFACTS_FRESH_FAILED missing BaselineOfGemStonePharo' ]);
				cr ]
		ifNotNil: [
			| repoRoot normalizeContents writeArtifact artifactSpecs |
			repoRoot := '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge' asFileReference.
			normalizeContents := [ :contents |
				(contents ifNil: [ '' ]) copyReplaceAll: (String with: Character cr) with: (String with: Character lf) ].
			writeArtifact := [ :relativePath :contents |
				| file |
				file := repoRoot / relativePath.
				file parent ensureCreateDirectory.
				file writeStreamDo: [ :stream |
					stream nextPutAll: (normalizeContents value: contents) ] ].
			artifactSpecs := baselineContract generatedContractArtifactSpecs.

			generateContractArtifacts ifTrue: [
				artifactSpecs do: [ :spec |
					writeArtifact value: spec first value: spec second ].
				Transcript show: 'GENERATED_CONTRACT_ARTIFACTS_OK'; cr ].

			verifyContractArtifacts ifTrue: [
				artifactSpecs do: [ :spec |
					| relativePath expected file actual |
					relativePath := spec first.
					expected := normalizeContents value: spec second.
					file := repoRoot / relativePath.
					actual := file exists
						ifTrue: [ normalizeContents value: file contents ]
						ifFalse: [ nil ].
					(actual = expected)
						ifTrue: [
							Transcript
								show: 'CONTRACT_ARTIFACT_FRESH_OK ';
								show: relativePath;
								cr ]
						ifFalse: [
							contractArtifactFreshnessFailures := true.
							Transcript
								show: 'CONTRACT_ARTIFACT_FRESH_FAIL ';
								show: relativePath;
								show: (actual isNil
									ifTrue: [ ' missing' ]
									ifFalse: [ ' stale' ]);
								cr ] ].
				Transcript
					show: (contractArtifactFreshnessFailures
						ifTrue: [ 'CONTRACT_ARTIFACTS_FRESH_FAILED' ]
						ifFalse: [ 'CONTRACT_ARTIFACTS_FRESH_OK' ]);
					cr ] ] ].

Smalltalk snapshot: true andQuit: true.
