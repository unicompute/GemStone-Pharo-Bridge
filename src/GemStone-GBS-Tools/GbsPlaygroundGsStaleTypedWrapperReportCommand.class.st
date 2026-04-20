Class {
	#name : 'GbsPlaygroundGsStaleTypedWrapperReportCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsStaleTypedWrapperReportCommand class >> defaultDescription [
	^ 'Browse the GemStone stale typed wrapper report.'
]

{ #category : 'defaults' }
GbsPlaygroundGsStaleTypedWrapperReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundGsStaleTypedWrapperReportCommand class >> defaultName [
	^ 'GS-Stale Typed Wrapper Report'
]

{ #category : 'defaults' }
GbsPlaygroundGsStaleTypedWrapperReportCommand class >> order [
	^ 911
]

{ #category : 'executing' }
GbsPlaygroundGsStaleTypedWrapperReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseStaleTypedWrapperLifecycleReportIn: context
]
