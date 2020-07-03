##!bin/perl -w
# Written by Nazar Zaki, CIT, UAEU, Aug 2008

($prot_interactions, $protein_seq, $window_size, $pos) = @ARGV;

# Put the protiens in a list
# **************************
open(INF, "<$prot_interactions");

$line = <INF>;
while ($line )
{
	$line =~ /(\S+)\s+(\S+)/;
	push @prot_lst, "$1";
	push @prot_lst, "$2";
	$line = <INF>;
}
close(INF);
$prot_pair = @prot_lst/2;

# Delete the duplicated protein in the array list
# ***********************************************
my %Seen   = ();
foreach my $elem (@prot_lst)
{
	next if $Seen{ $elem }++;
	push @prot_no_repeat, $elem;
}
$seq_no = @prot_no_repeat;
print "$prot_pair training protein pairs with $seq_no proteins invlove.\n";

# Replace the protein lables by integers
# **************************************
open (FILE,"<$protein_seq");
open (OUT,">data.s");

$i=1;
while (<FILE>)
{
	if (/>/)
	{
		s/.*/>$i /;
		print OUT $_;
		$i++;
		chomp  $_;
	}else{
		print OUT $_;
	}
}
close (FILE);
close (OUT);

# Making Subsequenses
# *******************
open (inF,"<$protein_seq");
open (oF,">out.s");
while (<inF>)
{
	s/>.*//g;
	s/\r?\n//g;
	print oF $_;
}
close (inF);
close (oF);

open (inF,"<out.s");
open (oF,">subsequence.txt");

$all=<inF>;
my $i=1;

while($all=~ /(.{1,$window_size})/ig)
{
	print oF  ">$i\n";
	print oF "$1\n";
	$i++;
}
close (inF);
close (oF);

$sub_no = $i-1;
print "Sub-sequences are $sub_no.\n";

# Returning one substring at a time
# *********************************
open IN,"<subsequence.txt";
$line = "0";
while(<IN> )
{
       chomp;
       open OUT,">testfile.s" if $line == 0;
       print OUT "$_\n";
       $line++;
       if($line == 2){ close OUT;

# Running FASTA
#**************
print ".";
system "./fasta34.exe -q -s BL50 -f -13 -g -3 -d 0 -H -b $seq_no testfile.s data.s > fastaoutput.s";

# Returning the sequence label and score lines
# ********************************************
@arrayone=();
open (File,"<fastaoutput.s");
while(<File>)
{
	if (/(\d.* \s+\(.*)/)
	{
		push @arrayone, "$1\n";
	}
}
close File;

# Sorting
# *******
@arraytwo=();
for (@arrayone)
{
	chomp; push @array, $_;
	if (@array == $seq_no) 
	{
		@AB = sort { $a <=> $b; } @array;
		foreach (@AB)
		{
			push @arraytwo, "$_\n";
		}
		@array = ();
	}
}

# Returning the scores only and push them to an array
# ***************************************************
@score=();
for (@arraytwo)
{
		/\d.*\s+\(*.*\)\s+(\S+)\s+(\S+)\s+(\S+)/;
	push @score," $2\n";
}
close File;

# save the score of the substrings in columns
# *******************************************

@new = @score;
chomp @new;
$file = "matrix.s";
@prev = ();
open(fhOut, "$file");
while ($Line = <fhOut>)
{
	chomp($Line);
	push (@prev,$Line);
}
close fhOut;

open(fhOut, ">$file") or die "can't open $file";
$i=0;
if ($#prev <= 0)
{
	$spc = "";
}else{
	$spc = "";
}
foreach (@new)
{
	$Line = $prev[$i++];
	$Line = $Line . $spc . $_ . "\n";
	print fhOut $Line;
}
$line = "0";
}
}
print "\n";
close (fhOut);

# Add labels to the protein features
# **********************************
open(File,"<matrix.s");
foreach $p(<@prot_no_repeat>)
{
	for ($b = <File>)
	{ push @features, "$p $b"; }
}
close(File);

# Concatenating featues and prepare the training file
# ***************************************************
open(INFO,"<$prot_interactions");
open(OUT,">tr_examples.txt");

$size = @features;
print OUT "Protein";

for $i(1..$sub_no*2)
{
		print OUT "\tM$i"
}
print OUT "\n";

$no = 1;
while ($line = <INFO>)
{
	($p1, $p2) = split(/\s+/,$line);
	$i=0; $flag = 0;
	while($i<$size && !$flag)
	{
		$features[$i] =~ /(\S+)\s/;
		if($1 eq $p1)
		{
			$str = $features[$i];
			chomp($str);
			$str =~ s/\S+\s//;
			$str =~ s/\s+/\t/g;
			print OUT "$no\t$str";
			$no++;
			$flag = 1;
		}
		$i++;
	}
	$i=0; $flag=0;
	while($i<$size && !$flag)
	{
		$features[$i] =~ /(\S+)\s/;
     		if($1 eq $p2)
		{
			$str = $features[$i];
			chomp($str);
			$str =~ s/\S+\s//;
			$str =~ s/\s+/\t/g;
			print OUT "$str";
			$flag = 1;
		}
		$i++;
	}
	print OUT "\n";
}
close(INFO);
close(OUT);

# Creating the index file
#************************
open (outFile,">tr_labels.txt");
print outFile "Protein\tNo\n";
for ($i = 1; $i <= $pos; $i++){
		print outFile "S $i\t1\n";
}
for ($i = $pos+1; $i <= $prot_pair; $i++){
	print outFile "S $i\t-1\n";
}
close (outFile);

# Delete unneeded files
# *********************
system "rm *.s";
