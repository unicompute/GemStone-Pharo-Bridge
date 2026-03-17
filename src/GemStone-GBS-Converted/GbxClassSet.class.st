Class {
	#name : #'GbxClassSet',
	#superclass : #'IdentitySet',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'adding' }
GbxClassSet >> add: aClass

	super add: aClass.
	self markDirty

{ #category : #'accessing' }
GbxClassSet >> removeIfPresent: aClass

	self remove: aClass ifAbsent: [^nil].
	self markDirty

