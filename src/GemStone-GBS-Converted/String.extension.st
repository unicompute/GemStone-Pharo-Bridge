Extension { #name : 'String' }

{ #category : '*GemStone-GBS-Converted' }
String >> asGemStoneUTF8Bytes [
	"Serialize both ByteString and WideString instances to the UTF-8 bytes
	expected by the GemStone bridge."
	^ self utf8Encoded asByteArray
]
