Class {
	#name : 'GbxSocketPollPrimInterfaceFake',
	#superclass : 'Object',
	#instVars : [
		'lastHandle',
		'lastDelay',
		'returnValue',
		'workerSeen'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'initialization' }
GbxSocketPollPrimInterfaceFake >> initialize [
	super initialize.
	returnValue := 1
]

{ #category : 'ffi' }
GbxSocketPollPrimInterfaceFake >> gciPollSocket: socketFd forRead: timeout [
	lastHandle := socketFd.
	lastDelay := timeout.
	workerSeen := TFProcessLocalWorker worker.
	^ returnValue
]

{ #category : 'accessing' }
GbxSocketPollPrimInterfaceFake >> lastDelay [
	^ lastDelay
]

{ #category : 'accessing' }
GbxSocketPollPrimInterfaceFake >> lastHandle [
	^ lastHandle
]

{ #category : 'accessing' }
GbxSocketPollPrimInterfaceFake >> returnValue [
	^ returnValue
]

{ #category : 'accessing' }
GbxSocketPollPrimInterfaceFake >> workerSeen [
	^ workerSeen
]
