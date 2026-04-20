Class {
	#name : 'GbsPlaygroundMenuObjectsInMemoryReportCommand',
	#superclass : 'CmCommand',
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'defaults' }
GbsPlaygroundMenuObjectsInMemoryReportCommand class >> defaultDescription [
	^ 'Browse a GemStone objects-in-memory report.'
]

{ #category : 'defaults' }
GbsPlaygroundMenuObjectsInMemoryReportCommand class >> defaultIconName [
	^ #smallInspectIt
]

{ #category : 'defaults' }
GbsPlaygroundMenuObjectsInMemoryReportCommand class >> defaultName [
	^ 'GS-Objects In Memory Report...'
]

{ #category : 'defaults' }
GbsPlaygroundMenuObjectsInMemoryReportCommand class >> order [
	^ 913
]

{ #category : 'executing' }
GbsPlaygroundMenuObjectsInMemoryReportCommand >> execute [
	^ GbsPlaygroundActions gsBrowseObjectsInMemoryReportIn: context
]
