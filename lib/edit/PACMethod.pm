package PACMethod;

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

use PACUtils;

# END: Import Modules
###################################################################

###################################################################
# Define GLOBAL CLASS variables

our $CONTAINER = Gtk2::VBox -> new( 0, 0 );
my %METHODS;

no strict 'refs'; # Trick or treat!! ;)

eval { require "$RealBin/lib/method/PACMethod_generic.pm"; }; die $@ if $@;
$METHODS{ 'Generic Command' } = "PACMethod_generic" -> new( $CONTAINER );

eval { require "$RealBin/lib/method/PACMethod_ssh.pm"; }; die $@ if $@;
$METHODS{ 'SSH' } = "PACMethod_ssh" -> new( $CONTAINER );

eval { require "$RealBin/lib/method/PACMethod_mosh.pm"; }; die $@ if $@;
$METHODS{ 'MOSH' } = "PACMethod_mosh" -> new( $CONTAINER );

eval { require "$RealBin/lib/method/PACMethod_cadaver.pm"; }; die $@ if $@;
$METHODS{ 'WebDAV' } = "PACMethod_cadaver" -> new( $CONTAINER );

eval { require "$RealBin/lib/method/PACMethod_sftp.pm"; }; die $@ if $@;
$METHODS{ 'SFTP' } = "PACMethod_sftp" -> new( $CONTAINER );

eval { require "$RealBin/lib/method/PACMethod_ftp.pm"; }; die $@ if $@;
$METHODS{ 'FTP' } = "PACMethod_ftp" -> new( $CONTAINER );

eval { require "$RealBin/lib/method/PACMethod_telnet.pm"; }; die $@ if $@;
$METHODS{ 'Telnet' } = "PACMethod_telnet" -> new( $CONTAINER );

eval { require "$RealBin/lib/method/PACMethod_cu.pm"; }; die $@ if $@;
$METHODS{ 'Serial (cu)' } = "PACMethod_cu" -> new( $CONTAINER );

eval { require "$RealBin/lib/method/PACMethod_remote_tty.pm"; }; die $@ if $@;
$METHODS{ 'Serial (remote-tty)' } = "PACMethod_remote_tty" -> new( $CONTAINER );

eval { require "$RealBin/lib/method/PACMethod_3270.pm"; }; die $@ if $@;
$METHODS{ 'IBM 3270/5250' } = "PACMethod_3270" -> new( $CONTAINER );

eval { require "$RealBin/lib/method/PACMethod_rdesktop.pm"; }; die $@ if $@;
$METHODS{ 'RDP (rdesktop)' } = "PACMethod_rdesktop" -> new( $CONTAINER );

eval { require "$RealBin/lib/method/PACMethod_xfreerdp.pm"; }; die $@ if $@;
$METHODS{ 'RDP (xfreerdp)' } = "PACMethod_xfreerdp" -> new( $CONTAINER );

`which vncviewer 1>/dev/null 2>&1`;
my $xtightvncviewer = $?;
`vncviewer --help 2>&1 | /bin/grep TigerVNC`;
my $tigervnc = $?;
if ( ! $tigervnc ) {
	eval { require "$RealBin/lib/method/PACMethod_tigervnc.pm"; }; die $@ if $@;
	$METHODS{ 'VNC' } = "PACMethod_tigervnc" -> new( $CONTAINER );
} elsif ( ! $xtightvncviewer ) {
	eval { require "$RealBin/lib/method/PACMethod_vncviewer.pm"; }; die $@ if $@;
	$METHODS{ 'VNC' } = "PACMethod_vncviewer" -> new( $CONTAINER );
}

use strict 'refs'; # Here we go!
	
# END: Define GLOBAL CLASS variables
###################################################################

###################################################################
# START: Public class methods

sub new {
	my $class	= shift;
	
	my $self	= {};
	
	$self -> {container} = $CONTAINER;
	
	$self -> {_METHOD}		= undef;
	$self -> {_CFG}			= undef;
	
	bless( $self, $class );
	return $self;
}

sub change {
	my $self	= shift;
	my $method	= shift;
	my $cfg		= shift;
	
	$$self{_METHOD}	= $method;
	
	defined $cfg and $$self{_CFG} = $cfg;
	
	$$self{container} -> foreach( sub { $_[0] -> destroy; } );
	$METHODS{ $$self{_METHOD} } -> _buildGUI;
	$METHODS{ $$self{_METHOD} } -> update( $$self{_CFG}{'options'} );
	
	return 1;
}

sub update {
	my $self	= shift;
	my $cfg		= shift;
	
	$$self{_CFG}	= $cfg;
	$$self{_METHOD}	= $$self{_CFG}{method};
	$$self{_METHOD}	=~ s/-/_/go;
	
	if ( ! defined $$self{_CFG}{method} || ! defined $METHODS{ $$self{_METHOD} } ) {
		_wMessage( $PACMain::{FUNCS}{_MAIN}{_WINDOWEDIT}, "Sorry, but connection <b>'$$self{_CFG}{'name'}'</b> is of type <b>'$$self{_CFG}{'method'}'</b>, wich is not supported in your actual system state.\nPlease, try installing the proper package providing that functionality." );
		return 0;
	}
	
	$METHODS{ $$self{_METHOD} } -> update( $$self{_CFG}{'options'} );
	
	return 1;
}

sub get_cfg { return $METHODS{ $_[0]{_METHOD} } -> get_cfg; }

sub embed { return $METHODS{ $_[0]{_METHOD} } -> embed; }

# END: Public class methods
###################################################################


# END: Private functions definitions
###################################################################

1;
