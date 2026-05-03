Class {
	#name : 'GbsPlaygroundGsLoadPathReportCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-MagLev-Tools',
	#package : 'GemStone-GBS-MagLev-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsLoadPathReportCommand class >> defaultDescription [
	^ 'Browse the GemStone Ruby load path report.'
]

{ #category : 'defaults' }
GbsPlaygroundGsLoadPathReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundGsLoadPathReportCommand class >> defaultName [
	^ 'GS-$LOAD_PATH Report'
]

{ #category : 'defaults' }
GbsPlaygroundGsLoadPathReportCommand class >> order [
	^ 906
]

{ #category : 'executing' }
GbsPlaygroundGsLoadPathReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseRubyLoadPathReportIn: context
]
