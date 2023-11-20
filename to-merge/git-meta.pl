#!/usr/bin/perl -w

our $VERSION='0.20231111';	# Please use format: major_revision.YYYYMMDD[hh24mi]

=head1 NAME

git-meta.pl - solution for maintaining all the file dates, times, ownership, and access permissions in git
.git/hooks/pre-commit	- this same perl script, when it has the name "pre-commit" assumes you're running "git-meta.pl -save"
.git/hooks/post-merge	- this same perl script, when it has the name "post-merge" assumes you're running "git-meta.pl -restore"

newgit.pl		- this same perl script, when it has the name "newgit.pl", behaves as if the -newgit option was supplied - see below.

=head1 SYNOPSIS


	# creates the pre-commit and post-merge hooks (see below)
	cd ~/myrepo
	git-meta.pl -setup -l /usr/local/bin/git-meta.pl
	-or-
	git-meta.pl -setup


	# Typically called from the pre-commit
	cd ~/myrepo
	git-meta.pl -save [optional list of files]


	# Typically called from post-merge
	cd ~/myrepo
	git-meta.pl -restore [optional list of files]


	# sets up your system to automatically extract files every time you push - handy for working on your own private mahcines, such as when maintaining web servers.
	newgit.pl ... see below

	Note: adds the file .git-meta to your project
	Recommend: set up .gitignore properly first

=head2 OPTIONS

	-f		# Specify the meta filename to use ( defaults to .git-meta )
	-save		# Save into the .git-meta. Saves all files if none are provided
	-restore	# Restore from the .git-meta. Restores all files if none are provided
	-setup		# create the necessary pre-commit and post-merge files to activate this solution in your repo
	-strict		# Stop with errors instead of assume what the user wants (partially implimented)
	-dryrun		# Show what would be done, without doing it (partially implimented)
	-debug		# print everything going on
	-l		# use a symlink when doing setup, for pre-commit and post-merge (e.g. -l /usr/local/bin/git-meta.pl) - otherwise - copies the file there.

=head2 .git-meta file format

	# lines starting with # are comments
	octal file mode, owner, group, mtime, atime, spare1, spare2, filename

=head2 known issues

	Only handles .gitignore files found inside your repo (not any set in your profile or elsewhere)




=head1 NAME

newgit.pl - create a new, optionally auto-extracting, private git repo, with preservation of file metadata (dates/time, permissions, ownership)
 -or-
git-meta.pl -newgit

=head1 SYNOPSIS

	newgit.pl gitname [optional-auto-extract-location]
	# creates gitname				# this is where master files live. Uses $master_location/gitname unless gitname starts with /
	# creates ./gitname				# this is a local working folder for editing your files etc (you can "git clone" more of these later)
	# maybe creates optional-auto-extract-location	# this is where they'll be auto-extracted (properly includes mv/rm etc) upon all git push operations

	SCREW_UP_DATES=1 newgit.pl gitname [optional-auto-extract-location]
	# same as above, omitting the hooks which preserve dates/permissions/ownership

	DRYRUN=1 newgit.pl gitname [optional-auto-extract-location]
	DRYRUN=1 SCREW_UP_DATES=1 newgit.pl gitname [optional-auto-extract-location]
	# same as either of the above two, but doing nothing (shows what commands will be executed)

=head2 Example

	newgit.pl leoweb ~/leo/public_html

=head2 File location info

	if there's no "/" within "gitname", it will put the files into $master_location/gitname (e.g. ~/Downloads/gitblobs/gitname ) by default

=cut
######################################################################


use bytes;		# don't break UTF8
use strict;
use warnings;		# same as -w switch above

use POSIX;		# for strftime
use Time::HiRes;	# Getting file microseconds
use Getopt::Long;	# Commandline argument parsing
use Pod::Usage;		# Inbuilt documentation helper
my %gitignore;		# global
my %names;my $i=0;$names{$_}=$i++ foreach(qw(mode owner group mtime atime spare1 spare2 filename));

my $is_tty_out = (!-f STDOUT) && ( -t STDOUT && -c STDOUT);	# -f is a file, -t is a terminal, -c is a character device
my ($norm,$red,$grn,$yel,$nav,$blu,$save,$rest,$clr,$prp,$wht)=!$is_tty_out ? ('','','','','','','','','','','') : ("\033[0m","\033[31;1m","\033[32;1m","\033[33;1m","\033[34;1m","\033[36;1m","\033[s","\033[u","\033[K","\033[35;1m","\033[37;1m"); # so we can print colour output if we want.


my %arg;&GetOptions('help|?'	=> \$arg{help},			# breif instructions
		    'f=s'	=> \$arg{gitmeta},		# meta filename
		    'save'	=> \$arg{save},
		    'restore'	=> \$arg{restore},
		    'strict'	=> \$arg{strict},		# stop instead of assume
		    'debug'	=> \$arg{debug},
		    'setup'	=> \$arg{setup},
		    'dryrun'	=> \$arg{dryrun},		# not full implimented!
		    'l=s'	=> \$arg{l},
		    'newgit'	=> \$arg{newgit},
	   ) or &pod2usage(2); 
no warnings;
	   &pod2usage(1) if ($arg{help});			# exits
use warnings;
$arg{gitmeta}=".git-meta" unless($arg{gitmeta});
$arg{dryrun}=$ENV{'DRYRUN'} unless($arg{dryrun});		# debugging - set the switch or env var to 1 if you want to print, but not execute, the commands
my $dryrun=$arg{dryrun};


# Change the personality of this program, depending on what name $0 it has:
if($0=~/pre-commit/) {
  $arg{save}=1;
  my @staged_files=`git diff --cached --name-only`;
  chomp(@staged_files);
  @staged_files=('.') unless(@staged_files);
  # warn "$blu doing:" . join("^",@staged_files) . "$norm\n";
  # print "$blu doing:" . join("^",@staged_files) . "$norm\n";
  @ARGV=@staged_files;
}

if($0=~/post-merge/) {
  $arg{restore}=1;
  @ARGV='.'; # do/check everything
}

if($0=~/newgit/) {
  $arg{newgit}=1;
}






######################################################################
if($arg{newgit}) {
  
  # newgit settings
  
  my $master_location=$ENV{"HOME"}."/gitblobs"; # Change this to whatever default folder you want to use for storing master copies of files
  &do("mkdir -p $master_location") unless(-d $master_location);
  
  my $gitprog=''; open(IN,'<',$0) or die "Could not open file '$0' $!";
  $gitprog.=$_ while(<IN>);
  close(IN); # Reads in ourself - for git-meta.pl to use
  my $hookfolder='';
  
  $ARGV[0]='-' unless($ARGV[0]); # see next
  foreach(@ARGV){die "Usage:\t$0 gitname [optional-auto-extract-location]" if(/^-/);} # stop if they're confused
  my $gitblob=$ARGV[0]; $gitblob="$master_location/$ARGV[0]" unless($ARGV[0]=~/\//);
  die "Sorry, $gitblob exists" if(-e $gitblob);
  my $gitnamee=$ARGV[0]=~s/([\$\#\&\*\?\;\|\>\<\(\)\{\}\[\]\"\'\~\!\\\s])/\\$1/rg;
  my $gitblobe=$gitblob=~s/([\$\#\&\*\?\;\|\>\<\(\)\{\}\[\]\"\'\~\!\\\s])/\\$1/rg;	# shell-escape for dummies who use spaces in filenames
  my $workblob=$ARGV[0];
  my $workblobe=$ARGV[0]=~s/([\$\#\&\*\?\;\|\>\<\(\)\{\}\[\]\"\'\~\!\\\s])/\\$1/rg;
  my $target=$ARGV[1] if($ARGV[1]);
  my $targete=$ARGV[1]=~s/([\$\#\&\*\?\;\|\>\<\(\)\{\}\[\]\"\'\~\!\\\s])/\\$1/rg if($ARGV[1]);
  my $pwd=`pwd`=~s/([\$\#\&\*\?\;\|\>\<\(\)\{\}\[\]\"\'\~\!\\\t ])/\\$1/rg;chomp($pwd);
  
  $workblobe="$pwd/$workblobe" unless($workblobe=~/^\//);
  $targete="$pwd/$targete" unless(!$target || $targete=~/^\//);
  
  &msg("# Create the master location");
  &do("mkdir -p $gitblobe");	# ~/Downloads/gitblobs/foo
  &do("cd $gitblobe;git init --bare;cd $pwd");
  
  # Set up auto-extract if wanted
  if($targete) {
    &msg("# Set up auto-extract into $targete");
    my $targetee=$targete=~s/\\/\\\\/rg;
    if(!-e $targete){
      &do("mkdir -p $targete") unless(-e $target);
    } else {
      print $red."Caution: '$target' exists: files in here will be overwritten by future 'git push' operations$norm\n";
    }
    &do("cd $gitblobe/hooks/;cat >post-update <<\\EOF
#!/bin/bash
printf \"post-update: running...\\n\"
env -u GIT_DIR git -C $targetee pull || exit
printf \"post-update: ran ok $targetee\\n\"
EOF");
    &do("cd $gitblobe/hooks/;chmod -c +x post-update;cd $pwd");
    &do("cd $targete;git clone $gitblobe; mv $gitnamee/.git .;rmdir $gitnamee;cd $pwd");
    &do("touch $targete/AUTOGENERATED_FOLDER-DOT_NOT_EDIT");
  
    unless($ENV{'SCREW_UP_DATES'}) {
      &msg("# Setting up '$target' to preserve dates");
      # unless($gitprog) { $gitprog.=$_ while (<DATA>); } # Reads from the end of this file
      my(@pfn)=&preserve_dates($target,$hookfolder,$gitprog);
    }
    
  } # targete
  
  &msg("# Create one initial working folder");
  &do("mkdir -p $workblobe") if($workblobe);	# ./foo
  &do("cd $workblobe;git clone $gitblobe; mv $gitnamee/.git .;rmdir $gitnamee;cd $pwd");
  unless($ENV{'SCREW_UP_DATES'}) {
    &msg("# Setting up '$workblob' to preserve dates");
    # unless($gitprog) { push $gitprog.=$_ while (<DATA>); } # Reads from the end of this file
    my(@pfn)=&preserve_dates($workblob,$hookfolder,$gitprog);
    print($blu."If doing \"git clone\" in other machines later, remember to copy the following files into your new location .git/hooks/ folder too:\n\t".join("\n\t",@pfn)."$norm\n");
  }
  
  
  &msg("# Done! Try these next perhaps:\ncd $ARGV[0]\necho hello>index.html\ngit add index.html\ngit commit -m Initial_Commit\ngit push" . ( $target? "\ndir $target" : ""));
  # Done!
  exit(0);
} # newgit
######################################################################









if($arg{setup}) {
  my $hookfolder='.git/hooks';
  $hookfolder='hooks' unless(-d $hookfolder);
  die "No hooks folder: must run this from inside your repo folder." unless(-d $hookfolder);

  #my $gitprog=''; push $gitprog.=$_ while (<DATA>); # Reads from the end of this file - for newgit to use
  # unless($gitprog) { push $gitprog.=$_ while (<DATA>); } # Reads from the end of this file
  my $gitprog=''; open(IN,'<',$0) or die "Could not open file '$0' $!";
  $gitprog.=$_ while(<IN>);
  close(IN); # Reads in ourself - for git-meta.pl to use
  &preserve_dates('.',$hookfolder,$gitprog);
  
  exit(0);
}

my(@meta,%meta); &LoadMeta($arg{gitmeta});			# Get existing metadata

if($arg{save}) {
  &GetIgnore();
  &GetMeta(undef,@ARGV);					# Append new metadata to @meta
  &SaveMeta($arg{gitmeta});					# Write new metadata to file
  `git add $arg{gitmeta}` if($0=~/pre-commit/);			# save the metadata with this commit too
} elsif($arg{restore}) {
  &GetIgnore();
  my @files=&GetMeta('nosave',@ARGV);				# which files to restore
  &RestoreMeta(@files);						# restore all or some file metadatas
  
} else {
  &pod2usage(1);
}



# warn '%meta='. join("^",%meta); warn '@meta='. join("^",@meta);



# Load the .gitignore file into a hash
sub GetIgnore {
  $gitignore{'.git'}++ if(-e '.git');	# don't do the git blobs
  $gitignore{$arg{gitmeta}}++;		# don't do our own metafile
  #$gitignore{'./.git'}++ if(-e '.git');
  if(-e '.gitignore') {
    open(IN,'<','.gitignore') or die "open .gitignore: $!";
    while(<IN>) {
      chomp; $gitignore{$_}++; # $gitignore{"./$_"}++;
    }
    close(IN);
  }
} # GetIgnore



# Update @meta and %meta with metadata from a filesystem file or folder
sub MetaFile {
  my($nosave,$filename)=@_;

  my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks)=Time::HiRes::lstat($filename); # the symlink itself, not the target

  # Retrieve specific file information
  my $permissions = sprintf "%04o", $mode & 07777;

  # Convert numeric user ID and group ID to names
  my $owner_name = getpwuid($uid);
  my $group_name = getgrgid($gid);

  my $microsecs_m=($mtime=~/(\.\d+)/)[0] // ""; # returns .456 or (if no decimal places) just ""
  my $humantime_m= strftime("%Y-%m-%d %H:%M:%S",localtime($mtime)) . $microsecs_m . strftime(" %z", localtime()) ;
  my $microsecs_a=($atime=~/(\.\d+)/)[0] // ""; # returns .456 or (if no decimal places) just ""
  my $humantime_a= strftime("%Y-%m-%d %H:%M:%S",localtime($atime)) . $microsecs_a . strftime(" %z", localtime()) ;
  # For later use thusly: touch -hcmd "2023-11-10 06:39:09.1234 +0000" filename

  my @fm=($permissions, $owner_name, $group_name, $humantime_m, $humantime_a,"","",$filename);

  return \@fm if($nosave); # restore-er made the call

  # warn join(",",@fm);
  # warn join(",",@{$meta[ $meta{$fm[-1]} ]}) if (defined  $meta{$fm[-1]} );

  if ( (! defined $meta{$fm[-1]})  ||  (join(",",@{$meta[ $meta{$fm[-1]} ]}) ne join(",",@fm) ) ) {
    push @meta,\@fm; # store everything in the original order inside an array
    $meta{$fm[-1]}=$#meta; # keep a searchable hash of the filenames as we go.  This on-purpose will overwrite old duplicates with new times later.
    print "STORED: ARRAY $fm[-1] at index $#meta\n" if($arg{debug});
  } else {
    print "Skipped unchanged file $fm[-1]\n" if($arg{debug});
  }

  if(0 && $arg{debug}) {	# Display the retrieved information
    print "File: $filename\n";
    print "Permissions suitable for chmod: $permissions\n";
    print "Owner: $owner_name\n";
    print "Group: $group_name\n";
    print "Last Modification Time (touch format): $mtime\n";
    print "Last Modification Time (human + format): $humantime_m\n";
    print "Last Access Time (touch format): $atime\n";
    print "Last Access Time (human + format): $humantime_a\n";
    print '(' . join(',',@fm) . ")\n";
  } # debug

  return \@fm;
} # MetaFile



# Load a .git-meta file into @meta and %meta
sub LoadMeta {
  my($metafile)=@_;
  if(!-f $metafile) {
    die "Expecting -f $metafile" if $arg{strict};
    print STDERR $yel."Warning: no $metafile" . ($arg{save} ? " (it will be created next)" : "") . "$norm\n";
  } else {
    open(IN,'<',$metafile) or die "$metafile: $!";
    while(<IN>) {
      chomp;
      my $fm=$_; 
      unless(/^\s*#/) {
        my @fm=split(/,/,$_,8); $fm=\@fm;
	if (ref $meta{$$fm[-1]} && join(',',@{$meta{$$fm[-1]}}) eq $_) {
	  $fm=undef;
	  print "Skipping unchanged file info for $$fm[-1]\n" if($arg{debug});
	}
      }
      push @meta,$fm; # store everything in the original order inside an array
      print "STORED: $fm at index $#meta\n" if($arg{debug});
      $meta{$$fm[-1]}=$#meta if(ref $fm); # keep a searchable hash of the filenames as we go.  This on-purpose will overwrite old duplicates with new times later.
    }
    close(IN);
  }
} # LoadMeta



# Write out (overwrite) our @meta and %meta into the .git-metafile, keeping original order
sub SaveMeta {
  my($metafile)=@_; my %done;
  open(OUT,'>',$metafile) or die "write: $metafile: $!";

  my $commit_author=`git config user.name`; chomp $commit_author; $commit_author .= ' <' . `git config user.email`; chomp $commit_author; $commit_author .= '> at ' . strftime("%Y-%m-%d %H:%M:%S %z",localtime());

  # my $current_branch=`git rev-parse --abbrev-ref HEAD`; chomp $current_branch;
  
  print OUT "# octal file mode, owner, group, mtime, atime, spare1, spare2, filename\t# https://github.com/gitcnd/git-meta.git v$VERSION\n" if(ref $meta[0]);
  print OUT "# last: $commit_author\n" if(ref $meta[0]);
  
  for(my $i=0; $i<=$#meta;$i++) {
    # warn "i=$i"; warn "fn=" . $meta[$i]->[-1]; warn "idx=" . $meta{ $meta[$i]->[-1] };
    if(!ref $meta[$i]) { # comment
      if($meta[$i]=~/^# last: /) {
	print OUT "# last: $commit_author\n"; # discard the old last: author remark
      } else {
	print OUT $meta[$i] . "\n";
      }
    } elsif( !$done{$meta[$i]->[-1]}++ ) { 	#   $meta{ $meta[$i]->[-1] }==$i ) 	# new or unchanged
      my $newest_i=$meta{ $meta[$i]->[-1] };
      print OUT join(',',@{$meta[$newest_i]}) . "\n";	# "$meta[$i]->[-1]" is the filename, and the outer $meta{  } is the hash of the filename, which contains the @meta index number of the most recent info to use
    } else {
      print "Skipping appended $meta[$i]->[-1] at index $i because we earlier overwrote the older one from here: $meta{ $meta[$i]->[-1] }\n" if($arg{debug}); 
    }
  }
  close(OUT);
} # SaveMeta



# Recursively spider the input set of files, calling MetaFile on them all to add them into @meta and %meta
sub GetMeta {
  my ($nosave,@files) = @_;

#warn join("^",@files);

  for(my $i=0; $i<=$#files;$i++) {
    my $f=$files[$i];
#warn "$i: $f";
    if(-d $f) {
      opendir(my $dh, $f) or die "Could not open '$f' for reading: $!";
      while (my $subfile = readdir($dh)) {
        next if $subfile eq '.' or $subfile eq '..';
        push @files, ($f eq '.' ? $subfile : "$f/$subfile") unless($gitignore{$f} || $gitignore{"$f/$subfile"}); #  || $f eq '.' );
      }
      closedir($dh);
    }
    &MetaFile($nosave,$f) unless($nosave || $gitignore{$f} || $f eq '.');	# add file *and* folders to .git-meta @meta and %meta ram storage

  } # for
  return @files;
} # GetMeta



# restore metadata for the named files
sub RestoreMeta {
  my (@files) = @_;
  my $fixed=0;

  foreach my $f (@files) {
    if( ! $meta{ $f } ) {
      print "No metadata for $f... skipping\n" if($arg{debug});
      next;
    }

    my $nowfm=&MetaFile('nosave',$f);
    my $newfm=$meta[ $meta{ $f } ]; my $n;
    my $qmf=$f=~s/([\$\#\&\*\?\;\|\>\<\(\)\{\}\[\]\"\'\~\!\\\s])/\\$1/rg;        # shell-escape for dummies who use spaces in filenames

    if ( join(',',@$nowfm) ne join(',',@$newfm) ) {
      # mode owner group mtime atime spare1 spare2 filename

      $n='mode';
      if( $nowfm->[$names{$n}] ne $newfm->[$names{$n}] ) {
	my $cmd="chmod $newfm->[$names{$n}] $qmf";
	print "$grn$cmd$norm\n" if($arg{debug});
	print $yel . `$cmd` . $norm unless($dryrun);
      }

      $n='owner';
      if( $nowfm->[$names{$n}] ne $newfm->[$names{$n}] ) {
	my $cmd="chown $newfm->[$names{$n}] $qmf";
	print "$grn$cmd$norm\n" if($arg{debug});
	print $yel . `$cmd` . $norm unless($dryrun);
      }

      $n='group';
      if( $nowfm->[$names{$n}] ne $newfm->[$names{$n}] ) {
	my $cmd="chgrp $newfm->[$names{$n}] $qmf";
	print "$grn$cmd$norm\n" if($arg{debug});
	print $yel . `$cmd` . $norm unless($dryrun);
      }

      $n='mtime';
      if( $nowfm->[$names{$n}] ne $newfm->[$names{$n}] ) {
	my $cmd="touch -hcmd \"$newfm->[$names{$n}]\" $qmf";
	print "$grn$cmd$norm\n" if($arg{debug});
	print $yel . `$cmd` . $norm unless($dryrun);
      }

      $n='atime';
      if( $nowfm->[$names{$n}] ne $newfm->[$names{$n}]  && $f ne '.gitignore') {	# we read this ourselves, so the atime always changes
	my $cmd="touch -hcad \"$newfm->[$names{$n}]\" $qmf";
	print "$grn$cmd$norm\n" if($arg{debug});
	print $yel . `$cmd` . $norm unless($dryrun);
      }
      $fixed++;
    } else {
      print "Skipping unchanged file $f\n" if($arg{debug});
    }
  }
  return $fixed
} # RestoreMeta


# Caution: these subs msg and do in 3 places
sub msg{ print "\n$wht$_[0]$norm\n"; }
sub do {
  my($cmd)=@_;
  print "$grn$cmd$norm\n";
  print $yel.`$cmd`.$norm unless($dryrun);
}

# CAUTION!! This code in 3 places (inside newgit.pl, and ALSO inside git-meta.pl and in the the pre-commit and post-merge DATA sections of newgit.pl)
sub preserve_dates {
  my($base,$hookfolder,$gitprog)=@_;

  $hookfolder="$base/hooks" unless($hookfolder && -d $hookfolder);
  $hookfolder="$base/.git/hooks" unless(-d $hookfolder);
  die "No hooks folder ($hookfolder from ".`pwd`."): must run this from inside your repo folder." unless(-d $hookfolder);

  my $precommit="$hookfolder/pre-commit";	# $base/.git/hooks/pre-commit
  my $postmerge="$hookfolder/post-merge";	# $base/.git/hooks/post-merge

  # my $gitprog=''; push $gitprog.=$_ while (<DATA>); # Reads from the end of this file
  if(!$dryrun) {
    if(-e $precommit) {
      print $yel."Caution: moved existing $precommit to $precommit.save$norm\n";
      rename($precommit,"$precommit.save");
    }
    if(-e $postmerge) {
      print $yel."Caution: moved existing $postmerge to $postmerge.save$norm\n";
      rename($postmerge,"$postmerge.save");
    }
  }

  if($arg{l}) {
    &do("ln -s $arg{l} $precommit");
  } else {
    open(OUT,'>>',$dryrun ? '/dev/null' : $precommit) or die "Cannot create file '$precommit': $!";
    print OUT $gitprog; close(OUT); 
  }

	#commit_author="$(git config user.name)"" <""$(git config user.email)"">" 
	#commit_message=$(cat $1)
	#current_branch=$(git rev-parse --abbrev-ref HEAD) #from https://dev.to/anibalardid/how-to-check-commit-message-and-branch-name-with-git-hooks-without-any-new-installation-n34
	#https://github.com/typicode/husky/discussions/1171

	# Get a list of all staged files
	#staged_files=$(git diff --cached --name-only)

	#bash .git/hooks/git-meta --store
	#git add .git-meta
	# echo "Done. Meta has been preserved!"

  my $precommite=$precommit=~s/([\$\#\&\*\?\;\|\>\<\(\)\{\}\[\]\"\'\~\!\\\s])/\\$1/rg;
  &do("chmod ugo+x $precommite");


  if($arg{l}) {
    &do("ln -s $arg{l} $postmerge");
  } else {
    open(OUT,'>>',$dryrun ? '/dev/null' : $postmerge) or die "Cannot create file '$postmerge': $!";
    print OUT $gitprog; close(OUT);
  }
	#q#!/bin/bash
	#echo "Restoring files' timestamp, CID/hash; and other files/commit's metadata..."
	#bash .git/hooks/git-meta -r
	#echo "Done. Meta has been restored!"

  my $postmergee=$postmerge=~s/([\$\#\&\*\?\;\|\>\<\(\)\{\}\[\]\"\'\~\!\\\s])/\\$1/rg;
  &do("chmod ugo+x $postmergee");

  return($precommit,$postmerge);
} # preserve_dates

