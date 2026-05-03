Class {
	#name : 'GbsPlaygroundGsMaglevFinalizerRegistryReportCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-MagLev-Tools',
	#package : 'GemStone-GBS-MagLev-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsMaglevFinalizerRegistryReportCommand class >> defaultDescription [
	^ 'Browse the GemStone MagLev finalizer registry report.'
]

{ #category : 'defaults' }
GbsPlaygroundGsMaglevFinalizerRegistryReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundGsMaglevFinalizerRegistryReportCommand class >> defaultName [
	^ 'GS-MagLev Finalizer Registry Report'
]

{ #category : 'defaults' }
GbsPlaygroundGsMaglevFinalizerRegistryReportCommand class >> order [
	^ 914
]

{ #category : 'executing' }
GbsPlaygroundGsMaglevFinalizerRegistryReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseMaglevFinalizerRegistryReportIn: context
]
