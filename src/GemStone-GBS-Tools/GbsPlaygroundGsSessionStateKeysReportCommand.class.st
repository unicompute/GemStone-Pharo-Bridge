Class {
	#name : 'GbsPlaygroundGsSessionStateKeysReportCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsSessionStateKeysReportCommand class >> defaultDescription [
	^ 'Browse GemStone session-state report entries by key.'
]

{ #category : 'defaults' }
GbsPlaygroundGsSessionStateKeysReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundGsSessionStateKeysReportCommand class >> defaultName [
	^ 'GS-Session State Keys Report...'
]

{ #category : 'defaults' }
GbsPlaygroundGsSessionStateKeysReportCommand class >> order [
	^ 912
]

{ #category : 'executing' }
GbsPlaygroundGsSessionStateKeysReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseSessionStateKeysReportIn: context
]
