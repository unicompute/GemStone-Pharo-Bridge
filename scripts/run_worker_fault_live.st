| suites total pass fail err skip |
[
Metacello new baseline: 'GemStonePharo'; repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src'; load: #('GemStone-GBS-ThreadSafe' 'GemStone-Pharo-Core-Tests' 'GemStone-Pharo-Tests' 'GemStone-Pharo-ThreadSafe-Tests').
suites := #(#GbsWorkerFaultLiveTest #GbsLegacyWorkerFaultLiveTest).
total := 0. pass := 0. fail := 0. err := 0. skip := 0.
suites do: [ :className |
	| result |
	result := (Smalltalk globals at: className) suite run.
	total := total + result runCount.
	pass := pass + result passedCount.
	fail := fail + result failureCount.
	err := err + result errorCount.
	skip := skip + result skippedCount.
	Stdio stdout lf; nextPutAll: 'WORKER-FAULT-SUITE '; nextPutAll: className asString; nextPutAll: ' '; nextPutAll: result printString; lf.
	result failures do: [ :each | Stdio stdout nextPutAll: 'FAIL: '; nextPutAll: each printString; lf ].
	result errors do: [ :each | Stdio stdout nextPutAll: 'ERR: '; nextPutAll: each printString; lf ] ].
Stdio stdout lf; nextPutAll: 'WORKER-FAULT-TOTAL run='; print: total; nextPutAll: ' pass='; print: pass; nextPutAll: ' fail='; print: fail; nextPutAll: ' err='; print: err; nextPutAll: ' skip='; print: skip; lf.
(fail = 0 and: [ err = 0 ])
	ifTrue: [ Stdio stdout nextPutAll: 'WORKER-FAULT-RESULT ok'; lf ]
	ifFalse: [ Stdio stdout nextPutAll: 'WORKER-FAULT-RESULT failed'; lf ].
] on: Error do: [ :ex |
	Stdio stdout lf; nextPutAll: 'WORKER-FAULT-RESULT crashed: '; nextPutAll: ([ ex messageText asString ] on: Error do: [ ex class name ]); lf ].
Smalltalk snapshot: false andQuit: true.
