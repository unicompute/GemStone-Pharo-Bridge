Class {
	#name : 'GbsTestableThreadSafeReleaseInterface',
	#superclass : 'GbsThreadSafeInterface',
	#instVars : [
		'capturedReleaseOops',
		'releaseCallCount',
		'blockNextRelease',
		'releaseEntered',
		'continueRelease'
	],
	#category : 'GemStone-Pharo-ThreadSafe-Tests',
	#package : 'GemStone-Pharo-ThreadSafe-Tests'
}

{ #category : 'accessing' }
GbsTestableThreadSafeReleaseInterface >> capturedReleaseOops [
	^ capturedReleaseOops
]

{ #category : 'controlling' }
GbsTestableThreadSafeReleaseInterface >> allowBlockedRelease [
	continueRelease signal
]

{ #category : 'controlling' }
GbsTestableThreadSafeReleaseInterface >> blockNextRelease [
	blockNextRelease := true.
	releaseEntered := Semaphore new.
	continueRelease := Semaphore new
]

{ #category : 'private - ffi' }
GbsTestableThreadSafeReleaseInterface >> ffiDo: aBlock [
	^ aBlock value
]

{ #category : 'private - ffi' }
GbsTestableThreadSafeReleaseInterface >> gciTsReleaseObjs: sess objects: objects count: count gsError: gsError [
	releaseCallCount := releaseCallCount + 1.
	capturedReleaseOops := (1 to: count) collect: [ :index |
		objects unsignedLongLongAt: ((index - 1) * 8) + 1 ].
	blockNextRelease ifTrue: [
		blockNextRelease := false.
		releaseEntered signal.
		continueRelease wait ].
	^ 1
]

{ #category : 'initialization' }
GbsTestableThreadSafeReleaseInterface >> initialize [
	super initialize.
	capturedReleaseOops := #().
	releaseCallCount := 0.
	blockNextRelease := false
]

{ #category : 'accessing' }
GbsTestableThreadSafeReleaseInterface >> pendingReleaseOopsCopy [
	^ pendingReleaseOops
		ifNil: [ #() ]
		ifNotNil: [ :oops | oops asArray ]
]

{ #category : 'accessing' }
GbsTestableThreadSafeReleaseInterface >> releaseCallCount [
	^ releaseCallCount
]

{ #category : 'controlling' }
GbsTestableThreadSafeReleaseInterface >> waitUntilReleaseEntered [
	releaseEntered wait
]
