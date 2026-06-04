Class {
	#name : 'GbsPlaygroundMenuSessionEventReportCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-Core-Tools',
	#package : 'GemStone-GBS-Core-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuSessionEventReportCommand class >> defaultDescription [
	^ 'Browse the GemStone session event report.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuSessionEventReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundMenuSessionEventReportCommand class >> defaultName [
	^ 'GS-Session Event Report'
]

{ #category : 'defaults' }
GbsPlaygroundMenuSessionEventReportCommand class >> order [
	^ 914
]

{ #category : 'executing' }
GbsPlaygroundMenuSessionEventReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseSessionEventReportIn: context
]
