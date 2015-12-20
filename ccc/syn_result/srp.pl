#!/usr/bin/perl
use warnings;
use strict;
my @design_list = qw(Scalar VLIW MSA dual);
my @cyc_list    = (15..25);

# power parser
open my $ofh, '>', "power.csv";
print $ofh "design\\cyc";
foreach my $cyc (@cyc_list)
{
    print $ofh ',', $cyc/10;
}
print $ofh "\n";
foreach my $design (@design_list)
{
    print $ofh $design;
    foreach my $cyc (@cyc_list)
    {
        my $file = "$design\_$cyc\.power";
        open my $ifh, '<', $file;
        while( my $line = <$ifh>)
        {
            if( $line =~ m/Total Dynamic Power/)
            {
                my @tokens = split /\s+/, $line;
                my $power =  $tokens[4];
                print $ofh ',', $power; 
            }
        }
    }
    print $ofh "\n";
}
close $ofh;

# area parser
open $ofh, '>', "area.csv";
print $ofh "design\\cyc";
foreach my $cyc (@cyc_list)
{
    print $ofh ',', $cyc/10;
}
print $ofh "\n";
foreach my $design (@design_list)
{
    print $ofh $design;
    foreach my $cyc (@cyc_list)
    {
        my $file = "$design\_$cyc\.area";
        open my $ifh, '<', $file;
        while( my $line = <$ifh>)
        {
            if( $line =~ m/Total area:/)
            {
                my @tokens = split /\s+/, $line;
                my $area =  $tokens[2];
                print $ofh ',', $area; 
            }
        }
    }
    print $ofh "\n";
}
close $ofh;


