Class {
	#name : 'GbsPlaygroundGsObjectsInMemoryReportCommand',
	#superclass : 'StPlaygroundMenuExtensionCommand',
	#category : 'GemStone-GBS-Core-Tools',
	#package : 'GemStone-GBS-Core-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundGsObjectsInMemoryReportCommand class >> defaultDescription [
	^ 'Browse a GemStone objects-in-memory report.'
]

{ #category : 'defaults' }
GbsPlaygroundGsObjectsInMemoryReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundGsObjectsInMemoryReportCommand class >> defaultName [
	^ 'GS-Objects In Memory Report...'
]

{ #category : 'defaults' }
GbsPlaygroundGsObjectsInMemoryReportCommand class >> order [
	^ 913
]

{ #category : 'executing' }
GbsPlaygroundGsObjectsInMemoryReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseObjectsInMemoryReportIn: context
]
