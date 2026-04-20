Class {
	#name : 'GbxContextListPolicyTest',
	#superclass : 'TestCase',
	#category : 'GemStone-Pharo-Core-Tests',
	#package : 'GemStone-Pharo-Core-Tests'
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

	self assert: list size equals: 2.
	self assert: (list at: 1) == gsContext.
	self assert: (list at: 2) == topClient.
]

{ #category : 'tests' }
GbxContextListPolicyTest >> testMatchingServerCallMarkerForServerContextReturnsMarkerContext [
	| debugger policy gsContext gsError topClient glueMarker |

	debugger := GbxFakeDebuggerForPolicy new.
	policy := GbxTestableContextListPolicy debugger: debugger.

	gsContext := GbxFakeContextForPolicy new.
	gsContext
		gbxIsServerContext: true;
		processOop: 123.

	gsError := GbxFakeGbsErrorForPolicy new.
	gsError serverProcessOop: 123.

	glueMarker := GbxFakeContextForPolicy new.
	glueMarker
		isGlue: true;
		receiver: gsError.

	topClient := GbxFakeContextForPolicy new.
	topClient
		isGlue: false;
		sender: glueMarker.
	debugger topContext: topClient.

	self assert: (policy matchingServerCallMarkerForServerContext: gsContext) == glueMarker
]

{ #category : 'tests' }
GbxContextListPolicyTest >> testIsGlueTreatsIntermediateContextsAsGlue [
	| debugger policy topClient topGlue intermediate bottomGlue visibleBelow |

	debugger := GbxFakeDebuggerForPolicy new.
	policy := GbxTestableContextListPolicy debugger: debugger.

	visibleBelow := GbxFakeContextForPolicy new.
	visibleBelow isGlue: false.

	bottomGlue := GbxFakeContextForPolicy new.
	bottomGlue
		gbxIsGsBottomGlue: true;
		sender: visibleBelow.

	intermediate := GbxFakeContextForPolicy new.
	intermediate
		isGlue: false;
		sender: bottomGlue.

	topGlue := GbxFakeContextForPolicy new.
	topGlue
		gbxIsGsTopGlue: true;
		sender: intermediate.

	topClient := GbxFakeContextForPolicy new.
	topClient
		isGlue: false;
		sender: topGlue.

	debugger topContext: topClient.

	self assert: (policy isGlue: intermediate).
	self deny: (policy isGlue: visibleBelow)
]

{ #category : 'tests' }
GbxContextListPolicyTest >> testFirstClientContextAboveDoesNotCountIntermediateGlueContexts [
	| debugger policy gsContext gsError markerTopGlue intermediate bottomGlue visibleBelow |

	debugger := GbxFakeDebuggerForPolicy new.
	policy := GbxTestableContextListPolicy debugger: debugger.

	gsContext := GbxFakeContextForPolicy new.
	gsContext
		gbxIsServerContext: true;
		processOop: 88.

	gsError := GbxFakeGbsErrorForPolicy new.
	gsError serverProcessOop: 88.

	visibleBelow := GbxFakeContextForPolicy new.
	visibleBelow isGlue: false.

	bottomGlue := GbxFakeContextForPolicy new.
	bottomGlue
		gbxIsGsBottomGlue: true;
		sender: visibleBelow.

	intermediate := GbxFakeContextForPolicy new.
	intermediate
		isGlue: false;
		sender: bottomGlue.

	markerTopGlue := GbxFakeContextForPolicy new.
	markerTopGlue
		gbxIsGsTopGlue: true;
		receiver: gsError;
		sender: intermediate.

	debugger topContext: markerTopGlue.

	self assert: (policy firstClientContextAbove: gsContext) isNil
]
