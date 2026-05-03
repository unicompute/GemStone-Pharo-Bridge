Class {
	#name : 'GbsPlaygroundGsTypedWrapperLifecycleReportCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-Core-Tools',
	#package : 'GemStone-GBS-Core-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsTypedWrapperLifecycleReportCommand class >> defaultDescription [
	^ 'Browse the GemStone typed wrapper lifecycle report.'
]

{ #category : 'defaults' }
GbsPlaygroundGsTypedWrapperLifecycleReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundGsTypedWrapperLifecycleReportCommand class >> defaultName [
	^ 'GS-Typed Wrapper Lifecycle Report'
]

{ #category : 'defaults' }
GbsPlaygroundGsTypedWrapperLifecycleReportCommand class >> order [
	^ 910
]

{ #category : 'executing' }
GbsPlaygroundGsTypedWrapperLifecycleReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseTypedWrapperLifecycleReportIn: context
]
