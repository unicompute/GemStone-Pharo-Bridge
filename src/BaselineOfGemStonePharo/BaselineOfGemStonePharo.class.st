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
		spec package: 'GemStone-GBS-Converted'
			with: [ spec preLoadDoIt: #preloadConvertedBootstrap ].
		
		spec package: 'GemStone-GBS-Tools' 
			with: [ spec requires: #('GemStone-GBS-Converted') ].
			
		spec package: 'GemStone-Pharo-Tests' 
			with: [ spec requires: #('GemStone-GBS-Converted' 'GemStone-GBS-Tools') ].
			
		"2. Define the Load Groups"
		spec 
			group: 'Core' with: #('GemStone-GBS-Converted');
			group: 'Tools' with: #('GemStone-GBS-Converted' 'GemStone-GBS-Tools');
			group: 'Tests' with: #('GemStone-Pharo-Tests');
			group: 'default' with: #('Tools');
			group: 'full' with: #('Tools' 'Tests').
	]
]

{ #category : 'baselines' }
BaselineOfGemStonePharo >> preloadConvertedBootstrap [
	('/Users/tariq/src/gemtools/GemStone-Pharo-Bridge/scripts/prebootstrap_pharo13.st' asFileReference)
		fileIn
]
