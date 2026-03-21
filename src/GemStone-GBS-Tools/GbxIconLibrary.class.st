Class {
	#name : 'GbxIconLibrary',
	#superclass : 'AlphaBlendedIcons',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'utility' }
GbxIconLibrary class >> addMethod: selector forPng: pathString
[
	"GbxIconLibrary addMethod: #foo forPng: '/home/myname/myIcon.png'.
	Then remember to put it in the proper package, because it's likely in UserClasses"

	self class
		compile: (self methodSourceForPng: pathString selector: selector)
		classified: 'png imports'
		notifying: nil
		environment: Smalltalk
]

{ #category : 'private support' }
GbxIconLibrary class >> methodSourceForPng: pathString selector: selector
[
	| stream |
	stream := WriteStream on: (String new: 200).
	stream
		nextPutAll: selector;
		cr;
		cr;
		nextPutAll: '^self placeholderIcon24'.
	^stream contents
]

{ #category : 'private support' }
GbxIconLibrary class >> placeholderIcon16
[
	^self placeholderIconExtent: 16@16
]

{ #category : 'private support' }
GbxIconLibrary class >> placeholderIcon24
[
	^self placeholderIconExtent: 24@24
]

{ #category : 'private support' }
GbxIconLibrary class >> placeholderIconExtent: anExtent
[
	"VW stored pre-rendered alpha-blended images here. Pharo uses a simpler
	compatibility fallback so these menu/toolbar hooks still answer an icon."

	^Form extent: anExtent depth: 32
]

{ #category : 'png imports' }
GbxIconLibrary class >> abort
[
	^self placeholderIcon24
]

{ #category : 'png imports' }
GbxIconLibrary class >> autoCommit
[
	^self placeholderIcon24
]

{ #category : 'png imports' }
GbxIconLibrary class >> autoCommitImage
[
	^self placeholderIcon24
]

{ #category : 'png imports' }
GbxIconLibrary class >> breakpoint
[
	^self placeholderIcon24
]

{ #category : 'png imports' }
GbxIconLibrary class >> browseMethodImplementors
[
	^self placeholderIcon24
]

{ #category : 'png imports' }
GbxIconLibrary class >> browseSystem
[
	^self placeholderIcon24
]

{ #category : 'png imports' }
GbxIconLibrary class >> commit
[
	^self placeholderIcon24
]

{ #category : 'png imports' }
GbxIconLibrary class >> connectors
[
	^self placeholderIcon24
]

{ #category : 'png imports' }
GbxIconLibrary class >> diamond24
[
	^self placeholderIcon24
]

{ #category : 'png imports' }
GbxIconLibrary class >> findClass
[
	^self placeholderIcon24
]

{ #category : 'png imports' }
GbxIconLibrary class >> findMethod
[
	^self placeholderIcon24
]

{ #category : 'png imports' }
GbxIconLibrary class >> noChanges
[
	^self placeholderIcon16
]

{ #category : 'png imports' }
GbxIconLibrary class >> noChangesGray
[
	^self placeholderIcon16
]

{ #category : 'png imports' }
GbxIconLibrary class >> referenceClass
[
	^self placeholderIcon24
]

{ #category : 'png imports' }
GbxIconLibrary class >> referenceMethod
[
	^self placeholderIcon24
]

{ #category : 'png imports' }
GbxIconLibrary class >> unsavedChanges
[
	^self placeholderIcon16
]
