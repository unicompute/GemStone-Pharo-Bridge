Class {
	#name : #'GbxFetchTraversalWithStats',
	#superclass : #'GbxFetchTraversal',
	#instVars : [ #'statResource' ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'accessing' }
GbxFetchTraversalWithStats >> statResource

	^statResource

{ #category : #'initialize-release' }
GbxFetchTraversalWithStats >> statResource: aSessionStatResource
	
	statResource := aSessionStatResource

{ #category : #'instance creation' }
GbxFetchTraversalWithStats class >> for: aServerInteraction statResource: aStatResource
	
	^(super for: aServerInteraction) statResource: aStatResource

