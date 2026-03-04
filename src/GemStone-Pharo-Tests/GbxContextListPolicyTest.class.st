Class {
	#name : 'GbxContextListPolicyTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Tests',
	#package : 'GemStone-Pharo-Tests'
}

{ #category : 'tests' }
GbxContextListPolicyTest >> testFirstClientContextAboveReturnsNearestNonGlueContext [
	| debugger policy gsContext gsError topClient glueMarker bottomClient |

	debugger := GbxFakeDebuggerForPolicy new.
	policy := GbxTestableContextListPolicy debugger: debugger.

	gsContext := GbxFakeContextForPolicy new.
	gsContext
		gbxIsServerContext: true;
		processOop: 42.

	gsError := GbxFakeGbsErrorForPolicy new.
	gsError serverProcessOop: 42.

	bottomClient := GbxFakeContextForPolicy new.
	bottomClient isGlue: false.

	glueMarker := GbxFakeContextForPolicy new.
	glueMarker
		isGlue: true;
		receiver: gsError;
		sender: bottomClient.

	topClient := GbxFakeContextForPolicy new.
	topClient
		isGlue: false;
		sender: glueMarker.

	debugger topContext: topClient.

	self assert: (policy firstClientContextAbove: gsContext) == topClient
]

{ #category : 'tests' }
GbxContextListPolicyTest >> testFirstClientContextAboveReturnsNilWithoutMatchingMarker [
	| debugger policy gsContext gsError topClient glueMarker |

	debugger := GbxFakeDebuggerForPolicy new.
	policy := GbxTestableContextListPolicy debugger: debugger.

	gsContext := GbxFakeContextForPolicy new.
	gsContext
		gbxIsServerContext: true;
		processOop: 99.

	gsError := GbxFakeGbsErrorForPolicy new.
	gsError serverProcessOop: 42.

	glueMarker := GbxFakeContextForPolicy new.
	glueMarker
		isGlue: true;
		receiver: gsError.

	topClient := GbxFakeContextForPolicy new.
	topClient
		isGlue: false;
		sender: glueMarker.

	debugger topContext: topClient.

	self assert: (policy firstClientContextAbove: gsContext) isNil
]

{ #category : 'tests' }
GbxContextListPolicyTest >> testComputeContextListMergesServerAndClientContexts [
	| debugger policy gsContext gsError topClient glueMarker bottomClient list |

	debugger := GbxFakeDebuggerForPolicy new.
	policy := GbxTestableContextListPolicy debugger: debugger.

	gsContext := GbxFakeContextForPolicy new.
	gsContext
		gbxIsServerContext: true;
		processOop: 7.
	policy serverContexts: { gsContext }.

	gsError := GbxFakeGbsErrorForPolicy new.
	gsError serverProcessOop: 7.

	bottomClient := GbxFakeContextForPolicy new.
	bottomClient isGlue: false.

	glueMarker := GbxFakeContextForPolicy new.
	glueMarker
		isGlue: true;
		receiver: gsError;
		sender: bottomClient.

	topClient := GbxFakeContextForPolicy new.
	topClient
		isGlue: false;
		sender: glueMarker.
	debugger topContext: topClient.

	list := policy computeContextList.

	self assert: list size equals: 3.
	self assert: (list at: 1) == gsContext.
	self assert: (list at: 2) == topClient.
	self assert: (list at: 3) == bottomClient.
]
