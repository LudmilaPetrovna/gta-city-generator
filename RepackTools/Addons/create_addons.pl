#!/usr/bin/perl

use utf8;
use File::Slurp;
use File::Basename;
use File::Path qw(make_path remove_tree);
use Data::Dumper;
use Encode;

mkdir("__Addons");
@install=();
@summary=();

foreach $pi(split(/\n\n+/,read_file("packages.txt"))){
%pi=map{split(/:/,$_,2)}split(/\n/,$pi);
if(!exists $pi{file}){
$pi{file}=basename($pi{load});
}
$cache_file="cache/".$pi{file};
$output="__Addons/$pi{name}";
if(!-s($cache_file) && $pi{load}){
`curl -Lo "$cache_file" "$pi{load}"`;
}
if(!-s($cache_file)){next;}
$opts=" -o -d \"$output\" ";
if(exists $pi{use} || exists $pi{path}){
$opts.="-j ";
}
@files=();
if($pi{use}){
@files=map{$pi{path}?$pi{path}.'/'.$_:$_}split(/;/,$pi{use});
} else {
@files=();
}
$files=join(" ",map{"\"$_\""}@files);
print `echo unzip $opts $cache_file $files`;
`unzip $opts $cache_file $files`;
write_file($output.'/readme-'.$pi{name}.'.txt',encode("cp1251",decode_utf8($pi{info})));

foreach $file(split(/;/,$pi{tweak})){
print `cp -v tweaks/$file $output`;
}
if(!$pi{noinstall}){
push(@install,$pi{name});
}
push(@summary,"**$pi{name}**: $pi{info} ($pi{home})");
print Dumper(\%pi);


}

write_file("__Addons/install_all.bat",join("",map{"xcopy.exe /E /Y $_ ..\r\n"}@install));


print map{"".(++$uid).". ".$_."\n"} @summary;

