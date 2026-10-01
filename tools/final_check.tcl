# 覆盖率校验：加载 messages/zh_cn.msg，逐条比对 runtime3.txt 中的 msgid
# 用法：tclsh tools/final_check.tcl   （在仓库任意位置均可）
package require msgcat
set here [file dirname [file normalize [info script]]]
set repo [file dirname $here]
msgcat::mclocale zh_cn
set n [msgcat::mcload [file join $repo messages]]
puts "loaded=$n"
set fh [open [file join $here runtime3.txt] r]
set out [open [file join $here checked_final.txt] w]
fconfigure $fh -encoding utf-8
fconfigure $out -encoding utf-8
set uniq 0
set translated 0
array set seen {}
while {[gets $fh line] >= 0} {
    set parts [split $line \t]
    set b64 [lindex $parts 0]
    set msg [binary decode base64 $b64]
    if {$msg eq "\\"} continue
    set got [::msgcat::mc $msg]
    set eq [expr {$got eq $msg}]
    puts $out "$b64\t$eq"
    if {![info exists seen($msg)]} {
        set seen($msg) 1
        incr uniq
        if {!$eq} { incr translated }
    }
}
close $fh; close $out
puts "unique msgids: $uniq"
puts "translated:    $translated"
puts "untranslated:  [expr {$uniq - $translated}]"
puts "detail:        [file join $here checked_final.txt]"
if {$uniq == 0} { puts stderr "FAIL: no msgids found"; exit 1 }
