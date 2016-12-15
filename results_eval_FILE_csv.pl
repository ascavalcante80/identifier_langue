use utf8;
use LangID::Train;
use LangID::Identify;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use Getopt::Long;
use Unicode::String qw(utf8);

# ce script realise une serie de testes pour identifier la langues des fichiers présents dans un dossier passé comme argument
# les résultats sont écrit dans en deux fichiers CSV enregistré dans le dossier 'stats'. Le fichier results_files_PROBAS.csv 
# contient le résultat d'identification avec la méthode de somme de probabilités et le dossier results_files_DIST.csv contient
# les résultats d'identification avec la méthode de calcul de distance


# -------------------------------- phrases --------------------------------------------------------------#
my %directories = browse_train('eval_short');

#------------------------------------- VARIER OPTIONS ------------------------------------------------#

my @limits = (50000, 500000, 1100000);
my @ns = (1,3,5);

my @space = (0,1);
my @digits = (0);
my @punt = (0);

my $lenght = 10000000;

# ----------------------------------- creer fichier csv de sortie ----------------------------------------#
open(CSVPROBAS, ">:encoding(UTF-8)", "stats/results_files_PROBAS.csv") || croak $!;
open(CSVDIST, ">:encoding(UTF-8)", "stats/results_files_DIST.csv") || croak $!;

foreach my $lang (keys %directories){
	
	my @files = browse_files('eval_short/'.$lang."/");
	
	foreach my $file (@files){
		
		print CSVPROBAS "\n".$lang.','.$file.',';
		print CSVDIST "\n".$lang.','.$file.',';
		print "\n".$file.',';
		# faire varier le nombre de ngrams et la taille du corpus
		foreach my $n (@ns){
			
			foreach my $limit (@limits){
				
				foreach my $p (@punt){
				
					foreach my $d (@digits){
					
						foreach my $s (@space){
					

  						print $n.'_'.$limit.'_'.$p.$s.$d."\n";

							# char trigrams
							my %ngramProb = load_probabilities('output_prob/'.$n.'_probabilities_'.$limit.'_'.$p.$s.$d, $n);
							
							## creer les ngrams de la string teste 
							my %ngram_teste = compute_ngram('eval_short/'.$lang."/".$file, $n, $lenght, $p, $s, $d );
							
							# tableau de hash avec la somme te probababilites de tout les ngrams de la string teste
							my %ranks = rank_languages_probabilities(\%ngram_teste, 'output_prob/'.$n.'_probabilities_'.$limit.'_'.$p.$s.$d, $n);
					
							# afficher les 3 première langues resultat en ordre croissante
							my $counter = 0;			
							foreach my $item (reverse sort { $ranks{$a} <=> $ranks{$b} } keys %ranks) {
								if ($counter < 3){
									print CSVPROBAS (sprintf "%.20f",$ranks{$item}).','.$item.',';	
								}
								$counter++;			    
							}
            
						%ranks = identify_with_distance(\%ngram_teste, 'output/'.$n.'_output_'.$limit.'_'.$p.$s.$d);
				
						# afficher les 3 première langues resultat en ordre croissante
						$counter = 0;			
						foreach my $item (sort { $ranks{$a} <=> $ranks{$b} } keys %ranks) {
							if ($counter < 3){
								print CSVDIST ",".$ranks{$item}.','.$item.',';	
							}
							$counter++;			    
						}

						}				
					}
				}
			}
		}
	}
}

close(CSVPROBAS);
close(CSVDIST);
