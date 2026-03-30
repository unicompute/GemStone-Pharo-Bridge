Class {
	#name : 'GbxOverrideFixture',
	#superclass : 'Object',
	#instVars : [
		'oldVar'
	],
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'defaults' }
GbxOverrideFixture class >> restoreDefaultDefinition [
	Smalltalk classInstaller make: [ :builder |
		builder
			superclass: Object;
			name: #GbxOverrideFixture;
			slots: { #oldVar };
			package: 'GemStone-Pharo-Tests' ].
	self compile: 'value
	^ 1' classified: 'defaults'
]

{ #category : 'defaults' }
GbxOverrideFixture >> value [
	^ 1
]
