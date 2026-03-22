Class {
	#name : 'Unicode7',
	#superclass : 'ByteString',
	#type : 'bytes',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Bootstrap',
	#package : 'GemStone-GBS-Bootstrap'
}

{ #category : 'converting' }
Unicode7 >> asFourByteString
[
	^ self asWideString
]

{ #category : 'converting' }
Unicode7 >> asTwoByteString
[
	^ self asWideString
]
