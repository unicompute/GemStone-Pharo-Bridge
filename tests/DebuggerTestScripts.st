"
Test Scripts for GemStone Remote Debugger

These scripts test the basic functionality of the GbsRemoteDebugger.
Run these in the GemStone Workspace after logging in to GemStone.
"

"============================================================================="
"Test 1: Simple Execution (1+1)"
"Expected: Should execute without error, no debugger opens"
"============================================================================="
[
Transcript show: '=== Test 1: Simple Execution (1+1) ==='; cr.
1 + 1.
Transcript show: 'Result: 2 (success)'; cr.
] on: Error do: [ :ex |
	Transcript show: 'UNEXPECTED ERROR: ', ex messageText; cr.
].

"============================================================================="
"Test 2: Division by Zero Error"
"Expected: GbsRemoteDebugger should open showing the error"
"============================================================================="
[
Transcript show: '=== Test 2: Division by Zero (1/0) ==='; cr.
1 / 0.
Transcript show: 'Should not reach here'; cr.
] on: Error do: [ :ex |
	Transcript show: 'Error caught: ', ex messageText; cr.
	Transcript show: 'Debugger should have opened'; cr.
].

"============================================================================="
"Test 3: Multi-line Error with Variables"
"Expected: Debugger opens showing stack with local variables a, b"
"============================================================================="
[
Transcript show: '=== Test 3: Multi-line Error ==='; cr.
| a b |
a := 10.
b := 0.
a / b.
] on: Error do: [ :ex |
	Transcript show: 'Error: ', ex messageText; cr.
].

"============================================================================="
"Test 4: Nested Block Error"
"Expected: Debugger shows nested block context"
"============================================================================="
[
Transcript show: '=== Test 4: Nested Block Error ==='; cr.
[
	[
		1 / 0
	] value
] value.
] on: Error do: [ :ex |
	Transcript show: 'Error: ', ex messageText; cr.
].

"============================================================================="
"Test 5: Message Not Understood"
"Expected: Debugger shows MessageNotUnderstood error"
"============================================================================="
[
Transcript show: '=== Test 5: Message Not Understood ==='; cr.
Object thisMessageDoesNotExist.
] on: Error do: [ :ex |
	Transcript show: 'Error: ', ex messageText; cr.
].

"============================================================================="
"Test 6: Index Out of Bounds"
"Expected: Debugger shows SubscriptOutOfBounds error"
"============================================================================="
[
Transcript show: '=== Test 6: Index Out of Bounds ==='; cr.
| arr |
arr := #(1 2 3).
arr at: 10.
] on: Error do: [ :ex |
	Transcript show: 'Error: ', ex messageText; cr.
].

"============================================================================="
"Test 7: Successful Complex Calculation"
"Expected: No error, result displayed"
"============================================================================="
[
Transcript show: '=== Test 7: Complex Calculation ==='; cr.
| x y z |
x := 10.
y := 20.
z := x + y * 2.
Transcript show: 'Result: ', z asString; cr.
] on: Error do: [ :ex |
	Transcript show: 'UNEXPECTED ERROR: ', ex messageText; cr.
].

"============================================================================="
"Test 8: Block with Arguments"
"Expected: Block executes correctly"
"============================================================================="
[
Transcript show: '=== Test 8: Block with Arguments ==='; cr.
[:x :y | x + y] value: 5 value: 10.
Transcript show: 'Result: 15 (success)'; cr.
] on: Error do: [ :ex |
	Transcript show: 'UNEXPECTED ERROR: ', ex messageText; cr.
].

"============================================================================="
"Test 9: Recursive Error"
"Expected: Debugger shows recursive stack frames"
"============================================================================="
[
Transcript show: '=== Test 9: Recursive Error ==='; cr.
| recurse |
recurse := [ :n |
	n > 0 
		ifTrue: [ recurse value: n - 1 ]
		ifFalse: [ 1 / 0 ]
].
recurse value: 3.
] on: Error do: [ :ex |
	Transcript show: 'Error: ', ex messageText; cr.
].

"============================================================================="
"Test 10: Method Call Chain Error"
"Expected: Debugger shows method call chain"
"============================================================================="
[
Transcript show: '=== Test 10: Method Call Chain ==='; cr.
'hello' uppercase first: 100.
] on: Error do: [ :ex |
	Transcript show: 'Error: ', ex messageText; cr.
].

Transcript show: '=== All Tests Complete ==='; cr.
