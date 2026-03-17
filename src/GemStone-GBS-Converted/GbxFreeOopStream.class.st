Class {
	#name : #'GbxFreeOopStream',
	#superclass : #'Object',
	#instVars : [ #'session' #'cache' #'position' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'accessing' }
GbxFreeOopStream >> nextFreeOop
	"Answer a delegate for a free oop. Fetch more from the server if necessary."

	| freeOop |
	position > cache size 
		ifTrue: 
			[cache := session getFreeOops: 2000.
			position := 1].
	freeOop := cache at: position.
	"Don't want the free oop to keep the delegate from being GC'ed"
	cache at: position put: nil.
	position := position + 1.
	^freeOop

{ #category : #'private-accessing' }
GbxFreeOopStream >> session: aSession 
	session := aSession

{ #category : #'initialize-release' }
GbxFreeOopStream >> initialize
	"Set position to just past the end of the initial cache, so the first #next will have to fetch oops."

	cache := #().
	position := 1

{ #category : #'instance creation' }
GbxFreeOopStream class >> for: aSession 
	^self new session: aSession

{ #category : #'instance creation' }
GbxFreeOopStream class >> new
	^super new initialize

