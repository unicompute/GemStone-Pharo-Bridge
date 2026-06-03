Class {
	#name : 'CoreGbsReplicationSpecFixture',
	#superclass : 'Object',
	#instVars : [
		'key',
		'value'
	],
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
}

{ #category : 'replication' }
CoreGbsReplicationSpecFixture class >> replicationSpec [
	^ #(
		#(#key #forwarder)
		#(#value #min 2))
]
