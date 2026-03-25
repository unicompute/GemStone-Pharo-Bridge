Class {
	#name : 'GbxStoreTraversalWithStats',
	#superclass : 'GbxStoreTraversal',
	#instVars : [
		'statResource'
	],
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'instance creation' }
GbxStoreTraversalWithStats class >> for: aServerInteraction statResource: aStatResource [

	
	^(super for: aServerInteraction) statResource: aStatResource
]

{ #category : 'accessing' }
GbxStoreTraversalWithStats >> statResource [


	^statResource
]

{ #category : 'initialize-release' }
GbxStoreTraversalWithStats >> statResource: aSessionStatResource [

	
	statResource := aSessionStatResource
]
