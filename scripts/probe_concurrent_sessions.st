"Concurrent repro: log in N GBS sessions, fork N processes that each repeatedly
 call session>>evaluate: simultaneously. evaluate: goes through
 withActiveGciSessionDo: (activate+execute). On the current branch that is
 serialised by the fix #5 GCI mutex, so all should succeed. counts in a shared
 Dictionary to avoid closure-temp pitfalls."
| env e2 stone user pass svc nhost nname huser hpass pc mk sessions counters done sc iters |
[
[ Metacello new baseline: 'GemStonePharo';
	repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
	load: 'default' ] on: Error do: [ :ex | Transcript show: 'LOAD_ERROR: ', ex messageText; cr. Smalltalk snapshot: false andQuit: true ].
env := [ OSEnvironment current ] on: Error do: [ Dictionary new ].
e2 := [ :keys :default | | v | v := default. keys do: [ :k | | raw | v = default ifTrue: [ raw := [ env at: k ifAbsent: [ nil ] ] on: Error do: [ nil ]. raw ifNotNil: [ raw := [ raw asString trimBoth ] on: Error do: [ '' ]. raw isEmpty ifFalse: [ v := raw ] ] ] ]. v ].
stone := e2 value: #('GS_STONE') value: 'gs64stone'.
user := e2 value: #('GS_USER' 'GS_USERNAME') value: ''.
pass := e2 value: #('GS_PASS' 'GS_PASSWORD') value: ''.
svc := e2 value: #('GS_SERVICE') value: 'gemnetobject'.
nhost := e2 value: #('GS_NETLDI_HOST' 'GS_HOST') value: ''.
nname := e2 value: #('GS_NETLDI_NAME_OR_PORT' 'GS_NETLDI') value: ''.
huser := e2 value: #('OKZ_GEMSTONE_HOST_USERNAME' 'GS_HOST_USERNAME') value: ''.
hpass := e2 value: #('OKZ_GEMSTONE_HOST_PASSWORD' 'GS_HOST_PASSWORD') value: ''.
pc := Smalltalk at: #GbsSessionParameters ifAbsent: [ nil ].
mk := [ | p | p := pc new. p gemStoneName: stone; username: user; password: pass; gemService: svc. nhost isEmpty ifFalse: [ p netldiHostOrIp: nhost ]. nname isEmpty ifFalse: [ p netldiNameOrPort: nname ]. huser isEmpty ifFalse: [ p hostUsername: huser ]. hpass isEmpty ifFalse: [ p hostPassword: hpass ]. [ p login ] on: Error do: [ :ex | Transcript show: 'LOGIN_ERROR: ', ex messageText; cr. nil ] ].
sc := 4. iters := 25.
sessions := (1 to: sc) collect: [ :i | mk value ].
(sessions includes: nil) ifTrue: [ Transcript show: 'A_LOGIN_FAILED'; cr. Smalltalk snapshot: false andQuit: true ].
Transcript show: 'LOGGED_IN ', sc printString, ' ids=', (sessions collect: [ :s | s sessionId ]) printString; cr.
counters := Dictionary new. counters at: #ok put: 0; at: #fail put: 0; at: #activate put: 0.
done := Semaphore new.
sessions doWithIndex: [ :s :idx |
	[ 1 to: iters do: [ :n | [ s evaluate: '40 + 2'. counters at: #ok put: (counters at: #ok) + 1 ]
		on: Error do: [ :ex | counters at: #fail put: (counters at: #fail) + 1.
			(ex messageText includesSubstring: 'Could not activate') ifTrue: [ counters at: #activate put: (counters at: #activate) + 1 ].
			(counters at: #fail) <= 3 ifTrue: [ Transcript show: 'FAIL: ', ex messageText; cr ] ] ].
	done signal ] fork ].
sc timesRepeat: [ done wait ].
Transcript show: 'RESULT ok=', (counters at: #ok) printString, ' fail=', (counters at: #fail) printString, ' couldNotActivate=', (counters at: #activate) printString; cr.
sessions do: [ :s | [ s logout ] on: Error do: [ ] ].
Transcript show: 'PROBE_DONE'; cr.
] ensure: [ Smalltalk snapshot: false andQuit: true ].
