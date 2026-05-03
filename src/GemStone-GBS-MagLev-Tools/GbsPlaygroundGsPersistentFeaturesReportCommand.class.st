Class {
	#name : 'GbsPlaygroundGsPersistentFeaturesReportCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-MagLev-Tools',
	#package : 'GemStone-GBS-MagLev-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsPersistentFeaturesReportCommand class >> defaultDescription [
	^ 'Browse the GemStone Ruby persistent loaded features report.'
]

{ #category : 'defaults' }
GbsPlaygroundGsPersistentFeaturesReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundGsPersistentFeaturesReportCommand class >> defaultName [
	^ 'GS-Persistent Features Report'
]

{ #category : 'defaults' }
GbsPlaygroundGsPersistentFeaturesReportCommand class >> order [
	^ 908
]

{ #category : 'executing' }
GbsPlaygroundGsPersistentFeaturesReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseRubyPersistentLoadedFeaturesReportIn: context
]
