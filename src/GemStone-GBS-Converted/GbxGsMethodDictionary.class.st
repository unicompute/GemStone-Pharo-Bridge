Class {
	#name : 'GbxGsMethodDictionary',
	#superclass : 'IdentityDictionary',
	#instVars : [
		'valueConstraint',
		'keyConstraint'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxGsMethodDictionary >> valueConstraint

	^valueConstraint

{ #category : 'accessing' }
GbxGsMethodDictionary >> keyConstraint

	^keyConstraint

{ #category : 'accessing' }
GbxGsMethodDictionary >> removeKeyIfPresent: aClientClass

	self
		removeKey: aClientClass ifAbsent: [^nil];
		markDirty

{ #category : 'accessing' }
GbxGsMethodDictionary >> at: aClientClass put: levelsArray

	super at: aClientClass put: levelsArray.
	self markDirty

{ #category : 'copying' }
GbxGsMethodDictionary >> copyEmpty

	^self class new

{ #category : 'initialize-release' }
GbxGsMethodDictionary >> initialize

	keyConstraint := Class.
	valueConstraint := Array

{ #category : 'instance creation' }
GbxGsMethodDictionary class >> new

	^super new initialize

