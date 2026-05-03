Class {
	#name : 'GbsPlaygroundMenuTopLevelAutoloadReportCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-MagLev-Tools',
	#package : 'GemStone-GBS-MagLev-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuTopLevelAutoloadReportCommand class >> defaultDescription [
	^ 'Browse the GemStone top-level Ruby autoload registrations report.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuTopLevelAutoloadReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundMenuTopLevelAutoloadReportCommand class >> defaultName [
	^ 'GS-Top-Level Autoload Report'
]

{ #category : 'defaults' }
GbsPlaygroundMenuTopLevelAutoloadReportCommand class >> order [
	^ 909
]

{ #category : 'executing' }
GbsPlaygroundMenuTopLevelAutoloadReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseTopLevelAutoloadRegistrationsReportIn: context
]
