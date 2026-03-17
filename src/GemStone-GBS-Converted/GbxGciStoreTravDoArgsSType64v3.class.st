Class {
	#name : 'GbxGciStoreTravDoArgsSType64v3',
	#superclass : 'GbxGciStoreTravDoArgsSType64',
	#instVars : [
	],
	#classVars : [
	],
	#category : 'GemStone-GBS-Converted'
}

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64v3 >> pEnvironmentId: anInteger 
	"The environment ID in which to perform the execution. 0 for normal Smalltalk execution."

	self pArgsRef memberAt: #environmentId put: anInteger

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64v3 >> eEnvironmentId: anInteger 
	"The environment ID in which to perform the execution. 0 for normal Smalltalk execution."

	self eArgsRef memberAt: #environmentId put: anInteger

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64v3 >> pEnvironmentId
	"The environment ID in which to perform the execution. 0 for normal Smalltalk execution."

	^self pArgsRef memberAt: #environmentId

{ #category : 'accessing' }
GbxGciStoreTravDoArgsSType64v3 >> eEnvironmentId
	"The environment ID in which to perform the execution. 0 for normal Smalltalk execution."

	^self eArgsRef memberAt: #environmentId

{ #category : 'initialize-release' }
GbxGciStoreTravDoArgsSType64v3 >> initialize
	"Set things appropriately for initial allocation."

	"Don't know at this point whether we're being used for perform or execute or something else,
	so set the environment to 0 regardless."

	super initialize.
	self
		pEnvironmentId: 0;
		eEnvironmentId: 0.
	^self

