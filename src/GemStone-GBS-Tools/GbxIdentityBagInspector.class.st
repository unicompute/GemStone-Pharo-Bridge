Class {
	#name : #'GbxIdentityBagInspector',
	#superclass : #'GbxArrayInspector',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Tools'
}

{ #category : #'private' }
GbxIdentityBagInspector >> refresh
	"refresh the remote IdentityBag values, then refresh the gui"

	object refreshIdentityBag.
	super refresh

{ #category : #'actions' }
GbxIdentityBagInspector >> removeSelected
	"GBS: make sure we refresh the collection afterwards"

	self gbxFixMe.	"gemstone undo's not supported yet"
	self selections do: 
			[:sel |
			object delegate unsynchronizedPerform: #remove:
				with: (sel valueDelegate delegate "dig into the wrapper to get the object")].
	self refresh

{ #category : #'actions' }
GbxIdentityBagInspector >> gbxCacheInterval: anInterval 
	object cacheIdentityBagInterval: anInterval

{ #category : #'initialize-release' }
GbxIdentityBagInspector >> initialize: anObject 
	undoHistory := OrderedCollection new.
	object := anObject.
	object refreshIdentityBag.
	self refresh

