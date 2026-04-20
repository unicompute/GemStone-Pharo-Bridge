Class {
	#name : 'GbxOverrideSpecFixture',
	#superclass : 'GbxAbstractOverrideSpec',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
GbxOverrideSpecFixture class >> overridesPackageName [
	^ 'GemStone-GBS-Converted'
]

{ #category : 'specs' }
GbxOverrideSpecFixture class >> spec100 [
	<version: '1.0'>
	^ GbxOverrideSet
		destinationPackageName: 'OlderPackage'
		classOverrides: #()
		variableOverrides: #()
		methodOverrides: #()
]

{ #category : 'specs' }
GbxOverrideSpecFixture class >> spec200 [
	<version: '2.0'>
	^ GbxOverrideSet
		destinationPackageName: 'NewestPackage'
		classOverrides: #()
		variableOverrides: #()
		methodOverrides: #()
]
