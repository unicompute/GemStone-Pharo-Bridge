Class {
	#name : 'GbsRubyRuntimeEntry',
	#superclass : 'Object',
	#instVars : [
		'kind',
		'value',
		'persistent'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRubyRuntimeEntry class >> kind: aSymbol value: anObject [
	^ self
		kind: aSymbol
		value: anObject
		persistent: false
]

{ #category : 'instance creation' }
GbsRubyRuntimeEntry class >> kind: aSymbol value: anObject persistent: aBoolean [
	^ self new
		kind: aSymbol;
		value: anObject;
		persistent: aBoolean;
		yourself
]

{ #category : 'printing' }
GbsRubyRuntimeEntry >> displayString [
	^ value ifNil: [ '(nil)' ] ifNotNil: [ value asString ]
]

{ #category : 'querying' }
GbsRubyRuntimeEntry >> directoryPath [
	^ nil
]

{ #category : 'actions' }
GbsRubyRuntimeEntry >> loadAction [
	^ GbsRubyRuntimeProvenanceAction
		action: #load
		sourceEntry: self
		targetPath: self value
]

{ #category : 'querying' }
GbsRubyRuntimeEntry >> isPersistent [
	^ persistent == true
]

{ #category : 'accessing' }
GbsRubyRuntimeEntry >> kind [
	^ kind
]

{ #category : 'accessing' }
GbsRubyRuntimeEntry >> kind: aSymbol [
	kind := aSymbol
]

{ #category : 'querying' }
GbsRubyRuntimeEntry >> provenanceLabel [
	^ kind ifNil: [ 'Ruby Runtime' ] ifNotNil: [ kind asString ]
]

{ #category : 'querying' }
GbsRubyRuntimeEntry >> provenanceLinks [
	^ { GbsRubyRuntimeProvenanceLink
		source: self provenanceLabel
		target: self displayString
		kind: self kind
		entry: self }
]

{ #category : 'querying' }
GbsRubyRuntimeEntry >> provenanceActionsUsing: aRuntimeFacade [
	^ #()
]

{ #category : 'actions' }
GbsRubyRuntimeEntry >> loadUsing: aRuntimeFacade [
	^ self value
		ifNil: [ nil ]
		ifNotNil: [ :path | aRuntimeFacade loadFileNamed: path ]
]

{ #category : 'actions' }
GbsRubyRuntimeEntry >> loadRelative: aRelativePath using: aRuntimeFacade [
	^ aRuntimeFacade
		loadRelativeFileNamed: aRelativePath
		relativeTo: self value
]

{ #category : 'actions' }
GbsRubyRuntimeEntry >> loadRelativeActionFor: aRelativePath using: aRuntimeFacade [
	^ GbsRubyRuntimeProvenanceAction
		relativeAction: #loadRelative
		sourceEntry: self
		relativePath: aRelativePath
		basePath: self value
		resolvedPath: (self resolvedRelativePath: aRelativePath using: aRuntimeFacade)
]

{ #category : 'accessing' }
GbsRubyRuntimeEntry >> persistent [
	^ persistent
]

{ #category : 'accessing' }
GbsRubyRuntimeEntry >> persistent: aBoolean [
	persistent := aBoolean == true
]

{ #category : 'printing' }
GbsRubyRuntimeEntry >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: kind asString;
		nextPutAll: ': ';
		nextPutAll: self displayString;
		nextPut: $)
]

{ #category : 'actions' }
GbsRubyRuntimeEntry >> requireRelative: aRelativePath using: aRuntimeFacade [
	^ aRuntimeFacade
		requireRelativeFileNamed: aRelativePath
		relativeTo: self value
]

{ #category : 'actions' }
GbsRubyRuntimeEntry >> requireAction [
	^ GbsRubyRuntimeProvenanceAction
		action: #require
		sourceEntry: self
		targetPath: self value
]

{ #category : 'actions' }
GbsRubyRuntimeEntry >> requireRelativeActionFor: aRelativePath using: aRuntimeFacade [
	^ GbsRubyRuntimeProvenanceAction
		relativeAction: #requireRelative
		sourceEntry: self
		relativePath: aRelativePath
		basePath: self value
		resolvedPath: (self resolvedRelativePath: aRelativePath using: aRuntimeFacade)
]

{ #category : 'actions' }
GbsRubyRuntimeEntry >> requireUsing: aRuntimeFacade [
	^ self value
		ifNil: [ nil ]
		ifNotNil: [ :path | aRuntimeFacade requireFileNamed: path ]
]

{ #category : 'actions' }
GbsRubyRuntimeEntry >> resolvedRelativePath: aRelativePath using: aRuntimeFacade [
	^ aRuntimeFacade
		resolvedRelativePath: aRelativePath
		relativeTo: self value
]

{ #category : 'accessing' }
GbsRubyRuntimeEntry >> value [
	^ value
]

{ #category : 'accessing' }
GbsRubyRuntimeEntry >> value: anObject [
	value := anObject
]
