Class {
	#name : 'GbsPlaygroundMenuTypedWrapperLifecycleReportCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-Core-Tools',
	#package : 'GemStone-GBS-Core-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuTypedWrapperLifecycleReportCommand class >> defaultDescription [
	^ 'Browse the GemStone typed wrapper lifecycle report.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuTypedWrapperLifecycleReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundMenuTypedWrapperLifecycleReportCommand class >> defaultName [
	^ 'GS-Typed Wrapper Lifecycle Report'
]

{ #category : 'defaults' }
GbsPlaygroundMenuTypedWrapperLifecycleReportCommand class >> order [
	^ 910
]

{ #category : 'executing' }
GbsPlaygroundMenuTypedWrapperLifecycleReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseTypedWrapperLifecycleReportIn: context
]
