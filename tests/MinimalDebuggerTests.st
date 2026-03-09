"
Minimal Test Scripts for GemStone Remote Debugger

Run these individually in the GemStone Workspace to test debugger functionality.
"

"============================================================================="
"TEST 1: Simple Success - Should NOT open debugger"
"Expected: Transcript shows '2'"
"============================================================================="
1 + 1.


"============================================================================="
"TEST 2: Division by Zero - SHOULD open debugger"
"Expected: GbsRemoteDebugger opens with stack frame showing this line"
"============================================================================="
1 / 0.


"============================================================================="
"TEST 3: Variable Assignment then Error - SHOULD open debugger"
"Expected: Debugger shows variables a=10, b=0 in context"
"============================================================================="
| a b |
a := 10.
b := 0.
a / b.


"============================================================================="
"TEST 4: Message Not Understood - SHOULD open debugger"
"Expected: Debugger shows MessageNotUnderstood error"
"============================================================================="
Object thisMessageDoesNotExist.


"============================================================================="
"TEST 5: Nested Block Error - SHOULD open debugger with nested frames"
"Expected: Debugger shows multiple stack frames for nested blocks"
"============================================================================="
[
	[
		1 / 0
	] value
] value.


"============================================================================="
"TEST 6: Array Index Out of Bounds - SHOULD open debugger"
"Expected: Debugger shows SubscriptOutOfBounds error"
"============================================================================="
| arr |
arr := #(1 2 3).
arr at: 10.


"============================================================================="
"TEST 7: Successful Block Execution - Should NOT open debugger"
"Expected: Transcript shows '15'"
"============================================================================="
[:x :y | x + y] value: 5 value: 10.


"============================================================================="
"TEST 8: String Operation Error - SHOULD open debugger"
"Expected: Debugger shows error in string operation"
"============================================================================="
'hello' uppercase first: 100.
