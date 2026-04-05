Class {
	#name : 'GbsServerInterface',
	#superclass : 'Object',
	#instVars : [
		'libraryPath'
	],
	#classInstVars : [
		'UniqueInstance'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'as yet unclassified' }
GbsServerInterface class >> initialize [ UniqueInstance := nil
]

{ #category : 'class initialization' }
GbsServerInterface class >> reset [
    "Resets the singleton instance to nil"
    UniqueInstance := nil
]

{ #category : 'accessing' }
GbsServerInterface class >> uniqueInstance [ ^ UniqueInstance ifNil: [ UniqueInstance := self new ]
]

{ #category : 'ffi-binding' }
GbsServerInterface >> ffiLibraryName [
	^ self libraryPath ifNil: [ self defaultLibraryPath ]
]

{ #category : 'initialization' }
GbsServerInterface >> initialize [
	super initialize.
	libraryPath ifNil: [ libraryPath := self defaultLibraryPath ]
]

{ #category : 'private' }
GbsServerInterface >> defaultLibraryPath [
	| os |
	os := OSPlatform current.
	os isMacOS ifTrue: [ ^ GbsLibrary macLibraryName ].
	os isUnix ifTrue: [ ^ GbsLibrary unixLibraryName ].
	os isWindows ifTrue: [ ^ GbsLibrary win32LibraryName ].
	^ nil
]

{ #category : 'accessing' }
GbsServerInterface >> libraryPath [
	^ libraryPath
]

{ #category : 'accessing' }
GbsServerInterface >> libraryPath: aString [
	libraryPath := aString
]

{ #category : 'api' }
GbsServerInterface >> apiGciInit [
	^ self ffiCall: #(int GciInit()) module: self ffiLibraryName options: #( + optNonThreaded )
]

{ #category : 'api - login' }
GbsServerInterface >> apiGciLogin: gemService user: userId pass: password [
	^ self ffiCall: #(uint64 GciLogin(void* gemService, void* userId, void* password))
		module: self ffiLibraryName
		options: #(+ optNonThreaded)
]

{ #category : 'api' }
GbsServerInterface >> apiGciSetNet: aStone host: host net: net service: service [
	^ self ffiCall: #(void GciSetNet(void* aStone, void* host, void* net, void* service))
		module: self ffiLibraryName
		options: #( + optNonThreaded )
]

{ #category : 'api - password' }
GbsServerInterface >> apiGciEncrypt: aString into: aBuffer size: aSize [
	^ self ffiCall: #(char* GciEncrypt(char* aString, void* aBuffer, uint64 aSize)) 
		module: self ffiLibraryName
		options: #(+ optNonThreaded)
]

{ #category : 'api' }
GbsServerInterface >> apiGciExecuteStr: source context: contextOop env: env [
	^ self ffiCall: #(uint64 GciExecuteStr_(String source, uint64 contextOop, ushort env))
		module: self ffiLibraryName
		options: #( + optNonThreaded )
]

{ #category : 'api - fetching' }
GbsServerInterface >> apiGciFetchSize: anOop [
	^ self ffiCall: #(int64 GciFetchSize_(uint64 anOop)) 
		module: self ffiLibraryName
		options: #( + optNonThreaded )
]

{ #category : 'api - fetching' }
GbsServerInterface >> apiGciFetchBytes: anOop startingAt: startIndex into: aBuffer size: maxSize [
	^ self ffiCall: #(int64 GciFetchBytes_(uint64 anOop, int64 startIndex, void* aBuffer, int64 maxSize)) 
		module: self ffiLibraryName
		options: #( + optNonThreaded )
]

{ #category : 'api' }
GbsServerInterface >> apiGciErr: aBuffer [
	^ self ffiCall: #(bool GciErr(void *aBuffer))
		module: self ffiLibraryName
		options: #( + optNonThreaded )
]

{ #category : 'api' }
GbsServerInterface >> apiGciLogout [
	^ self ffiCall: #(int GciLogout())
		module: self ffiLibraryName
		options: #( + optNonThreaded )
]

{ #category : 'api' }
GbsServerInterface >> apiGciCommit [
	^ self ffiCall: #(int GciCommit())
		module: self ffiLibraryName
		options: #( + optNonThreaded )
]

{ #category : 'api' }
GbsServerInterface >> apiGciAbort [
	^ self ffiCall: #(int GciAbort())
		module: self ffiLibraryName
		options: #( + optNonThreaded )
]
