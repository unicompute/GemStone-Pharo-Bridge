Class {
	#name : 'GbxMappingList',
	#superclass : 'Object',
	#instVars : [
		'coll'
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'enumerating' }
GbxMappingList >> delegatesAndClientObjsDo: block

	1 to: coll size
		by: 2
		do: [:i | block value: (coll at: i) value: (coll at: i + 1)]

{ #category : 'accessing' }
GbxMappingList >> addDelegate: del clientObj: clientObj

	coll
		add: del;
		add: clientObj

{ #category : 'initialize-release' }
GbxMappingList >> initialize

	coll := OrderedCollection new

{ #category : 'instance creation' }
GbxMappingList class >> new

	^self basicNew initialize

