Class {
	#name : 'GbxRBScanner',
	#superclass : 'RBScanner',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'accessing' }
GbxRBScanner class >> classificationTable
[

	| ct |
	ct := super classificationTable.
	ct at: ${ asInteger put: #special.
	ct at: $} asInteger put: #special.
	^ct
]

