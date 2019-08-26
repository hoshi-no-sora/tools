#!/usr/bin/perl -w
#
# [ 使用方法及び効果(目的) ]
# 元ファイルを.plファイル(本ファイル)と同じディdレクトリにコピーし実行すれば、
# windinfo_extractionというディレクトリに抽出した複数列の txtファイルができる。
###################################################################

use warnings;
use strict;
# file move
use File::Copy;

# splitting letter for split function
# regular expression( \s+ : space)
my $sepatator = '\s+';
#my $sepatator = ","; 

our $year   = '2017';
our $month  = '08';
our $day    = '09';
our $second = '00';

###################################################################

# [ making directory ]
mkdir 'windinfo_extraction', 0700 or warn "Cannot make windinfo_extraction directory: $!";

# our : strict環境では宣言が必要でmyが推奨される。
#       myの代わりにourを使えばグローバル変数宣言となる！
our $i = 0;
foreach(@ARGV){
&processing;
$i = $i +1;
}


###################################################################
###################################################################

sub processing {
#==============================================#
####my $filename = $ARGV[0];

my $filename = $ARGV[$i];

my @row = ();
# IN : filehandle name
open(IN, "$filename") or die("> error : $!");
while(<IN>){
  if ($. >= 4){
    chomp;
    push(@row, $_);
    #print "$_\n";
  }
}
close(IN);

#print "@row\n";
my @array = ();
#my @column = ();

foreach(@row){
  # print "$_\n";
    my @column = split(/$sepatator/, $_);
    if ( ($column[2] >= 0) && ($column[2] <= 9) ){$column[2] = 0 . $column[2]}
    if ( ($column[3] >= 0) && ($column[3] <= 9) ){$column[3] = "0$column[3]"}
    push(@array, "$year $month $day $column[2] $column[3] $second $column[5] $column[7]");
    print        "$year $month $day $column[2] $column[3] $second $column[5] $column[7]\n"
}

# output
my $outfile = "extract_" . $filename;
open(DATA, ">./$outfile");
print DATA "$_\n" foreach(@array);
close(DATA);
#==============================================#
my $orgfile = './' . $outfile;
my $mvfile  = './windinfo_extraction/' . $outfile;
print "$outfile\n";
move $orgfile, $mvfile or die $!; 
}


#################################
# [memo] 以下でもよい！
#my $time = join ":" $hour $min

