Class {
	#name : 'GbxToolsOverrideSpec',
	#superclass : 'GbxAbstractOverrideSpec',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'private' }
GbxToolsOverrideSpec class >> emptySpec [
	"VisualWorks tool overrides target the old Tools.* UI classes. Those classes do
	not exist in the Pharo bridge, so the tools spec is intentionally empty here."
	^ GbxOverrideSet
		destinationPackageName: self overridesPackageName
		classOverrides: #()
		variableOverrides: #()
		methodOverrides: #()
]

{ #category : 'accessing' }
GbxToolsOverrideSpec class >> overridesPackageName [
	^ 'GbsToolsOverrides'
]

{ #category : 'generated' }
GbxToolsOverrideSpec class >> spec832 [
	<version: '8.3.2'>
	^ self emptySpec
]

{ #category : 'generated' }
GbxToolsOverrideSpec class >> spec911 [
	<version: '9.1.1'>
	^ self emptySpec
]

{ #category : 'generated' }
GbxToolsOverrideSpec class >> spec921 [
	<version: '9.2.1'>
	^ self emptySpec
]

{ #category : 'generated' }
GbxToolsOverrideSpec class >> spec93 [
	<version: '9.3'>
	^ self emptySpec
]
