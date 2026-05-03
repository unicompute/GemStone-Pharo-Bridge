Class {
	#name : 'GbsPlaygroundMenuLoadedFeaturesReportCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-MagLev-Tools',
	#package : 'GemStone-GBS-MagLev-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuLoadedFeaturesReportCommand class >> defaultDescription [
	^ 'Browse the GemStone Ruby loaded features report.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuLoadedFeaturesReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundMenuLoadedFeaturesReportCommand class >> defaultName [
	^ 'GS-Loaded Features Report'
]

{ #category : 'defaults' }
GbsPlaygroundMenuLoadedFeaturesReportCommand class >> order [
	^ 907
]

{ #category : 'executing' }
GbsPlaygroundMenuLoadedFeaturesReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseRubyLoadedFeaturesReportIn: context
]
