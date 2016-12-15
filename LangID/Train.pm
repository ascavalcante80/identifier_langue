package LangID::Train;

use utf8;
use strict;
use warnings;
use Data::Dumper;
use List::Util qw( min max sum);
use Carp;
use Unicode::String qw(utf8);
use Unicode::UCD qw(charinfo);
use Storable;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw/ browse_files select_languages_char_info save_probabilities create_stats build_char_info build_probabilities browse_train compute_ngram get_ngram_model get_train_corpus output_ngram create_evaluation_corpus /;



our $VERSION = 0.1;

=head1 NAME

LangID::Train - Train ngram models for language identification

=head1 VERSION

version 0.1

=cut

my $verbose = 1;


=item compute_ngram()
=encoding utf8

calcule les modèles ngram pour des fichiers des textes presents dans un dossier passé comme argument.
La fonction reçoit comme argument le chemin du dossier contenant les fichiers de texte, le taille du ngram, les options pour prendre en compte ou pas les ponctuations, les spaces et les chiffres.
Comme résultat, la fonction un tableau de hashes listes de ngrams et leurs respectives fréquences.
La fonction returne comme résultat un tableau de hashes listes de ngrams et fréquences.

=cut
sub compute_ngram {
	
  	# lire arguments
  	my ($ref_lang_dir, $n, $length, $punct, $space, $digit) = @_;
	    
	#créer tableau qui va stocker les ngrams
	my %lang_ngram;
	
	# verifier si la variable ref_lang_dir stoque un tableau de hash
	if(ref($ref_lang_dir) eq "HASH"){
	
		# lire les chemins de dossier
		foreach my $lang (keys %{ $ref_lang_dir }){
		  	
		  	# obtenir corpus normalisé, selon les options passées comme argument
		    my $corpus = get_train_corpus($ref_lang_dir->{$lang}, $length, $punct, $space, $digit);
		    
		    #obtenir les ngrams de langue
		    my %model = get_ngram_model($corpus, $n);
		    
		    #stocker valeurs de ngrams comme références et utiliser le code de langue comme clé
		    $lang_ngram{$lang} = \%model;
		}	
		return %lang_ngram;
		
	# verifier si la variable ref_lang_dir est un scalar	
	} else {
		  	
	  	# obtenir corpus normalisé, selon les options passées comme argument
	    my $corpus = get_train_corpus($ref_lang_dir, $length, $punct, $space, $digit);
	    
	    #obtenir les ngrams de langue
	    my %model = get_ngram_model($corpus, $n);
	    
	    #return les ngrams dans un tableau de hash
	    return %model;
	}    
}

## Découpe les données en ngram et compte les occurrences des ngram
## params : $data (les données), $n (taille du ngram)
## sortir : tableh ("ngram" => occ)
=item get_ngram_model()
=encoding utf8

calcule les modèles ngram pour d'une string passée comme argument. La fonction retourne un tableau de hashes contenant les ngrams et leurs respectives fréquences.


=cut
sub get_ngram_model{
	
	my ($corpus, $n) = @_;
	
	if (-e $corpus) {
		
		my $file = $corpus;
		
		open(FILE, "<:encoding(UTF-8)", "$file") || croak $!;
	    
	    # lire les lignes du fichier
	    while(<FILE>, my $tmp){
	    	
	    	$corpus = $corpus.$tmp;
	    }
		
	}
	 
	# ------------------ tableaux de ngrams -----------------------------#
	  
	#créer le tableau qui va stocker les ngrams et leur fréquences
	my %model;
	
	# stockers les caracteres du corpus en grapheme dans la liste @tmp
	my @tmp = $corpus =~ /(\X)/g;
	  
	# 
	for my $i (0 .. scalar(@tmp) - $n) {
		my $ngram = join('',@tmp[$i..$i+$n-1]);
	    
	    # stocker ngrams et incrementer compteur (autovivifiction pour les ngrams pas encore vus)
	    $model{$ngram}++;
	}
		
	# retourner le tableau contenant les ngrams et leur fréquences
	return %model;
}

## Lit les fichiers d'un répertoire et renvoie le contenu en retour selon les options, limite à n caractères
## params : $dir (le répertoire), $length (taille en car.), $punct (garder ou non les poncutations), $space (garder ou non les espaces), $digit (garder ou non les chiffres)
## sortie : $corpus_train (scalaire)
=item get_train_corpus()
=encoding utf8

lit les fichier présents dans un dossier et les normalise selon les options passées comme arugment.
L'utilisateur peut choisir passer les optioins pour déterminer la taille, la lecture ou non des: ponctuations, des spaces et des chiffres.
La fonction retourne une string normalisée.

=cut
sub get_train_corpus{
  my ($dir, $length, $punct, $space, $digit)  = @_;

  my $train_data;
  my $i = 0;
   
  # verifier si le chemin donné n`est pas un dossier
  if(! -d $dir && !-f $dir){
  	    
    # variable dir n`est pas un dossier, on la traite en tant que string
    
  	# stockers les caracteres du corpus en grapheme dans la liste @tmp
  	my @chars = $dir =~ /(\X)/g;
    
    foreach my $tmp (@chars){
      
      	# passer un autre caracter si le carater est retour à la ligne
      	next if($tmp =~ /\n|\r/);
      
      	# si le caractere est un space et et si l'option $punct est fausse, avec ! elle devient vraie et on passe au caractere suivant
      	next if($tmp =~ /\p{Gc:P}/ && ! $punct);
      
      	# si le caractere est un space et l'option $space est fausse, avec ! elle devient vraie et on passe au caractere suivant
      	next if($tmp =~ /\p{Gc:Z}/ && ! $space);
      
      	# si le caractere est une chiffre et l'option $digit est fausse, avec ! elle devient vraie et on passe au caractere suivant
      	next if($tmp =~ /\p{Digit}/ && ! $digit);
      
      	# incrementer compteur de caractere
      	$i++;
      
      	# concatener la string $train_data
      	$train_data .= $tmp;
      }
      # si le compteur a atteint la valeur limite definie par taille, on retourne le $train_data
   	  return $train_data;
   	
  } else {
  
	  my @tab;
	  
	  # ouvir le dossier
	  if(-d $dir){
	  	opendir(DIR, $dir) || croak $!;
	  
	  	# lire les elements du dossier et stocke les adresses de fichier das le tableau @tab
	  	@tab = grep {!(/^\./) && -f "$dir/$_"} readdir(DIR);
	  }
	  
	 if(-f $dir){
	    
	    my @temp_dir = split('/', $dir);
	    	    	    
	  	push(@tab, pop @temp_dir);
	  	
	  	$dir = join("/", @temp_dir);
	  	
	  }
	   
  
  # lire les fichiers presents de @tab
  foreach my $file (@tab){
  	
  	# ouvrir fichier
    open(FILE, "<:encoding(UTF-8)", "$dir/$file") || croak $!;
    
    # lire les lignes du fichier
    while(read(FILE, my $tmp, 1)){
      
      # passer un autre caracter si le carater est retour à la ligne
      next if($tmp =~ /\n|\r/);
      
      # si le caractere est un space et et si l'option $punct est fausse, avec ! elle devient vraie et on passe au caractere suivant
      next if($tmp =~ /\p{Gc:P}/ && ! $punct);
      
      # si le caractere est un space et l'option $space est fausse, avec ! elle devient vraie et on passe au caractere suivant
      next if($tmp =~ /\p{Gc:Z}/ && ! $space);
      
      # si le caractere est une chiffre et l'option $digit est fausse, avec ! elle devient vraie et on passe au caractere suivant
      next if($tmp =~ /\p{Digit}/ && ! $digit);
      
      # incrementer compteur de caractere
      $i++;
      
      # concatener la string $train_data
      $train_data .= $tmp;
      
      # si le compteur a atteint la valeur limite definie par taille, on retourne le $train_data
      return $train_data if($i == $length);
    }
    # fermer fichier
    close FILE;
  }
  # fermer dossier
  close(DIR);
  
  carp("$dir length is lower than $length ") if($i < $length);
  return $train_data;
  }
}


## Parcours le dossier corpus d'entraînement
## param : $dir (directory)
## sortie : tableh ("lang" => "dir_path")
=item browse_train()
=encoding utf8

parcours le dossier d'entraînement et construit le chemin relatif pour les dossier contenant les corpus de langue à partir du dossier passé comm argument.
La fonction retourne un tableau de hashes contenant le code la langue comme clé.

=cut
sub browse_train {
  my $dir = shift;
  my %lang_dir;

  opendir(DIR, $dir) || croak $!;
  my @tab = grep {!(/^\./) && -d "$dir/$_"} readdir(DIR);
  foreach my $lang (@tab){
    	 $lang_dir{$lang} = "$dir/$lang";
  }
  close(DIR);
  
  return %lang_dir;
}



sub browse_files {
  my $dir = shift;
  my %lang_dir;

  opendir(DIR, $dir) || croak $!;
  my @tab = grep {!(/^\./) && -f "$dir/$_"} readdir(DIR);
 
  close(DIR);
  
  return @tab;
}




# la fonction output_ngram recoit comme argument:
# - un tableau des hashes %lang_grams, qui contient les qtd de n_grams pour chaque langue traitee
# - la taille de ngram choisie $n
# - la taille du corpus utilise $length
# - la valeur qui indique si les punctuations ont ete prises en compte $punct
# - la valeur qui indique si les chifres ont ete prises en compte $punct
# SORTIE - la fonction ecrit pour chaque langue traitee un fichier qui contient les infos de ngram + un ligne d`en-tete qui contient les options utilisees. 
=item output_ngram()
=encoding utf8

écrit le valeur de ngrams et leurs fréquences dans un fichier texte, CODE_LANGUE_grams.txt. 
Le fichier contient les un en-tête pour indique les options utilisées.

=cut
sub output_ngram{
	
  my $lang_grams = shift;
  my $output_dir = shift;
  my $n = shift;
  my $length = shift;
  my $punct = shift;
  my $space = shift;
  my $digit = shift;
  	
  	 	
  	# créer le dossiers pour les langues sous le dossier train
    unless(-e "output" or mkdir "output") {
     		die "Unable to create output\n";
    }
  	
  	 	
  	# créer le dossiers pour les langues sous le dossier train
    unless(-e "output/$output_dir" or mkdir "output/$output_dir") {
     		die "Unable to create output/$output_dir\n";
    }
    
    #--------------------- enregistrer tableau en bytes ------------------------------#
    
    my %lang_grams = %{$lang_grams};
    $lang_grams = undef;
    
    $lang_grams{'entete'} = "<n>".$n."</n><length>".$length."</length><puntc>".$punct."</punct><space>".$space."</space><digit>".$digit."</digit></meta>";
    
    print "saving ngrams hash tables...\n";
    
    # enregistrer le tableau de hashes
    store \%lang_grams, "output/$output_dir/ngrams_sortie"; 
    	
}

=item create_evaluation_corpus()
=encoding utf8

cree un corpus de evalution avec les fichiers du training corpus. 
La fonction reçoit comme argument le nom du dossier ou se trouvent les fichiers d`entrainement et la taille désirée du corpus d'évalution en termes de pourcentage (valeur de 1 a 99).
Si l`argument de taille de fichier n`est pas passé, la fonction utilise la taille defaut de 20%.
Comme résultat, la fonction créer deux dossier: train_corpus et eval_corpus

=cut
sub create_evaluation_corpus{
	my($dir, $taille) = @_;
	
	if ($taille == undef || $taille > 99 || $taille < 1){
		print 'La valeur de taille du corpus dévaluation incorrecte. Utilizez un valuer entre 1 et 99\n';
	} 
	
	##################### première partie lecture des fichiers #############################
	
	my $corpus;  	
  	
  	my %dir_lang = browse_train($dir);  	
  	
  	# créer le dossiers pour les langues sous le dossier train
    unless(-e "train" or mkdir "train/") {
     		die "Unable to create train\n";
    }    		
    
    # créer le dossiers pour les langues sous le dossier eval
    unless(-e "eval" or mkdir "eval/") {
     		die "Unable to create eval\n";
    }    		    
      	
  	foreach my $lang (keys %dir_lang){
	  
	  	# verifier si le chemin donné est un dossier
	  	unless( -d $dir_lang{$lang} ){
	  	
	  		# si le chemin n'est pas un dossier, afficher message et finir l'execution
	    	carp "$dir is not a directory";
	    	return();
	  	}
	  
	 	# ouvir le dossier
	  	opendir(DIR, $dir_lang{$lang}) || croak $!;
	  
	  	# lire les elements du dossier et stocke les adresses de fichier das le tableau @tab
	 	 my @tab = grep {!(/^\./) && -f "$dir_lang{$lang}/$_"} readdir(DIR);
	 	 
	 	# poucentage du training corpus
	 	my $pourcentage_train = (100 - $taille)/100; 	 
	 	 
	  	# lire les fichiers presents de @tab
	  	foreach my $file (@tab){
	  	
	  		# ouvrir fichier
	    	open(FILE, "<:encoding(UTF-8)", $dir_lang{$lang}."/".$file) || croak $!;	    	    	    	
	    	
	    	# obtenir taille du fichier
	    	my $taille_corpus = 0;    	
	    	while(read(FILE, my $tmp, 1)){
	    		
	    		$taille_corpus++;    		
	    	}    	
	    	close FILE;
	    	
	    	# obtenir la taille limite 
	    	my $taille_limite = $taille_corpus * $pourcentage_train;
	    	
	    	# créer le dossiers pour les langues sous le dossier train
    		unless(-e "train/".$lang."/" or mkdir "train/".$lang."/") {
        		die "Unable to create train/$lang/\n";
    		}    		
    		
    		# créer le dossiers pour les langues sous le dossier eval
    		unless(-e "eval/".$lang."/" or mkdir "eval/".$lang."/") {
        		die "Unable to create train/$lang/\n";
    		}
	    		    	
	    	# creer fichier pour ecrire training_corpus
	    	open(TRAINCORPUS, ">>:encoding(UTF-8)", "train/".$lang."/".$file) || croak $!;
	    	
	    	# creer fichier pour ecrire evaluation_corpus 
	    	open(EVALCORPUS, ">>:encoding(UTF-8)", "eval/".$lang."/".$file) || croak $!;
	    		    	
	  		# ouvrir fichier
	    	open(FILE, "<:encoding(UTF-8)", $dir_lang{$lang}."/".$file) || croak $!;	    	  
	    	
	    	#afficher message    	
	    	print "Treating file $dir_lang{$lang}/$file \n";  
	    	my $i = 0;
	    	# lire les lignes du fichier
	    	while(read(FILE, my $tmp, 1)){
	      
	      		# incrementer compteur de caractere
	      		$i++;
	      	      
	      		# si le compteur a atteint la valeur limite definie par taille, on retourne le $train_data
	      		if($i <= $taille_limite){
	      			print TRAINCORPUS $tmp;      			
	      		} else {
	      			print EVALCORPUS $tmp;
	      		}
	      		
		    }
	    	# fermer fichier
	    	close FILE;
	    	close TRAINCORPUS;
	    	close EVALCORPUS;    	
  	}
  	# fermer dossier
  	close(DIR);
  	}
  	
}

sub create_stats{
	
	my $dir = shift;
		
	##################### première partie lecture des fichiers #############################
	
	my $corpus;  	
  	
  	my %dir_lang = browse_train($dir);  	
  	
  	my %total_stats;
  	
  	# créer le dossiers pour les langues sous le dossier eval
    unless(-e "stats" or mkdir "stats") {
     		die "Unable to create the folder stats\n";
    }   
  	
  	  	      	
  	# creer fichier pour ecrire evaluation_corpus 
	open(STATS, ">>:encoding(UTF-8)", "stats/stats_$dir.txt") || croak $!;  	      	
  	  	      	
  	foreach my $lang (keys %dir_lang){
	  
	  	# verifier si le chemin donné est un dossier
	  	unless( -d $dir_lang{$lang} ){
	  	
	  		# si le chemin n'est pas un dossier, afficher message et finir l'execution
	    	carp "$dir is not a directory";
	    	return();
	  	}
	  
	 	# ouvir le dossier
	  	opendir(DIR, $dir_lang{$lang}) || croak $!;
	  
	  	# lire les elements du dossier et stocke les adresses de fichier das le tableau @tab
	 	 my @tab = grep {!(/^\./) && -f "$dir_lang{$lang}/$_"} readdir(DIR);
	 	
	 	my $compte_fichier = 0;
	 	 	 
	  	# lire les fichiers presents de @tab
	  	foreach my $file (@tab){
	    		    	
	  		# ouvrir fichier
	    	open(FILE, "<:encoding(UTF-8)", $dir_lang{$lang}."/".$file) || croak $!;	    	  
	    	
	    	#afficher message    	
	    	print "Treating file $dir_lang{$lang}/$file \n";
	    	  
	    	my $i = 0;
	    	# lire les lignes du fichier
	    	while(read(FILE, my $tmp, 1)){
	      
	      		# incrementer compteur de caractere
	      		$i++;
	      	    	      		
		    }
		    $compte_fichier++;
		  	print "langue $lang - fichier $compte_fichier total: $i\n";
		  	
		  	$total_stats{$lang} += $i;
		    		    
	    	# fermer fichier
	    	close FILE;
  	}

  	close(DIR);
  	}
	
	
	foreach my $lang (keys %total_stats){
	
		print STATS $lang.",".$total_stats{$lang}."\n";
	
	}
	
  	close STATS;
  	# fermer dossier
	
	return %total_stats;
	
}

sub build_probabilities{
	
	my $ngramsTemp = shift;
	
	my $dir = shift;
	
	my %ngrams = %{$ngramsTemp};
			
	my (%ngramsProb);
	
	print "Building probabilites \n";
	
    # créer le dossiers pour les langues sous le dossier eval
    unless(-e "output_prob" or mkdir "output_prob") {
     		die "Unable to create output_prob\n";
    }   
		
		
    # créer le dossiers pour les langues sous le dossier eval
    unless(-e "output_prob/$dir/" or mkdir "output_prob/$dir/") {
     		die "Unable to create output_prob/$dir/\n";
    }    		
    
    print "saving probabilities hash tables...\n";
    
    # lire les tableaux de hashes par langue - chaque $item est un code de langue
	foreach my $item (keys %ngrams){					
	  	
	  	my  %newModel;
	  	
	  	print "treating langue $item...\n";
	  	
		# get the hightest ngrams count in the %model	
		my %model = %{$ngrams{$item}};
		
		# effacer la ligne d`entete du tableau de hash
		delete $model{'entete'};
						
		my @values = values %model;
		
		# calculer le nb total de ngrams 
		my $max = sum(@values);		
		
		# calculer la probabilite pour chaque ngram
		foreach my $ngram (keys %model){
						
			my $count = $model{$ngram};
			my $probability = ($count/$max);
			
			$newModel{$ngram}= $probability;			
		}
						
		$ngramsProb{$item} = \%newModel;
		
	}
	
	return %ngramsProb;
			
}

sub save_probabilities{
	
	my $ngramsProb = shift;
	
	my $dir = shift;	
		
	print "Saving probabilities \n";
	
    # créer le dossiers pour les langues sous le dossier eval
    unless(-e $dir or mkdir $dir) {
     		die "Unable to create $dir\n";
    }   
	
	# enregistrer le tableaux de hash 
	store $ngramsProb, "output_prob/$dir/ngrams_proba";
	
}

sub select_languages_char_info{
	
	my $ngrams_temp = shift;
	my @code_list_entree;
	my $code;
		
	#----------------- obtenir informations de block de langues de la string d`entree -------------#
		
	my %ngrams = %{$ngrams_temp};
		
	foreach my $char (keys %ngrams){
		
		# passer les caracteres de retour a ligne, space, digit et ponctuation	
	    next if($char =~ /\n|\r/);
	    next if($char =~ /\p{Gc:P}/);
	    next if($char =~ /\p{Gc:Z}/);
	    next if($char =~ /\p{Digit}/);
				
		my $properties_temp = charinfo(sprintf("%#X",  ord($char)));
		my %properties = %{$properties_temp};
		
		if(defined $properties{'code'}){
			$code = $properties{'code'};
				
			if(!grep (/^$code$/, @code_list_entree)){
				push(@code_list_entree, $code);			
			}		
		}
	}
	
	#--------------	recuper infos de characteres du corpus --------#
	# recuerer les infos de ngrams		
	my %charinfo = %{retrieve("charinfo/charinfo")};
	
	# array pour stocker les liste de langue qui contiennent les caracteres de la string
	my @lang_list;
	
	foreach my $lang (keys %charinfo){
		
		my @code_list = sort @{$charinfo{$lang}};
		
		foreach my $code (@code_list_entree){
			
			#si le block teste' est dans la list, on rajoute la langue
			if(grep (/^$code$/, @code_list)){
				push(@lang_list, $lang);
				last;			
			}				
		}	
	}
	
	# si la @lang_list est vide, retourner la liste complete avec toutes les langues
	if(0 < scalar @lang_list){
		return @lang_list;	
	} else {		
		return @{keys %charinfo};		
	}	
}

sub build_char_info{
		
	my $dir = shift;
	
	# recuerer les infos de ngrams		
	my %ngrams = %{retrieve("$dir/ngrams_sortie")};
	
	my %charInfo;
	
	# suprimer information d`entete
	delete $ngrams{'entete'};
					  	  	  	  	      	
  	foreach my $lang (keys %ngrams){
	  
	 	# list pour stocker les infos de block de caracteres
    	my ($code, @code_list);
    	    		 
	  	# lire les fichiers presents de @tab
	  	foreach my $char (keys %{$ngrams{$lang}}){	  		
	  		
	  		# passer les caracteres de retour a ligne, space, digit et ponctuation	
		    next if($char =~ /\n|\r/);
		    next if($char =~ /\p{Gc:P}/);
		    next if($char =~ /\p{Gc:Z}/);
		    next if($char =~ /\p{Digit}/);
	  		  	  		
  			my $properties_temp = charinfo(sprintf("%#X",  ord($char)));
		
			if (!defined $properties_temp){
				print "Sans propriétés de caractères.\n";
				$code = "Bloque sans propriete";
			} else{
				my %properties = %{$properties_temp};
				$code = $properties{'code'};
					
			}
						
			if(!grep (/^$code$/, @code_list)){
				print $code."\n";
				push(@code_list, $code);			
			}  				   		    	
 		}
  		 
  		$charInfo{$lang} = \@code_list;
  	}	
  	
  	# créer le dossiers pour les langues sous le dossier eval
    unless(-e "charinfo" or mkdir "charinfo") {
     		die "Unable to create charinfo\n";
    }   
			
	# enregistrer le tableaux de hash 
	store \%charInfo, "charinfo/charinfo";	
}
