Class {
	#name : 'GbxAdminToolsBrain',
	#superclass : 'GbxBrain',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Tools'
}

{ #category : 'private' }
GbxAdminToolsBrain >> addSessionInfoTo: aStream
	" Add some info about the session for this tool to aStream. "

	super addSessionInfoTo: aStream.
	GbxClipboardObj isEmpty ifFalse: [
		aStream
			cr ;
			cr ;
			nextPutAll: 'The first Clipboard object''s session is:' ;
			cr ;
			nextPutAll: '    ' ;
			nextPutAll: GbxClipboardObj firstClipboardSession printString ;
			nextPut: $..
	].

