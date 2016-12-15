use utf8;
use LangID::Train;
use LangID::Identify;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use Unicode::String qw(utf8);

###################################### CREER STATS ################################################
	    
my %stats = create_stats('train');	       

###################################### CREER FICHIER CHARINFO ################################################


# l'information de caracteres est obtenu du plus gros jeux de ngrams du corpus sans spaces, sans ponctuation et sans chiffres
build_char_info('output/1_output_1100000_000');

###################################### CREER CORPUS D'EVALUATION ################################################

create_evaluation_corpus('corpus', 20);

###################################### CREATION DE JEUX DE NGRAMS ################################################
	
my %file = browse_train('train');

##------------------------------------ LISTES POUR FAIRE LA DU CORPUS À UTILISER --------------------------------------------------#

my @limits = (50000, 150000, 500000, 1100000);
my @ns = (1,2,3,4,5);

#------------------------------------- VARIER OPTIONS ------------------------------------------------#
my @space = (0,1);
my @digits = (0,1);
my @punt = (0,1);

# ------------------------------------- CONSTRUCTION DES JEUX DE NGRAMS AVEC LES DIFFERENTES OPTIONS -------------------------------#
foreach my $n (@ns){
	
	foreach my $limit (@limits){
		
		foreach my $p (@punt){
			
			foreach my $d (@digits){
				
				foreach my $s (@space){
				
					# construire fichier de ngrams normaux
					my %ngram = compute_ngram(\%file, $n , $limit, $p,$s,$d);	
					output_ngram(\%ngram, $n.'_output_'.$limit.'_'.$p.$s.$d, $n, $limit, $p,$s,$d);
							
					# construire fichier de probabilites
					my %probas = build_probabilities(\%ngram, $n.'_probabilities_'.$limit.'_'.$p.$s.$d);
					save_probabilities(\%probas, $n.'_probabilities_'.$limit.'_'.$p.$s.$d);
				}
			}
		}
	}
}

