Class {
	#name : 'GemStonePharoReloadBootstrapper',
	#superclass : 'Object',
	#instVars : [
		'environment',
		'logBlock'
	],
	#category : 'BaselineOfGemStonePharo',
	#package : 'BaselineOfGemStonePharo'
}

{ #category : 'instance creation' }
GemStonePharoReloadBootstrapper class >> baselineName [
	^ GemStonePharoReloadRunner baselineName
]

{ #category : 'instance creation' }
GemStonePharoReloadBootstrapper class >> baselineRepositoryUrl [
	^ GemStonePharoReloadRunner baselineRepositoryUrl
]

{ #category : 'instance creation' }
GemStonePharoReloadBootstrapper class >> loadGroupNameFromEnvironment: anEnvironment [
	^ GemStonePharoReloadRunner loadGroupNameFromEnvironment: anEnvironment
]

{ #category : 'instance creation' }
GemStonePharoReloadBootstrapper class >> onEnvironment: anEnvironment log: aBlock [
	^ self new
		environment: anEnvironment;
		logBlock: aBlock;
		yourself
]

{ #category : 'instance creation' }
GemStonePharoReloadBootstrapper class >> runBootstrapReloadOnEnvironment: anEnvironment log: aBlock [
	^ (self onEnvironment: anEnvironment log: aBlock)
		runBootstrapReload
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> baselineContract [
	^ BaselineOfGemStonePharo new contract
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> collectClassNamesToForceRemoveFromPackagesNamed: packageNames [
	| organizer classNames |
	organizer := Smalltalk at: #RPackageOrganizer ifAbsent: [ nil ].
	classNames := OrderedCollection new.
	organizer ifNil: [ ^ classNames ].
	packageNames do: [ :pkgName |
		| pkg |
		pkg := [ organizer default packageNamed: pkgName ] on: Error do: [ nil ].
		pkg ifNotNil: [
			[ pkg definedClasses do: [ :eachClass | classNames add: eachClass name ] ]
				on: Error
				do: [ :ex |
					self
						log: 'UNLOAD_WARN ', pkgName, ' classes :: ', ex messageText ] ] ].
	^ classNames asSet asOrderedCollection
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> environment [
	^ environment ifNil: [ Smalltalk os environment ]
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> environment: anEnvironment [
	environment := anEnvironment
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> forceRemoveClassesNamed: classNames [
	classNames do: [ :className |
		| cls |
		cls := Smalltalk at: className asSymbol ifAbsent: [ nil ].
		cls ifNotNil: [
			[ cls removeFromSystem ]
				on: Error
				do: [ :ex |
					self
						log: 'UNLOAD_WARN class ', className, ' :: ', ex messageText ] ] ]
]

{ #category : 'initialization' }
GemStonePharoReloadBootstrapper >> initialize [
	super initialize.
	logBlock := [ :line | Transcript show: line; cr ]
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> loadGroup [
	^ self class loadGroupNameFromEnvironment: self environment
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> loadRequestedGroup [
	[ Metacello new
		baseline: self class baselineName;
		repository: self class baselineRepositoryUrl;
		load: { self loadGroup } ]
		on: Error
		do: [ :ex | self log: 'LOAD_ERROR: ', ex messageText ]
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> log: aString [
	logBlock value: aString
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> logBlock: aBlock [
	logBlock := aBlock
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> packageNamesToUnload [
	^ (self baselineContract packageRequirementSpecs collect: [ :each | each first ]) reversed
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> removeOverrides [
	(Smalltalk at: #GbxOverrideUtility ifAbsent: [ nil ]) ifNotNil: [ :overrideUtility |
		[ overrideUtility removeOverridesForRelease ]
			on: Error
			do: [ :ex |
				self
					log: 'UNLOAD_WARN overrides :: ', ex messageText ] ]
]

{ #category : 'running' }
GemStonePharoReloadBootstrapper >> runBootstrapReload [
	| packageNames classNames |
	packageNames := self packageNamesToUnload.
	self removeOverrides.
	classNames := self collectClassNamesToForceRemoveFromPackagesNamed: packageNames.
	self unloadPackagesNamed: packageNames.
	self forceRemoveClassesNamed: classNames.
	self unregisterWorkingCopiesForPackagesNamed: packageNames.
	self warmTonelCacheForPackagesNamed: packageNames.
	self loadRequestedGroup.
	^ self runLoadedImageChecks
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> runLoadedImageChecks [
	^ GemStonePharoReloadRunner
		runLoadedImageOnEnvironment: self environment
		log: logBlock
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> tonelRepository [
	^ [ MCRepository fromUrl: self class baselineRepositoryUrl ]
		on: Error
		do: [ :ex |
			self
				log: 'CACHE_WARMUP_WARN repository :: ', ex messageText.
			nil ]
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> unloadPackagesNamed: packageNames [
	| organizer |
	organizer := Smalltalk at: #RPackageOrganizer ifAbsent: [ nil ].
	organizer ifNil: [ ^ self ].
	packageNames do: [ :pkgName |
		| pkg |
		pkg := [ organizer default packageNamed: pkgName ] on: Error do: [ nil ].
		pkg ifNotNil: [
			[ pkg removeFromSystem ]
				on: Error
				do: [ :ex |
					self
						log: 'UNLOAD_WARN ', pkgName, ' :: ', ex messageText ] ] ]
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> unregisterWorkingCopiesForPackagesNamed: packageNames [
	| workingCopyClass |
	workingCopyClass := Smalltalk at: #MCWorkingCopy ifAbsent: [ nil ].
	workingCopyClass ifNil: [ ^ self ].
	workingCopyClass allWorkingCopies do: [ :workingCopy |
		(packageNames includes: workingCopy packageName)
			ifTrue: [
				[ workingCopy unregister ]
					on: Error
					do: [ :ex |
						self
							log: 'UNLOAD_WARN working copy ', workingCopy packageName, ' :: ', ex messageText ] ] ]
]

{ #category : 'private' }
GemStonePharoReloadBootstrapper >> warmTonelCacheForPackagesNamed: packageNames [
	| tonelRepository |
	tonelRepository := self tonelRepository.
	tonelRepository ifNil: [ ^ self ].
	packageNames do: [ :pkgName |
		[ tonelRepository versionFrom: pkgName ]
			on: Error
			do: [ :ex |
				self
					log: 'CACHE_WARMUP_WARN ', pkgName, ' :: ', ex messageText ] ]
]
