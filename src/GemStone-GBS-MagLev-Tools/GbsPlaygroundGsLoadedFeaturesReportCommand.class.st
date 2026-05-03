Class {
	#name : 'GbsPlaygroundGsLoadedFeaturesReportCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-MagLev-Tools',
	#package : 'GemStone-GBS-MagLev-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsLoadedFeaturesReportCommand class >> defaultDescription [
	^ 'Browse the GemStone Ruby loaded features report.'
]

{ #category : 'defaults' }
GbsPlaygroundGsLoadedFeaturesReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundGsLoadedFeaturesReportCommand class >> defaultName [
	^ 'GS-Loaded Features Report'
]

{ #category : 'defaults' }
GbsPlaygroundGsLoadedFeaturesReportCommand class >> order [
	^ 907
]

{ #category : 'executing' }
GbsPlaygroundGsLoadedFeaturesReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseRubyLoadedFeaturesReportIn: context
]
