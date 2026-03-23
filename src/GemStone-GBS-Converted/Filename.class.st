Class {
	#name : 'Filename',
	#superclass : 'Object',
	#category : 'GemStone-GBS-Converted',
	#package : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
Filename class >> named: filename [
	^ filename asFileReference
]

{ #category : 'accessing' }
Filename class >> currentDirectory [
	^ FileLocator workingDirectory
]
