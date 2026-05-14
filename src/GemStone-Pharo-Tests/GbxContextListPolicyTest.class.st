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

	self assert: list size equals: 2.
	self assert: (list at: 1) == gsContext.
	self assert: (list at: 2) == topClient.
]

{ #category : 'tests' }
GbxContextListPolicyTest >> testFetchServerContextsUsesBoundDispatcherCommand [
	| debugger policy session contexts |

	session := MockGbsSession new.
	session stubs
		at: #evaluate
		put: [ :script | self fail: 'Context list policy should use dispatcher command execution, not evaluate:.' ].
	session stubs at: #executeAndFetchContext put: [ :script :contextOop |
		self assert: contextOop equals: 20.
		self assert: (script includesSubstring: ':obj').
		self assert: (script includesSubstring: 'value: (Object _objectForOop: 9001)').
		self deny: (script includesSubstring: 'obj := Object _objectForOop:').
		self assert: (script includesSubstring: '_gsiStackReportFromLevel: level toLevel: level').
		^ '1', Character tab asString,
			'DemoWorker', Character tab asString,
			'run', Character tab asString,
			'run', Character tab asString,
			'9001', Character tab asString,
			'2', Character tab asString,
			'1,5,9', Character tab asString,
			'3', String lf ].

	debugger := GbxFakeDebuggerForPolicy new.
	debugger
		session: session;
		processOop: 9001.
	policy := GbxContextListPolicy debugger: debugger.

	contexts := policy fetchServerContexts.

	self assert: contexts size equals: 1.
	self assert: contexts first processOop equals: 9001.
	self assert: contexts first methodClassOrUnknown equals: 'DemoWorker'.
	self assert: contexts first selectorOrUnknown equals: #run.
	self assert: contexts first quickStepPoint equals: 2.
	self assert: contexts first sourceOffsets equals: #(1 5 9).
	self assert: contexts first ipOffset equals: 3
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
