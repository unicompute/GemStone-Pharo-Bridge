Class {
	#name : #'GbxSpecialOop',
	#superclass : #'GbxKernelOop',
	#instVars : [ #'clientSpecial' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'comparing' }
GbxSpecialOop >> hash
	^clientSpecial hash

{ #category : #'accessing' }
GbxSpecialOop >> clientSpecial: anObject
	clientSpecial := anObject

{ #category : #'printing' }
GbxSpecialOop >> printOn: aStream

	super printOn: aStream.
	aStream
		nextPutAll: '(';
		print: clientSpecial;
		nextPutAll: ')'

{ #category : #'converting' }
GbxSpecialOop >> asGSObjectInSession: aSession 
	^clientSpecial asGSObjectInSession: aSession

{ #category : #'converting' }
GbxSpecialOop >> asKernelPomOop
	"and thouest says that it is not permitted to represent server specials as pom oops"

	^self error: 'You cannot treat a special like a POM oop'

{ #category : #'gemstone private' }
GbxSpecialOop >> gbxExistingOrSpecialDelegateInSession: aSession

	^clientSpecial gbxExistingOrSpecialDelegateInSession: aSession

{ #category : #'class initialization' }
GbxSpecialOop class >> initialize
	"GbxSpecialOop initialize"

	ONil := Onil := self for: nil.
	OTrue := Otrue := self for: true.
	OFalse := Ofalse := self for: false.
	Zero := self for: 0

{ #category : #'instance creation' }
GbxSpecialOop class >> for: aClientSpecial 
	^self new clientSpecial: aClientSpecial

