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
CoreGbsReplicationSpecFixture class >> callbackReplicationSpec [
	^ #callback
]

{ #category : 'replication' }
CoreGbsReplicationSpecFixture class >> customerReplicationSpec [
	^ #(
		#(#key #stub)
		#(#value #forwarder))
]

{ #category : 'replication' }
CoreGbsReplicationSpecFixture class >> replicationSpec [
	^ #(
		#(#key #forwarder)
		#(#value #min 2))
]
