Extension { #name : 'GBSM' }

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> maglev [
	^ self requireCurrentSession maglev
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> maglevPersistentRoot [
	^ self requireCurrentSession maglevPersistentRoot
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> transactionLevel [
	^ self requireCurrentSession transactionLevel
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> commitAndReleaseLocks [
	^ self requireCurrentSession commitAndReleaseLocks
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> sessionCount [
	^ self requireCurrentSession sessionCount
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> sessionId [
	^ self requireCurrentSession sessionId
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> sharedCounterAt: anIndex [
	^ self requireCurrentSession sharedCounterAt: anIndex
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> sharedCounterAt: anIndex put: anInteger [
	^ self requireCurrentSession
		sharedCounterAt: anIndex
		put: anInteger
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> incrementSharedCounterAt: anIndex by: anInteger [
	^ self requireCurrentSession
		incrementSharedCounterAt: anIndex
		by: anInteger
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> decrementSharedCounterAt: anIndex by: anInteger [
	^ self requireCurrentSession
		decrementSharedCounterAt: anIndex
		by: anInteger
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> objectLog [
	^ self requireCurrentSession objectLog
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> procObjectFor: anObject [
	^ self requireCurrentSession procObjectFor: anObject
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> procObjectForOop: anOop [
	^ self requireCurrentSession procObjectForOop: anOop
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> bindingObjectForProc: anObject [
	^ self requireCurrentSession bindingObjectForProc: anObject
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> bindingObjectForProcOop: anOop [
	^ self requireCurrentSession bindingObjectForProcOop: anOop
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> execBlockObjectFor: anObject [
	^ self requireCurrentSession execBlockObjectFor: anObject
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> execBlockObjectForOop: anOop [
	^ self requireCurrentSession execBlockObjectForOop: anOop
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> rubyLoadPath [
	^ self requireCurrentSession rubyLoadPath
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> rubyLoadedFeatures [
	^ self requireCurrentSession rubyLoadedFeatures
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> rubyPersistentLoadedFeatures [
	^ self requireCurrentSession rubyPersistentLoadedFeatures
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> sessionMethods [
	^ self requireCurrentSession sessionMethods
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> rubyRequireFileNamed: aString [
	^ self requireCurrentSession rubyRequireFileNamed: aString
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> rubyLoadFileNamed: aString [
	^ self requireCurrentSession rubyLoadFileNamed: aString
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> rubyRequireRelativeFileNamed: aString relativeTo: aBasePath [
	^ self requireCurrentSession
		rubyRequireRelativeFileNamed: aString
		relativeTo: aBasePath
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> rubyLoadRelativeFileNamed: aString relativeTo: aBasePath [
	^ self requireCurrentSession
		rubyLoadRelativeFileNamed: aString
		relativeTo: aBasePath
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> clearPersistentRubyLoadedFeatures [
	^ self requireCurrentSession clearPersistentRubyLoadedFeatures
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> rubyRuntime [
	^ self requireCurrentSession rubyRuntime
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> rubyRuntimeReport [
	^ self requireCurrentSession rubyRuntimeReport
]

{ #category : '*GemStone-GBS-MagLev' }
GBSM class >> maglevFinalizerRegistry [
	^ self requireCurrentSession maglevFinalizerRegistry
]
