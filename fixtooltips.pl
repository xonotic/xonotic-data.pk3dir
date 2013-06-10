use strict;
use warnings;
use Locale::PO;

sub quote($)
{
	my $s = shift;
	$s = '"' . quotemeta($s) . '"';
	return $s;
}
sub unquote($)
{
	my $s = shift;
	$s =~ s/^"//;
	$s =~ s/"$//;
	$s =~ s/\\(.)/$1/g;
	return $s;
}
my $po = Locale::PO->load_file_ashash("menu.dat." . $ENV{L} . ".po");
while(<>)
{
	/\\(.*?)\\(.*)/s or do { print; next; };
	my @s = split /\//, $1;
	@s = map { $po->{quote($_)} ? unquote($po->{quote($_)}->msgstr()) : $_ } @s;
	my $s = join "/", @s;
	$_ = "\\$s\\$2";
	print "$_";
}
