Class {
	#name : 'GbsTypedWrapperLifecycleEntry',
	#superclass : 'Object',
	#instVars : [
		'wrapperClass',
		'clientName',
		'serverName',
		'wrapperName',
		'source',
		'localVersion',
		'localNumberOfVersions',
		'remoteVersion',
		'remoteNumberOfVersions',
		'status'
	],
	#category : 'GemStone-GBS-Core',
	#package : 'GemStone-GBS-Core'
}

{ #category : 'instance creation' }
GbsTypedWrapperLifecycleEntry class >> wrapperClass: aClass clientName: clientName serverName: serverName source: aSource localVersion: localVersion localNumberOfVersions: localNumber remoteVersion: remoteVersion remoteNumberOfVersions: remoteNumber status: aStatus [
	^ self new
		wrapperClass: aClass;
		clientName: clientName;
		serverName: serverName;
		source: aSource;
		localVersion: localVersion;
		localNumberOfVersions: localNumber;
		remoteVersion: remoteVersion;
		remoteNumberOfVersions: remoteNumber;
		status: aStatus;
		yourself
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> clientName [
	^ clientName ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> clientName: aString [
	clientName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'printing' }
GbsTypedWrapperLifecycleEntry >> displayString [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: self clientName;
			tab;
			nextPutAll: self serverName;
			tab;
			nextPutAll: self wrapperName;
			tab;
			nextPutAll: self source;
			tab;
			nextPutAll: self localVersionString;
			tab;
			nextPutAll: self remoteVersionString;
			tab;
			nextPutAll: self status asString ]
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> localNumberOfVersions [
	^ localNumberOfVersions
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> localNumberOfVersions: anObject [
	localNumberOfVersions := anObject
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> localVersion [
	^ localVersion
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> localVersion: anObject [
	localVersion := anObject
]

{ #category : 'printing' }
GbsTypedWrapperLifecycleEntry >> localVersionString [
	^ (localVersion ifNil: [ '?' ] ifNotNil: [ :each | each asString ]),
		'/',
		(localNumberOfVersions ifNil: [ '?' ] ifNotNil: [ :each | each asString ])
]

{ #category : 'printing' }
GbsTypedWrapperLifecycleEntry >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self displayString;
		nextPut: $)
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> remoteNumberOfVersions [
	^ remoteNumberOfVersions
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> remoteNumberOfVersions: anObject [
	remoteNumberOfVersions := anObject
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> remoteVersion [
	^ remoteVersion
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> remoteVersion: anObject [
	remoteVersion := anObject
]

{ #category : 'printing' }
GbsTypedWrapperLifecycleEntry >> remoteVersionString [
	^ (remoteVersion ifNil: [ '?' ] ifNotNil: [ :each | each asString ]),
		'/',
		(remoteNumberOfVersions ifNil: [ '?' ] ifNotNil: [ :each | each asString ])
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> serverName [
	^ serverName ifNil: [ '' ]
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> serverName: aString [
	serverName := aString ifNil: [ '' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> source [
	^ source ifNil: [ 'unknown' ]
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> source: aString [
	source := aString ifNil: [ 'unknown' ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> status [
	^ status ifNil: [ #unknown ]
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> status: aSymbol [
	status := aSymbol ifNil: [ #unknown ] ifNotNil: [ aSymbol asSymbol ]
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> wrapperClass [
	^ wrapperClass
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> wrapperClass: aClass [
	wrapperClass := aClass.
	wrapperName := aClass ifNil: [ '' ] ifNotNil: [ aClass name asString ]
]

{ #category : 'accessing' }
GbsTypedWrapperLifecycleEntry >> wrapperName [
	^ wrapperName ifNil: [ '' ]
]
