Class {
	#name : 'GbxOverrideEdit',
	#superclass : 'GbxOverride',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'applying' }
GbxOverrideEdit >> applyFrom: inputStream to: outputStream [
	self subclassResponsibility
]

{ #category : 'accessing' }
GbxOverrideEdit >> count [
	self subclassResponsibility
]

{ #category : 'comparing' }
GbxOverrideEdit >> = anObject [
	self subclassResponsibility
]

{ #category : 'comparing' }
GbxOverrideEdit >> hash [
	self subclassResponsibility
]

{ #category : 'printing' }
GbxOverrideEdit >> printOn: aStream [
	aStream
		nextPutAll: self class name;
		nextPut: $(;
		print: self count;
		nextPut: $)
]
