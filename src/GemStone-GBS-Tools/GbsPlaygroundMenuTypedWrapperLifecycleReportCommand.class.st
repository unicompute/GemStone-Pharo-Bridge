Class {
	#name : 'GbsPlaygroundMenuTypedWrapperLifecycleReportCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
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
