Class {
	#name : 'GbsPlaygroundMenuLoadPathReportCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-MagLev-Tools',
	#package : 'GemStone-GBS-MagLev-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuLoadPathReportCommand class >> defaultDescription [
	^ 'Browse the GemStone Ruby load path report.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuLoadPathReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundMenuLoadPathReportCommand class >> defaultName [
	^ 'GS-$LOAD_PATH Report'
]

{ #category : 'defaults' }
GbsPlaygroundMenuLoadPathReportCommand class >> order [
	^ 906
]

{ #category : 'executing' }
GbsPlaygroundMenuLoadPathReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseRubyLoadPathReportIn: context
]
