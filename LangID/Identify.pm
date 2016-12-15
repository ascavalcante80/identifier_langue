package LangID::Identify;

use utf8;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use Tie::IxHash;
use Unicode::String qw(utf8);
use Unicode::UCD qw(charinfo);
use List::MoreUtils qw(firstidx);
use Storable;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw/ identify_with_distance load_ngrams rank_languages_probabilities load_probabilities build_ranks /;

our $VERSION = 0.1;

=head1 NAME

LangID::Identiy - Train ngram models for language identification

=head1 VERSION

version 0.1

=cut

=item load_ngrams()
charge lit les informations de ngrams dans un dictoire et retourne stocke ces informations tableau de hashes. Ces tableaux sont stockes dans un autre tableau de hashes ngrams.
La code de langue est utilise' pour acceder aux references de ces tableaux.

=cut
# methode pour charger en mémoire les ngrams
sub load_ngrams{
	
	my $dir = shift;
	
	my %ngrams = %{retrieve($dir.'/ngrams_sortie')};
		
	return %ngrams;	
}

# methode qui calcule ngram
sub rank_languages_probabilities{
	
	my $ngrams_text_entree = shift;
	my %ngrams_text_entree = %{$ngrams_text_entree};
		
	my $dir = shift;
	my $n = shift;
	my %ngrams_probs = load_probabilities($dir, $n);
		
	my %results;
	
	# lire ngrams du corpus
	for my $item (keys %ngrams_probs){
	
	
		# ----------------------- ATTENTION - DESACTIVER PENDANT LES TESTES!!!!!!!!!!!!!!!!!!!!!!	
#		my @lang_list = LangID::Train::select_languages_char_info(\%ngrams_text_entree);
  	
	  	# verifier la distance seulement pour les langues presentes dans la liste
	#  	if(!grep (/^$item$/, @lang_list)){
  	#		next;
	  	#}
				
				
				
		# construire dict temporaire avec ngrams d`une langue
		my %temp_model = %{$ngrams_probs{$item}};
		delete $ngrams_probs{$item};		
		my $total = 0.0;
				
		# compare ngrams du modele avec les ngrams du texte d`entree
		for my $item2 (keys %ngrams_text_entree){
			
			if (exists $temp_model{$item2}){				
				$total = $total + sprintf '%.20f',$temp_model{$item2};
			}			
		}
		
		%temp_model= ();
		$results{$item} = $total;		
	}
	return %results;
}

sub load_probabilities{
	
	my $dir = shift;
		
	my %ngrams = %{retrieve("$dir/ngrams_proba")};
		
	return %ngrams;		
}

sub compute_distance{
	
	my $test_ngrams = shift;
	my $lang_ngrams_temp = shift;
	my $max = shift;
	
	delete $lang_ngrams_temp ->{'entete'};
	
	my %lang_ngrams = %{$lang_ngrams_temp};
	$lang_ngrams_temp = undef;
	
	my $distance = 0;
	
	# convertir le tableau de hash en arrays	
	my @rank_test_ngrams = sort {$test_ngrams->{$b} <=> $test_ngrams->{$a}} keys %{ $test_ngrams };	
	
	$test_ngrams = undef;

	my @rank_lang_ngrams = sort {$lang_ngrams{$b} <=> $lang_ngrams{$a}} keys %lang_ngrams;
	
  	# parcourir la liste et comparer les indices des ngrams d'entree dans la liste
	for(my $i = 0; $i < @rank_test_ngrams; $i++){
		
		my $ngram = $rank_test_ngrams[$i];
		if(exists $lang_ngrams{$ngram}){
			$distance += abs($i - firstidx {$_ eq $ngram} @rank_lang_ngrams);
	    }
	    else{
			$distance += $max;
		}
	}
	return $distance;	
}

sub identify_with_distance{
  
  my $ngrams_test = shift;
  
  my %ngrams_test = %{$ngrams_test};
  $ngrams_test = undef;
  
  my $train_dir = shift;

#  croak("Error : invalid doc file : $test_file") unless -f $test_file;
#  croak("Error : invalid ngram models dir : $train_dir") unless -d $train_dir;

  my %lang_ngrams = load_ngrams($train_dir);
  
  #eliminer ligne d`entete
  delete $lang_ngrams{'entete'};
  
  # obtenir valeur de penalite pour les ngrams non trouves - 
  #il doit etre la distance la plus eleve parmi tous les jeux de ngrams
  
  my $penalite_max = 0;
  
  # obtenir valeur de penalite
  foreach my $item (keys %lang_ngrams){
  	
  		my $temp = scalar(keys %{ $lang_ngrams{$item} });
  		
  		if($temp > $penalite_max){
  			
  			$penalite_max = $temp;
  		}
    }
      
  my %lang_distance;
  
  foreach my $lang (keys %lang_ngrams){
  	
# TODO  - DESACTIVER PENDANT LES TESTES!!!!
#  	my @lang_list = LangID::Train::select_languages_char_info(\%ngrams_test);
  	
  	# verifier la distance seulement pour les langues presentes dans la liste
#  	if(!grep (/^$lang$/, @lang_list)){
 # 		next;
  #	}

    $lang_distance{$lang} = compute_distance(\%ngrams_test, $lang_ngrams{$lang}, $penalite_max);
    # suprimer ngrams afin de liberer space en memoire
    delete $lang_ngrams{$lang};
  	
  }
  
  #TODO : my %result = 5 premières distances
  return %lang_distance;
}
