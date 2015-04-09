package PACMethod_telnet;

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

my %IP_PROTOCOL = ( 4 => 0, 6 => 1, 'any' => 2 );
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
	
	$$self{gui}{cbTELNETProtocol}	-> set_active( $IP_PROTOCOL{ $$options{ipVersion} // 'any' } );
	$$self{gui}{entryBindAddress}	-> set_text( $$options{bindAddress} );
	$$self{gui}{entryEscapeChar}	-> set_text( $$options{escapeChar} );

	return 1;
}

sub get_cfg
{
	my $self = shift;
	
	my %options;
	
	$options{ipVersion}		= $$self{gui}{cbTELNETProtocol}	-> get_active_text;
	$options{bindAddress}	= $$self{gui}{entryBindAddress}	-> get_chars( 0, -1 );
	$options{escapeChar}	= $$self{gui}{entryEscapeChar}	-> get_chars( 0, -1 );
	
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
	$hash{ipVersion}	= 'any';
	$hash{bindAddress}	= '';
	$hash{escapeChar}	= '"^]"';
	
	my @opts = split( '-', $cmd_line );
	foreach my $opt ( @opts )
	{
		next unless $opt ne '';
		$opt =~ s/\s+$//go;
		
		$opt =~ /^([4|6]$)/go	and	$hash{ipVersion}	= $1;
		$opt =~ /^b\s+(.+$)/go	and	$hash{bindAddress}	= $1;
		$opt =~ /^e\s+(.+$)/go	and	$hash{escapeChar}	= $1;
	}
	
	return \%hash;
}

sub _parseOptionsToCfg
{
	my $hash = shift;
	
	my $txt = '';
	
	$txt .= ' -' . $$hash{ipVersion} if $$hash{ipVersion} ne 'any';
	$txt .= ' -b ' . $$hash{bindAddress} if $$hash{bindAddress};
	$txt .= ' -e ' . $$hash{escapeChar} if $$hash{escapeChar};
	
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
			
			$w{frSSHProtocol} = Gtk2::Frame -> new( 'IP Protocol:' );
			$w{hbox1} -> pack_start( $w{frSSHProtocol}, 1, 1, 0 );
			$w{frSSHProtocol} -> set_shadow_type( 'GTK_SHADOW_NONE' );
			$w{frSSHProtocol} -> set_tooltip_text( '-(4|6) : Uses IPv4, IPv6 or any of them' );
				
				$w{cbTELNETProtocol} = Gtk2::ComboBox -> new_text;
				$w{frSSHProtocol}  -> add( $w{cbTELNETProtocol} );
				foreach my $ip_protocol ( sort { $a cmp $b } keys %IP_PROTOCOL ) { $w{cbTELNETProtocol} -> append_text( $ip_protocol ); };
			
			$w{hbox1} -> pack_start( Gtk2::Label -> new( 'Bind Address:' ), 0, 1, 0 );
			$w{entryBindAddress} = Gtk2::Entry -> new;
			$w{hbox1} -> pack_start( $w{entryBindAddress} , 1, 1, 0 );
			$w{entryBindAddress} -> set_size_request( 200, 20 );
			$w{entryBindAddress} -> set_tooltip_text( '[-b ip] : Bind outgoing connection to given ip (leave blank to bind to any interface)' );
				
			$w{hbox1} -> pack_start( Gtk2::Label -> new( 'Escape Character:' ), 0, 1, 0 );
			$w{entryEscapeChar} = Gtk2::Entry -> new;
			$w{hbox1} -> pack_start( $w{entryEscapeChar} , 0, 1, 0 );
			$w{entryEscapeChar} -> set_size_request( 40, 20 );
			$w{entryEscapeChar} -> set_tooltip_text( '[-e [escape_character]] : Use given string (or an empty one to disable) as "Escape Character"' );
	
	$$self{gui} = \%w;
	
	return 1;
}

# END: Private functions definitions
###################################################################

1;
