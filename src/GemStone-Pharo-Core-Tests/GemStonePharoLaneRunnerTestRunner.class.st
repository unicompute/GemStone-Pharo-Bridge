Class {
	#name : 'GemStonePharoLaneRunnerTestRunner',
	#superclass : 'GemStonePharoLaneRunner',
	#instVars : [
		'loadedPackages'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'accessing' }
GemStonePharoLaneRunnerTestRunner >> loadedPackageNames [
	^ loadedPackages ifNil: [ #() ]
]

{ #category : 'accessing' }
GemStonePharoLaneRunnerTestRunner >> loadedPackageNames: aCollection [
	loadedPackages := aCollection asSet
]
