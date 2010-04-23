#!/usr/bin/perl
#
#  Copyright (c) 2009 Ondrej Dusek
#  All rights reserved.
# 
#  Redistribution and use in source and binary forms, with or without modification, 
#  are permitted provided that the following conditions are met:
#  Redistributions of source code must retain the above copyright notice, this list 
#  of conditions and the following disclaimer.
#  Redistributions in binary form must reproduce the above copyright notice, this 
#  list of conditions and the following disclaimer in the documentation and/or other 
#  materials provided with the distribution.
#  Neither the name of Ondrej Dusek nor the names of their contributors may be
#  used to endorse or promote products derived from this software without specific 
#  prior written permission.
# 
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
#  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
#  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
#  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
#  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
#  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
#  OF THE POSSIBILITY OF SUCH DAMAGE.
#

#
# A tokenizer, which doesn't handle sentence splitting (see sent.pl). Dates, numbers,
# URLs and e-mails are to be treated as single tokens.
#
# Usage: ./sent.pl [file1] [file2 ...] > tokenized-output
# If no input file name is given, it reads standard input.

use utf8;

binmode( STDIN, ":utf8" );
binmode( STDOUT, ":utf8" );


# funkce na hledani datumu (a vraceni cisel ve spravnem formatu)
# vraci pole plne clenu datumu ve spravnem poradi (vcetne delici interpunkce)
# nebo cele cislo splacnute dohromady, nejde-li o datum.
sub parse_date {

    my $num = $_[0];
    my $successful = 0;
    my @date, @delim;

    while( length $num ){

	if ( $num =~ m/^[0-9]{1,4}/g ){

	    push( @date, substr( $num, 0, pos $num ) );
	    $num = substr( $num, pos $num );

	    if ( @date == 2 ){
		if ( length $date[1] > 2 ){
		    last;
		}
		$successful = 1 unless( length $num );
	    }
	    elsif ( @date == 3 ){

		if ( length $date[0] > 2 && length $date[2] > 2 ){
		    last;
		}
		unless( length $num ){
		    
		    if ( length $date[0] > 2 ){
			$successful = 1
			    if ( $date[1] > 0 && $date[2] > 0 
				&& (( $date[1] <= 31 && $date[2] <= 12 ) 
				|| ( $date[2] <= 31 && $date[1] <= 12 )));
		    }
		    elsif( length $date[2] > 2 ){
			$successful = 1
			    if ( $date[0] > 0 && $date[1] > 0 
				&& (( $date[0] <= 31 && $date[1] <= 12 ) 
				|| ( $date[1] <= 31 && $date[0] <= 12 )));
		    }
		    else {
			$successful = 1
			    if (( length $date[2] == 2 && $date[1] > 0 && $date[0] > 0 
				&& (($date[0] <= 31 && $date[1] <= 12 ) || ( $date[1] <= 31 && $date[0] <= 12 )))
				|| ( length $date[0] == 2 && $date[1] > 0 && $date[2] > 0 
				&& (($date[2] <= 31 && $date[1] <= 12 ) || ( $date[1] <= 31 && $date[2] <= 12 ))));
		    }
		}
	    }
	}
	elsif ( $num =~ m/^[\.\-\/\']/ ){

	    push( @delim, substr( $num, 0, 1 ) );	    
	    $num = substr( $num, 1 );

	    $successful = 1 if ( @date == 2 && @delim == 2 && ! (length $num) );
	}
    }

    if ( $successful ){
	
	if ( @date == 3 ){
	    return ( $date[0], $delim[0], $date[1], $delim[1], $date[2] );
	}
	elsif ( @delim == 2 ){
	    return ( $date[0], $delim[0], $date[1], $delim[1] );
	}
	else {
	    return ( $date[0], $delim[0], $date[1] );
	}
    }
    else {
	return ( $_[0] );
    }
}


# zpracovani 1 vstupniho souboru
sub process_file {
    
    my $file = $_[0];

    # pro 1 radek
    while( <$file> ){
	
	$line = $_;
	reset 'tokens';

	while( length $line ){

	    # ABC$ -- musi byt pred beznymi slovy, jinak na nej nedojde
	    # URL (format protocol://server/page) -- nesmi koncit teckou (ta je oddelena)
	    # e-mail (viz http://www.houseoffusion.com/groups/regex/thread.cfm/threadid:149)
	    # bezna slova (vc. 12335fjfj)
	    if ( $line =~ m/^[\p{Letter}]+\$/g 
		|| $line =~ m/^[\p{Letter}]+:\/\/[\p{Number}\p{Letter}\.\-]+(:\d+)?(([\p{Number}\p{Letter}\.\/\-\_\&\%\+\?\#\;\~]+)?[\p{Number}\p{Letter}\/\-\_\&\%\+\?\#\;\~])?/g
		|| $line =~ m/^[a-zA-Z]([.]?([\p{Number}\p{Letter}_-]+)*)?@([\p{Number}\p{Letter}\-_]+\.)+[a-zA-Z]{2,4}/g 
		|| $line =~ m/^[\p{Number}]*[\p{Letter}][\p{Number}\p{Letter}]*/g ){ 

		$end = pos $line;
		push( @tokens, substr( $line, 0, $end ) );
	    }
	    # cisla, data apod.
	    elsif ( $line =~ m/^([\p{Number}]+[\p{Punctuation}\s])*[\p{Number}]+/g ){
		
		$end = pos $line;	   
		pos $line = 0;

		# cokoliv co ma aspon nejakou sanci byt validni datum je osetreno zvlast
		# !!! je 11.11. datum?
		if ( $line =~ m/^([0-9]{1,2}|[0-9]{4})[\.\-\/\'][0-9]{1,2}([\.\-\/\'](([0-9]{4}|[0-9]{1,2}))?)?[^0-9\.\-\/\']/g ){

		    $end = (pos $line) - 1;
		    push( @tokens, parse_date( substr( $line, 0, $end ) ) );
		}
		else {

		    $found = substr( $line, 0, $end );
		    $found =~ s/[\s]/_/g;
		    push( @tokens, $found );
		}
	    }
	    # interpunkce
	    elsif ( $line =~ m/^[\p{Punctuation}\p{Symbol}]/g ){

		# vyjimky --, ``, '', ...
		pos $line = 0;
		$end = 1;
		if ( $line =~ m/^(\.\.\.|\`\`|\'\'|\-\-)/g ){

		    $end = pos $line;
		}
		push( @tokens, substr( $line, 0, $end ) );
	    }
	    # whitespace
	    else { 
		$end = 1;
	    }
	
	    $line = substr( $line, $end );
	}

	if ( @tokens ){
	    print( join( " ", @tokens ) );
	    print( "\n" );
	}
    }

}

#
#
# MAIN
#
#

# argumenty: soubory se vstupem
if ( @ARGV ){
    while( @ARGV ){
	
	open( INPUT, $ARGV[0] );
	binmode( INPUT, ":utf8" );
	process_file( \*INPUT );
	shift( @ARGV );
    }
}
else {
    process_file( \*STDIN );
}
