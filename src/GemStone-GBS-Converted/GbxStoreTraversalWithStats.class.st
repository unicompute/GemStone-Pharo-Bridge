Class {
	#name : 'GbxStoreTraversalWithStats',
	#superclass : 'GbxStoreTraversal',
	#instVars : [
		'statResource'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxStoreTraversalWithStats >> statResource

	^statResource

{ #category : 'initialize-release' }
GbxStoreTraversalWithStats >> statResource: aSessionStatResource
	
	statResource := aSessionStatResource

{ #category : 'instance creation' }
GbxStoreTraversalWithStats class >> for: aServerInteraction statResource: aStatResource
	
	^(super for: aServerInteraction) statResource: aStatResource

