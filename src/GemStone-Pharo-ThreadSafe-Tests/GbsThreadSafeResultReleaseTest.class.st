Class {
	#name : 'GbsThreadSafeResultReleaseTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-ThreadSafe-Tests',
	#package : 'GemStone-Pharo-ThreadSafe-Tests'
}

{ #category : 'tests' }
GbsThreadSafeResultReleaseTest >> testFlushPreservesFullWidthOopValues [
	| interface oops |
	interface := GbsTestableThreadSafeReleaseInterface new.
	oops := #(16r123456789ABCDEF0 16r1FFFFFFFFFFFFFFF).
	oops do: [ :oop | interface queueResultOopForRelease: oop ].

	self assert: interface releaseCallCount equals: 0.
	self assert: interface pendingReleaseOopsCopy equals: oops.
	self assert: interface flushPendingResultOops.
	self assert: interface releaseCallCount equals: 1.
	self assert: interface capturedReleaseOops equals: oops.
	self assert: interface pendingReleaseOopsCopy isEmpty
]

{ #category : 'tests' }
GbsThreadSafeResultReleaseTest >> testQueueFlushesExactlyAtConfiguredBatchSize [
	| interface batchSize expected |
	interface := GbsTestableThreadSafeReleaseInterface new.
	batchSize := interface class resultOopReleaseBatchSize.
	expected := (1 to: batchSize) collect: [ :index | index * 8 ].

	1 to: batchSize - 1 do: [ :index |
		interface queueResultOopForRelease: (expected at: index) ].
	self assert: interface releaseCallCount equals: 0.
	self assert: interface pendingReleaseOopsCopy size equals: batchSize - 1.

	interface queueResultOopForRelease: expected last.
	self assert: interface releaseCallCount equals: 1.
	self assert: interface capturedReleaseOops equals: expected.
	self assert: interface pendingReleaseOopsCopy isEmpty
]

{ #category : 'tests' }
GbsThreadSafeResultReleaseTest >> testQueueDoesNotLoseOopAddedAcrossReleaseYield [
	| interface batchSize expected firstReleaseDone lateQueueStarted lateQueueDone lateOop |
	interface := GbsTestableThreadSafeReleaseInterface new.
	interface blockNextRelease.
	batchSize := interface class resultOopReleaseBatchSize.
	expected := (1 to: batchSize) collect: [ :index | index * 8 ].
	lateOop := 16r123456789ABCDEF0.
	firstReleaseDone := Semaphore new.
	lateQueueStarted := Semaphore new.
	lateQueueDone := Semaphore new.

	[
		expected do: [ :oop | interface queueResultOopForRelease: oop ].
		firstReleaseDone signal ] fork.
	interface waitUntilReleaseEntered.
	[
		lateQueueStarted signal.
		interface queueResultOopForRelease: lateOop.
		lateQueueDone signal ] fork.
	lateQueueStarted wait.
	(Delay forMilliseconds: 50) wait.
	interface allowBlockedRelease.
	firstReleaseDone wait.
	lateQueueDone wait.

	self assert: interface releaseCallCount equals: 1.
	self assert: interface capturedReleaseOops equals: expected.
	self assert: interface pendingReleaseOopsCopy equals: { lateOop }
]
