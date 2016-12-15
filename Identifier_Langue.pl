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

#------------------------------------- VARIER OPTIONS ------------------------------------------------#


my $limit = 500000;
my $ns = 3;

my $s = 1;
my $d = 0;
my $p = 0;

my $length = "total";

print "Obs ---> If you want treat, type the complet path even for a file in the same folder. Otherwise it won't work!\n";
print "Insert phrase or file path you want to analyse:\n";

my $phrase_test = <STDIN>;
chomp $phrase_test;

if (-f $phrase_test){

  print "Treating as file.\n";

} else {

    print "Treating as string. \n";
}

  
# ----------------------------------- creer fichier csv de sortie ----------------------------------------#

						
## creer les ngrams de la string teste 
my %ngram_teste = compute_ngram($phrase_test, $n,$length, $p, $s, $d);

print "\n\nConfig: taille-".$limit." p-".$p." s-".$s." d-".$d." Ngrams - $n \nResultat methode Probabilité\n";         

my %ranks = identify_with_distance(\%ngram_teste, 'output/'.$n.'_output_'.$limit.'_'.$p.$s.$d);

# afficher les 3 première langues resultat en ordre croissante
my $counter = 1;			
foreach my $item (sort { $ranks{$a} <=> $ranks{$b} } keys %ranks) {
	if ($counter < 4){
	  print "\tPosition $counter - langue - $item - score: $ranks{$item} \n";	
	}
	$counter++;			    
}
