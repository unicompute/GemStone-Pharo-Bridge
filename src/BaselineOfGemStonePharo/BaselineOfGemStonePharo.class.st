Class {
	#name : 'BaselineOfGemStonePharo',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfGemStonePharo',
	#package : 'BaselineOfGemStonePharo'
}

{ #category : 'baselines' }
BaselineOfGemStonePharo >> baseline: spec [
	<baseline>
	spec for: #common do: [ 
		spec
			preLoadDoIt: #preload:package:;
			postLoadDoIt: #postload:package:.
		
		"1. Define the Packages and their Dependencies"
		spec package: 'GemStone-GBS-Converted'.
		
		spec package: 'GemStone-GBS-Tools' 
			with: [ spec requires: #('GemStone-GBS-Converted') ].
			
		spec package: 'GemStone-Pharo-Tests' 
			with: [ spec requires: #('GemStone-GBS-Converted' 'GemStone-GBS-Tools') ].
			
		"2. Define the Load Groups"
		spec 
			group: 'Core' with: #('GemStone-GBS-Converted');
			group: 'Tools' with: #('GemStone-GBS-Converted' 'GemStone-GBS-Tools');
			group: 'Tests' with: #('GemStone-Pharo-Tests');
			group: 'default' with: #('Tools' 'Tests').
	]
]

{ #category : 'actions' }
BaselineOfGemStonePharo >> postload: loader package: packageSpec [
	self class environment
		at: #GbxRuntimeOverrideSpec
		ifPresent: [ :runtimeSpec | runtimeSpec apply ].
	self class environment
		at: #GbxToolsOverrideSpec
		ifPresent: [ :toolsSpec | toolsSpec apply ]
]

{ #category : 'actions' }
BaselineOfGemStonePharo >> preload: loader package: packageSpec [
	self class environment
		at: #GbxOverrideUtility
		ifPresent: [ :overrideUtility |
			[ overrideUtility removeOverridesForRelease ]
				on: MessageNotUnderstood
				do: [ "Method removed or renamed in newer versions - safely skip" ] ]
]
