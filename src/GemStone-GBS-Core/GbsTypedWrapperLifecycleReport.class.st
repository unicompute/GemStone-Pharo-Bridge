Class {
	#name : 'GbsTypedWrapperLifecycleReport',
	#superclass : 'Object',
	#instVars : [
		'entries'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsTypedWrapperLifecycleReport class >> entries: aCollection [
	^ self new
		entries: aCollection;
		yourself
]

{ #category : 'printing' }
GbsTypedWrapperLifecycleReport >> appendOn: aStream [
	aStream nextPutAll: 'Client'; tab; nextPutAll: 'Server'; tab; nextPutAll: 'Wrapper'; tab; nextPutAll: 'Source'; tab; nextPutAll: 'Local'; tab; nextPutAll: 'Remote'; tab; nextPutAll: 'Status'; cr.
	self entries
		ifEmpty: [ aStream nextPutAll: 'No typed wrappers generated.'; cr ]
		ifNotEmpty: [
			self entries do: [ :each |
				aStream nextPutAll: each displayString; cr ] ]
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleReport >> entries [
	^ entries ifNil: [ #() ]
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleReport >> entries: aCollection [
	entries := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'querying' }
GbsTypedWrapperLifecycleReport >> staleEntries [
	^ self entries select: [ :each | each status = #stale ]
]

{ #category : 'printing' }
GbsTypedWrapperLifecycleReport >> text [
	^ String streamContents: [ :stream |
		stream nextPutAll: 'Typed Wrapper Lifecycle'; cr; cr.
		self appendOn: stream ]
]
