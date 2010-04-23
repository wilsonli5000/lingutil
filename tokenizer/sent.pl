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
# This is a sentence-splitting script. It tries to get statistics (see sentrain.pl) from 
# a file given under the -s parameter, but works even without it.
#
# Usage: ./sent.pl [-s statistics] [file1] [file2]
# If no file is given, it reads standard input. The results are written to the standard
# output. 

use utf8;

binmode( STDIN, ":utf8" );
binmode( STDOUT, ":utf8" );


# nacteni statistiky ze souboru
sub get_statistics {

    my %stats;

    open( STATFILE, @_[0] );     
    binmode( STATFILE, ":utf8" );
    
    while( <STATFILE> ){
	
	@line = split( ' ' );
	$stats{ $line[0] } = $line[1];
    }

    return %stats;
}


# Testuje, zda ma byt na dane pozici hranice vety.
#
# parametry: @line, $pos
#
# Je-li na $i tecka, testuju co bylo pred ni, pokud je ve statistice nebo je to cislo,
# jedu dal. Potom preskocim vsechny za ni nasledujici Final_ a Close_Punctuation, az dojdu k 
# prvnimu nasl. znaku. Byly-li tam nejake punctuations, nebo nasleduje velke pismeno / open punct. / 
# necasovane pismeno / cislo, zalomim vetu.
#
# Vraci vzdalenost od $pos do skutecneho konce vety (pres vsechny tecky a uvozovky).
sub is_break {


    my ($pos, @line) = @_;
    my $forward = $pos + 1;

    # porovnani se zkratkami a vylouceni cisel
    return 0 if ( $line[$pos] == '.' 
	&& ( exists( $stats{ $line[$pos-1] } ) || $line[$pos-1] =~ m/^[\p{Number}]+$/ ) );

    # prolezeni final a close punctuation dopredu; 0x201C unicode bohuzel je v Initial, i kdyz 
    # v nemcine a cestine jde o konecnou uvozovku, proto ji pridavam.
    $forward++ while ( $forward < @line
	&& $line[$forward] =~ m/^[\p{STerm}\p{Close_Punctuation}\p{Final_Punctuation}\x{201C}]$/ );

    # byla-li nejaka close punctuation nebo nasleduje-li velke/necasove pismeno nebo open punct. nebo cislo,
    # muzu zalomit vetu (na pozici forward). (Vezme vsechna pismenka a vylouci mala)
    return ( $forward - $pos ) if ( $forward > $pos + 1 
	|| ( $line[$forward] =~ m/^[\p{Letter}\p{Open_Punctuation}\p{Initial_Punctuation}\p{Number}]/
	&& $line[$forward] !=~ m/^[\p{Lowercase_Letter}]/ ) );

    return 0;
}



# Deleni vet v 1 souboru.
# 
# parametry: $file
#
# Najdu STerm a predam na posouzeni procedure is_break. Vrati-li 1, zalamuji vetu.
# Po kazdem radku (odstavci) zalomi vystup jeste jednou.
sub process_file {

    my $file = $_[0];

    while( <$file> ){
	
	my @tokens = split( ' ' );
	my $i = 0;
	my $break = 0;
	my $break_dst = 0;

	while( $i < @tokens ){
	    
	    $break = 0;

	    until( $i >= @tokens || $tokens[$i] =~ m/^[\p{STerm}]$/ ){
		print( $tokens[$i++] . " " );
	    }
	    #zjistim, zda stojim pred zalomenim
	    $break = 1 if ( $i == @tokens - 1 || ( $i > 0 && ( $break_dst = is_break( $i, @tokens ) ) ) );
	    print( $tokens[$i++] . " " );

	    #dovypsani zbytku az do konce vety a zalomeni, pokud ho is_break nasel
	    if ( $break == 1 ){

		my $j = $i;
		
		print( $tokens[$j++] . " " ) while( $j < $i + $break_dst - 1 );
		$i = $j;
		print( "\n" );
	    }		
	}

	print( "\n" ) if ( $break == 0 );
	print( "\n" );
    }
}


#
# MAIN
#

# pokus o ziskani statistiky
if ( @ARGV >= 2 && $ARGV[0] == "-s" ){
   
    %stats = get_statistics( $ARGV[1] );

    shift( @ARGV );
    shift( @ARGV );
}

# deleni vet
#

# argumenty: soubory se vstupem! 
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
