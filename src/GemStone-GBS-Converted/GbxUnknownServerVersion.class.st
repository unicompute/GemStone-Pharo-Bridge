Class {
	#name : #'GbxUnknownServerVersion',
	#superclass : #'GbxServerVersion',
	#instVars : [  ],
	#classVars : [  ],
	#category : #'GemStone-GBS-Converted'
}

{ #category : #'comparing' }
GbxUnknownServerVersion >> > aStringOrServerVersion 
	^false

{ #category : #'comparing' }
GbxUnknownServerVersion >> < aStringOrServerVersion 
	^false

{ #category : #'comparing' }
GbxUnknownServerVersion >> hash
	"I'm never equal to anything, and have no significant state except my class, so answer my identity hash.
	A constant would also be legal, but this way if multiple instances of this class end up in the same hash table
	at least they won't *all* collide."
	
	^ self identityHash

{ #category : #'comparing' }
GbxUnknownServerVersion >> = aStringOrServerVersion 
	^false

{ #category : #'testing' }
GbxUnknownServerVersion >> isUnknown
	"Answer true if the server version cannot be determined."

	^true

{ #category : #'printing' }
GbxUnknownServerVersion >> printOn: aStream 
	aStream nextPutAll: 'Unknown server product and version'

{ #category : #'private' }
GbxUnknownServerVersion >> componentSize
	"If compared with another ServerVersion, avoid 
	trying to compare components that aren't there."

	^0

