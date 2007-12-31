set assertcount 0
set current_test "Test"

proc die s {
  puts $s
  exit
}

source include.tcl

proc assertEq {a b} {
  global current_test
  if {== $a $b} {
    assertPass
  } else {
    die "$current_test failed: $a != $b"
  }
}


proc checkthat { var op r } {
  set res [eval "$op {$var} {$r}"]
  if { == $res 1 } {
    assertPass
  } else {
    assertFail "\"$var $op $r\" was not true"
  }
}

proc assertPass {} {
  global assertcount
  puts -nonewline "."
  incr assertcount
}

proc assertFail why {
  global current_test
  die "'$current_test' failed: $why"
}

proc assertStrEq {a b} {
  global current_test
  if {eq $a $b} {
    assertPass
  } else {
    assertFail "\"$a\" != \"$b\""
  }
}

proc assertNoErr code {
  set ret [catch $code]
  if { == $ret 0 } {
    assertPass
  } else {
    assertFail "code failed: $code"
  }
}

proc assertErr code {
  set ret [catch "eval {$code}"]
  if { == $ret 1 } {
    assertPass
  } else {
    assertFail "code should've failed: $code"
  }
}

proc announce { } { 
  puts "Running tests"
}

proc assert code {
  set ret [uplevel $code]
  if { == $ret 1 } { assertPass } else { assertFail "Failed: $code" }
}

announce

assertEq [eval {[* 4 4]}] 16


proc uptest {var v} {
  upvar $var loc
  set loc $v
}

set x 4
uptest x 3
assertEq $x 3

proc uptest2 {var2 v} {
  proc inner {a b} {
    upvar 2 $b whee 
    set whee $a
  }
  upvar $var2 lark
  inner $v $var2 
  incr lark
}

set y 99 
uptest2 y 3
assertEq $y 4

proc test {name body} {
  global current_test
  set current_test $name
  eval $body
}

test "unevaluated blocks aren't parsed" {
  if {== 3 4} {
   "This should be no problem. $woo_etcetera.; 
   "
  } else {
   assertPass
  }
}

test "unused args" {
  proc addem {a b} {
    return [+ $a $a]
    return [+ $b $a]
  }

  checkthat [addem 5 "balloon"] == 10
}

test "incr test" {
  set count 0

  incr count
  incr count
  incr count

  assertEq $count 3

  incr count 2

  assertEq 5 $count

  incr count -2

  assertEq 3 $count

  decr count
  decr count
  decr count

  assertEq $count 0
}

test "list test" {
  set bean [list 1 2 3 4 5 {6 7 8}]

  assertEq [llength $bean] 6
  assertEq [lindex $bean 3] 4
  assertEq [lindex $bean 5] {6 7 8}

  checkthat [llength "peanut"] == 1
  checkthat [llength "peanut ontology"] == 2
  checkthat [llength ""] == 0

  checkthat [llength {one [puts bean]}] == 3

  checkthat [llength {a b # c d}] == 5

  checkthat [llength [list [list 1 2 3] [list 3 4 5]]] == 2
  assertEq [lindex 4] 4
  assertStrEq [lindex $bean 8] "" 

}

test "test if, elseif, else" {
  if { eq "one" "two" } {
    die "Should not have hit this."
  } elseif { == 1 1 } {
    assertPass
  } else {
    die "Should not have hit this."
  }
}

test "test args parameter" {
  set total 0
  proc argstest {tot args} {
    upvar $tot total
    set i 0
    while {< $i [llength $args]} {
      set total [+ [lindex $args $i] $total]
      incr i
    }
  }

  assertEq 0 $total
  argstest total 1 2 3 4 5 6 7 8
  assertEq 36 $total
}

set sval 0
set sval2 1
while {<= $sval 10} {
  incr sval
  if {<= 8 $sval} {
    break
  }
  if {<= 4 $sval} {
    continue
  }
  incr sval2
}

assertEq 8 $sval
assertEq 4 $sval2


assertEq 10 [+ 15 -5] # Check that negatives parse.

test "string methods" {
  assertEq 4 [string length "five"]
  assertEq 0 [string length ""]
  assertEq 7 [string length "one\ntwo"]
  assertEq 4 [string length "h\n\ti"]

  set fst [string index "whee" 1]
  assertStrEq "h" $fst

  assertStrEq "wombat" [string tolower "WOMBAT"]
  assertStrEq "CALCULUS" [string toupper "calculus"]
  assertStrEq "hello" [string trim "  hello  "]
}


set somestr "one"
append somestr " two" " three" " four"
assertStrEq "one two three four" $somestr
append avar a b c
assertStrEq "abc" $avar

set numbers {1 2 3 4 5}
set result 0
foreach number $numbers {
  set result [+ $number $result]
}

assertEq 15 $result

set fer "old"
foreach feitem {"a b" "c d"} {
  set fer $feitem
}

checkthat $fer eq "c d" 
# $fer

test "join and foreach" {
  set misc { 1 2 3 4 5 6 }
  proc join { lsx mid } {
    set res ""
    set first_time 1
    foreach ind $lsx {
      if { [== $first_time 1] } {
        set res $ind
        set first_time 0
      } else {
        set res "$res$mid$ind"
      }
    }
    return $res
  }

  checkthat [join $misc +] eq "1+2+3+4+5+6"
}

test "for loop" {
  set res 0
  for {set i 0} { < $i 20 } { incr i } {
    incr res $i
  }

  checkthat $res == 190
  checkthat $i == 20

  set val 0
  for {set i 20} { > $i 0 } { decr i } {
    incr val
  }

  checkthat $val == 20
}


proc expr { a1 args } { 
  if { != [llength $args] 0 } {  
    eval "[lindex $args 0] $a1 [lindex $args 1]"
  } else {
    eval "expr $a1"
  }
}

assertEq 8 [expr 4 + 4]
assertEq 8 [expr {4 + 4}]

test "set returns correctly" {
  set babytime 444
  checkthat [set babytime] == 444
  assertEq 512 [set babytime 512]
  assertEq 512 $babytime
}

assertErr { error "oh noes" }

assertEq 1 [catch { puts "$thisdoesntexist" }]
assertEq 0 [catch { [+ 1 1] }]

set whagganog ""
set otherthing ""

test "global test" {
  upvar otherthing ot
  proc testglobal {bah} {
    proc modother { m } {
      global whagganog otherthing
      set otherthing $whagganog$m
    }

    global whagganog
    append whagganog $bah
    modother $bah
    return $whagganog
  }

  checkthat [testglobal 1] == 1
  checkthat $ot            == 11
  checkthat [testglobal 2] == 12
  checkthat $ot            == 122
}



test "parsing corners" {
  set { shh.. ?} 425
  assertStrEq " 425 " " ${ shh.. ?} "

  assertStrEq "whee $ stuff" "whee \$ stuff"

  assertStrEq "whee \$ stuff" "whee \$ stuff"
  assertStrEq "whee \$\" stuff" "whee $\" stuff"
  assertNoErr { 
    if { == 3 3 } { } else { die "bad" } 
  }
}


proc not v {
  if { == 1 $v } { return false } else { return true }
}

test "equality of strings and nums" {
  set x 10
  set y " 10 "
  assert { == $x $y }
  assert { ne $x $y }
  assert { eq 33 33 }
  assert { == "cobra" "cobra" }
  checkthat " 1 " ne 1 
  checkthat " 1 " == 1 
  assert { eq "cobra" "cobra" }
  assert { == 4 4 }
}

test "early return" {
  set moo 4
  proc yay {} { 
    upvar moo moo2
    return 
    set moo2 5
  }

  yay
  checkthat $moo == 4
}

test "arg count check" {
  proc blah {a b} {
   + $a $b
  }


 assertErr { blah 4 }
 assertErr { blah 4 5 6 }
 assertNoErr { blah 4 5 }

  proc blah2 {a b args} {
    + $a [+ $b [llength $args]]
  }

 assertErr { blah2 1 }
 assertErr { blah2 }
 checkthat [blah2 1 2 3] == 4
 checkthat [blah2 1 2]   == 3
 checkthat [blah2 1 2 1 1 1] == 6
}

test "bad continue/break test" {
  proc whee {} {
    break
  }

  assertErr { whee }

  proc whee2 {} {
    continue
  }

  assertErr { whee2 }

  proc whee3 {} {
    return
  }

  assertNoErr { whee3 }

}

test "incomplete parse" {
  assertErr { set bean 4 " }
  assertNoErr { set bean 4() }
  assertErr { " }
}

test "default proc args" {

  proc plus { t { y 1 } } {
    [+ $t $y]
  }

  proc plus2 { x {y 1} } {
    [+ $x $y]
  }

  proc plus3 { {a 5} {b 1} } {
    [+ $a $b]
  }

  proc weirdorder { { a1 "boo" } a2 } {
    return $a1$a2
  }

  proc withargs { i {j 4} args } {
    [+ [llength $args] [+ $i $j]]
  }

  checkthat [plus 3 3] == 6
  checkthat [plus2 3 3] == 6
  checkthat [plus3 3 3] == 6
  checkthat [plus 3] == 4
  checkthat [plus2 3] == 4
  checkthat [plus3 3] == 4

  checkthat [plus3] == 6

  checkthat [weirdorder "xx" "yy"] eq "xxyy"

  assertErr { weirdorder "xx" }

  checkthat [withargs 1] == 5
  checkthat [withargs 1 3] == 4
  checkthat [withargs 1 3 1] == 5
  checkthat [withargs 1 3 1 1 1 8 1] == 9
}

test "array set/get" {
  # Currently faked
  set boo(4) 111
  checkthat "$boo(4)" == 111
}

assertErr { proc banana }
assertErr { proc banana { puts "banana" } }
assertNoErr { proc banana { } { puts "banana" } }
assertNoErr { proc banana {} { puts "banana" } }

puts ""
puts stdout "Done. Passed $assertcount checks."
