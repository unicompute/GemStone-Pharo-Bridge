Class {
	#name : 'GemStonePharoReloadBootstrapperTestBootstrapper',
	#superclass : 'GemStonePharoReloadBootstrapper',
	#instVars : [
		'calls'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
GemStonePharoReloadBootstrapperTestBootstrapper >> calls [
	^ calls ifNil: [ calls := OrderedCollection new ]
]

{ #category : 'private' }
GemStonePharoReloadBootstrapperTestBootstrapper >> collectClassNamesToForceRemoveFromPackagesNamed: packageNames [
	self calls add: { #collectClassNames. packageNames asArray }.
	^ #('LegacyBridgeClass')
]

{ #category : 'initialization' }
GemStonePharoReloadBootstrapperTestBootstrapper >> initialize [
	super initialize.
	calls := OrderedCollection new
]

{ #category : 'private' }
GemStonePharoReloadBootstrapperTestBootstrapper >> forceRemoveClassesNamed: classNames [
	self calls add: { #forceRemoveClasses. classNames asArray }
]

{ #category : 'private' }
GemStonePharoReloadBootstrapperTestBootstrapper >> loadRequestedGroup [
	self calls add: { #loadRequestedGroup. self loadGroup }
]

{ #category : 'private' }
GemStonePharoReloadBootstrapperTestBootstrapper >> removeOverrides [
	self calls add: #removeOverrides
]

{ #category : 'private' }
GemStonePharoReloadBootstrapperTestBootstrapper >> runLoadedImageChecks [
	self calls add: #runLoadedImageChecks.
	^ true
]

{ #category : 'private' }
GemStonePharoReloadBootstrapperTestBootstrapper >> unloadPackagesNamed: packageNames [
	self calls add: { #unloadPackages. packageNames asArray }
]

{ #category : 'private' }
GemStonePharoReloadBootstrapperTestBootstrapper >> unregisterWorkingCopiesForPackagesNamed: packageNames [
	self calls add: { #unregisterWorkingCopies. packageNames asArray }
]

{ #category : 'private' }
GemStonePharoReloadBootstrapperTestBootstrapper >> warmTonelCacheForPackagesNamed: packageNames [
	self calls add: { #warmTonelCache. packageNames asArray }
]
