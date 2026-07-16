"Test: what does activating a LOGGED-OUT session id do? If GciSetSessionId_ on a
 stale id returns FALSE -> 'Could not activate'. Also: after logging out session
 B, does reusing session A (whose id may have been recycled) still work? This
 models the prod pool discarding+recreating sessions (fixes #3/#4)."
| env e2 stone user pass svc nhost nname huser hpass pc mk a b c |
[
[ Metacello new baseline: 'GemStonePharo';
	repository: 'tonel:///Users/tariq/src/gemtools/GemStone-Pharo-Bridge/src';
	load: 'default' ] on: Error do: [ :ex | Transcript show: 'LOAD_ERROR: ', ex messageText; cr. Smalltalk snapshot: false andQuit: true ].
env := [ OSEnvironment current ] on: Error do: [ Dictionary new ].
e2 := [ :keys :default | | v | v := default. keys do: [ :k | | raw | v = default ifTrue: [ raw := [ env at: k ifAbsent: [ nil ] ] on: Error do: [ nil ]. raw ifNotNil: [ raw := [ raw asString trimBoth ] on: Error do: [ '' ]. raw isEmpty ifFalse: [ v := raw ] ] ] ]. v ].
stone := e2 value: #('GS_STONE') value: 'gs64stone'.
user := e2 value: #('GS_USER') value: ''.
pass := e2 value: #('GS_PASS') value: ''.
svc := e2 value: #('GS_SERVICE') value: 'gemnetobject'.
nhost := e2 value: #('GS_NETLDI_HOST') value: ''.
nname := e2 value: #('GS_NETLDI_NAME_OR_PORT') value: ''.
huser := e2 value: #('OKZ_GEMSTONE_HOST_USERNAME') value: ''.
hpass := e2 value: #('OKZ_GEMSTONE_HOST_PASSWORD') value: ''.
pc := Smalltalk at: #GbsSessionParameters ifAbsent: [ nil ].
mk := [ | p | p := pc new. p gemStoneName: stone; username: user; password: pass; gemService: svc. nhost isEmpty ifFalse: [ p netldiHostOrIp: nhost ]. nname isEmpty ifFalse: [ p netldiNameOrPort: nname ]. huser isEmpty ifFalse: [ p hostUsername: huser ]. hpass isEmpty ifFalse: [ p hostPassword: hpass ]. [ p login ] on: Error do: [ :ex | Transcript show: 'LOGIN_ERROR: ', ex messageText; cr. nil ] ].

a := mk value. b := mk value.
(a isNil or: [ b isNil ]) ifTrue: [ Transcript show: 'LOGIN_FAILED'; cr. Smalltalk snapshot: false andQuit: true ].
Transcript show: 'A id=', a sessionId printString, ' B id=', b sessionId printString; cr.
Transcript show: 'A eval=', ([ (a evaluate: '7+7') printString ] on: Error do: [ :e | 'ERR:', e messageText ]); cr.

"Log B out, then try to use B (stale) — expect 'Could not activate'."
[ b logout ] on: Error do: [ ].
Transcript show: 'B logged out'; cr.
Transcript show: 'B-after-logout eval=', ([ (b evaluate: '8+8') printString ] on: Error do: [ :e | 'ERR:', e messageText ]); cr.

"Now log in C (it may RECYCLE B's freed session id). Does A still work? Does C work?"
c := mk value.
c ifNotNil: [
	Transcript show: 'C id=', c sessionId printString; cr.
	Transcript show: 'C eval=', ([ (c evaluate: '9+9') printString ] on: Error do: [ :e | 'ERR:', e messageText ]); cr.
	"Critical: reuse A after C logged in (id churn). Prod does this constantly."
	Transcript show: 'A-after-C eval=', ([ (a evaluate: '5+5') printString ] on: Error do: [ :e | 'ERR:', e messageText ]); cr.
	[ c logout ] on: Error do: [ ] ].
[ a logout ] on: Error do: [ ].
Transcript show: 'PROBE_DONE'; cr.
] ensure: [ Smalltalk snapshot: false andQuit: true ].
