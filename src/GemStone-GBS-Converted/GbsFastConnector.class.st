"
Connects a client object directly to a server object by identity, bypassing name lookup. Mirrors
VisualWorks GbsFastConnector: it holds the client object (clientObj) and the server object's kernel OOP
(serverKernelOop) directly, which is fast but fragile -- if the server object is renamed/reassigned the
connector keeps pointing at the old identity. Prefer named connectors unless object identity is stable.
"
Class {
	#name : 'GbsFastConnector',
	#superclass : 'GbsConnector',
	#instVars : [
		'clientObj',
		'serverKernelOop'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbsFastConnector class >> stObj: anObject gsObj: aServerOopOrObject [
	^ self new
		stObj: anObject gsObj: aServerOopOrObject;
		yourself
]

{ #category : 'accessing' }
GbsFastConnector >> clientObj [
	^ clientObj
]

{ #category : 'accessing' }
GbsFastConnector >> clientObj: anObject [
	clientObj := anObject
]

{ #category : 'accessing' }
GbsFastConnector >> serverKernelOop [
	^ serverKernelOop
]

{ #category : 'accessing' }
GbsFastConnector >> serverKernelOop: anOop [
	serverKernelOop := anOop
]

{ #category : 'initialization' }
GbsFastConnector >> stObj: anObject gsObj: aServerOopOrObject [
	"Bind the client object and the server object's OOP directly. aServerOopOrObject may be a raw OOP
	integer or an object answering #oop."
	clientObj := anObject.
	serverKernelOop := (aServerOopOrObject isInteger)
		ifTrue: [ aServerOopOrObject ]
		ifFalse: [
			((aServerOopOrObject respondsTo: #oop) and: [ aServerOopOrObject oop notNil ])
				ifTrue: [ aServerOopOrObject oop ]
				ifFalse: [ aServerOopOrObject ] ].
	^ self
]

{ #category : 'printing' }
GbsFastConnector >> clientObjDescription [
	^ self clientObj printString, ' -> oop ', self serverKernelOop printString
]

{ #category : 'printing' }
GbsFastConnector >> gsDescription [
	^ 'oop ', self serverKernelOop printString
]

{ #category : 'printing' }
GbsFastConnector >> stDescription [
	^ self clientObj printString
]

{ #category : 'printing' }
GbsFastConnector >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: ' for '; nextPutAll: self clientObjDescription
]
