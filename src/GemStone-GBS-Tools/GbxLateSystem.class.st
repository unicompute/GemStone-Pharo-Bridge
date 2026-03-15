Class {
	#name : 'GbxLateSystem',
	#superclass : 'Object',
	#classVars : [
		'UniqueInstance',
		'finalizationQueue',
		'isFinalizationEnabled'
	],
	#category : 'GemStone-GBS-Tools',
	#package : 'GemStone-GBS-Tools'
}

{ #category : 'instance creation' }
GbxLateSystem class >> initialize [
	UniqueInstance := nil.
	finalizationQueue := SharedQueue new.
	isFinalizationEnabled := true.
]

{ #category : 'instance creation' }
GbxLateSystem class >> reset [
	UniqueInstance := nil.
]

{ #category : 'instance creation' }
GbxLateSystem class >> uniqueInstance [
	^ UniqueInstance ifNil: [ UniqueInstance := self new ]
]

{ #category : 'finalization' }
GbxLateSystem >> finalizeProxy: aProxy [
	"Finalize a proxy when it's garbage collected"
	| oop session |
	
	isFinalizationEnabled ifFalse: [ ^ self ].
	
	aProxy ifNil: [ ^ self ].
	
	"Get the OOP before the proxy is fully finalized"
	oop := aProxy oop.
	session := aProxy session.
	
	(oop isNil or: [ oop <= 20 ]) ifTrue: [ ^ self ]. "Special oops"
	
	"Queue for release"
	finalizationQueue nextPut: { oop. session }.
	
	"Process queue asynchronously"
	self processFinalizationQueue.
]

{ #category : 'finalization' }
GbxLateSystem >> processFinalizationQueue [
	"Process the finalization queue"
	
	[ finalizationQueue isEmpty not ] whileTrue: [
		| entry oop session |
		
		entry := finalizationQueue nextAvailable.
		entry ifNotNil: [
			oop := entry first.
			session := entry second.
			
			"Release the OOP on the server"
			self releaseOop: oop onSession: session.
		].
	].
]

{ #category : 'finalization' }
GbxLateSystem >> releaseOop: anOop onSession: aSession [
	"Release an OOP on the server"
	
	aSession ifNil: [ ^ self ].
	anOop ifNil: [ ^ self ].
	anOop <= 20 ifTrue: [ ^ self ]. "Don't release special oops"
	
	[
		"Call GCI to release the OOP"
		aSession serverInterface
			apiGciReleaseOop: anOop
	] on: Error do: [
		"Silently ignore errors during finalization"
	].
]

{ #category : 'registration' }
GbxLateSystem >> registerProxy: aProxy [
	"Register a proxy for finalization"
	
	WeakArray register: aProxy finalizationAction: [ :proxy |
		self finalizeProxy: proxy.
	].
]

{ #category : 'registration' }
GbxLateSystem >> unregisterProxy: aProxy [
	"Unregister a proxy from finalization"
	
	WeakArray unregister: aProxy.
]

{ #category : 'accessing' }
GbxLateSystem >> isFinalizationEnabled [
	^ isFinalizationEnabled
]

{ #category : 'accessing' }
GbxLateSystem >> isFinalizationEnabled: aBoolean [
	isFinalizationEnabled := aBoolean.
]

{ #category : 'accessing' }
GbxLateSystem >> finalizationQueueSize [
	^ finalizationQueue size
]

{ #category : 'cleanup' }
GbxLateSystem >> flushFinalizationQueue [
	"Flush all pending finalizations"
	
	[ finalizationQueue isEmpty not ] whileTrue: [
		self processFinalizationQueue.
		(Delay forMilliseconds: 10) wait.
	].
]

{ #category : 'cleanup' }
GbxLateSystem >> shutdown [
	"Shutdown the late system"
	
	isFinalizationEnabled := false.
	self flushFinalizationQueue.
	UniqueInstance := nil.
]
