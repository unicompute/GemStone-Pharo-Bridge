# GemStone Remote Debugger Test Scripts

This directory contains test scripts for the GemStone Remote Debugger (GbsRemoteDebugger).

## Prerequisites

1. **Login to GemStone** first using the GemStone Launcher:
   - World Menu → Tools → GemStone Launcher
   - Enter your connection details (Stone, User, Password)
   - Click "Login"

2. **Open a GemStone Workspace**:
   - World Menu → Tools → GemStone Workspace
   - Or evaluate: `GbsWorkspace open`

## Running Tests

### Manual Tests (MinimalDebuggerTests.st)

Open `MinimalDebuggerTests.st` and copy/paste individual test cases into the GemStone Workspace.

**Expected Behavior:**

| Test | Code | Expected Result |
|------|------|-----------------|
| Test 1 | `1 + 1` | Shows "2" in Transcript, no debugger |
| Test 2 | `1 / 0` | **Opens GbsRemoteDebugger** |
| Test 3 | `\| a b \| a := 10. b := 0. a / b.` | **Opens GbsRemoteDebugger** with variables |
| Test 4 | `Object thisMessageDoesNotExist` | **Opens GbsRemoteDebugger** |
| Test 5 | `[[1 / 0] value] value` | **Opens GbsRemoteDebugger** with nested frames |
| Test 6 | `\| arr \| arr := #(1 2 3). arr at: 10.` | **Opens GbsRemoteDebugger** |
| Test 7 | `[:x :y \| x + y] value: 5 value: 10` | Shows "15" in Transcript, no debugger |
| Test 8 | `'hello' uppercase first: 100` | **Opens GbsRemoteDebugger** |

### Full Test Suite (DebuggerTestScripts.st)

Run the complete test suite by evaluating:

```smalltalk
(GemTools at: #DebuggerTestScripts) runAllTests
```

Or copy/paste the entire file into the GemStone Workspace.

### Pharo Unit Tests (GbsRemoteDebuggerTest)

Run the Pharo unit tests:

```smalltalk
GbsRemoteDebuggerTest run
```

Or use the Test Runner:
- World Menu → Tools → Test Runner
- Select "GemStone-Pharo-Tests" package
- Run "GbsRemoteDebuggerTest"

## Verifying Debugger Functionality

When the debugger opens, verify:

1. **Error Message**: Displayed at the top of the debugger window
2. **Stack Frames**: Listed in the left pane
3. **Source Code**: Displayed when selecting a stack frame
4. **Variables**: Shown in the right pane (for frames with local variables)
5. **Control Buttons**: Step Into, Step Over, Step Return, Resume, Terminate

## Troubleshooting

### "Not logged in to GemStone"
- Make sure you've logged in via the GemStone Launcher
- Check that `GbsSessionParameters currentSession isLoggedIn` returns `true`

### "No stack frames available"
- This is expected for simple errors like `1 / 0`
- The context OOP from GemStone may not always provide walkable stack frames
- Try Test 3 or Test 5 which have more context

### Pharo crashes when opening debugger
- Check the crash dump in your Pharo image folder
- The issue may be with fetching source code from GemStone contexts
- The debugger should still open, just without source code display

## Test Results Log

Keep a log of test results here:

```
Date: ___________
Pharo Version: ___________
GemStone Version: ___________

Test 1 (1+1): [ ] Pass  [ ] Fail  Notes: _______________
Test 2 (1/0): [ ] Pass  [ ] Fail  Notes: _______________
Test 3 (Variables): [ ] Pass  [ ] Fail  Notes: _______________
Test 4 (MessageNotUnderstood): [ ] Pass  [ ] Fail  Notes: _______________
Test 5 (Nested Blocks): [ ] Pass  [ ] Fail  Notes: _______________
Test 6 (Array Bounds): [ ] Pass  [ ] Fail  Notes: _______________
Test 7 (Block Args): [ ] Pass  [ ] Fail  Notes: _______________
Test 8 (String Error): [ ] Pass  [ ] Fail  Notes: _______________
```
