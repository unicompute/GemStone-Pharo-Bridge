Class {
	#name : 'GbxFinalizationLatch',
	#superclass : 'Object',
	#instVars : [
		'accessProtect',
		'blocker',
		'workerIsWaiting',
		'workIsAvailable'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'initialize-release' }
GbxFinalizationLatch >> initialize
	accessProtect := GbxSemaphore forMutualExclusion.
	blocker := GbxSemaphore new.
	workIsAvailable := false.
	workerIsWaiting := false

{ #category : 'accessing' }
GbxFinalizationLatch >> waitForWork
	| mustWait |
	accessProtect critical: 
			[[workerIsWaiting] gbxAssertEquals: false.	"If I were waiting, I wouldn't be here..."
			mustWait := workIsAvailable not.
			mustWait 
				ifTrue: [workerIsWaiting := true]
				ifFalse: 
					[workIsAvailable := false.
					workerIsWaiting := false	"Not needed. Bullet-proofing."]].
	"Cannot wait on blocker while holding accessProtect. 
	Must decide whether to wait *inside* the critical block, and actually wait *outside*."
	mustWait ifTrue: [blocker wait]

{ #category : 'accessing' }
GbxFinalizationLatch >> needFinalization
	accessProtect critical: 
			[workerIsWaiting 
				ifTrue: 
					[workerIsWaiting := false.
					blocker signal]
				ifFalse: [workIsAvailable := true]]

{ #category : 'instance creation' }
GbxFinalizationLatch class >> new
	^super new initialize

