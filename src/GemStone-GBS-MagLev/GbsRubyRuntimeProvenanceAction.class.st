Class {
	#name : 'GbsRubyRuntimeProvenanceAction',
	#superclass : 'Object',
	#instVars : [
		'actionKind',
		'sourceEntry',
		'targetPath',
		'basePath',
		'resolvedPath',
		'retrySourceKind'
	],
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'instance creation' }
GbsRubyRuntimeProvenanceAction class >> action: aSymbol sourceEntry: anEntry targetPath: aTargetPath [
	^ self new
		actionKind: aSymbol;
		sourceEntry: anEntry;
		targetPath: aTargetPath;
		yourself
]

{ #category : 'instance creation' }
GbsRubyRuntimeProvenanceAction class >> relativeAction: aSymbol sourceEntry: anEntry relativePath: aRelativePath basePath: aBasePath resolvedPath: aResolvedPath [
	^ self new
		actionKind: aSymbol;
		sourceEntry: anEntry;
		targetPath: aRelativePath;
		basePath: aBasePath;
		resolvedPath: aResolvedPath;
		yourself
]

{ #category : 'instance creation' }
GbsRubyRuntimeProvenanceAction class >> retryAction: aSymbol sourceEntry: anEntry targetPath: aTargetPath sourceKind: aSourceKind [
	^ self new
		actionKind: aSymbol;
		sourceEntry: anEntry;
		targetPath: aTargetPath;
		retrySourceKind: aSourceKind;
		yourself
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceAction >> actionKind [
	^ actionKind
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceAction >> actionKind: aSymbol [
	actionKind := aSymbol
]

{ #category : 'printing' }
GbsRubyRuntimeProvenanceAction >> actionLabel [
	actionKind = #require ifTrue: [ ^ 'require' ].
	actionKind = #load ifTrue: [ ^ 'load' ].
	actionKind = #requireRelative ifTrue: [ ^ 'require_relative' ].
	actionKind = #loadRelative ifTrue: [ ^ 'load_relative' ].
	actionKind = #recoverAutoload ifTrue: [ ^ 'recover autoload' ].
	actionKind = #resetAutoload ifTrue: [ ^ 'reset autoload' ].
	actionKind = #retryAutoload ifTrue: [
		retrySourceKind ifNil: [ ^ 'retry autoload' ].
		^ 'retry autoload [', retrySourceKind asString, ']' ].
	^ actionKind ifNil: [ 'action' ] ifNotNil: [ actionKind asString ]
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceAction >> basePath [
	^ basePath
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceAction >> basePath: aString [
	basePath := aString
]

{ #category : 'printing' }
GbsRubyRuntimeProvenanceAction >> displayString [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: self actionLabel;
			nextPutAll: ' ';
			nextPutAll: (self targetPath ifNil: [ '(nil)' ]) asString.
		self isRelativeAction ifTrue: [
			stream
				nextPutAll: ' from ';
				nextPutAll: (self basePath ifNil: [ '(nil)' ]) asString.
			self resolvedPath ifNotNil: [
				stream
					nextPutAll: ' => ';
					nextPutAll: self resolvedPath asString ] ] ]
]

{ #category : 'actions' }
GbsRubyRuntimeProvenanceAction >> executeUsing: aRuntimeFacade [
	self isRelativeAction ifTrue: [
		actionKind = #requireRelative ifTrue: [
			^ aRuntimeFacade
				requireRelativeFileNamed: self targetPath
				relativeTo: self basePath ].
		actionKind = #loadRelative ifTrue: [
			^ aRuntimeFacade
				loadRelativeFileNamed: self targetPath
				relativeTo: self basePath ] ].
	actionKind = #require ifTrue: [ ^ aRuntimeFacade requireFileNamed: self targetPath ].
	actionKind = #load ifTrue: [ ^ aRuntimeFacade loadFileNamed: self targetPath ].
	actionKind = #recoverAutoload ifTrue: [ ^ self sourceEntry ifNotNil: [ self sourceEntry recoverRegistration ] ].
	actionKind = #resetAutoload ifTrue: [ ^ self sourceEntry ifNotNil: [ self sourceEntry resetRegistration ] ].
	actionKind = #retryAutoload ifTrue: [ ^ self sourceEntry ifNotNil: [
		retrySourceKind
			ifNil: [ self sourceEntry retryRegistration ]
			ifNotNil: [ self sourceEntry retryRegistrationUsingSourceKind: retrySourceKind ] ] ].
	^ nil
]

{ #category : 'testing' }
GbsRubyRuntimeProvenanceAction >> isRelativeAction [
	^ #(requireRelative loadRelative) includes: actionKind
]

{ #category : 'printing' }
GbsRubyRuntimeProvenanceAction >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self displayString;
		nextPut: $)
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceAction >> resolvedPath [
	^ resolvedPath
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceAction >> resolvedPath: aString [
	resolvedPath := aString
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceAction >> retrySourceKind [
	^ retrySourceKind
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceAction >> retrySourceKind: aString [
	retrySourceKind := aString
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceAction >> sourceEntry [
	^ sourceEntry
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceAction >> sourceEntry: anObject [
	sourceEntry := anObject
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceAction >> targetPath [
	^ targetPath
]

{ #category : 'accessing' }
GbsRubyRuntimeProvenanceAction >> targetPath: aString [
	targetPath := aString
]
