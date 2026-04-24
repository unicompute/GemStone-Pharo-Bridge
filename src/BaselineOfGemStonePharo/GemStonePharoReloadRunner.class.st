Class {
	#name : 'GemStonePharoReloadRunner',
	#superclass : 'Object',
	#instVars : [
		'environment',
		'baselineContract',
		'reloadGuards',
		'logBlock',
		'loadedPackages',
		'repoRoot',
		'workingCopyClass',
		'workingCopyNamedBlock',
		'verificationRunBlock'
	],
	#category : 'BaselineOfGemStonePharo',
	#package : 'BaselineOfGemStonePharo'
}

{ #category : 'instance creation' }
GemStonePharoReloadRunner class >> baselineName [
	^ 'GemStonePharo'
]

{ #category : 'instance creation' }
GemStonePharoReloadRunner class >> baselineRepositoryUrl [
	^ 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src'
]

{ #category : 'instance creation' }
GemStonePharoReloadRunner class >> booleanFlagNamed: variableName fromEnvironment: anEnvironment [
	^ ((([ anEnvironment at: variableName ifAbsent: [ '0' ] ]
		on: Error
		do: [ '0' ]) asString) = '1')
]

{ #category : 'instance creation' }
GemStonePharoReloadRunner class >> generateContractArtifactsFromEnvironment: anEnvironment [
	^ self booleanFlagNamed: 'GBS_GENERATE_CONTRACT_ARTIFACTS' fromEnvironment: anEnvironment
]

{ #category : 'instance creation' }
GemStonePharoReloadRunner class >> loadGroupNameFromEnvironment: anEnvironment [
	^ (([ anEnvironment at: 'GBS_LOAD_GROUP' ifAbsent: [ 'default' ] ]
		on: Error
		do: [ 'default' ]) asString)
]

{ #category : 'instance creation' }
GemStonePharoReloadRunner class >> onEnvironment: anEnvironment log: aBlock [
	^ self new
		environment: anEnvironment;
		logBlock: aBlock;
		yourself
]

{ #category : 'instance creation' }
GemStonePharoReloadRunner class >> reloadCheckModeFromEnvironment: anEnvironment [
	^ (([ anEnvironment at: 'GBS_RELOAD_CHECK_MODE' ifAbsent: [ 'default' ] ]
		on: Error
		do: [ 'default' ]) asString) asLowercase
]

{ #category : 'instance creation' }
GemStonePharoReloadRunner class >> repoRootPath [
	^ '/Users/tariq/src/gemtools/GemStone-Pharo-Bridge'
]

{ #category : 'instance creation' }
GemStonePharoReloadRunner class >> runLoadedImageOnEnvironment: anEnvironment log: aBlock [
	^ (self onEnvironment: anEnvironment log: aBlock)
		runLoadedImage
]

{ #category : 'instance creation' }
GemStonePharoReloadRunner class >> verifyContractArtifactsFromEnvironment: anEnvironment [
	^ self booleanFlagNamed: 'GBS_VERIFY_CONTRACT_ARTIFACTS' fromEnvironment: anEnvironment
]

{ #category : 'instance creation' }
GemStonePharoReloadRunner class >> verificationLaneNameFromEnvironment: anEnvironment [
	^ (([ anEnvironment at: 'GBS_VERIFY_LANE' ifAbsent: [ '' ] ]
		on: Error
		do: [ '' ]) asString) asLowercase
]

{ #category : 'accessing' }
GemStonePharoReloadRunner >> baselineContract [
	^ baselineContract
]

{ #category : 'accessing' }
GemStonePharoReloadRunner >> baselineContract: anObject [
	baselineContract := anObject
]

{ #category : 'private' }
GemStonePharoReloadRunner >> collectLoadedPackages [
	| packages |
	packages := Set new.
	self workingCopyClass ifNotNil: [
		[ self workingCopyClass allWorkingCopies
			do: [ :each | packages add: each packageName ] ]
			on: Error
			do: [ :ex |
				self log: 'PACKAGE_OWNERSHIP_DRIFT_FAIL unable to enumerate working copies :: ', ex messageText.
				self log: 'PACKAGE_OWNERSHIP_DRIFT_FAILED' ] ].
	^ packages
]

{ #category : 'private' }
GemStonePharoReloadRunner >> emitMissingContractFailure [
	self log: 'ARCHITECTURE_BOUNDARY_FAIL missing BaselineOfGemStonePharo contract or reload guards'.
	self log: 'ARCHITECTURE_BOUNDARY_FAILED'.
	self log: 'PACKAGE_OWNERSHIP_DRIFT_FAILED'.
	self log: 'NO_COMPAT_SOURCE_SCAN_FAILED'.
	self log: 'NO_COMPATIBILITY_PROOF_FAILED'.
	self reloadCheckMode = 'core-only'
		ifTrue: [ self log: 'CORE_ONLY_CLEAN_RELOAD_FAILED' ]
		ifFalse: [ self log: 'CLEAN_RELOAD_DONE' ].
	self shouldGenerateContractArtifacts ifTrue: [
		self log: 'GENERATED_CONTRACT_ARTIFACTS_FAILED missing BaselineOfGemStonePharo contract or reload guards' ].
	self shouldVerifyContractArtifacts ifTrue: [
		self log: 'CONTRACT_ARTIFACTS_FRESH_FAILED missing BaselineOfGemStonePharo contract or reload guards' ].
	^ false
]

{ #category : 'private' }
GemStonePharoReloadRunner >> environment [
	^ environment ifNil: [ Smalltalk os environment ]
]

{ #category : 'private' }
GemStonePharoReloadRunner >> environment: anEnvironment [
	environment := anEnvironment
]

{ #category : 'initialization' }
GemStonePharoReloadRunner >> initialize [
	super initialize.
	logBlock := [ :line | Transcript show: line; cr ]
]

{ #category : 'private' }
GemStonePharoReloadRunner >> loadGroup [
	^ self class loadGroupNameFromEnvironment: self environment
]

{ #category : 'private' }
GemStonePharoReloadRunner >> log: aString [
	logBlock value: aString
]

{ #category : 'private' }
GemStonePharoReloadRunner >> logBlock: aBlock [
	logBlock := aBlock
]

{ #category : 'accessing' }
GemStonePharoReloadRunner >> loadedPackages [
	^ loadedPackages ifNil: [ loadedPackages := self collectLoadedPackages ]
]

{ #category : 'accessing' }
GemStonePharoReloadRunner >> loadedPackages: aCollection [
	loadedPackages := aCollection asSet
]

{ #category : 'private' }
GemStonePharoReloadRunner >> refreshBaselineContext [
	| baseline |
	baseline := (Smalltalk at: #BaselineOfGemStonePharo ifAbsent: [ nil ])
		ifNil: [ nil ]
		ifNotNil: [ :cls | cls new ].
	baselineContract := baseline
		ifNil: [ nil ]
		ifNotNil: [ :each | each contract ].
	reloadGuards := baseline
		ifNil: [ nil ]
		ifNotNil: [ :each | each reloadGuards ]
]

{ #category : 'private' }
GemStonePharoReloadRunner >> reloadCheckMode [
	^ self class reloadCheckModeFromEnvironment: self environment
]

{ #category : 'private' }
GemStonePharoReloadRunner >> runVerificationIfRequested [
	| laneName |
	laneName := self verificationLane.
	laneName isEmpty ifTrue: [ ^ true ].
	^ verificationRunBlock
		ifNil: [ GemStonePharoVerificationRunner runOnEnvironment: self environment log: logBlock ]
		ifNotNil: [ verificationRunBlock value ]
]

{ #category : 'accessing' }
GemStonePharoReloadRunner >> reloadGuards [
	^ reloadGuards
]

{ #category : 'accessing' }
GemStonePharoReloadRunner >> reloadGuards: anObject [
	reloadGuards := anObject
]

{ #category : 'accessing' }
GemStonePharoReloadRunner >> repoRoot [
	^ repoRoot ifNil: [ repoRoot := self class repoRootPath asFileReference ]
]

{ #category : 'accessing' }
GemStonePharoReloadRunner >> repoRoot: aFileReference [
	repoRoot := aFileReference
]

{ #category : 'running' }
GemStonePharoReloadRunner >> runLoadedImage [
	| checksSucceeded |
	(self baselineContract isNil or: [ self reloadGuards isNil ])
		ifTrue: [ self refreshBaselineContext ].
	self loadedPackages.
	(self baselineContract isNil or: [ self reloadGuards isNil ])
		ifTrue: [ ^ self emitMissingContractFailure ].

	checksSucceeded := true.
	checksSucceeded := (self reloadGuards
		checkArchitectureFor: self baselineContract
		loadGroup: self loadGroup
		loadedPackages: self loadedPackages
		log: logBlock) & checksSucceeded.
	self shouldCheckPackageOwnership
		ifTrue: [
			checksSucceeded := (self reloadGuards
				checkPackageOwnershipFor: self baselineContract
				loadedPackages: self loadedPackages
				log: logBlock) & checksSucceeded ]
		ifFalse: [
			self log: 'PACKAGE_OWNERSHIP_DRIFT_SKIPPED load group ', self loadGroup ].
	checksSucceeded := (self reloadGuards
		checkNoCompatibilitySourceFor: self baselineContract
		repoRoot: self repoRoot
		log: logBlock) & checksSucceeded.

	self reloadCheckMode = 'core-only'
		ifTrue: [
			checksSucceeded := (self reloadGuards
				checkNoCompatibilityFor: self baselineContract
				loadedPackages: self loadedPackages
				log: logBlock) & checksSucceeded.
			checksSucceeded := (self reloadGuards
				checkCoreOnlyFor: self baselineContract
				workingCopyNamed: self workingCopyNamedBlock
				log: logBlock) & checksSucceeded ]
		ifFalse: [
			checksSucceeded := (self reloadGuards
				checkNoCompatibilityFor: self baselineContract
				loadedPackages: self loadedPackages
				log: logBlock) & checksSucceeded.
			self log: 'CLEAN_RELOAD_DONE' ].

	self shouldGenerateContractArtifacts ifTrue: [
		checksSucceeded := (self reloadGuards
			generateContractArtifactsFor: self baselineContract
			repoRoot: self repoRoot
			log: logBlock) & checksSucceeded ].
	self shouldVerifyContractArtifacts ifTrue: [
		checksSucceeded := (self reloadGuards
			verifyContractArtifactFreshnessFor: self baselineContract
			repoRoot: self repoRoot
			log: logBlock) & checksSucceeded ].
	checksSucceeded ifTrue: [
		checksSucceeded := self runVerificationIfRequested ].
	^ checksSucceeded
]

{ #category : 'private' }
GemStonePharoReloadRunner >> shouldGenerateContractArtifacts [
	^ self class generateContractArtifactsFromEnvironment: self environment
]

{ #category : 'private' }
GemStonePharoReloadRunner >> shouldCheckPackageOwnership [
	^ (#('Original' 'Original-Tests') includes: self loadGroup) not
]

{ #category : 'private' }
GemStonePharoReloadRunner >> shouldVerifyContractArtifacts [
	^ self class verifyContractArtifactsFromEnvironment: self environment
]

{ #category : 'private' }
GemStonePharoReloadRunner >> verificationLane [
	^ self class verificationLaneNameFromEnvironment: self environment
]

{ #category : 'private' }
GemStonePharoReloadRunner >> verificationRunBlock: aBlock [
	verificationRunBlock := aBlock
]

{ #category : 'private' }
GemStonePharoReloadRunner >> workingCopyClass [
	^ workingCopyClass ifNil: [ Smalltalk at: #MCWorkingCopy ifAbsent: [ nil ] ]
]

{ #category : 'private' }
GemStonePharoReloadRunner >> workingCopyClass: aClass [
	workingCopyClass := aClass
]

{ #category : 'private' }
GemStonePharoReloadRunner >> workingCopyNamedBlock [
	^ workingCopyNamedBlock ifNil: [
		workingCopyNamedBlock := [ :packageName |
			self workingCopyClass
				ifNil: [ nil ]
				ifNotNil: [
					[ self workingCopyClass allWorkingCopies
						detect: [ :each | each packageName = packageName ]
						ifNone: [ nil ] ]
						on: Error
						do: [ nil ] ] ] ]
]

{ #category : 'private' }
GemStonePharoReloadRunner >> workingCopyNamedBlock: aBlock [
	workingCopyNamedBlock := aBlock
]
