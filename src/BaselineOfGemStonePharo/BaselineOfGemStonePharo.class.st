Class {
	#name : 'BaselineOfGemStonePharo',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfGemStonePharo',
	#package : 'BaselineOfGemStonePharo'
}

{ #category : 'baselines' }
BaselineOfGemStonePharo >> baseline: spec [
	| packageSpecs groupSpecs |
	<baseline>
	spec for: #common do: [
		spec
			preLoadDoIt: #preload:package:;
			postLoadDoIt: #postload:package:.

		packageSpecs := self packageRequirementSpecs.
		packageSpecs do: [ :each |
			| packageName requiredPackages |
			packageName := each first.
			requiredPackages := each second.
			requiredPackages isEmpty
				ifTrue: [ spec package: packageName ]
				ifFalse: [
					spec package: packageName
						with: [ spec requires: requiredPackages ] ] ].

		groupSpecs := self groupMemberSpecs.
		groupSpecs do: [ :each |
			spec group: each first with: each second ] ]
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> contract [
	^ GemStonePharoContract new
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> coreOnlyClassChecks [
	^ self contract coreOnlyClassChecks
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> coreOnlyPackageChecks [
	^ self contract coreOnlyPackageChecks
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> coreOnlySelectorChecks [
	^ self contract coreOnlySelectorChecks
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> forbiddenPackageRequirementSpecs [
	^ self contract forbiddenPackageRequirementSpecs
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> generatedContractArtifactSpecs [
	^ self contract generatedContractArtifactSpecs
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> generatedPackageGraphDot [
	^ self contract generatedPackageGraphDot
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> generatedPackageGraphMarkdown [
	^ self contract generatedPackageGraphMarkdown
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> generatedPackageGraphSvg [
	^ self contract generatedPackageGraphSvg
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> generatedLivePreflightPolicyMarkdown [
	^ self contract generatedLivePreflightPolicyMarkdown
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> generatedReloadPolicyMarkdown [
	^ self contract generatedReloadPolicyMarkdown
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> generatedUserManualReferenceHtml [
	^ self contract generatedUserManualReferenceHtml
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> generatedVerificationLanesMarkdown [
	^ self contract generatedVerificationLanesMarkdown
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> groupMemberSpecs [
	^ self contract groupMemberSpecs
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> noCompatibilityClassNames [
	^ self contract noCompatibilityClassNames
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> noCompatibilityMethodPackageNames [
	^ self contract noCompatibilityMethodPackageNames
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> noCompatibilityPackageNames [
	^ self contract noCompatibilityPackageNames
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> noCompatibilitySelectorChecks [
	^ self contract noCompatibilitySelectorChecks
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageOwnershipBehaviorSpecs [
	^ self contract packageOwnershipBehaviorSpecs
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageOwnershipClassSpecs [
	^ self contract packageOwnershipClassSpecs
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageOwnershipCorePackages [
	^ self contract packageOwnershipCorePackages
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageOwnershipForbiddenCoreClassPatterns [
	^ self contract packageOwnershipForbiddenCoreClassPatterns
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageOwnershipForbiddenCoreSelectorPatterns [
	^ self contract packageOwnershipForbiddenCoreSelectorPatterns
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageOwnershipSelectorSpecs [
	^ self contract packageOwnershipSelectorSpecs
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageOwnershipSelectorFamilySpecs [
	^ self contract packageOwnershipSelectorFamilySpecs
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> packageRequirementSpecs [
	^ self contract packageRequirementSpecs
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> reloadGuards [
	^ GemStonePharoReloadGuards new
]

{ #category : 'contracts' }
BaselineOfGemStonePharo >> verificationLaneSpecs [
	^ self contract verificationLaneSpecs
]

{ #category : 'actions' }
BaselineOfGemStonePharo >> postload: loader package: packageSpec [
	self class environment
		at: #GbxRuntimeOverrideSpec
		ifPresent: [ :runtimeSpec | runtimeSpec apply ].
	self class environment
		at: #GbxToolsOverrideSpec
		ifPresent: [ :toolsSpec | toolsSpec apply ].
	self class environment
		at: #CoreGbsLiveSessionTestSupport
		ifPresent: [ :supportClass |
			[ supportClass installDelegatesOnOriginalSupportClass ]
				on: Error
				do: [ ] ].
	self repairUndeclaredGlobals
]

{ #category : 'actions' }
BaselineOfGemStonePharo >> preload: loader package: packageSpec [
	self class environment
		at: #GbxOverrideUtility
		ifPresent: [ :overrideUtility |
			[ overrideUtility removeOverridesForRelease ]
				on: MessageNotUnderstood
				do: [ ] ]
]

{ #category : 'actions' }
BaselineOfGemStonePharo >> repairUndeclaredGlobals [
	(self class environment at: #Undeclared ifAbsent: [ nil ]) ifNotNil: [ :undeclared |
		[ undeclared fixUndeclaredVariables ]
			on: MessageNotUnderstood
			do: [ ].
		[ Smalltalk image cleanOutUndeclared ]
			on: MessageNotUnderstood
			do: [ ] ]
]
