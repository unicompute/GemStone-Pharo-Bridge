Class {
	#name : 'GbsPlaygroundMenuPersistentFeaturesReportCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-MagLev-Tools',
	#package : 'GemStone-GBS-MagLev-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuPersistentFeaturesReportCommand class >> defaultDescription [
	^ 'Browse the GemStone Ruby persistent loaded features report.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuPersistentFeaturesReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundMenuPersistentFeaturesReportCommand class >> defaultName [
	^ 'GS-Persistent Features Report'
]

{ #category : 'defaults' }
GbsPlaygroundMenuPersistentFeaturesReportCommand class >> order [
	^ 908
]

{ #category : 'executing' }
GbsPlaygroundMenuPersistentFeaturesReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseRubyPersistentLoadedFeaturesReportIn: context
]
