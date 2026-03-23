Class {
	#name : 'OSHandle',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
OSHandle class >> currentProcessID [
	^ OSPlatform current processID
]

{ #category : 'accessing' }
OSHandle class >> currentPlatformID [
	^ OSPlatform current name
]
