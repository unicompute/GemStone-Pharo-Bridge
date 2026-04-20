Class {
	#name : 'GbsPlaygroundMenuStaleTypedWrapperReportCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuStaleTypedWrapperReportCommand class >> defaultDescription [
	^ 'Browse the GemStone stale typed wrapper report.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuStaleTypedWrapperReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundMenuStaleTypedWrapperReportCommand class >> defaultName [
	^ 'GS-Stale Typed Wrapper Report'
]

{ #category : 'defaults' }
GbsPlaygroundMenuStaleTypedWrapperReportCommand class >> order [
	^ 911
]

{ #category : 'executing' }
GbsPlaygroundMenuStaleTypedWrapperReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseStaleTypedWrapperLifecycleReportIn: context
]
