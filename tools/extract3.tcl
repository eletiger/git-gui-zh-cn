# 提取 git-gui 运行时真实使用的 mc msgid
# 源码路径可用环境变量 GITGUI_SRC_ROOT 覆盖（默认 Git for Windows 标准安装路径）
set here [file dirname [file normalize [info script]]]
if {[info exists ::env(GITGUI_SRC_ROOT)] && $::env(GITGUI_SRC_ROOT) ne ""} {
	set root $::env(GITGUI_SRC_ROOT)
} else {
	set root "/mnt/c/Program Files/Git/mingw64"
}
set lib  [file join $root share git-gui lib]
set main [file join $root libexec git-core git-gui.tcl]
if {![file exists $main]} {
	puts stderr "error: git-gui source not found: $main"
	puts stderr "       set GITGUI_SRC_ROOT to mingw64 dir of your Git for Windows"
	exit 1
}
set files [concat [glob -nocomplain $lib/*.tcl] [list $main]]
set ip [interp create -safe]
set fh [open [file join $here runtime3.txt] w]
fconfigure $fh -encoding utf-8
puts "extracting from $root ..."
set nsources [llength $files]
foreach f $files {
    set in [open $f r]; fconfigure $in -encoding utf-8
    set data [read $in]; close $in
    set len [string length $data]
    set idx 0
    while {[regexp -indices -start $idx {(^|[^\\\w:$])mc[ \t]+} $data m]} {
        set end [expr {[lindex $m 1] + 1}]
        set i $end
        while {$i < $len && [string index $data $i] in {" " "\t"}} { incr i }
        set c [string index $data $i]
        set frag ""
        if {$c eq "\""} {
            set j [expr {$i + 1}]
            while {$j < $len} {
                set ch [string index $data $j]
                if {$ch eq "\\"} { incr j 2; continue }
                if {$ch eq "\""} break
                incr j
            }
            set frag [string range $data $i $j]
        } elseif {$c eq "\{"} {
            set depth 0; set j $i
            while {$j < $len} {
                set ch [string index $data $j]
                if {$ch eq "\{"} { incr depth }
                if {$ch eq "\}"} { incr depth -1; if {$depth == 0} break }
                incr j
            }
            set frag [string range $data $i $j]
        } else {
            # bare word: up to closing bracket or whitespace-then-paren
            set j $i
            while {$j < $len && [string index $data $j] ne "\]"} {
                set ch [string index $data $j]
                if {$ch in {"\n" " " "\t"}} {
                    # stop if next non-space is not word-ish
                    set k $j
                    while {$k < $len && [string index $data $k] in {" " "\t" "\n"}} { incr k }
                    if {[string index $data $k] eq "\]"} break
                    # allow single spaces inside words like "Stage To Commit"? only if word continues with letter
                    if {[regexp {[A-Za-z0-9]} [string index $data $k]]} { set j [expr {$k-1}]; incr j; continue }
                    break
                }
                incr j
            }
            set frag [string range $data $i [expr {$j - 1}]]
        }
        if {$frag eq ""} { set idx [expr {$end + 1}]; continue }
        if {![catch {set rt [$ip eval "return $frag"]} err]} {
            if {[string trim $rt] ne ""} {
                puts $fh "[binary encode base64 [encoding convertto utf-8 $rt]]\t[file tail $f]"
            }
        }
        set idx [expr {$i + [string length $frag]}]
    }
}
close $fh

set out [open [file join $here runtime3.txt] r]
fconfigure $out -encoding utf-8
array set seen {}
set total 0
while {[gets $out line] >= 0} {
	incr total
	set b64 [lindex [split $line \t] 0]
	set seen([binary decode base64 $b64]) 1
}
close $out
puts "sources: $nsources files, occurrences: $total, unique msgids: [array size seen]"
puts "written: [file join $here runtime3.txt]"
