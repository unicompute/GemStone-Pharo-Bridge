Class {
	#name : 'GbxFetchTraversalWithStats',
	#superclass : 'GbxFetchTraversal',
	#instVars : [
		'statResource'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxFetchTraversalWithStats class >> for: aServerInteraction statResource: aStatResource [

	
	^(super for: aServerInteraction) statResource: aStatResource
]

{ #category : 'accessing' }
GbxFetchTraversalWithStats >> statResource [


	^statResource
]

{ #category : 'initialize-release' }
GbxFetchTraversalWithStats >> statResource: aSessionStatResource [

	
	statResource := aSessionStatResource
]
