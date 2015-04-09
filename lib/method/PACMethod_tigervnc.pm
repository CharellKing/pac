package PACMethod_tigervnc;

##################################################################
# This file is part of PAC( Perl Auto Connector)
#
# Copyright (C) 2010-2014  David Torrejon Vaquerizas
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###################################################################

$|++;

###################################################################
# Import Modules

# Standard
use strict;
use warnings;
use FindBin qw ( $RealBin $Bin $Script );

# GTK2
use Gtk2 '-init';

# END: Import Modules
###################################################################

###################################################################
# Define GLOBAL CLASS variables

my $RES_DIR = $RealBin . '/res';
my %COLOURS = ( 8 => 0, 64 => 1, 256 => 2, 'AutoSelect' => 3 );
my %REVCOLOURS = ( 0 => 0, 1 => 1, 2 => 2, 'AutoSelect' => 3 );

# END: Define GLOBAL CLASS variables
###################################################################

###################################################################
# START: Public class methods

sub new
{
	my $class	= shift;
	my $self	= {};
	
	$self -> {container}	= shift;
	
	$self -> {cfg}			= undef;
	$self -> {gui}			= undef;
	$self -> {frame}		= {};
	
	_buildGUI( $self );
	
	bless( $self, $class );
	return $self;
}

sub update
{
	my $self	= shift;
	my $cfg		= shift;
	
	defined $cfg and $$self{cfg} = $cfg;
	
	my $options = _parseCfgToOptions( $$self{cfg});
	
	$$self{gui}{chFullScreen}		-> set_active( $$options{fullScreen} );
	$$self{gui}{chListen}			-> set_active( $$options{listen} );
	$$self{gui}{chViewOnly}			-> set_active( $$options{viewOnly} );
	$$self{gui}{spQuality}			-> set_value( $$options{quality} );
	$$self{gui}{spCompressLevel}	-> set_value( $$options{compressLevel} );
	$$self{gui}{chEmbed}			-> set_active( $$options{embed} );
	$$self{gui}{entryVia}			-> set_text( $$options{via} );
	$$self{gui}{cbColours}			-> set_active( $REVCOLOURS{ $$options{colours} } );

	return 1;
}

sub get_cfg
{
	my $self = shift;
	
	my %options;
	
	$options{fullScreen}	= $$self{gui}{chFullScreen}		-> get_active;
	$options{listen}		= $$self{gui}{chListen}			-> get_active;
	$options{viewOnly}		= $$self{gui}{chViewOnly}		-> get_active;
	$options{quality}		= $$self{gui}{spQuality}		-> get_value;
	$options{compressLevel}	= $$self{gui}{spCompressLevel}	-> get_value;
	$options{embed}			= $$self{gui}{chEmbed}			-> get_active;
	$options{via}			= $$self{gui}{entryVia}			-> get_chars( 0, -1 );
	$options{colours}		= $$self{gui}{cbColours}		-> get_active_text;
	
	return _parseOptionsToCfg( \%options );
}

# END: Public class methods
###################################################################

###################################################################
# START: Private functions definitions

sub _parseCfgToOptions
{
	my $cmd_line = shift;
	
	my %hash;
	$hash{colours}			= 'AutoSelect';
	$hash{fullScreen}		= 0;
	$hash{quality}			= 5;
	$hash{compressLevel}	= 8;
	$hash{viewOnly}			= 0;
	$hash{listen}			= 0;
	$hash{embed}			= 0;
	$hash{via}				= '';
	
	my @opts = split( /\s+-/, $cmd_line );
	foreach my $opt ( @opts )
	{
		next unless $opt ne '';
		$opt =~ s/\s+$//go;
		
		$opt =~ /^LowColourLevel\s+(\d)$/go	and	$hash{colours}			= $1;
		$opt =~ /^FullScreen=(\d+)$/go		and	$hash{fullScreen}		= $1;
		$opt =~ /^Parent=(\d+)$/go			and	$hash{embed}			= $1;
		$opt =~ /^listen=(\d+)$/go			and	$hash{listen}			= $1;
		$opt =~ /^ViewOnly=(\d+)$/go		and	$hash{viewOnly}			= $1;
		$opt =~ /^CompressLevel=(\d+)$/go	and	$hash{compressLevel}	= $1;
		$opt =~ /^QualityLevel=(\d+)$/go	and	$hash{quality}			= $1;
		$opt =~ /^via\s+(.+)$/go			and	$hash{via}				= $1;
	}
	
	return \%hash;
}

sub _parseOptionsToCfg
{
	my $hash = shift;
	
	my $txt = '';
	
	( $$hash{colours} ne 'AutoSelect' ) and $txt .= ' -AutoSelect=0';
	( $$hash{colours} ne 'AutoSelect' ) and $txt .= ' -LowColourLevel '	. ( $COLOURS{ $$hash{colours} } );
	$txt .= ' -FullScreen='		. ( $$hash{fullScreen}	|| '0' );
	$txt .= ' -Parent=1'		if $$hash{embed};
	$txt .= ' -listen='			. ( $$hash{listen}		|| '0' );
	$txt .= ' -ViewOnly='		. ( $$hash{viewOnly}	|| '0' );
	$txt .= ' -CompressLevel='	. $$hash{compressLevel};
	$txt .= ' -QualityLevel='	. $$hash{quality};
	$txt .= " -via $$hash{via}" if $$hash{via};
	
	return $txt;
}

sub embed
{
	my $self = shift;
	return $$self{gui}{chEmbed} -> get_active;
}

sub _buildGUI
{
	my $self		= shift;
	
	my $container	= $self -> {container};
	my $cfg			= $self -> {cfg};
	
	my %w;
	
	$w{vbox} = $container;
		
		$w{hbox1} = Gtk2::HBox -> new( 0, 5 );
		$w{vbox} -> pack_start( $w{hbox1}, 0, 1, 5 );
			
			$w{frCompressLevel} = Gtk2::Frame -> new( 'Compression level (1: min, 10: max) :' );
			$w{hbox1} -> pack_start( $w{frCompressLevel}, 1, 1, 0 );
			$w{frCompressLevel} -> set_tooltip_text( '[-g] : Percentage of the whole screen to use' );
				
				$w{spCompressLevel} = Gtk2::HScale -> new( Gtk2::Adjustment -> new( 8, 1, 11, 1.0, 1.0, 1.0 ) );
				$w{frCompressLevel} -> add( $w{spCompressLevel} );
			
			$w{frQuality} = Gtk2::Frame -> new( 'Picture quality (1: min, 10: max) :' );
			$w{hbox1} -> pack_start( $w{frQuality}, 1, 1, 0 );
			$w{frQuality} -> set_tooltip_text( '[-g] : Percentage of the whole screen to use' );
				
				$w{spQuality} = Gtk2::HScale -> new( Gtk2::Adjustment -> new( 5, 1, 11, 1.0, 1.0, 1.0 ) );
				$w{frQuality} -> add( $w{spQuality} );
			
			$w{frColour} = Gtk2::Frame -> new( 'Colour Level:' );
			$w{hbox1} -> pack_start( $w{frColour}, 1, 1, 0 );
			$w{frColour} -> set_tooltip_text( 'Select the reduced colour level, or leave as automatic' );
				
				$w{cbColours} = Gtk2::ComboBox -> new_text;
				$w{frColour} -> add( $w{cbColours} );
				foreach my $depth ( 8, 64, 256, 'AutoSelect' ) { $w{cbColours} -> append_text( $depth ); };
		
		$w{hbox2} = Gtk2::HBox -> new( 0, 5 );
		$w{vbox} -> pack_start( $w{hbox2}, 0, 1, 5 );
			
			$w{chFullScreen} = Gtk2::CheckButton -> new_with_label( 'Fullscreen' );
			$w{hbox2} -> pack_start( $w{chFullScreen}, 0, 1, 0 );
			$w{chFullScreen} -> set_tooltip_text( '[-FullScreen] : Fullscreen window' );
			
			$w{chListen} = Gtk2::CheckButton -> new_with_label( 'Listen' );
			$w{hbox2} -> pack_start( $w{chListen}, 0, 1, 0 );
			$w{chListen} -> set_tooltip_text( '[-listen] : Listen for incoming connections' );
			
			$w{chViewOnly} = Gtk2::CheckButton -> new_with_label( 'View Only' );
			$w{hbox2} -> pack_start( $w{chViewOnly}, 0, 1, 0 );
			$w{chViewOnly} -> set_tooltip_text( '[-ViewOnly] : View only mode' );
			
			$w{chEmbed} = Gtk2::CheckButton -> new_with_label( 'Embed in TAB' );
			$w{hbox2} -> pack_start( $w{chEmbed}, 0, 1, 0 );
			$w{chEmbed} -> set_tooltip_text( '[-Parent=XID] : Embed VNC window in PAC TAB' );
			
			$w{lblVia} = Gtk2::Label -> new( 'Via:' );
			$w{hbox2} -> pack_start( $w{lblVia}, 0, 0, 0 );
			$w{lblVia} -> set_tooltip_text( '[-via gateway] : Starts an SSH to tunnel the connection' );
			
			$w{entryVia} = Gtk2::Entry -> new;
			$w{hbox2} -> pack_start( $w{entryVia}, 0, 1, 0 );
			$w{entryVia} -> set_tooltip_text( '[-via gateway] : Starts an SSH to tunnel the connection' );
	
	$$self{gui} = \%w;
	
	return 1;
}

# END: Private functions definitions
###################################################################

1;
