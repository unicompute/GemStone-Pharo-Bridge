Class {
	#name : 'GbxCPrimInterface',
	#superclass : 'FFILibrary',
	#instVars : [
		'currentSessionId'
	],
	#classVars : [
		'CIntegerType',
		'CPointerType',
		'ErrorCode',
		'ExternalLibrary',
		'ExternalLibraryHolder',
		'ExternalMethod',
		'UninterpretedBytes',
		'VMLibPath'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'constants' }
GbxCPrimInterface class >> loadFailedSignals [
	^ Error
]

{ #category : 'libraries' }
GbxCPrimInterface class >> vmLibPath: aString [
	VMLibPath := aString.
	^ self
]

{ #category : 'libraries' }
GbxCPrimInterface class >> sharedLibraryFilename [
	^ VMLibPath ifNil: [ GbsConfiguration sharedLibraryFilename ]
]

{ #category : 'instance creation' }
GbxCPrimInterface class >> newInterface: libraryFilename [
	self vmLibPath: libraryFilename.
	^ self uniqueInstance
]

{ #category : 'accessing - platform' }
GbxCPrimInterface >> macLibraryName [
	^ self class sharedLibraryFilename
]

{ #category : 'accessing - platform' }
GbxCPrimInterface >> unixLibraryName [
	^ self class sharedLibraryFilename
]

{ #category : 'accessing - platform' }
GbxCPrimInterface >> win32LibraryName [
	^ self class sharedLibraryFilename
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciVersion [
	^[ 'GCI-' , (self ffiCall: #(String GciVersion(void))) ]
		on: Error
		do: [ :ex | ex return: 'GCI version is not available' ]
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciProduct [
	^[ self ffiCall: #(uchar GciProduct(void)) ]
		on: Error
		do: [ :ex | ex return: 0 ]
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciInit [
	| result |
	result := self ffiCall: #(int GciInit(void)) options: #( + optNonThreaded ).
	^ result = 1
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciInitAppName: appName logWarnings: logWarnings [
	^ self
		ffiCall: #(void GciInitAppName(String appName, bool logWarnings))
		options: #( + optNonThreaded )
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciSetCacheName: cacheName [
	^ self
		ffiCall: #(int GciSetCacheName_(String cacheName))
		options: #( + optNonThreaded )
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciEnableFullCompression [
	^ self ffiCall: #(void GciEnableFullCompression(void))
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciSetSessionId: sessionId [
	"Any sender of this message must be holding GciCallProtect."

	^ sessionId ~= currentSessionId
		ifTrue: [
			currentSessionId := sessionId.
			self ffiCall: #(void GciSetSessionId(uint64 sessionId)) ]
		ifFalse: [ nil ]
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciGetSessionId [
	^ currentSessionId := self ffiCall: #(uint64 GciGetSessionId(void))
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciErr: errorReport [
	^ self
		ffiCall: #(bool GciErr(void* errorReport))
		options: #( + optNonThreaded )
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciIsRemote [
	^ (self ffiCall: #(int GciIsRemote(void))) = 1
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciSessionIsRemote [
	^ (self ffiCall: #(int GciSessionIsRemote(void))) = 1
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciGetSignalHandle [
	^ self ffiCall: #(int GciGetSignalHandle(void))
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciFloatKind: aReal [
	^ self ffiCall: #(int GciFloatKind(double aReal))
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciGemTrace: anInt [
	^ self ffiCall: #(void GciGemTrace(int anInt))
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciLoginUsername: gemstoneUsername password: gemstonePassword flags: loginFlags haltOnErr: errNum [
	^ self
		ffiCall: #(int GciLoginEx(String gemstoneUsername, String gemstonePassword, uint32 loginFlags, int errNum))
		options: #( + optNonThreaded )
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciSetNetStoneName: StoneName hostUsername: HostUserId hostPassword: HostPassword gemService: GemService [
	^ self
		ffiCall: #(void GciSetNet(String StoneName, String HostUserId, String HostPassword, String GemService))
		options: #( + optNonThreaded )
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciLogout [
	^ self ffiCall: #(void GciLogout(void))
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciSoftBreak [
	^ self ffiCall: #(void GciSoftBreak(void))
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciPollForSignal [
	^ (self ffiCall: #(int GciPollForSignal(void)) options: #( + optNonThreaded )) = 1
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciHardBreak [
	^ self ffiCall: #(void GciHardBreak(void))
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciDirtyObjsInit [
	^ self ffiCall: #(void GciDirtyObjsInit(void))
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciObjExists: obj [
	^ (self ffiCall: #(int GciObjExists(uint64 obj))) = 1
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciSaveObjs: theOops with: numOops [
	^ self ffiCall: #(void GciSaveObjs(void* theOops, uint32 numOops))
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciFetchClass: theObject [
	^ self ffiCall: #(uint64 GciFetchClass(uint64 theObject))
]
