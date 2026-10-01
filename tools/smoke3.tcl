# 冒烟测试：用真实菜单/按钮 msgid 检查译文是否生效
# 用法：tclsh tools/smoke3.tcl
package require msgcat
set here [file dirname [file normalize [info script]]]
set repo [file dirname $here]
msgcat::mclocale zh_cn
msgcat::mcload [file join $repo messages]
# proc mc 是 git-gui 自己的实现（git-gui.tcl L339），保留供参考。
# 校验只做查表，不做 format —— 否则 %d 占位符会因参数类型不符回落英文。
proc mc {en_fmt args} {
    set fmt [::msgcat::mc $en_fmt]
    if {[catch {set msg [eval [list format $fmt] $args]}]} {
        set msg [eval [list format $en_fmt] $args]
    }
    return $msg
}
set bad 0
set total 0
foreach s {
    "Repository" "Edit" "Branch" "Commit@@noun" "Commit@@verb" "Merge" "Remote" "Tools" "Help"
    "Database Statistics" "Compress Database" "Verify Database" "Quit"
    "Undo" "Redo" "Cut" "Copy" "Paste" "Delete" "Select All"
    "Create..." "Checkout..." "Rename..." "Delete..." "Reset..."
    "Rescan" "Stage To Commit" "Stage Changed Files To Commit" "Unstage From Commit" "Revert Changes"
    "Local Merge..." "Abort Merge..." "Options..." "Online Documentation" "Show SSH Key"
    "Add" "Remove" "OK" "Find:" "Next" "Prev" "RegExp" "Case" "Go" "Error" "Other" "usage:"
    "Delete untracked file %s?" "None of the %d selected files could be deleted."
    "Stage %d untracked files?" "Revert changes in file %s?"
} {
    incr total
    set r [::msgcat::mc $s]
    if {$r eq $s} { incr bad }
    puts [format "%-45s => %s" [string range $s 0 44] [string map {\n ⏎} $r]]
}
puts ""
puts "checked: $total, unchanged(english): $bad"
if {$bad > 0} { puts stderr "WARN: $bad string(s) not translated"; exit 1 }
