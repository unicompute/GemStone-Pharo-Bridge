Class {
	#name : 'GbxOverrideReleaseSpecFixture',
	#superclass : 'GbxAbstractOverrideSpec',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'defaults' }
GbxOverrideReleaseSpecFixture class >> overridesPackageName [
	^ 'GbxOverrideReleasePackage'
]

{ #category : 'defaults' }
GbxOverrideReleaseSpecFixture class >> restoreDefaultSpecMethod [
	self class compile: 'spec100
	<version: ''1.0''>
	^ GbxOverrideSet
		destinationPackageName: ''GbxOverrideReleasePackage''
		classOverrides: #()
		variableOverrides: #()
		methodOverrides: #()' classified: 'specs'
]

{ #category : 'specs' }
GbxOverrideReleaseSpecFixture class >> spec100 [
	<version: '1.0'>
	^ GbxOverrideSet
		destinationPackageName: 'GbxOverrideReleasePackage'
		classOverrides: #()
		variableOverrides: #()
		methodOverrides: #()
]
