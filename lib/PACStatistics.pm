package PACStatistics;

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
use File::Copy;
use Storable qw ( nstore retrieve );
use POSIX qw( strftime );

# GTK2
use Gtk2 '-init';

# PAC modules
use PACUtils;

# END: Import Modules
###################################################################

###################################################################
# Define GLOBAL CLASS variables

my $APPNAME		= $PACUtils::APPNAME;
my $APPVERSION	= $PACUtils::APPVERSION;
my $APPICON		= $RealBin . '/res/pac64x64.png';
my $CFG_DIR		= $ENV{'HOME'} . '/.config/pac';
my $STATS_FILE	= $CFG_DIR . '/pac_stats.nfreeze';

# END: Define GLOBAL CLASS variables
###################################################################

###################################################################
# START: Public class methods

sub new {
	my $class	= shift;
	
	my $self	= {};
	
	$self -> {cfg}			= shift;
	$self -> {statistics}	= {};
	
	$self -> {container}	= undef;
	$self -> {frame}		= {};
	
	readStats( $self );
	_buildStatisticsGUI( $self );
	
	bless( $self, $class );
	return $self;
}

sub update {
	my $self	= shift;
	my $uuid	= shift;
	my $cfg		= shift // $PACMain::FUNCS{_MAIN}{_CFG};
	
	$$self{cfg}		= $cfg;
	$$self{uuid}	= $uuid;
	my $name		= $$cfg{environments}{$uuid}{name};
	
	my $font = 'font="monospace 9"';
	
	$$self{frame}{lblPR} -> set_markup( '' );
	$$self{frame}{lblPG} -> set_markup( '' );
	$$self{frame}{lblPN} -> set_markup( '' );
	$$self{frame}{hboxPACRoot}	-> hide;
	$$self{frame}{hboxPACGroup}	-> hide;
	$$self{frame}{hboxPACNode}	-> hide;
	
	# Show/Hide widgets
	if ( $uuid eq '__PAC__ROOT__' ) {
		$$self{frame}{hboxPACRoot}	-> show;
		$$self{frame}{hboxPACGroup}	-> hide;
		$$self{frame}{hboxPACNode}	-> hide;
		
		my $groups		= 0;
		my $nodes		= 0;
		my $total_conn	= 0;
		my $total_time	= 0;
		
		foreach my $tmpuuid ( keys %{ $$cfg{'environments'} } ) {
			if ( $$cfg{'environments'}{$tmpuuid}{_is_group} ) {
				next if $tmpuuid eq '__PAC__ROOT__';
				$groups++;
				$total_conn += ( $$self{statistics}{$tmpuuid}{total_connections} // 0 );
			} else {
				$nodes++;
				$total_time += ( $$self{statistics}{$tmpuuid}{total_time} // 0 );
				$total_conn += ( $$self{statistics}{$tmpuuid}{total_conn} // 0 );
			}
		}
		
		# Prepare STRINGIFIED data
		my $str_total_time = '';
		$str_total_time .= int( $total_time / 86400 )	. ' days, ';
		$str_total_time .= ( $total_time / 3600 ) % 24	. ' hours, ';
		$str_total_time .= ( $total_time / 60 ) % 60	. ' minutes, ';
		$str_total_time .= $total_time % 60				. ' seconds';
		
		$$self{frame}{lblPR}	-> set_markup(
			"<span $font>" .
				"Total PAC Groups:              <b>$groups</b>"			. "\n" .
				"Total PAC Nodes:               <b>$nodes</b>"			. "\n" .
				"Total Connections Established: <b>$total_conn</b>"		. "\n" .
				"Total Time Connected:          <b>$str_total_time</b>" .
			"</span>"
		);
	} elsif ( $$cfg{environments}{$uuid}{_is_group} ) {
		$$self{frame}{hboxPACRoot}	-> hide;
		$$self{frame}{hboxPACGroup}	-> show;
		$$self{frame}{hboxPACNode}	-> hide;
		
		my $groups		= 0;
		my $nodes		= 0;
		my $total_conn	= 0;
		my $total_time	= 0;
		
		foreach my $tmpuuid ( $PACMain::FUNCS{_MAIN}{_GUI}{treeConnections} -> _getChildren( $uuid, 'all', 1 ) ) {
			if ( $$cfg{'environments'}{$tmpuuid}{_is_group} ) {
				$groups++;
				$total_conn += ( $$self{statistics}{$tmpuuid}{total_conn} // 0 );
			} else {
				$nodes++;
				$total_time += ( $$self{statistics}{$tmpuuid}{total_time} // 0 );
				$total_conn += ( $$self{statistics}{$tmpuuid}{total_conn} // 0 );
			}
		}
		
		# Prepare STRINGIFIED data
		my $str_total_time = '';
		$str_total_time .= int( $total_time / 86400 )	. ' days, ';
		$str_total_time .= ( $total_time / 3600 ) % 24	. ' hours, ';
		$str_total_time .= ( $total_time / 60 ) % 60	. ' minutes, ';
		$str_total_time .= $total_time % 60				. ' seconds';
		
		$$self{frame}{lblPG}	-> set_markup(
			"<span $font>" .
				"Total Sub-Groups:              <b>$groups</b>"			. "\n" .
				"Total Contained Nodes:         <b>$nodes</b>"			. "\n" .
				"Total Connections Established: <b>$total_conn</b>"		. "\n" .
				"Total Time Connected:          <b>$str_total_time</b>" .
			"</span>"
		);
	} else {
		$$self{frame}{hboxPACRoot}	-> hide;
		$$self{frame}{hboxPACGroup}	-> hide;
		$$self{frame}{hboxPACNode}	-> show;
		
		my $groups		= 0;
		my $nodes		= 0;
		my $start		= 0;
		my $stop		= 0;
		my $total_conn	= 0;
		my $total_time	= 0;
		
		if ( ! defined $$self{statistics}{$uuid} ) {
			$$self{statistics}{$uuid}{start}		= 0;
			$$self{statistics}{$uuid}{stop}			= 0;
			$$self{statistics}{$uuid}{total_conn}	= 0;
			$$self{statistics}{$uuid}{total_time}	= 0;
		}
		
		$start		= $$self{statistics}{$uuid}{start}		// 0;
		$stop		= $$self{statistics}{$uuid}{stop}		// 0;
		$total_conn	= $$self{statistics}{$uuid}{total_conn}	// 0;
		$total_time	= $$self{statistics}{$uuid}{total_time}	// 0;
		
		my $str_start	= $start ? strftime( "%Y-%m-%d %H:%M:%S", localtime( $$self{statistics}{$uuid}{start} ) ) : 'NO DATA AVAILABLE';
		my $str_stop	= $stop ? strftime( "%Y-%m-%d %H:%M:%S", localtime( $$self{statistics}{$uuid}{stop} ) ) : 'NO DATA AVAILABLE';
		
		# Prepare STRINGIFIED data
		my $str_total_time = '';
		$str_total_time .= int( $total_time / 86400 )	. ' days, ';
		$str_total_time .= ( $total_time / 3600 ) % 24	. ' hours, ';
		$str_total_time .= ( $total_time / 60 ) % 60	. ' minutes, ';
		$str_total_time .= $total_time % 60				. ' seconds';
		
		$$self{frame}{lblPN}	-> set_markup(
			"<span $font>" .
				"Total Time Connected:          <b>$str_total_time</b>"	. "\n" .
				"Total Connections Established: <b>$total_conn</b>"		. "\n" .
				"Last Connection:               <b>$str_start</b>" .
			"</span>"
		);
	}
	
	if ( $uuid eq '__PAC__ROOT__' )						{ $$self{frame}{btnReset} -> set_label( "Reset Statistics for\n'ALL PAC CONNECTIONS'..." ); }
	elsif ( $$cfg{'environments'}{$uuid}{_is_group} )	{ $$self{frame}{btnReset} -> set_label( "Reset Statistics for group\n'$name'..." ); }
	else												{ $$self{frame}{btnReset} -> set_label( "Reset Statistics for\n'$name'..." ); }
	
	return 1;
}

sub readStats {
	my $self = shift;
	eval { $$self{statistics} = retrieve( $STATS_FILE ); };
	return $@ ? 0 : 1;
}

sub saveStats { return nstore( $_[0]{statistics}, $STATS_FILE ); }

sub start {
	my $self	= shift;
	my $uuid	= shift;
	
	$$self{statistics}{$uuid}{total_conn}++;
	$$self{statistics}{$uuid}{start} = time;
	$$self{statistics}{$uuid}{stop} = 0;
	$self -> update( $uuid );
	
	return 1;
}

sub stop {
	my $self	= shift;
	my $uuid	= shift;
	
	$$self{statistics}{$uuid}{stop} = time;
	$$self{statistics}{$uuid}{total_time} += ( $$self{statistics}{$uuid}{stop} - $$self{statistics}{$uuid}{start} );
	$self -> update( $uuid );
	
	return 1;
}

sub purge {
	my $self	= shift;
	my $cfg		= shift // $PACMain::FUNCS{_MAIN}{_CFG};
	
	foreach my $uuid ( keys %{ $$self{statistics} } ) { delete $$self{statistics}{$uuid} unless defined $$cfg{environments}{$uuid}; }
	
	return 1;
}

# END: Public class methods
###################################################################

###################################################################
# START: Private functions definitions

sub _buildStatisticsGUI {
	my $self = shift;
	
	my $cfg = $$self{cfg};
	
	my %w;
	
	# Build a vbox for:buttons, separator and image widgets
	$w{hbox} = Gtk2::HBox -> new( 0, 0 );
		
		$w{btnReset} = Gtk2::Button -> new_with_label( 'Reset Statistics...' );
		$w{btnReset} -> set_image( Gtk2::Image -> new_from_stock( 'gtk-refresh', 'button' ) );
		$w{btnReset} -> set( 'can-focus', 0 );
		$w{hbox} -> pack_start( $w{btnReset}, 0, 1, 0 );
		
		$w{hbox} -> pack_start( Gtk2::VSeparator -> new, 0, 1, 5 );
		
		$w{vbox} = Gtk2::VBox -> new( 0, 0 );
		$w{hbox} -> pack_start( $w{vbox}, 1, 1, 0 );
			
			$w{hboxPACRoot} = Gtk2::HBox -> new( 0, 0 );
			$w{vbox} -> pack_start( $w{hboxPACRoot}, 0, 1, 0 );
				
				$w{lblPR} = Gtk2::Label -> new;
				$w{lblPR} -> set_justify( 'left' );
				$w{hboxPACRoot} -> pack_start( $w{lblPR}, 0, 1, 0 );
			
			$w{hboxPACGroup} = Gtk2::HBox -> new( 0, 0 );
			$w{vbox} -> pack_start( $w{hboxPACGroup}, 0, 1, 0 );
				
				$w{lblPG} = Gtk2::Label -> new;
				$w{lblPG} -> set_justify( 'left' );
				$w{hboxPACGroup} -> pack_start( $w{lblPG}, 0, 1, 0 );
			
			$w{hboxPACNode} = Gtk2::HBox -> new( 0, 0 );
			$w{vbox} -> pack_start( $w{hboxPACNode}, 0, 1, 0 );
				
				$w{lblPN} = Gtk2::Label -> new;
				$w{lblPN} -> set_justify( 'left' );
				$w{hboxPACNode} -> pack_start( $w{lblPN}, 0, 1, 0 );
	
	$$self{container} = $w{hbox};
	$$self{frame} = \%w;
	
	# Callback(s)
	
	$w{btnReset} -> signal_connect( 'clicked', sub {
		my $cfg		= $$self{cfg};
		my $uuid	= $$self{uuid};
		my $name	= $$cfg{environments}{$uuid}{name};
		
		if ( $uuid eq '__PAC__ROOT__' ) {
			return 1 unless _wConfirm( $PACMain::FUNCS{_MAIN}{_GUI}{main}, "Are you sure you want to reset <b>ALL PAC</b> statistics?\n(This action can not be undone!)" );
			foreach my $child ( keys %{ $$cfg{environments} } )
			{
				next if $child eq '__PAC__ROOT__';
				$$self{statistics}{$child}{start}		= 0;
				$$self{statistics}{$child}{stop}		= 0;
				$$self{statistics}{$child}{total_conn}	= 0;
				$$self{statistics}{$child}{total_time}	= 0;
			}
		} elsif ( $$cfg{environments}{$uuid}{_is_group} ) {
			return 1 unless _wConfirm( $PACMain::FUNCS{_MAIN}{_GUI}{main}, "Are you sure you want to reset statistics for group '<b>$name</b>'?\n(This action can not be undone!)" );
			foreach my $child ( $PACMain::FUNCS{_MAIN}{_GUI}{treeConnections} -> _getChildren( $uuid, 0, 1 ) )
			{
				$$self{statistics}{$child}{start}		= 0;
				$$self{statistics}{$child}{stop}		= 0;
				$$self{statistics}{$child}{total_conn}	= 0;
				$$self{statistics}{$child}{total_time}	= 0;
			}
		} else {
			return 1 unless _wConfirm( $PACMain::FUNCS{_MAIN}{_GUI}{main}, "Are you sure you want to reset statistics for connection '<b>$name</b>'?\n(This action can not be undone!)" );
			$$self{statistics}{$uuid}{start}		= 0;
			$$self{statistics}{$uuid}{stop}			= 0;
			$$self{statistics}{$uuid}{total_conn}	= 0;
			$$self{statistics}{$uuid}{total_time}	= 0;
		}
		
		$self -> update( $uuid );
		return 1;
	} );
	
	return 1;
}

# END: Private functions definitions
###################################################################

1;
