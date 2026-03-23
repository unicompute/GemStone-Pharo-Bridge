Class {
	#name : 'SocketAccessor',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
SocketAccessor class >> getHostname [
	^ NetNameResolver localHostName
]
