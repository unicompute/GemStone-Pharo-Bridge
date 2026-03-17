Class {
	#name : 'GbxDeferredAssignment',
	#superclass : 'Object',
	#instVars : [
		'clientOffset',
		'delegate',
		'buffer'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxDeferredAssignment >> delegate: aDelegate
	delegate := aDelegate

{ #category : 'accessing' }
GbxDeferredAssignment >> buffer: anObject
	buffer := anObject

{ #category : 'accessing' }
GbxDeferredAssignment >> clientOffset: anObject
	clientOffset := anObject

{ #category : 'resolving' }
GbxDeferredAssignment >> assignValue: val 
	^self subclassResponsibility

{ #category : 'resolving' }
GbxDeferredAssignment >> resolveIn: sess
	"Sender must hold the session's sessionProtect"

	| val |
	val := sess lookupOop: delegate.
	val == NotCachedToken
		ifTrue: 
			["There was no report anywhere in the traversal, so make a stub. 
					There are no longer any known valid ways to take this path."
			val := GbxUnknownStub new.
			sess privateConnectNewClient: val toServer: delegate].
	self assignValue: val

{ #category : 'instance creation' }
GbxDeferredAssignment class >> offset: clientOffset delegate: aDelegate buffer: aBuffer 
	^(self new)
		clientOffset: clientOffset;
		delegate: aDelegate;
		buffer: aBuffer

