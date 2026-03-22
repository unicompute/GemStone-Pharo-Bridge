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

{ #category : 'serverInterface interface' }
GbxCPrimInterface >> storeTravDoArgsSTypeClass [
	"Current bridge support targets the 64-bit store-traversal layout used by
	modern GemStone libraries."

	^ GbxGciStoreTravDoArgsSType64v31
]

{ #category : 'serverInterface interface' }
GbxCPrimInterface >> executableBlockClassOop [
	"ExecutableBlock in GS64 v2.x, ExecBlock in GS64 3.x."

	^ GbxKernelPomOop oopNumber: 560
]

{ #category : 'serverInterface interface' }
GbxCPrimInterface >> clampSpecClassOop [
	"ClampSpecification kernel oop for the 64-bit runtimes we target."

	^ GbxKernelPomOop oopNumber: 530
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
GbxCPrimInterface >> gciEncrypt: rawPassword into: outBuffer size: bufferSize [
	^ self
		ffiCall: #(void* GciEncrypt(String rawPassword, void* outBuffer, int64 bufferSize))
		options: #( + optNonThreaded )
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciLoginUsername: gemstoneUsername password: gemstonePassword [
	^ self
		ffiCall: #(int GciLogin(String gemstoneUsername, String gemstonePassword))
		options: #( + optNonThreaded )
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciLoginUsername: gemstoneUsername password: gemstonePassword flags: loginFlags haltOnErr: errNum [
	^ self
		ffiCall: #(uint64 GciLoginEx(void* gemstoneUsername, void* gemstonePassword, int loginFlags, int errNum))
		options: #( + optNonThreaded )
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciSetNetStoneName: StoneName hostUsername: HostUserId hostPassword: HostPassword gemService: GemService [
	^ self
		ffiCall: #(void GciSetNet(void* StoneName, void* HostUserId, void* HostPassword, void* GemService))
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

{ #category : 'procedures' }
GbxCPrimInterface >> gciGetFreeOops: count with: resultOops [
	^ self ffiCall: #(void GciGetFreeOops(int count, void* resultOops))
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciNBGetNotifyHandle [
	^ self ffiCall: #(int GciNbGetNotifyHandle(void))
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciPollSocket: socketFd forRead: timeout [
	"Return 0 if timed out, 1 if ready for read, and -1 on error.
	Run on the UFFI worker thread so the event detector wait does not block the VM."

	^ self ffiCall: #(int _threaded GciPollSocketForRead(int socketFd, int timeout))
]

{ #category : 'non-blocking procedures' }
GbxCPrimInterface >> gciNbEndResultPtrPtr: resultPtrPtr [
	^ self ffiCall: #(int GciNbEnd(void* resultPtrPtr))
]

{ #category : 'non-blocking procedures' }
GbxCPrimInterface >> gciNbMoreTraversalBuffer: travBuff maxSize: travBuffSize [
	"Shed the size argument, which is not needed by the 64-bit GCI entry point."

	^ self ffiCall: #(void GciNbMoreTraversal(void* travBuff))
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciMoreTraversalBuffer: travBuff maxSize: travBuffSize [
	"Shed the size argument, which is not needed by the 64-bit GCI entry point."

	^ (self ffiCall: #(int GciMoreTraversal(void* travBuff))) = 1
]

{ #category : 'non-blocking procedures' }
GbxCPrimInterface >> gciNbStoreTravDoTravRefsnlr: oopsNoLongerReplicated nnr: numNotReplicated ogoc: oopsGcedOnClient ngc: numGced stdArgs: stdArgs ctArgs: ctArgs [
	^ self
		ffiCall:
			#(void GciNbStoreTravDoTravRefs_(void* oopsNoLongerReplicated, int numNotReplicated, void* oopsGcedOnClient, int numGced, void* stdArgs, void* ctArgs))
]

{ #category : 'procedures' }
GbxCPrimInterface >> gciStoreTravDoTravRefsnlr: oopsNoLongerReplicated nnr: numNotReplicated ogoc: oopsGcedOnClient ngc: numGced stdArgs: stdArgs ctArgs: ctArgs [
	^ self
		ffiCall:
			#(int GciStoreTravDoTravRefs_(void* oopsNoLongerReplicated, int numNotReplicated, void* oopsGcedOnClient, int numGced, void* stdArgs, void* ctArgs))
]
