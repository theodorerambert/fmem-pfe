# Theodore Rambert, Gabe Kahen, Tim Lam
# Fmem-PFE
# Fmem Perl Front End
# Version 1.2
# Released Under the MIT License
# Uses Fmem (GPL), Perl (GPL), DD (GPLv3+) & Tk (BSD-style)



#!/usr/local/bin/perl
use strict;
use warnings;
use Tk;
use Tk::DirTree;
use Tk::Dialog;

my $text;
my($memsize, $curr_dir);
my @flags = (
	"1",	#noconv
	"1", 	#sync
	"1", 	#generate md5sum
	"1"		#use date as name
	);

#starting directory
$curr_dir = "";

#check our rights
if (index(`whoami`, "root") < 0)
{
	error("Requires root!");
	warn "[Error] Must be run as root.\n";
	exit;
}

#check for fmem
if (index(`stat /dev/fmem 2>&1`, "cannot stat") >= 0)
{
	error("Fmem not found.");
	warn "[Error] Fmem not found.\n";
	warn "You can download it from http://hysteria.sk/~niekt0/foriana/fmem_current.tgz\n";
	exit;
}

#pull the amount of installed RAM from logs
my $raw_mem_start = `free -m | grep Mem | awk '{ print \$2}'`;
warn "[Info] Raw memory line: $raw_mem_start";
$memsize = $raw_mem_start;

#create the file browsing window, then hide it
my $top = new MainWindow;
$top->withdraw;

#Create Window
my $mw = MainWindow->new;

my $w = $mw->Frame->pack(-side => 'top', -fill => 'x');

#Save To?
$w->Label(-text => "Destination:")->
			pack(-side => 'left', -anchor => 'e');

$w->Entry(-textvariable => \$curr_dir)->
    		pack(-side => 'left', -anchor => 'e', -fill => 'x', -expand => 1);

$w->Button(-text => "Choose", -command => \&dir)->
			pack(-side=> 'left', -anchor => 'e');

#Size?
my $w2 = $mw->Frame->pack(-side => 'top', -fill => 'x');


$w2->Label(-text => "Size in MB:")->
			pack(-side => 'left', -anchor => 'e');

$w2->Entry(-textvariable => \$memsize)->
    			pack(-side => 'left', -anchor => 'e', -fill => 'x', -expand => 1);

my $option1 = $mw->Frame->pack(-side => 'left');
$option1->Checkbutton (-text=>"noerror", -variable=>\$flags[0])->pack(-side => 'top', -anchor => 'w');
my $option2 = $mw->Frame->pack(-side => 'right');
$option2->Checkbutton (-text=>"sync", -variable=>\$flags[1])->pack(-side => 'top', -anchor => 'e');

my $option3 = $mw->Frame->pack(-side => 'top');
$option3->Checkbutton (-text=>"generate md5sum", -variable=>\$flags[2])->pack();
my $option4 = $mw->Frame->pack(-side => 'top');
$option4->Checkbutton (-text=>"use date as filename", -variable=>\$flags[3])->pack();

#note area
#enter notes here
$mw->title("Text Entry");

    $mw->Label(
        -text => "Enter Notes here:")->pack();
#Future To-Do
#$mw->Text(-width => '50', -height => '10', -textvariable => \$text) -> pack();
    $mw->Entry(
	-width => 50, 
	-textvariable => \$text)->pack();

#Fancy Buttons
my $w3 = $mw->Frame->pack(-side => 'top', -fill => 'x');
$w3->Button(-text => "Copy", -command => \&mem, qw/-background cyan/)->
    			pack(-side => 'left');
$w3->Button(-text => "Exit", -command => \&quit, qw/-background red/)->
			pack(-side => 'right', -anchor => 'w');


MainLoop;

sub mem 
{
	#If filename or memsize isn't defined || not a file || if memsize is not a positive number
	if(!defined $curr_dir || !defined $memsize  || !($memsize =~ /^[+]?\d+$/))
	{
		error("Undefined directory or bad memory size");
		warn "[Error] Undefined directory or memory size\n";
		exit;
	} 
	else
	{
		my $date = `date`;
		$date =~ s/\s//g;
		chomp($memsize);

	

		$curr_dir .= "/$date\_memory.dd";
		
		warn "[Info] Writing to: $curr_dir\n";

		if($flags[0] eq 1 && $flags[1] eq 1) #conv=noerror & sync chosen
		{
			warn "[Info] Running: dd if=/dev/fmem of=$curr_dir bs=1M count=$memsize conv=noerror,sync\n";
			my $output = `dd if=/dev/fmem of=$curr_dir bs=1M count=$memsize conv=noerror,sync 2>/dev/null`;
		}
		elsif($flags[0] eq 1 && $flags[1] ne 1) #conv=noerror chosen
		{
			warn "[Info] Running: dd if=/dev/fmem of=$curr_dir bs=1M count=$memsize conv=noerror\n";
			my $output = `dd if=/dev/fmem of=$curr_dir bs=1M count=$memsize conv=noerror 2>/dev/null`;
		}
		elsif($flags[0] ne 1 && $flags[1] eq 1) #sync chosen
		{
			warn "[Info] Running: dd if=/dev/fmem of=$curr_dir bs=1M count=$memsize sync\n";
			my $output = `dd if=/dev/fmem of=$curr_dir bs=1M count=$memsize sync 2>/dev/null`;
		}
		else
		{
			warn "[Info] Running: dd if=/dev/fmem of=$curr_dir bs=1M count=$memsize\n";
			my $output = `dd if=/dev/fmem of=$curr_dir bs=1M count=$memsize 2>/dev/null`;
		}
		#calc hash if chosen & check if file exists
		if(-e $curr_dir && $flags[2] eq 1)
		{
			
			if(defined $text)
        		{
                		my $file= $curr_dir . "_notes.txt";
				`openssl dgst -md5 $curr_dir > $file`;
				system("echo 'Notes for $curr_dir:' $text >> $file");
        		}
			else
			{
				`openssl dgst -md5 $curr_dir > $curr_dir.md5.txt`;
			}

		}
		#clear $curr_dur so we can make multiple images
		$curr_dir = "/";
	}
}

sub quit
{
	exit;
}

sub dir
{
	$top = new MainWindow;
	$top->withdraw;
	#create the window...
	my $t = $top->Toplevel;
	$t->title("Choose Output Folder");
	my $ok = 0;

	my $f = $t->Frame->pack(-fill => "x", -side => "bottom");
	my $d;
	$d = $t->Scrolled('DirTree',
		              -scrollbars => 'osoe',
		              -width => 35,
		              -height => 20,
		              -selectmode => 'browse',
		              -exportselection =>1,
		              -browsecmd => sub { $curr_dir = shift },
		              -command => sub { $ok = 1; },
		             )->pack(-fill => "both", -expand => 1);

	$d->chdir($curr_dir);
	$f->Button(-text => 'Ok',
		       -command => sub { $top->destroy; }) ->pack(-side => 'left');;
}

sub error
{
	my $err = new MainWindow;
	$err->withdraw;

	#Create Window
	my $DialogRef = $err->Dialog(
		-title => "Error",
		-text  => $_[0]
	);
	$DialogRef->Show();
}
