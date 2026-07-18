Class {
	#name : 'GbsNonblockingTimeoutError',
	#superclass : 'Error',
	#instVars : [
		'elapsedMilliseconds',
		'timeoutMilliseconds'
	],
	#category : 'GemStone-GBS-ThreadSafe',
	#package : 'GemStone-GBS-ThreadSafe'
}

{ #category : 'signalling' }
GbsNonblockingTimeoutError class >> signalAfterMilliseconds: elapsedMs timeoutMilliseconds: timeoutMs [
	^ self new
		elapsedMilliseconds: elapsedMs;
		timeoutMilliseconds: timeoutMs;
		signal: 'nonblocking GCI call timeout after ', elapsedMs printString,
			'ms (budget ', timeoutMs printString, 'ms); session terminated'
]

{ #category : 'accessing' }
GbsNonblockingTimeoutError >> elapsedMilliseconds [
	^ elapsedMilliseconds
]

{ #category : 'accessing' }
GbsNonblockingTimeoutError >> elapsedMilliseconds: anInteger [
	elapsedMilliseconds := anInteger
]

{ #category : 'accessing' }
GbsNonblockingTimeoutError >> timeoutMilliseconds [
	^ timeoutMilliseconds
]

{ #category : 'accessing' }
GbsNonblockingTimeoutError >> timeoutMilliseconds: anInteger [
	timeoutMilliseconds := anInteger
]
