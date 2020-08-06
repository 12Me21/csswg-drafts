#!/usr/bin/perl

use strict;

my $sourcedir = shift @ARGV;

unless ($sourcedir) {
  print <<XXX;
= CSSWG Cross-Level Commit Script =

This script takes diffs from the specified directory,
applies them to all of that module’s specs with a higher level number,
and issues a `git commit` command if requested.

cross-commit.pl SPECDIR

For example,
  xcommit.pl css-grid-1
or
  xcommit.pl . # e.g. css-grid-1 as current dir

Your system’s `git` and `patch` commands are used.
Failed patches will be handled as usual for `patch`,
and will cause the commit to abort so you can fix it up
and commit manually.

Note: Assumes shortname-N naming scheme for SPECDIR and friends
at only one level of depth below git repo root.
XXX
  exit;
}

# Too lazy to look up the right way to do this
chdir $sourcedir || die "Invalid source directory: $!";
$sourcedir = `pwd`;
chomp $sourcedir;

# extract info
$sourcedir =~ m#(.*)/([^/]+)-([\d+])$#;
my $rootdir = $1;
my $specname = $2;
my $speclevel = $3;
my @failed = ();

# confirm before continuing
print "Sourcing diffs from $specname level $speclevel under root $rootdir:\n";
chdir $rootdir;
$_ = `ls -d $specname-*`;
my @dirlist = split;
print "Matching specs: @dirlist\n";

print "Press enter to continue, q to quit:";
$_ = <STDIN>;
chomp;
exit if ($_);

# main patching loop
foreach (@dirlist) {
  /(\d+)$/;
  my $level = $1;
  if ($level > $speclevel) {
    print "\nPatching $_ ...\n";
    chdir $_;
    print `git diff $sourcedir | patch -p2`;
    push @failed, $specname . '-' . $speclevel if $?;
    chdir $rootdir;
  }
}

# wrap it up
if (@failed == 0) {
  my $dirs = join ' ', @dirlist;
  print "\n\nWould you like me to issue `git commit $dirs`?\n";
  print "Enter arguments (e.g. -m 'message' --amend) or leave blank to skip commit.\n";
  print "git commit : ";
  my $args = <STDIN>;
  chomp $args;
  if ($args) {
    print "Executing git commit $args $dirs ...\n\n";
    exec "git commit $args $dirs";
  }
}
else {
  die "Patching failed for @failed, please fix and commit manually.\n";
}
