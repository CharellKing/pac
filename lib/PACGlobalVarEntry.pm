package PACGlobalVarEntry;

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

# PAC modules
use PACUtils;

# END: Import Modules
###################################################################

###################################################################
# Define GLOBAL CLASS variables



# END: Define GLOBAL CLASS variables
###################################################################

###################################################################
# START: Public class methods

sub new {
	my $class	= shift;
	my $self	= {};
	
	$self -> {cfg}			= shift;
	
	$self -> {container}	= undef;
	$self -> {frame}		= {};
	$self -> {list}			= [];
	
	_buildVarGUI( $self );
	defined $self -> {cfg} and PACGlobalVarEntry::update( $self -> {cfg} );
	
	bless( $self, $class );
	return $self;
}

sub update {
	my $self	= shift;
	my $cfg		= shift;
	
	defined $cfg and $$self{cfg} = $cfg;
	
	# Destroy previous widgets
	$$self{frame}{vbvar} -> foreach( sub { $_[0] -> destroy(); } );
	
	# Empty parent widgets' list
	$$self{list} = [];
	
	# Now, add the -new?- widgets
	foreach my $var ( sort { $a cmp $b } keys %{ $$self{cfg} } ) { _buildVar( $self, $var, $$self{cfg}{$var}{'value'}, $$self{cfg}{$var}{'hidden'} ); }
	
	return 1;
}

sub get_cfg {
	my $self = shift;
	
	my %hash;
	
	foreach my $w ( @{ $self -> {list} } ) {
		next if $$w{var} -> get_chars( 0, -1 ) eq '';
		$hash{ $$w{var} -> get_chars( 0, -1 ) }{'value'}	= $$w{val} -> get_chars( 0, -1 );
		$hash{ $$w{var} -> get_chars( 0, -1 ) }{'hidden'}	= $$w{hide} -> get_active;
	}
	
	return \%hash;
}

# END: Public class methods
###################################################################

###################################################################
# START: Private functions definitions

sub _buildVarGUI {
	my $self		= shift;
	
	my $cfg			= $self -> {cfg};
	
	my %w;
	
	# Build a vbox for:buttons, separator and expect widgets
	$w{vbox} = Gtk2::VBox -> new( 0, 0 );
		
		# Build a hbuttonbox for widgets actions (add, etc.)
		$w{bbox} = Gtk2::HButtonBox -> new();
		$w{vbox} -> pack_start( $w{bbox}, 0, 1, 0 );
		$w{bbox} -> set_layout( 'GTK_BUTTONBOX_START' );
			
			# Build 'add' button
			$w{btnadd} = Gtk2::Button -> new_from_stock( 'gtk-add' );
			$w{bbox} -> add( $w{btnadd} );
		
		# Build a separator
		$w{sep} = Gtk2::HSeparator -> new();
		$w{vbox} -> pack_start( $w{sep}, 0, 1, 5 );
		
		# Build a scrolled window
		$w{sw} = Gtk2::ScrolledWindow -> new();
		$w{vbox} -> pack_start( $w{sw}, 1, 1, 0 );
		$w{sw} -> set_policy( 'automatic', 'automatic' );
		$w{sw} -> set_shadow_type( 'none' );
			
			$w{vp} = Gtk2::Viewport -> new();
			$w{sw} -> add( $w{vp} );
			$w{vp} -> set_property( 'border-width', 5 );
			$w{vp} -> set_shadow_type( 'none' );
				
				# Build and add the vbox that will contain the expect widgets
				$w{vbvar} = Gtk2::VBox -> new( 0, 0 );
				$w{vp} -> add( $w{vbvar} );
	
	$$self{container} = $w{vbox};
	$$self{frame} = \%w;
	
	# Button(s) callback(s)
	
	$w{btnadd} -> signal_connect( 'clicked', sub {
		# Save current cfg
		$$self{cfg} = $self -> get_cfg();
		# Append an empty var entry to cfg
		$$self{cfg}{' _variable'}{'value'} = '_value';
		$$self{cfg}{' _variable'}{'hidden'} = 0;
		# Update gui
		$self -> update();
		# Set keyboard focus on first created entry
		$$self{list}[0]{var} -> grab_focus();
		return 1;
	} );
	
	return 1;
}

sub _buildVar {
	my $self	= shift;
	my $var		= shift;
	my $val		= shift;
	my $hide	= shift;
	
	my @undo;
	my $undoing = 0;
	
	my %w;
	
	$w{position} = scalar @{ $$self{list} };
	
	# Make an HBox to contain label, entry and del button
	$w{hbox} = Gtk2::HBox -> new( 0, 0 );
		
		# Build label
		$w{lbl1} = Gtk2::Label -> new( 'Variable:' );
		$w{hbox} -> pack_start( $w{lbl1}, 0, 1, 0 );
		
		# Build entry
		$w{var} = Gtk2::Entry -> new;
		$w{hbox} -> pack_start( $w{var}, 0, 1, 0 );
		$w{var} -> set_text( $var );
		
		# Build label
		$w{lbl2} = Gtk2::Label -> new( ' Value:' );
		$w{hbox} -> pack_start( $w{lbl2}, 0, 1, 0 );
		
		# Build entry
		$w{val} = Gtk2::Entry -> new;
		$w{hbox} -> pack_start( $w{val}, 1, 1, 0 );
		$w{val} -> set_text( $val );
		
		$w{hide} = Gtk2::CheckButton -> new( 'Hide' );
		$w{hbox} -> pack_start( $w{hide}, 0, 1, 0 );
		$w{hide} -> set_active( $hide );
		$w{hide} -> signal_connect( toggled => sub { $w{val} -> set_visibility( ! $w{hide} -> get_active ); } );
		
		$w{val} -> set_visibility( ! $w{hide} -> get_active );
		
		# Build delete button
		$w{btn} = Gtk2::Button -> new_from_stock( 'gtk-delete' );
		$w{hbox} -> pack_start( $w{btn}, 0, 1, 0 );
	
	# Add built control to main container
	$$self{frame}{vbvar} -> pack_start( $w{hbox}, 0, 1, 0 );
	$$self{frame}{vbvar} -> show_all;
	
	$$self{list}[$w{position}] = \%w;
	
	# Setup some callbacks
	
	# Asign a callback for deleting entry
	$w{btn} -> signal_connect( 'clicked' => sub {
		$$self{cfg} = $self -> get_cfg();
		splice( @{ $$self{list} }, $w{position}, 1 );
		delete $$self{cfg}{ $w{var} -> get_chars( 0, -1 ) } ;
		$self -> update();
		return 1;
	} );
	
	$w{var} -> signal_connect( 'delete_text' => sub { ! $undoing and push( @undo, $w{var} -> get_chars( 0, -1 ) ); return $_[1], $_[3]; } );
	$w{var} -> signal_connect( 'insert_text' => sub { ! $undoing and push( @undo, $w{var} -> get_chars( 0, -1 ) ); return $_[1], $_[3]; } );
	$w{var} -> signal_connect( 'key_press_event' => sub {
		my ( $widget, $event ) = @_; 
		
		my $keyval	= '' . ( $event -> keyval );
		my $state	= '' . ( $event -> state );
		# Check if <Ctrl>z is pushed
		if ( ( $event -> state == [ qw( control-mask ) ] ) && ( chr( $keyval ) eq 'z' ) && ( scalar @undo ) ) {
			$undoing = 1;
			$w{var} -> set_text( pop( @undo ) );
			$undoing = 0;
			return 1;
		}
		return 0;
	} );
	
	$w{val} -> signal_connect( 'delete_text' => sub { ! $undoing and push( @undo, $w{val} -> get_chars( 0, -1 ) ); return $_[1], $_[3]; } );
	$w{val} -> signal_connect( 'insert_text' => sub { ! $undoing and push( @undo, $w{val} -> get_chars( 0, -1 ) ); return $_[1], $_[3]; } );
	$w{val} -> signal_connect( 'key_press_event' => sub {
		my ( $widget, $event ) = @_; 
		
		my $keyval	= '' . ( $event -> keyval );
		my $state	= '' . ( $event -> state );
		# Check if <Ctrl>z is pushed
		if ( ( $event -> state == [ qw( control-mask ) ] ) && ( chr( $keyval ) eq 'z' ) && ( scalar @undo ) ) {
			$undoing = 1;
			$w{val} -> set_text( pop( @undo ) );
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
