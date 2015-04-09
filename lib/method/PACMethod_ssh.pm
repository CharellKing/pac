package PACMethod_ssh;

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

my %SSH_VERSION = ( 1 => 0, 2 => 1, 'any' => 2 );
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
	$self -> {list}			= [];
	$self -> {listRemote}	= [];
	$self -> {listDynamic}	= [];
	
	_buildGUI( $self );
	$$self{gui}{nb} -> set_current_page( 0 );
	
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
	$$self{gui}{cbSSHProtocol}			-> set_active( $IP_PROTOCOL{ $$options{ipVersion} // 'any' } );
	$$self{gui}{chNoRemoteCmd}			-> set_active( $$options{noRemoteCmd} );
	$$self{gui}{chForwardX}				-> set_active( $$options{forwardX} );
	$$self{gui}{chUseCompression}		-> set_active( $$options{useCompression} );
	$$self{gui}{chAllowPortConnect}		-> set_active( $$options{allowRemoteConnection} );
	$$self{gui}{chForwardAgent}			-> set_active( $$options{forwardAgent} );
	$$self{gui}{entryAdvancedOptions}	-> set_text( $$options{otherOptions} );

	# Destroy previuos widgets
	$$self{gui}{vbForward}	-> foreach( sub { $_[0] -> destroy; } );
	$$self{gui}{vbRemote}	-> foreach( sub { $_[0] -> destroy; } );
	$$self{gui}{vbDynamic}	-> foreach( sub { $_[0] -> destroy; } );
	
	# Empty parent's forward ports widgets' list
	$$self{list}		= [];
	$$self{listRemote}	= [];
	$$self{listDynamic}	= [];
	
	# Now, add the -new?- local forward widgets
	if		( $$self{gui}{rbOrderLI} -> get_active )	{ foreach my $hash ( sort { $$a{localIP} cmp $$b{localIP} } @{ $$options{forwardPort} } ) { $self -> _buildForward( $hash ); } }
	elsif	( $$self{gui}{rbOrderLP} -> get_active )	{ foreach my $hash ( sort { $$a{localPort} <=> $$b{localPort} } @{ $$options{forwardPort} } ) { $self -> _buildForward( $hash ); } }
	elsif	( $$self{gui}{rbOrderRI} -> get_active )	{ foreach my $hash ( sort { $$a{remoteIP} cmp $$b{remoteIP} } @{ $$options{forwardPort} } ) { $self -> _buildForward( $hash ); } }
	$$self{gui}{lblLocal} -> set_markup( 'Local Port Forwarding (<b>' . ( scalar( @{ $$self{list} } ) ) . '</b>)' );
	
	# Now, add the -new?- remote forward widgets
	if		( $$self{gui}{rbOrderLI2} -> get_active )	{ foreach my $hash ( sort { $$a{localIP} cmp $$b{localIP} } @{ $$options{remotePort} } ) { $self -> _buildRemote( $hash ); } }
	elsif	( $$self{gui}{rbOrderLP2} -> get_active )	{ foreach my $hash ( sort { $$a{localPort} <=> $$b{localPort} } @{ $$options{remotePort} } ) { $self -> _buildRemote( $hash ); } }
	elsif	( $$self{gui}{rbOrderRI2} -> get_active )	{ foreach my $hash ( sort { $$a{remoteIP} cmp $$b{remoteIP} } @{ $$options{remotePort} } ) { $self -> _buildRemote( $hash ); } }
	$$self{gui}{lblRemote} -> set_markup( 'Remote Port Forwarding (<b>' . ( scalar( @{ $$self{listRemote} } ) ) . '</b>)' );
	
	# Now, add the -new?- dynamic socks widgets
	if		( $$self{gui}{rbOrderLI3} -> get_active )	{ foreach my $hash ( sort { $$a{localIP} cmp $$b{localIP} } @{ $$options{dynamicForward} } ) { $self -> _buildDynamic( $hash ); } }
	elsif	( $$self{gui}{rbOrderLP3} -> get_active )	{ foreach my $hash ( sort { $$a{localPort} <=> $$b{localPort} } @{ $$options{dynamicForward} } ) { $self -> _buildDynamic( $hash ); } }
	$$self{gui}{lblDynamic} -> set_markup( 'Dynamic Socks Proxy (<b>' . ( scalar( @{ $$self{listDynamic} } ) ) . '</b>)' );
	
	return 1;
}

sub get_cfg
{
	my $self = shift;
	
	my %options;
	
	$options{sshVersion}				= $$self{gui}{cbSSHVersion}			-> get_active_text;
	$options{ipVersion}					= $$self{gui}{cbSSHProtocol}		-> get_active_text;
	$options{noRemoteCmd}				= $$self{gui}{chNoRemoteCmd}		-> get_active;
	$options{forwardX}					= $$self{gui}{chForwardX}			-> get_active;
	$options{useCompression}			= $$self{gui}{chUseCompression}		-> get_active;
	$options{allowRemoteConnection}		= $$self{gui}{chAllowPortConnect}	-> get_active;
	$options{forwardAgent}				= $$self{gui}{chForwardAgent}		-> get_active;
	$options{otherOptions}				= $$self{gui}{entryAdvancedOptions}	-> get_chars( 0, -1 );
	$options{forwardPort}				= ();
	$options{localPort}					= ();
	$options{dynamicForward}			= ();
	
	my %lp;
	
	foreach my $w ( @{ $$self{list} } )
	{
		my %hash;
		$hash{'localIP'}	= $$w{entryPFLocalIP}	-> get_chars( 0, -1 ) || '';
		$hash{'localPort'}	= $$w{spinPFLocalPort}	-> get_chars( 0, -1 ) || '';
		$hash{'remoteIP'}	= $$w{entryPFRemoteIP}	-> get_chars( 0, -1 ) || '';
		$hash{'remotePort'}	= $$w{spinPFRemotePort}	-> get_chars( 0, -1 ) || '';
		next unless $hash{'localPort'} && $hash{'remoteIP'} && $hash{'remotePort'};
		defined $lp{$hash{'localIP'}}{$hash{'localPort'}} and return "CONFIG ERROR: Local Port $hash{'localPort'} on Local IP '$hash{'localIP'}' defined in Local Port Forwarding is already in use!";
		$lp{$hash{'localIP'}}{$hash{'localPort'}} = 1;
		push( @{ $options{forwardPort} }, \%hash );
	}
	
	foreach my $w ( @{ $$self{listRemote} } )
	{
		my %hash;
		$hash{'localIP'}	= $$w{entryPFLocalIP}	-> get_chars( 0, -1 ) || '';
		$hash{'localPort'}	= $$w{spinPFLocalPort}	-> get_chars( 0, -1 ) || '';
		$hash{'remoteIP'}	= $$w{entryPFRemoteIP}	-> get_chars( 0, -1 ) || '';
		$hash{'remotePort'}	= $$w{spinPFRemotePort}	-> get_chars( 0, -1 ) || '';
		next unless $hash{'localPort'} && $hash{'remoteIP'} && $hash{'remotePort'};
		defined $lp{$hash{'localIP'}}{$hash{'localPort'}} and return "CONFIG ERROR: Local Port $hash{'localPort'} on Local IP '$hash{'localIP'}' defined in Remote Port Forwarding is already in use!";
		$lp{$hash{'localIP'}}{$hash{'localPort'}} = 1;
		push( @{ $options{remotePort} }, \%hash );
	}
	
	foreach my $w ( @{ $$self{listDynamic} } )
	{
		my %hash;
		$hash{'dynamicIP'}		= $$w{entryPFLocalIP}	-> get_chars( 0, -1 ) || '';
		$hash{'dynamicPort'}	= $$w{spinPFLocalPort}	-> get_chars( 0, -1 ) || '';
		next unless $hash{'dynamicPort'};
		defined $lp{$hash{'dynamicIP'}}{$hash{'dynamicPort'}} and return "CONFIG ERROR: Local Port $hash{'dynamicPort'} on Local IP '$hash{'dynamicIP'}' defined in Dynamic Socks Proxy is already in use!";
		$lp{$hash{'dynamicIP'}}{$hash{'dynamicPort'}} = 1;
		push( @{ $options{dynamicForward} }, \%hash );
	}
	
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
	$hash{sshVersion}				= 'any';
	$hash{ipVersion}				= 'any';
	$hash{noRemoteCmd}				= 0;
	$hash{forwardX}					= 1;
	$hash{useCompression}			= 0;
	$hash{allowRemoteConnection}	= 0;
	$hash{forwardAgent}				= 0;
	$hash{otherOptions}				= '';
	@{ $hash{dynamicForward} }		= ();
	@{ $hash{forwardPort} }			= ();
	@{ $hash{remotePort} }			= ();
	
	while ( $cmd_line =~ s/\s*\-o\s+\"(.+)\"//go )	{ $hash{otherOptions} .= ' -o "' . $1 . '"'}
	my @opts = split( /\s+-/, $cmd_line );
	foreach my $opt ( @opts )
	{
		next unless $opt ne '';
		$opt =~ s/\s+$//go;
		
		$opt =~ /^([1|2]$)/go				and	$hash{sshVersion}							= $1;
		$opt =~ /^([4|6]$)/go				and	$hash{ipVersion}							= $1;
		$opt =~ /^([X|x]$)/go				and	$hash{forwardX}								= $1 eq 'X' ? 1 : 0;
		$opt eq 'N'							and	$hash{noRemoteCmd}							= 1;
		$opt eq 'C'							and	$hash{useCompression}						= 1;
		$opt eq 'g'							and	$hash{allowRemoteConnection}				= 1;
		$opt eq 'A'							and	$hash{forwardAgent}							= 1;
		
		while ( $opt =~ /^D\s+([^\s]*\/)*(\d+)$/go )
		{
			my %dynamic;
			( $dynamic{dynamicIP}, $dynamic{dynamicPort} ) = ( $1 // '', $2 );
			$dynamic{dynamicIP} =~ s/\/+//go;
			push( @{ $hash{dynamicForward} }, \%dynamic );
		}
		while ( $opt =~ /^L\s+(.+)$/go )
		{
			my @fields = split( '/', $1 );
			my %forward;
			$forward{remotePort}	= pop( @fields );
			$forward{remoteIP}		= pop( @fields );
			$forward{localPort}		= pop( @fields );
			$forward{localIP}		= pop( @fields ) // '';
			push( @{ $hash{forwardPort} }, \%forward );
		}
		while ( $opt =~ /^R\s+(.+)$/go )
		{
			my @fields = split( '/', $1 );
			my %remote;
			$remote{remotePort}	= pop( @fields );
			$remote{remoteIP}	= pop( @fields );
			$remote{localPort}	= pop( @fields );
			$remote{localIP}	= pop( @fields ) // '';
			push( @{ $hash{remotePort} }, \%remote );
		}
	}
	
	return \%hash;
}

sub _parseOptionsToCfg
{
	my $hash = shift;
	
	my $txt = '';
	
	$txt .= ' -' . $$hash{sshVersion} unless $$hash{sshVersion} eq 'any';
	$txt .= ' -' . $$hash{ipVersion} unless $$hash{ipVersion} eq 'any';
	$txt .= ' -' . ( $$hash{forwardX} ? 'X' : 'x' );
	$txt .= ' -N' if $$hash{noRemoteCmd} ;
	$txt .= ' -C' if $$hash{useCompression} ;
	$txt .= ' -g' if $$hash{allowRemoteConnection};
	$txt .= ' -A' if $$hash{forwardAgent};
	$txt .= ' ' . $$hash{otherOptions} if $$hash{otherOptions};
	foreach my $dynamic ( @{ $$hash{dynamicForward} } )
	{
		$txt .= ' -D ' . ( $$dynamic{dynamicIP} ? "$$dynamic{dynamicIP}/" : '' ) . $$dynamic{dynamicPort};
	}
	foreach my $forward ( @{ $$hash{forwardPort} } )
	{
		$txt .= ' -L ' . ( $$forward{localIP} ? "$$forward{localIP}/" : '' ) . $$forward{localPort} . '/' . $$forward{remoteIP} . '/' . $$forward{remotePort};
	}
	foreach my $remote ( @{ $$hash{remotePort} } )
	{
		$txt .= ' -R ' . ( $$remote{localIP} ? "$$remote{localIP}/" : '' ) . $$remote{localPort} . '/' . $$remote{remoteIP} . '/' . $$remote{remotePort};
	}
	
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
	$w{vbox} -> set_border_width( 5 );
		
		$w{hbox1} = Gtk2::HBox -> new( 0, 5 );
		$w{vbox} -> pack_start( $w{hbox1}, 0, 1, 0 );
		$w{hbox1} -> set_border_width( 5 );
			
			$w{vboxipv} = Gtk2::VBox -> new( 0, 5 );
			$w{hbox1} -> pack_start( $w{vboxipv}, 0, 1, 0 );
				
				my $hb123 = Gtk2::HBox -> new( 0, 5 );
				$w{vboxipv} -> pack_start( $hb123, 1, 1, 0 );
					
					my $lblsshv = Gtk2::Label -> new( 'SSH Version: ' );
					$lblsshv -> set_alignment( 1, 0.5 );
					$hb123 -> pack_start( $lblsshv, 1, 1, 0 );
					$hb123 -> set_tooltip_text( '-(1|2|any) : Use SSH v1, v2 or any  of them' );
					
					$w{cbSSHVersion} = Gtk2::ComboBox -> new_text;
					$hb123 -> pack_start( $w{cbSSHVersion}, 0, 1, 0 );
					foreach my $ssh_version ( sort { $a cmp $b } keys %SSH_VERSION ) { $w{cbSSHVersion} -> append_text( $ssh_version ); };
					
				my $hb456 = Gtk2::HBox -> new( 0, 5 );
				$w{vboxipv} -> pack_start( $hb456, 1, 1, 0 );
					
					my $lblipv = Gtk2::Label -> new( 'IP Protocol: ' );
					$lblipv -> set_alignment( 1, 0.5 );
					$hb456 -> pack_start( $lblipv, 1, 1, 0 );
					$hb456 -> set_tooltip_text( '-(4|6) : Uses IPv4, IPv6 or no specification (ip based)' );
					
					$w{cbSSHProtocol} = Gtk2::ComboBox -> new_text;
					$hb456 -> pack_start( $w{cbSSHProtocol}, 0, 1, 0 );
					foreach my $ip_protocol ( sort { $a cmp $b } keys %IP_PROTOCOL ) { $w{cbSSHProtocol} -> append_text( $ip_protocol ); };
			
			$w{frSSHOther} = Gtk2::Frame -> new( ' Other Options: ' );
			$w{hbox1} -> pack_start( $w{frSSHOther}, 1, 1, 0 );
				
				my $vboxother = Gtk2::VBox -> new( 0, 0 );
				$w{frSSHOther} -> add( $vboxother );
					
					my $hbox1 = Gtk2::HBox -> new( 0, 0 );
					#$w{frSSHOther} -> add( $hbox1 );
					$vboxother -> add( $hbox1 );
					$hbox1 -> set_border_width( 5 );
						
						$w{chForwardX} = Gtk2::CheckButton -> new_with_label( 'Forward X' );
						$hbox1 -> pack_start( $w{chForwardX}, 1, 1, 0 );
						$w{chForwardX} -> set_tooltip_text( '-(X|x) : Forwards or not the X' );
						
						$w{chUseCompression} = Gtk2::CheckButton -> new_with_label( 'Use Compression' );
						$hbox1 -> pack_start( $w{chUseCompression}, 1, 1, 0 );
						$w{chUseCompression} -> set_tooltip_text( '[-C] : Use or not compression' );
						
						$w{chAllowPortConnect} = Gtk2::CheckButton -> new_with_label( 'Allow Remote Port Connect' );
						$hbox1 -> pack_start( $w{chAllowPortConnect}, 1, 1, 0 );
						$w{chAllowPortConnect} -> set_tooltip_text( '[-g] : Allow or not Remote Port Connections' );
						
						$w{chForwardAgent} = Gtk2::CheckButton -> new_with_label( 'Forward Agent' );
						$hbox1 -> pack_start( $w{chForwardAgent}, 1, 1, 0 );
						$w{chForwardAgent} -> set_tooltip_text( '[-A] : Forward or not the SSH authentication agent' );
		
					my $hbox2 = Gtk2::HBox -> new( 0, 0 );
					$vboxother -> add( $hbox2 );
					$hbox2 -> set_border_width( 5 );
						
						$w{chNoRemoteCmd} = Gtk2::CheckButton -> new_with_label( 'Do NOT execute remote command' );
						$hbox2 -> pack_start( $w{chNoRemoteCmd}, 1, 1, 0 );
						$w{chNoRemoteCmd} -> set_tooltip_text( '[-N]: Do NOT execute a remote command.  This is useful for just forwarding ports (protocol version 2 only)' );
		
		$w{vbox} -> pack_start( Gtk2::HSeparator -> new, 0, 1, 5 );
		
		$w{hbox3} = Gtk2::HBox -> new( 0, 0 );
		$w{vbox} -> pack_start( $w{hbox3}, 0, 1, 0 );
		$w{hbox3} -> set_tooltip_text( "[-o <advanced_options>]* : Use advanced options (see 'man ssh_config'), for example:\n-o \"TCPKeepALive=yes\" -o \"ServerAliveInterval=300\"\n-o \"ProxyCommand corkscrew <<proxy_host>> <<proxy_port>> %h %p /tmp/proxy_authfile\"" );
			
			my $lbltmpao = Gtk2::Label -> new;
			$lbltmpao -> set_markup( '<span foreground="blue"> Advanced Options: </span>' );
			$w{hbox3} -> pack_start( $lbltmpao, 0, 1, 0 );
			$w{entryAdvancedOptions} = Gtk2::Entry -> new;
			$w{hbox3} -> pack_start( $w{entryAdvancedOptions}, 1, 1, 0 );
			$w{entryAdvancedOptions} -> set_size_request( 30, 20 );
		
		$w{vbox} -> pack_start( Gtk2::HSeparator -> new, 0, 1, 5 );
		
		$w{hbox4} = Gtk2::HBox -> new( 0, 0 );
		$w{vbox} -> pack_start( $w{hbox4}, 1, 1, 0 );
		
		$w{nb} = Gtk2::Notebook -> new;
		$w{hbox4} -> pack_start( $w{nb}, 1, 1, 0 );
			
			$w{vbox2} = Gtk2::VBox -> new( 0, 0 );
			$w{lblLocal} = Gtk2::Label -> new( 'Local Port Forwarding' );
			$w{nb} -> append_page( $w{vbox2}, $w{lblLocal} );
			$w{vbox2} -> set_tooltip_text( '[-L [bind_address:]local_port:remote_address:remote_port] : Forward local_port to remote_address -> remote_port' );
			$w{vbox2} -> set_border_width( 5 );
				
				$w{hboxorder} = Gtk2::HBox -> new( 0, 0 );
				$w{vbox2} -> pack_start( $w{hboxorder}, 0, 1, 0 );
					
					$w{lblOrder} = Gtk2::Label -> new( 'Show ordered by: ' );
					$w{hboxorder} -> pack_start( $w{lblOrder}, 0, 1, 0 );
					
					# Build the "order" radiobuttons
					$w{rbOrderLI} = Gtk2::RadioButton -> new_with_label( undef, 'Local IP, ' );
					$w{hboxorder} -> pack_start( $w{rbOrderLI}, 0, 1, 0 );
					$w{rbOrderLI} ->set( 'can_focus', 0 );
					
					$w{rbOrderLP} = Gtk2::RadioButton -> new_with_label( $w{rbOrderLI}, 'Local Port, ' );
					$w{hboxorder} -> pack_start( $w{rbOrderLP}, 0, 1, 0 );
					$w{rbOrderLP} ->set( 'can_focus', 0 );
					
					$w{rbOrderRI} = Gtk2::RadioButton -> new_with_label( $w{rbOrderLI}, 'Remote IP' );
					$w{hboxorder} -> pack_start( $w{rbOrderRI}, 0, 1, 0 );
					$w{rbOrderRI} ->set( 'can_focus', 0 );
					
					$w{rbOrderLP} -> set_active( 1 );
				
				# Build 'add' button
				$w{btnadd} = Gtk2::Button -> new_from_stock( 'gtk-add' );
				$w{vbox2} -> pack_start( $w{btnadd}, 0, 1, 0 );
				
				# Build a scrolled window
				$w{sw} = Gtk2::ScrolledWindow -> new;
				$w{vbox2} -> pack_start( $w{sw}, 1, 1, 0 );
				$w{sw} -> set_policy( 'automatic', 'automatic' );
				$w{sw} -> set_shadow_type( 'none' );
					
					$w{vp} = Gtk2::Viewport -> new;
					$w{sw} -> add( $w{vp} );
					$w{vp} -> set_shadow_type( 'GTK_SHADOW_NONE' );
						
						# Build and add the vbox that will contain the forward widgets
						$w{vbForward} = Gtk2::VBox -> new( 0, 0 );
						$w{vp} -> add( $w{vbForward} );
			
			$w{vbox3} = Gtk2::VBox -> new( 0, 0 );
			$w{lblRemote} = Gtk2::Label -> new( 'Remote Port Forwarding' );
			$w{nb} -> append_page( $w{vbox3}, $w{lblRemote} );
			$w{vbox3} -> set_tooltip_text( '[-R [bind_address:]port:address:remote_port] :Bring remote_port to local_address -> local_port' );
			$w{vbox3} -> set_border_width( 5 );
				
				$w{hboxorder2} = Gtk2::HBox -> new( 0, 0 );
				$w{vbox3} -> pack_start( $w{hboxorder2}, 0, 1, 0 );
					
					$w{lblOrder2} = Gtk2::Label -> new( 'Show ordered by: ' );
					$w{hboxorder2} -> pack_start( $w{lblOrder2}, 0, 1, 0 );
					
					# Build the "order" radiobuttons
					$w{rbOrderLI2} = Gtk2::RadioButton -> new_with_label( undef, 'Local IP, ' );
					$w{hboxorder2} -> pack_start( $w{rbOrderLI2}, 0, 1, 0 );
					$w{rbOrderLI2} ->set( 'can_focus', 0 );
					
					$w{rbOrderLP2} = Gtk2::RadioButton -> new_with_label( $w{rbOrderLI2}, 'Local Port, ' );
					$w{hboxorder2} -> pack_start( $w{rbOrderLP2}, 0, 1, 0 );
					$w{rbOrderLP2} ->set( 'can_focus', 0 );
					
					$w{rbOrderRI2} = Gtk2::RadioButton -> new_with_label( $w{rbOrderLI2}, 'Remote IP' );
					$w{hboxorder2} -> pack_start( $w{rbOrderRI2}, 0, 1, 0 );
					$w{rbOrderRI2} ->set( 'can_focus', 0 );
					
					$w{rbOrderLP2} -> set_active( 1 );
				
				# Build 'add' button
				$w{btnaddRemote} = Gtk2::Button -> new_from_stock( 'gtk-add' );
				$w{vbox3} -> pack_start( $w{btnaddRemote}, 0, 1, 0 );
				
				# Build a scrolled window
				$w{swRemote} = Gtk2::ScrolledWindow -> new;
				$w{vbox3} -> pack_start( $w{swRemote}, 1, 1, 0 );
				$w{swRemote} -> set_policy( 'automatic', 'automatic' );
				$w{swRemote} -> set_shadow_type( 'none' );
					
					$w{vpRemote} = Gtk2::Viewport -> new;
					$w{swRemote} -> add( $w{vpRemote} );
					$w{vpRemote} -> set_shadow_type( 'GTK_SHADOW_NONE' );
						
						# Build and add the vbox that will contain the remote widgets
						$w{vbRemote} = Gtk2::VBox -> new( 0, 0 );
						$w{vpRemote} -> add( $w{vbRemote} );
			
			$w{vbox33} = Gtk2::VBox -> new( 0, 0 );
			$w{lblDynamic} = Gtk2::Label -> new( 'Dynamic Socks Proxy' );
			$w{nb} -> append_page( $w{vbox33}, $w{lblDynamic} );
			$w{vbox33} -> set_tooltip_text( '[-D [bind_address:]local_port] : Create a Dynamic Socks proxy at local_port' );
			$w{vbox33} -> set_border_width( 5 );
				
				$w{hboxorder3} = Gtk2::HBox -> new( 0, 0 );
				$w{vbox33} -> pack_start( $w{hboxorder3}, 0, 1, 0 );
					
					$w{lblOrder3} = Gtk2::Label -> new( 'Show ordered by: ' );
					$w{hboxorder3} -> pack_start( $w{lblOrder3}, 0, 1, 0 );
					
					# Build the "order" radiobuttons
					$w{rbOrderLI3} = Gtk2::RadioButton -> new_with_label( undef, 'Local IP, ' );
					$w{hboxorder3} -> pack_start( $w{rbOrderLI3}, 0, 1, 0 );
					$w{rbOrderLI3} ->set( 'can_focus', 0 );
					
					$w{rbOrderLP3} = Gtk2::RadioButton -> new_with_label( $w{rbOrderLI3}, 'Local Port' );
					$w{hboxorder3} -> pack_start( $w{rbOrderLP3}, 0, 1, 0 );
					$w{rbOrderLP3} ->set( 'can_focus', 0 );
					
					$w{rbOrderLP3} -> set_active( 1 );
				
				# Build 'add' button
				$w{btnaddDynamic} = Gtk2::Button -> new_from_stock( 'gtk-add' );
				$w{vbox33} -> pack_start( $w{btnaddDynamic}, 0, 1, 0 );
				
				# Build a scrolled window
				$w{swDynamic} = Gtk2::ScrolledWindow -> new;
				$w{vbox33} -> pack_start( $w{swDynamic}, 1, 1, 0 );
				$w{swDynamic} -> set_policy( 'automatic', 'automatic' );
				$w{swDynamic} -> set_shadow_type( 'none' );
					
					$w{vpDynamic} = Gtk2::Viewport -> new;
					$w{swDynamic} -> add( $w{vpDynamic} );
					$w{vpDynamic} -> set_shadow_type( 'GTK_SHADOW_NONE' );
						
						# Build and add the vbox that will contain the remote widgets
						$w{vbDynamic} = Gtk2::VBox -> new( 0, 0 );
						$w{vpDynamic} -> add( $w{vbDynamic} );
		
		$w{nb} -> set_current_page( 0 );
	
	$$self{gui} = \%w;
	
	# Choose the first 'port forward' tab on Notebook 'map'
	$w{nb} -> signal_connect( 'map' => sub { $w{nb} -> set_current_page( 0 ); } );
	
	foreach my $txt ( 'LI', 'LP', 'RI', 'LI2', 'LP2', 'RI2', 'LI3', 'LP3' ) { $w{'rbOrder' . $txt} -> signal_connect( 'toggled' => sub { $self -> update } ); };
	
	# Button(s) callback(s)
	$w{btnadd} -> signal_connect( 'clicked', sub
	{
		$$self{cfg} = $self -> get_cfg();
		my $opt_hash = _parseCfgToOptions( $$self{cfg} );
		push( @{ $$opt_hash{forwardPort} }, { 'localIP' => '', 'localPort' => 1, 'remoteIP' => 'localhost', 'remotePort' => 1 } );
		$$self{cfg} = _parseOptionsToCfg( $opt_hash );
		$self -> update( $$self{cfg} );
		return 1;
	} );
	
	$w{btnaddRemote} -> signal_connect( 'clicked', sub
	{
		$$self{cfg} = $self -> get_cfg();
		my $opt_hash = _parseCfgToOptions( $$self{cfg} );
		push( @{ $$opt_hash{remotePort} }, { 'localIP' => '', 'localPort' => 1, 'remoteIP' => 'localhost', 'remotePort' => 1 } );
		$$self{cfg} = _parseOptionsToCfg( $opt_hash );
		$self -> update( $$self{cfg} );
		return 1;
	} );
	
	$w{btnaddDynamic} -> signal_connect( 'clicked', sub
	{
		$$self{cfg} = $self -> get_cfg();
		my $opt_hash = _parseCfgToOptions( $$self{cfg} );
		push( @{ $$opt_hash{dynamicForward} }, { 'dynamicIP' => '', 'dynamicPort' => 1080 } );
		$$self{cfg} = _parseOptionsToCfg( $opt_hash );
		$self -> update( $$self{cfg} );
		return 1;
	} );
	
	return 1;
}

sub _buildForward
{
	my $self	= shift;
	my $hash	= shift;
	
	my $localIP		= $$hash{'localIP'}		// '';
	my $localPort	= $$hash{'localPort'}	// 1;
	my $remoteIP	= $$hash{'remoteIP'}	// 'localhost';
	my $remotePort	= $$hash{'remotePort'}	// 1;
	
	my @undo;
	my $undoing = 0;
	
	my %w;
	
	$w{position} = scalar @{ $$self{list} };
	
	# Make an HBox to contain local address, local port, remote address, remote port and delete
	$w{hbox} = Gtk2::HBox -> new( 0, 0 );
		
		$w{frPFLocalIP} = Gtk2::Frame -> new( 'Bind Address:' );
		$w{hbox} -> pack_start( $w{frPFLocalIP}, 1, 1, 0 );
		$w{frPFLocalIP} -> set_shadow_type( 'GTK_SHADOW_NONE' );
			
			$w{entryPFLocalIP} = Gtk2::Entry -> new;
			$w{frPFLocalIP} -> add( $w{entryPFLocalIP} );
			$w{entryPFLocalIP} -> set_size_request( 30, 20 );
			$w{entryPFLocalIP} -> set_text( $localIP );
			$w{entryPFLocalIP} -> set_tooltip_text( 'Bind incoming connection to given ip (leave blank to bind to any interface)' );
		
		$w{frPFLocalPort} = Gtk2::Frame -> new( 'Local Port:' );
		$w{hbox} -> pack_start( $w{frPFLocalPort}, 0, 1, 0 );
		$w{frPFLocalPort} -> set_shadow_type( 'GTK_SHADOW_NONE' );
			
			$w{spinPFLocalPort} = Gtk2::SpinButton -> new( Gtk2::Adjustment -> new( 1, 1, 65535, 1, 10, 0 ), 1, 0 );
			$w{frPFLocalPort} -> add( $w{spinPFLocalPort} );
			$w{spinPFLocalPort} -> set_size_request( 30, 20 );
			$w{spinPFLocalPort} -> set_value( $localPort );
		
		$w{frPFRemoteIP} = Gtk2::Frame -> new( 'Remote Address:' );
		$w{hbox} -> pack_start( $w{frPFRemoteIP}, 1, 1, 0 );
		$w{frPFRemoteIP} -> set_shadow_type( 'GTK_SHADOW_NONE' );
			
			$w{entryPFRemoteIP} = Gtk2::Entry -> new;
			$w{frPFRemoteIP} -> add( $w{entryPFRemoteIP} );
			$w{entryPFRemoteIP} -> set_size_request( 30, 20 );
			$w{entryPFRemoteIP} -> set_text( $remoteIP );
		
		$w{frPFRemotePort} = Gtk2::Frame -> new( 'Remote Port:' );
		$w{hbox} -> pack_start( $w{frPFRemotePort}, 0, 1, 0 );
		$w{frPFRemotePort} -> set_shadow_type( 'GTK_SHADOW_NONE' );
			
			$w{spinPFRemotePort} = Gtk2::SpinButton -> new( Gtk2::Adjustment -> new( 1, 1, 65535, 1, 10, 0 ), 1, 0 );
			$w{frPFRemotePort} -> add( $w{spinPFRemotePort} );
			$w{spinPFRemotePort} -> set_size_request( 30, 20 );
			$w{spinPFRemotePort} -> set_value( $remotePort );
		
		# Build delete button
		$w{btn} = Gtk2::Button -> new_from_stock( 'gtk-delete' );
		$w{hbox} -> pack_start( $w{btn}, 0, 1, 0 );
	
	# Add built control to main container
	$$self{gui}{vbForward} -> pack_start( $w{hbox}, 0, 1, 0 );
	$$self{gui}{vbForward} -> show_all;
	
	$$self{list}[$w{position}] = \%w;
	
	# Setup some callbacks
	
	# Asign a callback for deleting entry
	$w{btn} -> signal_connect( 'clicked' => sub {
		$$self{cfg} = $self -> get_cfg();
		splice( @{ $$self{list} }, $w{position}, 1 );
		$$self{cfg} = $self -> get_cfg();
		$self -> update( $$self{cfg} );
		return 1;
	} );
	
	
	# Avoid the enter of non numeric values in this entry
	$w{spinPFLocalPort} -> signal_connect( 'insert_text' => sub { $_[1] =~ s/[^\d]//go; return $_[1], $_[3]; } );
	# Prepare 'undo' for this entry
	$w{entryPFLocalIP} -> signal_connect( 'delete_text' => sub { ! $undoing and push( @undo, $w{entryPFLocalIP} -> get_chars( 0, -1 ) ); return $_[1], $_[3]; } );
	$w{entryPFLocalIP} -> signal_connect( 'insert_text' => sub { ! $undoing and push( @undo, $w{entryPFLocalIP} -> get_chars( 0, -1 ) ); return $_[1], $_[3]; } );
	$w{entryPFLocalIP} -> signal_connect( 'key_press_event' => sub {
		my ( $widget, $event ) = @_; 
		my $keyval	= '' . ( $event -> keyval );
		my $state	= '' . ( $event -> state );
		# Check if <Ctrl>z is pushed
		if ( ( $event -> state >= 'control-mask' ) && ( chr( $keyval ) eq 'z' ) && ( scalar @undo ) ) {
			$undoing = 1;
			$w{entryPFLocalIP} -> set_text( pop( @undo ) );
			$undoing = 0;
			return 1;
		}
		return 0;
	} );
	
	# Avoid the enter of non numeric values in this entry
	$w{spinPFRemotePort} -> signal_connect( 'insert_text' => sub { $_[1] =~ s/[^\d]//go; return $_[1], $_[3]; } );
	# Prepare 'undo' for this entry
	$w{entryPFRemoteIP} -> signal_connect( 'delete_text' => sub { ! $undoing and push( @undo, $w{entryPFRemoteIP} -> get_chars( 0, -1 ) ); return $_[1], $_[3]; } );
	$w{entryPFRemoteIP} -> signal_connect( 'insert_text' => sub { ! $undoing and push( @undo, $w{entryPFRemoteIP} -> get_chars( 0, -1 ) ); return $_[1], $_[3]; } );
	$w{entryPFRemoteIP} -> signal_connect( 'key_press_event' => sub {
		my ( $widget, $event ) = @_; 
		my $keyval	= '' . ( $event -> keyval );
		my $state	= '' . ( $event -> state );
		# Check if <Ctrl>z is pushed
		if ( ( $event -> state >= 'control-mask' ) && ( chr( $keyval ) eq 'z' ) && ( scalar @undo ) )
		{
			$undoing = 1;
			$w{entryPFRemoteIP} -> set_text( pop( @undo ) );
			$undoing = 0;
			return 1;
		}
		return 0;
	} );
	
	return %w;
}

sub _buildRemote
{
	my $self	= shift;
	my $hash	= shift;
	
	my $localIP		= $$hash{'localIP'}		// '';
	my $localPort	= $$hash{'localPort'}	// 1;
	my $remoteIP	= $$hash{'remoteIP'}	// 'localhost';
	my $remotePort	= $$hash{'remotePort'}	// 1;
	
	my @undo;
	my $undoing = 0;
	
	my %w;
	
	$w{position} = scalar @{ $$self{listRemote} };
	
	# Make an HBox to contain local address, local port, remote address, remote port and delete
	$w{hbox} = Gtk2::HBox -> new( 0, 0 );
		
		$w{frPFLocalIP} = Gtk2::Frame -> new( 'Bind Address:' );
		$w{hbox} -> pack_start( $w{frPFLocalIP}, 1, 1, 0 );
		$w{frPFLocalIP} -> set_shadow_type( 'GTK_SHADOW_NONE' );
			
			$w{entryPFLocalIP} = Gtk2::Entry -> new;
			$w{frPFLocalIP} -> add( $w{entryPFLocalIP} );
			$w{entryPFLocalIP} -> set_size_request( 30, 20 );
			$w{entryPFLocalIP} -> set_text( $localIP );
			$w{entryPFLocalIP} -> set_tooltip_text( 'Bind outgoing connection to given ip (leave blank to bind to any interface)' );
		
		$w{frPFLocalPort} = Gtk2::Frame -> new( 'Local Port:' );
		$w{hbox} -> pack_start( $w{frPFLocalPort}, 0, 1, 0 );
		$w{frPFLocalPort} -> set_shadow_type( 'GTK_SHADOW_NONE' );
			
			$w{spinPFLocalPort} = Gtk2::SpinButton -> new( Gtk2::Adjustment -> new( 1, 1, 65535, 1, 10, 0 ), 1, 0 );
			$w{frPFLocalPort} -> add( $w{spinPFLocalPort} );
			$w{spinPFLocalPort} -> set_size_request( 30, 20 );
			$w{spinPFLocalPort} -> set_value( $localPort );
		
		$w{frPFRemoteIP} = Gtk2::Frame -> new( 'Remote Address:' );
		$w{hbox} -> pack_start( $w{frPFRemoteIP}, 1, 1, 0 );
		$w{frPFRemoteIP} -> set_shadow_type( 'GTK_SHADOW_NONE' );
			
			$w{entryPFRemoteIP} = Gtk2::Entry -> new;
			$w{frPFRemoteIP} -> add( $w{entryPFRemoteIP} );
			$w{entryPFRemoteIP} -> set_size_request( 30, 20 );
			$w{entryPFRemoteIP} -> set_text( $remoteIP );
		
		$w{frPFRemotePort} = Gtk2::Frame -> new( 'Remote Port:' );
		$w{hbox} -> pack_start( $w{frPFRemotePort}, 0, 1, 0 );
		$w{frPFRemotePort} -> set_shadow_type( 'GTK_SHADOW_NONE' );
			
			$w{spinPFRemotePort} = Gtk2::SpinButton -> new( Gtk2::Adjustment -> new( 1, 1, 65535, 1, 10, 0 ), 1, 0 );
			$w{frPFRemotePort} -> add( $w{spinPFRemotePort} );
			$w{spinPFRemotePort} -> set_size_request( 30, 20 );
			$w{spinPFRemotePort} -> set_value( $remotePort );
		
		# Build delete button
		$w{btn} = Gtk2::Button -> new_from_stock( 'gtk-delete' );
		$w{hbox} -> pack_start( $w{btn}, 0, 1, 0 );
	
	# Add built control to main container
	$$self{gui}{vbRemote} -> pack_start( $w{hbox}, 0, 1, 0 );
	$$self{gui}{vbRemote} -> show_all;
	
	$$self{listRemote}[$w{position}] = \%w;
	
	# Setup some callbacks
	
	# Asign a callback for deleting entry
	$w{btn} -> signal_connect( 'clicked' => sub
	{
		$$self{cfg} = $self -> get_cfg();
		splice( @{ $$self{listRemote} }, $w{position}, 1 );
		$$self{cfg} = $self -> get_cfg();
		$self -> update( $$self{cfg} );
		return 1;
	} );
	
	# Avoid the enter of non numeric values in this entry
	$w{spinPFLocalPort} -> signal_connect( 'insert_text' => sub { $_[1] =~ s/[^\d]//go; return $_[1], $_[3]; } );
	# Prepare 'undo' for this entry
	$w{entryPFLocalIP} -> signal_connect( 'delete_text' => sub { ! $undoing and push( @undo, $w{entryPFLocalIP} -> get_chars( 0, -1 ) ); return $_[1], $_[3]; } );
	$w{entryPFLocalIP} -> signal_connect( 'insert_text' => sub { ! $undoing and push( @undo, $w{entryPFLocalIP} -> get_chars( 0, -1 ) ); return $_[1], $_[3]; } );
	$w{entryPFLocalIP} -> signal_connect( 'key_press_event' => sub
	{
		my ( $widget, $event ) = @_; 
		my $keyval	= '' . ( $event -> keyval );
		my $state	= '' . ( $event -> state );
		# Check if <Ctrl>z is pushed
		if ( ( $event -> state >= 'control-mask' ) && ( chr( $keyval ) eq 'z' ) && ( scalar @undo ) )
		{
			$undoing = 1;
			$w{entryPFLocalIP} -> set_text( pop( @undo ) );
			$undoing = 0;
			return 1;
		}
		return 0;
	} );
	
	# Avoid the enter of non numeric values in this entry
	$w{spinPFRemotePort} -> signal_connect( 'insert_text' => sub { $_[1] =~ s/[^\d]//go; return $_[1], $_[3]; } );
	# Prepare 'undo' for this entry
	$w{entryPFRemoteIP} -> signal_connect( 'delete_text' => sub { ! $undoing and push( @undo, $w{entryPFRemoteIP} -> get_chars( 0, -1 ) ); return $_[1], $_[3]; } );
	$w{entryPFRemoteIP} -> signal_connect( 'insert_text' => sub { ! $undoing and push( @undo, $w{entryPFRemoteIP} -> get_chars( 0, -1 ) ); return $_[1], $_[3]; } );
	$w{entryPFRemoteIP} -> signal_connect( 'key_press_event' => sub
	{
		my ( $widget, $event ) = @_; 
		my $keyval	= '' . ( $event -> keyval );
		my $state	= '' . ( $event -> state );
		# Check if <Ctrl>z is pushed
		if ( ( $event -> state >= 'control-mask' ) && ( chr( $keyval ) eq 'z' ) && ( scalar @undo ) )
		{
			$undoing = 1;
			$w{entryPFRemoteIP} -> set_text( pop( @undo ) );
			$undoing = 0;
			return 1;
		}
		return 0;
	} );
	
	return %w;
}

sub _buildDynamic
{
	my $self	= shift;
	my $hash	= shift;
	
	my $localIP		= $$hash{'dynamicIP'}	// '';
	my $localPort	= $$hash{'dynamicPort'}	// 1080;
	
	my @undo;
	my $undoing = 0;
	
	my %w;
	
	$w{position} = scalar @{ $$self{listDynamic} };
	
	# Make an HBox to contain local address, local port, remote address, remote port and delete
	$w{hbox} = Gtk2::HBox -> new( 0, 0 );
		
		$w{frPFLocalIP} = Gtk2::Frame -> new( 'Bind Address:' );
		$w{hbox} -> pack_start( $w{frPFLocalIP}, 1, 1, 0 );
		$w{frPFLocalIP} -> set_shadow_type( 'GTK_SHADOW_NONE' );
			
			$w{entryPFLocalIP} = Gtk2::Entry -> new;
			$w{frPFLocalIP} -> add( $w{entryPFLocalIP} );
			$w{entryPFLocalIP} -> set_size_request( 30, 20 );
			$w{entryPFLocalIP} -> set_text( $localIP );
			$w{entryPFLocalIP} -> set_tooltip_text( 'Leave blank to bind to any interface' );
		
		$w{frPFLocalPort} = Gtk2::Frame -> new( 'Local Port:' );
		$w{hbox} -> pack_start( $w{frPFLocalPort}, 0, 1, 0 );
		$w{frPFLocalPort} -> set_shadow_type( 'GTK_SHADOW_NONE' );
			
			$w{spinPFLocalPort} = Gtk2::SpinButton -> new( Gtk2::Adjustment -> new( 1, 1, 65535, 1, 10, 0 ), 1, 0 );
			$w{frPFLocalPort} -> add( $w{spinPFLocalPort} );
			$w{spinPFLocalPort} -> set_size_request( 30, 20 );
			$w{spinPFLocalPort} -> set_value( $localPort );
		
		# Build delete button
		$w{btn} = Gtk2::Button -> new_from_stock( 'gtk-delete' );
		$w{hbox} -> pack_start( $w{btn}, 0, 1, 0 );
	
	# Add built control to main container
	$$self{gui}{vbDynamic} -> pack_start( $w{hbox}, 0, 1, 0 );
	$$self{gui}{vbDynamic} -> show_all;
	
	$$self{listDynamic}[$w{position}] = \%w;
	
	# Setup some callbacks
	
	# Asign a callback for deleting entry
	$w{btn} -> signal_connect( 'clicked' => sub
	{
		$$self{cfg} = $self -> get_cfg();
		splice( @{ $$self{listDynamic} }, $w{position}, 1 );
		$$self{cfg} = $self -> get_cfg();
		$self -> update( $$self{cfg} );
		return 1;
	} );
	
	# Avoid the enter of non numeric values in this entry
	$w{spinPFLocalPort} -> signal_connect( 'insert_text' => sub { $_[1] =~ s/[^\d]//go; return $_[1], $_[3]; } );
	# Prepare 'undo' for this entry
	$w{entryPFLocalIP} -> signal_connect( 'delete_text' => sub { ! $undoing and push( @undo, $w{entryPFLocalIP} -> get_chars( 0, -1 ) ); return $_[1], $_[3]; } );
	$w{entryPFLocalIP} -> signal_connect( 'insert_text' => sub { ! $undoing and push( @undo, $w{entryPFLocalIP} -> get_chars( 0, -1 ) ); return $_[1], $_[3]; } );
	$w{entryPFLocalIP} -> signal_connect( 'key_press_event' => sub
	{
		my ( $widget, $event ) = @_; 
		my $keyval	= '' . ( $event -> keyval );
		my $state	= '' . ( $event -> state );
		# Check if <Ctrl>z is pushed
		if ( ( $event -> state >= 'control-mask' ) && ( chr( $keyval ) eq 'z' ) && ( scalar @undo ) )
		{
			$undoing = 1;
			$w{entryPFLocalIP} -> set_text( pop( @undo ) );
			$undoing = 0;
			return 1;
		}
		return 0;
	} );
	
	return %w;
}

# END: Private functions definitions
###################################################################

1;
