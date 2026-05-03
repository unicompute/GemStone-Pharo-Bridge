Class {
	#name : 'GbsPlaygroundMenuMaglevFinalizerRegistryReportCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-MagLev-Tools',
	#package : 'GemStone-GBS-MagLev-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuMaglevFinalizerRegistryReportCommand class >> defaultDescription [
	^ 'Browse the GemStone MagLev finalizer registry report.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuMaglevFinalizerRegistryReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundMenuMaglevFinalizerRegistryReportCommand class >> defaultName [
	^ 'GS-MagLev Finalizer Registry Report'
]

{ #category : 'defaults' }
GbsPlaygroundMenuMaglevFinalizerRegistryReportCommand class >> order [
	^ 914
]

{ #category : 'executing' }
GbsPlaygroundMenuMaglevFinalizerRegistryReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseMaglevFinalizerRegistryReportIn: context
]
