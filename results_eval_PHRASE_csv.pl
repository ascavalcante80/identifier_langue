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

# -------------------------------- à analyser phrases --------------------------------------------------------------#
my $counter = 0;

my @langues = ('AF', 'AR', 'BG', 'BN', 'BS', 'CR', 'CS', 'DA', 'DE', 'EL', 'EN', 'ES','FA', 'FI', 'FR', 'GU', 'HE', 'HI', 'HU','ID', 'IS', 'IT', 'JP', 'KN', 'KO', 'LA', 'ML', 'NL', 'NO', 'PL', 'PT', 'RO', 'RU', 'SQ', 'SR', 'SV', 'TA', 'TE', 'TH', 'TR', 'UK', 'UR', 'VI');

my @phrases = ("En Josef het gesterwe, honderd en tien jaar oud. En hulle het hom gebalsem, en hy is in ‘n kis gesit in Egipte.",
"ثُمَّ مَاتَ يُوسُفُ وَهُوَ ابْنُ مِئَةٍ وَعَشَرِ سِنِينَ فَحَنَّطُوهُ وَوُضِعَ فِي تَابُوتٍ فِي مِصْرَ.",
"И тъй, Иосиф умря, на възраст сто и десет години; и балсамираха го и положиха го в ковчег в Египет.",
"য়োষেফ 110 বছর বয়সে মিশরে মারা যান| চিকিত্সকরা তাঁর দেহে ঔষধ দিয়ে মিশরে এক কফিনের মধ্যে রাখলেন|",
"Čile su mješavina različitih etničkih grupa, dominantno potomaka evropskih doseljenika.",
"Josip umrije kad mu bijaše sto i deset godina; balzamiraše ga i u Egiptu položiše u lijes",
"I umřel Jozef, když byl ve stu a v desíti letech; a pomazán jsa vonnými věcmi, vložen jest do truhly v Egyptě.",
"Josef døde 110 År gammel, og man balsamerede ham og lagde ham i Kiste i Ægypten.",
"Und Joseph starb, als er hundertundzehn Jahre alt war. Und sie salbten ihn und legten ihn in einen Sarg in Ägypten.",
"Και ο Ιωσήφ πέθανε σε ηλικία 110 χρόνων· και τον βαλσάμωσαν· και τέθηκε σε φέρετρο στην Αίγυπτο.",
"And Jesus came and spake unto them, saying, All power is given unto me in heaven and in earth.",
"Y murió José de edad de ciento diez años; y embalsamáronlo, y fué puesto en un ataúd en Egipto.",
"و یوسف‌ مـرد در حینی‌ كه‌ صد و ده‌ ساله‌ بود. و او را حنـوط كرده‌، در زمین‌ مصـر در تابوت‌ گذاشتند.",
"Ja Joosef kuoli sadan kymmenen vuoden vanhana. Ja hänet balsamoitiin ja pantiin arkkuun Egyptissä.",
"Joseph mourut, âgé de cent dix ans. On l'embauma, et on le mit dans un cercueil en Égypte.",
"આમ યૂસફ 110 વર્ષનો થઈને મૃત્યુ પામ્યો, અને તેના દેહને મિસરમાં સુગંધી દ્રવ્યો ભરીને એક શબ પેટીમાં મૂકવામાં આવ્યો.",
"וימת יוסף בן מאה ועשר שנים ויחנטו אתו ויישם בארון במצרים׃",
"निदान यूसुफ एक सौ दस वर्ष का हो कर मर गया: और उसकी लोथ में सुगन्धद्रव्य भरे गए, और वह लोथ मिस्र में एक सन्दूक में रखी गई॥",
"És meghala József száz tíz esztendõs korában, és bebalzsamozák, és koporsóba tevék Égyiptomban.",
"Kemudian matilah Yusuf, berumur seratus sepuluh tahun. Mayatnya dirempah-rempahi, dan ditaruh dalam peti mati di Mesir.",
"Og Jósef dó hundrað og tíu ára gamall, og þeir smurðu hann, og hann var kistulagður í Egyptalandi.",
"Poi Giuseppe morì, in età di centodieci anni; e fu imbalsamato, e posto in una bara in Egitto.",
"こうしてヨセフは百十歳で死んだ。彼らはこれに薬を塗り、棺に納めて、エジプトに置いた。",
"ಯೋಸೇಫನು ನೂರ ಹತ್ತು ವರುಷದವನಾಗಿ ಸತ್ತನು. ಅವರು ಅವನಿಗೆ ಸುಗಂಧದ್ರವ್ಯವನ್ನು ಹಾಕಿ ಐಗುಪ್ತದಲ್ಲಿ ಪೆಟ್ಟಿಗೆ ಯೊಳೆಗೆ ಇಟ್ಟರು.",
"요셉이 일백십세에 죽으매 그들이 그의 몸에 향 재료를 넣고 애굽에서 입관하였더라",
"mortuus est expletis centum decem vitae suae annis et conditus aromatibus repositus est in loculo in Aegypto",
"യോസേഫ് നൂറ്റിപ്പത്തു വയസ്സുള്ളവനായി മരിച്ചു. അവർ അവന്നു സുഗന്ധവർഗ്ഗം ഇട്ടു അവനെ മിസ്രയീമിൽ ഒരു ശവപ്പെട്ടിയിൽ വെച്ചു.",
"En Jozef stierf, honderd en tien jaren oud zijnde; en zij balsemden hem, en men leide hem in een kist in Egypte.",
"Og Josef døde, hundre og ti år gammel; og de balsamerte ham og la ham i kiste i Egypten.",
"I umarł Józef, mając sto i dziesięć lat; którego namazawszy wonnemi maściami, włożono do trumny w Egipcie.",
"E morreu José da idade de cento e dez anos; e o embalsamaram e o puseram num caixão no Egito.",
"Iosif a murit, în vîrstă de o sută zece ani. L-au îmbălsămat, şi l-au pus într'un sicriu în Egipt",
"И умер Иосиф ста десяти лет. И набальзамировали его и положили в ковчег в Египте.",
"Pastaj Jozefi vdiq në moshën njëqind e dhjetë vjeç; e balsamosën dhe e futën në një arkivol në Egjipt.",
"Potom umre Josif, a beše mu sto i deset godina; i pomazavši ga mirisima metnuše ga u kovčeg u Misiru.",
"Och Josef dog, när han var ett hundra tio år gammal. Och man balsamerade honom, och han lades i en kista, i Egypten.",
"யோசேப்பு நூற்றுப்பத்து வயதுள்ளவனாய் மரித்தான். அவனுக்குச் சுகந்தவர்க்கமிட்டு, எகிப்து தேசத்தில் அவனை ஒரு பெட்டியிலே வைத்துவைத்தார்கள்.",
" యోసేపు నూటపది సంవత్సరములవాడై మృతి పొందెను. వారు సుగంధ ద్రవ్యములతో అతని శవమును సిద్ధపరచి ఐగుప్తు దేశమందు ఒక పెట్టెలో ఉంచిరి.",
"โยเซฟสิ้นชีพเมื่ออายุได้ร้อยสิบปี เขาก็อาบยารักษาศพไว้แล้วบรรจุไว้ในโลงที่อียิปต์",
"Yusuf yüz on yaşında öldü. Onu mumyalayıp Mısır'da bir tabuta koydular.",
"І впокоївся Йосип у віці ста й десяти літ. І забальзамували його, і він був покладений у труну в Єгипті.",
"اور یُوؔسف نے ایک سو دس برس کا ہو کر وفات پائی اور اُنہوں نے اُسکی لاش میں خُوشبو بھری اور اُسے مصؔر ہی میں تابوت میں رکھاّ۔",
"Khi trối mấy lời nầy cho các con mình xong, thì Gia-cốp để chơn vào giường lại, rồi tắt hơi, được về cùng tổ tông mình.");


#------------------------------------- VARIER OPTIONS ------------------------------------------------#

my @limits = (50000, 500000, 1100000);
my @ns = (1,3,5);

my @space = (0,1);
my @digits = (0);
my @punt = (0,1);


my $length = "total";
# ----------------------------------- creer fichier csv de sortie ----------------------------------------#
open(CSVDIST, ">:encoding(UTF-8)", "stats/results_phrases_DIST.csv") || croak $!;
open(CSVPROBA, ">:encoding(UTF-8)", "stats/results_phrases_PROBA.csv") || croak $!;


foreach my $frase_test (@phrases){
	
	print CSVDIST "\n".$langues[$counter].',';
  print CSVPROBA "\n".$langues[$counter].',';
	print "Treating langue ".$langues[$counter]."\n";
	
	# faire varier le nombre de ngrams et la taille du corpus
	foreach my $n (@ns){
		
		foreach my $limit (@limits){
			
			foreach my $p (@punt){
			
				foreach my $d (@digits){
				
					foreach my $s (@space){
				
						# char trigrams
						my %ngramProb = load_probabilities('output_prob/'.$n.'_probabilities_'.$limit.'_'.$p.$s.$d, $n);
						
						print 'output_prob/'.$n.'_probabilities_'.$limit.'_'.$p.$s.$d."\n";
						
						## creer les ngrams de la string teste 
						my %ngram_teste = compute_ngram($frase_test, $n,$length, $p, $s, $d);
						
						# tableau de hash avec la somme te probababilites de tout les ngrams de la string teste
            my %ranks = rank_languages_probabilities(\%ngram_teste, 'output_prob/'.$n.'_probabilities_'.$limit.'_'.$p.$s.$d, $n);
          
						# afficher les 3 première langues resultat en ordre croissante
						my $counter = 0;			
						foreach my $item (reverse sort { $ranks{$a} <=> $ranks{$b} } keys %ranks) {
							if ($counter < 3){
								print CSVPROBA (sprintf "%.20f",$ranks{$item}).','.$item.',';	
							}
							$counter++;			    
						}

				
						%ranks = identify_with_distance(\%ngram_teste, 'output/'.$n.'_output_'.$limit.'_'.$p.$s.$d);
				
						# afficher les 3 première langues resultat en ordre croissante
						$counter = 0;			
						foreach my $item (sort { $ranks{$a} <=> $ranks{$b} } keys %ranks) {
							if ($counter < 3){
								print CSVDIST $ranks{$item}.','.$item.',';	
							}
							$counter++;			    
						}
					}				
				}
			}
		}
	}
	$counter++;	
}
close(CSVDIST);
close(CSVPROBA);
