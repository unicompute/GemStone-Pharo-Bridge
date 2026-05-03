Class {
	#name : 'GbsPlaygroundGsTopLevelAutoloadReportCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-MagLev-Tools',
	#package : 'GemStone-GBS-MagLev-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsTopLevelAutoloadReportCommand class >> defaultDescription [
	^ 'Browse the GemStone top-level Ruby autoload registrations report.'
]

{ #category : 'defaults' }
GbsPlaygroundGsTopLevelAutoloadReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundGsTopLevelAutoloadReportCommand class >> defaultName [
	^ 'GS-Top-Level Autoload Report'
]

{ #category : 'defaults' }
GbsPlaygroundGsTopLevelAutoloadReportCommand class >> order [
	^ 909
]

{ #category : 'executing' }
GbsPlaygroundGsTopLevelAutoloadReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseTopLevelAutoloadRegistrationsReportIn: context
]
