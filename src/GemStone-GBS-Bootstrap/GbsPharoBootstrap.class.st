Class {
	#name : 'GbsPharoBootstrap',
	#superclass : 'Object',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'bootstrap' }
GbsPharoBootstrap class >> installCompatibilityAliases
[
	Smalltalk at: #TwoByteString put: WideString.
	Smalltalk at: #FourByteString put: WideString.
]
