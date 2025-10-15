use File::Slurp;

$file=read_file($ARGV[0]);

$file=~s/\r//gs; # remove windows newlines
$file=~s/^\{\$CLEO \.cs\}//mg; # remove CLEO header
$file=~s/^(\:Label)([\da-fA-F]+)/uc($1).sprintf("_%04X \/\/ %d",hex($2),-hex($2))/egm; # format Labels
$file=~s/(goto|goto_if_false)\s+\@Label([\da-fA-F]+)/$1." ".-hex($2)/egm; # format goto
$file=~s/ \{[a-z_]+\}//gsi; # remove named arguments
$file=~s/ True/ 1/gs;
$file=~s/ False/ 0/gs;
$file=~s/^([\da-fA-F]{4}:)\s+(not )?/$1 /gm;

print $file;

=pod
^M
^M
0001: wait {time} 3000^M
03A4: script_name {name} 'TESTER'^M
0007: 9@ = 150.0^M
0007: 11@ = 2.0^M
0007: 12@ = 0.0^M
^M
:Label00002E^M
0001: wait {time} 50^M
00D6: if ^M
0256:   is_player_playing $2^M
004D: goto_if_false @Label00002E^M
00D6: if ^M
04EE:   has_animation_loaded {animationFile} "PARACHUTE"^M
004D: goto_if_false @Label000453^M
0819: get_char_height_above_ground $3 {var_height} 16@^M
06AC: get_char_speed $3 {var_speed} 8@^M
00D6: if ^M
84AD:   not is_char_in_water $3^M
004D: goto_if_false @Label0002BA^M
00D6: if ^M
04B5:   is_int_lvar_greater_or_equal_to_constant 16@ >= 1.5^M
004D: goto_if_false @Label0002BA^M
0494: get_position_of_analogue_sticks {pad} PadId.Pad1 {var_leftStickX} 1@ {var_leftStickY} 2@ {var_rightStickX} 3@ {var_rightStickY} 4@^M
0093: cset_lvar_float_to_lvar_int 1@ =# 1@^M
0093: cset_lvar_float_to_lvar_int 2@ =# 2@^M
0013: 1@ *= 0.02^M
006B: mult_float_lvar_by_float_lvar 1@ *= 11@^M
0172: get_char_heading $3 {var_heading} 4@^M
0063: sub_float_lvar_from_float_lvar 4@ -= 1@^M
0013: 1@ *= 8.0^M
0013: 2@ *= 0.02^M
006B: mult_float_lvar_by_float_lvar 2@ *= 11@^M
005B: add_float_lvar_to_float_lvar 12@ += 2@^M
00D6: if ^M
0023:   -80.0 > 12@^M
004D: goto_if_false @Label000114^M
0007: 12@ = -80.0^M
^M
:Label000114^M
00D6: if ^M
0021:   12@ > 80.0^M
004D: goto_if_false @Label000133^M
0007: 12@ = 80.0^M
^M
:Label000133^M
083E: set_char_rotation $3 {x} 12@ {y} 1@ {z} 4@^M
00D6: if ^M
04B5:   is_int_lvar_greater_or_equal_to_constant 8@ >= 1.0^M
004D: goto_if_false @Label00002E^M
00D6: if 1^M
8611:   not is_char_playing_anim $3 {animationName} "FALL_SKYDIVE"^M
8611:   not is_char_playing_anim $3 {animationName} "FALL_SKYDIVE_ACCEL"^M
004D: goto_if_false @Label0001DE^M
0812: task_play_anim_non_interruptable {handle} $3 {animationName} "FALL_SKYDIVE_ACCEL" {animationFile} "PARACHUTE" {blendSpeed} 1.0 {loop} True {lockX} False {lock
0007: 9@ = 15.0^M
0007: 11@ = 2.0^M
0007: 12@ = 0.0^M
^M
:Label0001DE^M
0007: 5@ = 360.0^M
0063: sub_float_lvar_from_float_lvar 5@ -= 4@^M
02F6: sin {angle} 5@ {var_result} 6@^M
02F7: cos {angle} 5@ {var_result} 7@^M
006B: mult_float_lvar_by_float_lvar 6@ *= 9@^M
006B: mult_float_lvar_by_float_lvar 7@ *= 9@^M
02F6: sin {angle} 12@ {var_result} 13@^M
02F7: cos {angle} 12@ {var_result} 14@^M
006B: mult_float_lvar_by_float_lvar 6@ *= 14@^M
006B: mult_float_lvar_by_float_lvar 7@ *= 14@^M
