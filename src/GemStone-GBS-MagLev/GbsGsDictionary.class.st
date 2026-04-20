Class {
	#name : 'GbsGsDictionary',
	#superclass : 'GbsRcHash',
	#category : 'GemStone-GBS-MagLev',
	#package : 'GemStone-GBS-MagLev'
}

{ #category : 'printing' }
GbsGsDictionary >> displayString [
	^ 'GsDict(size=', self size printString, ')'
]

{ #category : 'printing' }
GbsGsDictionary >> printOn: aStream [
	aStream nextPutAll: self displayString
]
