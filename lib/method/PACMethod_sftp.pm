package PACMethod_sftp;

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

#use Data::Dumper;

# GTK2
use Gtk2 '-init';

# END: Import Modules
###################################################################

###################################################################
# Define GLOBAL CLASS variables

my %SSH_VERSION = ( 1 => 0, 'any' => 1 );
my $RES_DIR = $RealBin . '/res';

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
	
	my $options = _parseCfgToOptions( $$self{cfg} );
	
	$$self{gui}{cbSSHVersion}			-> set_active( $SSH_VERSION{ $$options{sshVersion} // 'any' } );
	$$self{gui}{chUseCompression}		-> set_active( $$options{useCompression} );
	$$self{gui}{entryAdvancedOptions}	-> set_text( $$options{otherOptions} );

	return 1;
}

sub get_cfg
{
	my $self = shift;
	
	my %options;
	
	$options{sshVersion}		= $$self{gui}{cbSSHVersion}			-> get_active_text;
	$options{useCompression}	= $$self{gui}{chUseCompression}		-> get_active;
	$options{otherOptions}		= $$self{gui}{entryAdvancedOptions}	-> get_chars( 0, -1 );
	
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
	$hash{sshVersion}		= 'any';
	$hash{useCompression}	= 0;
	$hash{otherOptions}		= '';
	
	my @opts = split( '-', $cmd_line );
	foreach my $opt ( @opts )
	{
		next unless $opt ne '';
		$opt =~ s/\s+$//go;
		
		$opt eq 1							and	$hash{sshVersion}		= 1;
		$opt eq 'C'							and	$hash{useCompression}	= 1;
		while ( $opt =~ /^o\s+(.+)$/go )	{ $hash{otherOptions} .= ' -o ' . $1 }
	}
	
	return \%hash;
}

sub _parseOptionsToCfg
{
	my $hash = shift;
	
	my $txt = '';
	
	$txt .= ' -1' unless $$hash{sshVersion} eq 'any';
	$txt .= ' -C' if $$hash{useCompression} ;
	$txt .= ' ' . $$hash{otherOptions} if $$hash{otherOptions};
	
	return $txt;
}

sub embed
{
	my $self = shift;
	return 0;
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
			
			$w{frSSHVersion} = Gtk2::Frame -> new( 'SSH Version:' );
			$w{hbox1} -> pack_start( $w{frSSHVersion}, 0, 1, 0 );
			$w{frSSHVersion} -> set_shadow_type( 'GTK_SHADOW_NONE' );
			$w{frSSHVersion} -> set_tooltip_text( '-(1|any) : Use SSH v1 or let negotiate any of them' );
				
				$w{cbSSHVersion} = Gtk2::ComboBox -> new_text;
				$w{frSSHVersion} -> add( $w{cbSSHVersion} );
				foreach my $ssh_version ( sort { $a cmp $b } keys %SSH_VERSION ) { $w{cbSSHVersion} -> append_text( $ssh_version ); };
			
			$w{chUseCompression} = Gtk2::CheckButton -> new_with_label( 'Use Compression' );
			$w{hbox1} -> pack_start( $w{chUseCompression}, 1, 1, 0 );
			$w{chUseCompression} -> set_tooltip_text( '[-C] : Use or not compression' );
		
		$w{vbox} -> pack_start( Gtk2::HSeparator -> new, 0, 1, 5 );
		
		$w{hbox3} = Gtk2::HBox -> new( 0, 0 );
		$w{vbox} -> pack_start( $w{hbox3}, 0, 1, 0 );
		$w{hbox3} -> set_tooltip_text( "[-o <advanced_options>]* : Use advanced options (see 'man ssh_config'), for example:\n-o TCPKeepALive=yes -o ServerAliveInterval=300 " );
			
			my $lbltmpao = Gtk2::Label -> new;
			$lbltmpao -> set_markup( '<span foreground="blue"> Advanced Options: </span>' );
			$w{hbox3} -> pack_start( $lbltmpao, 0, 1, 0 );
			$w{entryAdvancedOptions} = Gtk2::Entry -> new;
			$w{hbox3} -> pack_start( $w{entryAdvancedOptions}, 1, 1, 0 );
			$w{entryAdvancedOptions} -> set_size_request( 30, 20 );
	
		$w{vbox} -> pack_start( Gtk2::HSeparator -> new, 0, 1, 5 );
	
	$$self{gui} = \%w;
	
	return 1;
}

# END: Private functions definitions
###################################################################

1;
