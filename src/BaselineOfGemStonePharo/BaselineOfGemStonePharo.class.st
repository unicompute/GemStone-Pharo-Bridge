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
		
		"1. Define the Packages and their Dependencies"
		spec package: 'GemStone-GBS-Bootstrap'
			with: [ spec postLoadDoIt: #postloadBootstrapCompatibility ].
		
		spec package: 'GemStone-GBS-Converted'
			with: [
				spec requires: #('GemStone-GBS-Bootstrap').
				spec preLoadDoIt: #preloadConvertedCompatibility ].
		
		spec package: 'GemStone-GBS-Tools' 
			with: [
				spec requires: #('GemStone-GBS-Converted').
				spec preLoadDoIt: #preloadToolsCompatibility ].
			
		spec package: 'GemStone-Pharo-Tests' 
			with: [ spec requires: #('GemStone-GBS-Converted' 'GemStone-GBS-Tools') ].
			
		"2. Define the Load Groups"
		spec 
			group: 'Bootstrap' with: #('GemStone-GBS-Bootstrap');
			group: 'Core' with: #('GemStone-GBS-Bootstrap' 'GemStone-GBS-Converted');
			group: 'Tools' with: #('GemStone-GBS-Bootstrap' 'GemStone-GBS-Converted' 'GemStone-GBS-Tools');
			group: 'Tests' with: #('GemStone-Pharo-Tests');
			group: 'default' with: #('Tools');
			group: 'full' with: #('Tools' 'Tests').
	]
]

{ #category : 'baselines' }
BaselineOfGemStonePharo >> postloadBootstrapCompatibility [
	(Smalltalk at: #GbsPharoBootstrap ifAbsent: [ ^ self ])
		installCompatibilityAliases
]

{ #category : 'baselines' }
BaselineOfGemStonePharo >> preloadConvertedCompatibility [
	(Smalltalk at: #GbxLateSystem ifAbsent: [ ^ self ])
		ifNotNil: [ :existing |
			(existing superclass isNil
				or: [ existing superclass name ~= #Subsystem ])
				ifTrue: [ [ existing removeFromSystem ] on: Error do: [ ] ] ]
]

{ #category : 'baselines' }
BaselineOfGemStonePharo >> preloadToolsCompatibility [
	(Smalltalk at: #Reconnect ifAbsent: [ ^ self ])
		ifNotNil: [ :existing |
			[ existing removeFromSystem ] on: Error do: [ ] ]
]
