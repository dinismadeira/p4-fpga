set_operating_conditions -model slow  -temperature 85 -voltage 1200


report_path -from [get_keepers *] -to [get_keepers *] -npaths 500 -panel_name "Report Path"
#report_net_timing -nworst_delay 2000 [get_nets *] -file "net_timing.txt"
#report_timing -hold  -less_than_slack 0.0 -from { * } -to { * }  -npaths 200 -from_clock { * }  -to_clock [get_clocks {*pll*}]     -file "mult_test.tq.hold.rpt"
#report_timing -from_clock { *clk[0] } -to_clock { *clk[0] } -from * -to * -setup -npaths 10000 -detail summary -panel_name {Report Timing} -file "time_quest_rpt.txt"
report_timing -from_clock { *clk[0] } -to_clock { *clk[0] } -from * -to * -setup -nworst 5000 -detail summary -panel_name {Report Timing} -file "time_quest_rpt0.txt"
report_timing -from_clock { *clk[1] } -to_clock { *clk[1] } -from * -to * -setup -nworst 2000 -detail summary -panel_name {Report Timing} -file "time_quest_rpt1.txt"
#report_timing -from_clock { *pll* } -to_clock { * } -from test* -to * -setup -npaths 10000 -detail summary -panel_name {Report Timing} -file "mult_test.tq.timing.rpt"
#report_path -from test* -to * -npaths 2000 -panel_name "Report Path" -file "mult_test.tq.path.rpt"

report_clock_fmax_summary -panel_name Fmax -file "fmax.txt"
