Class {
	#name : 'CoreGbsFaultLifecycleFixture',
	#superclass : 'Object',
	#instVars : [
		'events',
		'payload'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'replication' }
CoreGbsFaultLifecycleFixture class >> freeSlotsOnStubbing [
	^ false
]

{ #category : 'accessing' }
CoreGbsFaultLifecycleFixture >> events [
	^ events ifNil: [ events := OrderedCollection new ]
]

{ #category : 'accessing' }
CoreGbsFaultLifecycleFixture >> payload [
	^ payload
]

{ #category : 'accessing' }
CoreGbsFaultLifecycleFixture >> payload: anObject [
	payload := anObject
]

{ #category : 'faulting' }
CoreGbsFaultLifecycleFixture >> postFaultInSession: aSession [
	self events add: #postFault.
	^ self
]

{ #category : 'faulting' }
CoreGbsFaultLifecycleFixture >> preFault [
	self events add: #preFault.
	^ self
]
