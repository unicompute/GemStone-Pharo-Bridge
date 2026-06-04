Class {
	#name : 'GbsPlaygroundGsSessionEventReportCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-Core-Tools',
	#package : 'GemStone-GBS-Core-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsSessionEventReportCommand class >> defaultDescription [
	^ 'Browse the GemStone session event report.'
]

{ #category : 'defaults' }
GbsPlaygroundGsSessionEventReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundGsSessionEventReportCommand class >> defaultName [
	^ 'GS-Session Event Report'
]

{ #category : 'defaults' }
GbsPlaygroundGsSessionEventReportCommand class >> order [
	^ 914
]

{ #category : 'executing' }
GbsPlaygroundGsSessionEventReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseSessionEventReportIn: context
]
