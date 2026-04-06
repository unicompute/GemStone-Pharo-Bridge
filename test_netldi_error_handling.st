"Test script for netldi error handling"
"Run this in Pharo Playground to verify the error handling improvements"

Transcript clear.
Transcript show: '============================================================'; cr.
Transcript show: 'Testing Netldi Error Handling'; cr.
Transcript show: '============================================================'; cr; cr.

"Test 1: Verify error interpretation in GbsSessionParameters"
Transcript show: 'Test 1: GbsSessionParameters error interpretation'; cr.
[
    | params |
    params := GbsSessionParameters new.
    
    "Test various error messages"
    #('connection refused' 
      'no such stn: gs64stone' 
      'netldi not responding'
      'gemnetobject failed'
      'login denied'
      'stone is shutting down'
      'connection timeout'
      'some unknown error') do: [ :testMsg |
        
        | interpreted |
        interpreted := params 
            interpretErrorMessage: testMsg 
            errorNumber: 1234.
        
        Transcript tab; show: 'Input: ', testMsg; cr.
        Transcript tab; show: 'Output: ', interpreted; cr; cr ].
] on: Error do: [ :ex |
    Transcript tab; show: '✗ ERROR: ', ex messageText; cr; cr ].

"Test 2: Verify error interpretation in GbsSession"
Transcript show: 'Test 2: GbsSession error interpretation'; cr.
[
    | session |
    session := GbsSession new.
    
    "Test various error messages"
    #('connection refused' 
      'no such stn' 
      'netldi error'
      'timeout') do: [ :testMsg |
        
        | interpreted |
        interpreted := session 
            interpretErrorMessage: testMsg 
            errorNumber: 5678.
        
        Transcript tab; show: 'Input: ', testMsg; cr.
        Transcript tab; show: 'Output: ', interpreted; cr; cr ].
] on: Error do: [ :ex |
    Transcript tab; show: '✗ ERROR: ', ex messageText; cr; cr ].

"Test 3: Verify netldi fields are properly used"
Transcript show: 'Test 3: Netldi configuration fields'; cr.
[
    | params |
    params := GbsSessionParameters new
        gemStoneName: 'gs64stone';
        username: 'DataCurator';
        password: 'swordfish';
        netldiHostOrIp: '192.168.1.100';
        netldiNameOrPort: '50374';
        yourself.
    
    Transcript tab; show: '✓ Params created with netldi config'; cr.
    Transcript tab; show: '  Host/IP: ', params netldiHostOrIp; cr.
    Transcript tab; show: '  Port: ', params netldiNameOrPort; cr; cr.
] on: Error do: [ :ex |
    Transcript tab; show: '✗ ERROR: ', ex messageText; cr; cr ].

"Test 4: Try actual login (will fail if netldi not running)"
Transcript show: 'Test 4: Actual login attempt'; cr.
Transcript tab; show: '⚠ This test will attempt a real connection...'; cr.
Transcript tab; show: '  Expected to fail if netldi is not running'; cr; cr.

[
    | params |
    params := GbsSessionParameters new
        gemStoneName: 'gs64stone';
        username: 'DataCurator';
        password: 'swordfish';
        yourself.
    
    Transcript tab; show: 'Attempting login...'; cr.
    [ params login ] on: Error do: [ :ex |
        Transcript tab; show: '✗ Login failed (expected if netldi not running)'; cr.
        Transcript tab; show: 'Error message:'; cr.
        Transcript tab; tab; show: ex messageText; cr; cr ].
] on: Error do: [ :ex |
    Transcript tab; show: '✗ Test error: ', ex messageText; cr; cr ].

Transcript show: '============================================================'; cr.
Transcript show: 'Tests Complete'; cr.
Transcript show: '============================================================'; cr.
