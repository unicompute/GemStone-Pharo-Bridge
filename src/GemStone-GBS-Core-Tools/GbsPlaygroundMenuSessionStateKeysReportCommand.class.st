Class {
	#name : 'GbsPlaygroundMenuSessionStateKeysReportCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-Core-Tools',
	#package : 'GemStone-GBS-Core-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuSessionStateKeysReportCommand class >> defaultDescription [
	^ 'Browse GemStone session-state report entries by key.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuSessionStateKeysReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundMenuSessionStateKeysReportCommand class >> defaultName [
	^ 'GS-Session State Keys Report...'
]

{ #category : 'defaults' }
GbsPlaygroundMenuSessionStateKeysReportCommand class >> order [
	^ 912
]

{ #category : 'executing' }
GbsPlaygroundMenuSessionStateKeysReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseSessionStateKeysReportIn: context
]
