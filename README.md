# Basic Sample Hardhat Project

Prilikom deployovanja smart contracta potrebno je navesti timestamp, odnosno koliko ce depositovan ETH biti zakljucan.

Ukoliko korisnik deposituje svoj ETH i zeli da ga povuce nazad pre isteka vremena nije mu omoguceno povlacenje svog ETH-a.
Kolicinu ETH-a koju moze povuce pre isteka vremena racuna se po sledecog formuli:

    depositovan_ETH/2 + ( depositovan_ETH/2 * protekloVreme / timestamp )

Na ovaj nacin se obezbedjuje da ukoliko korisnik zeli da povuce svoj ETH odmah nakon depositovanja protekloVreme ce biti nula i dostupnaKolicina ce biti 50% ukupno depositovane. Ukoliko korisnik zeli da povuce ETH tacno u trenutku isteka vremena protekloVreme ce biti jednako timestamp-u pa ce njihov kolicnik biti 1, sto znaci da ce korisniku biti dostupan sav ETH za povlacenje.

    *Ovaj drugi slucaj ce biti obradjen posebnom if granom ali ovde sluzi samo za dokaz formule

Ukoliko korisnik povuce ETH pre isteka vremena on dobija nazad kolicinu koja se racuna po goreprikazanoj formuli a ostatak se raspodeljuje ostalim korisnicima. Svaki korisnik dobija ETH proporcionalno kolicini koju je on depositovao. Primer:

    Korisnik_1 - Depositovao 1 ETH
    Korisnik_2 - Depositovao 1 ETH
    Korisnik_3 - Depositovao 3 ETH
    Korisnik_4 - Depositovao 6 ETH

Ukoliko cetvrti korisnik zeli da povuce ETH pre isteka vremena, kolicina koju on gubi se deli izmedju korisnika 1,2 i 3.
Korisnik_1 ce dobiti 20% (1/(1+1+3)), Korisnik_2 ce takodje dobiti 20% dok ce Korisnik_3 dobiti 60%.

Ukoliko se u sistemu nalazi samo jedan korisnik i on zeli da povuce svoj ETH pre isteka vremena, ostatak njegovo ETH-a se nema kome raspodeliti tako da 
ostaje na contractu i racuna se kao zarada firme. To se postize time sto se racuna koliko je ETH-a podeljeno ostalim korisnicima. Smart contract pamti koliko je trenutno ETH-a depositovano od strane korisnika unutar promenljive totalBalance. Zarada odnosno pasivni prihod se smesta na contractu. Tako da kada firma zeli da pokupi svoju zaradu, ta zarada se racuna po formuli:

    trenutna_kolicina_na_contractu - depositovana_kolicina
Odnsno:
    trenutna_kolicina_na_contractu - totalBalance

Kada korisnik povuce svoj ETH totalBalance se smanjuje po formuli:

    totalBalance = totalBalance - ( kolicina_depositovana_od_korisnika - kolicina_raspodeljena_ostalima )

Ukoliko korisnik povuce ETH nakon isteka vremena kolicina_raspodeljena_ostalima ce biti 0. To znaci da ce totalBalance biti smanjem za celu kolicinu.
Ukoliko korisnik povuce ETH pre isteka vremena totalBalance ce se smanjiti samo za onoliko koliko je korisniku dozvoljeno da povuce.
Ukoliko korisnik povuce ETH pre isteka vremena trenutno ne postoji ni jedan drugi korisnik u sistemu kolicina_raspodeljena_ostalima ce biti 0. To znaci da ce se totalBalance smanjiti za celu kolicinu a korisniku biti poslat nazad samo deo. To znaci da ostatak ostaje na smart contract i firma to gleda kao svoju zaradu.

Unutar smart contracta nije koriscen WETHGateway vec je rucno odradjeno ono sto WETHGateway u stvari i radi.

Smart contract ima ILendingPoolAddressesProvider pomocu kojeg se unutar contrctora dobija adresa najnovijeg LendingPool-a.
Kada se dobije adresa pool-a kreira se pool. Pomocu njega se dobija adresa aWETH tokena. Zatim se daje odobrenje LendingPool-u na WETH i aWETH na svu kolicinu. 

Unutar smart contracta nalazi se structure UserInfo koja pamti koliko je ETH-a ukupno depositovano od strane korisnika i kada je poslednji put depositovan ETH. Struktura se sa korisnikom povezuje pomocu mappinga.

Prilikom depositovanja ETH-a gleda se da li je korisnik vec depositovao ETH pre toga. Ukoliko nije on se dodaje kao novi korisnik, vreme poslednjeg deposita se postavlja na trenutno vreme i ukupna depositovana kolicina se postavlja na vrednost upravo depositovanog. Ukoliko je korisnik pre toga depositovao ETH ukupna kolicina se samo povecava a vreme poslednjeg deposita se postavlja na trenutno vreme.
Nakon toga smart contract povlaci WETH u kolicini koju korisnik odredjuje prilikom depositovanja ETH-a. LendingPool prebacuje WETH na market a nazad dobija aWETH i smesta ga na smart contract. Pasivna zarada od depositovanja na market se smesta na adresu smart contraca. totalBalance se povecava za depositovanu kolicinu.

Prilikom povlacenja ETH-a nazad od strane korisnika nakog racunanja kolicine koju korisnik moze dobiti nazad, LendingPool burnuje izracunatu kolicinu aWETH tokena i nazad dobija WETH koji se smesta na smart contract. Onda smart contract vraca nazad WETH i dobija ETH koji salje korisniku. totalBalance se smanjuje kao sto je vec objasnjeno po formuli:
    totalBalance = totalBalance - ( kolicina_depositovana_od_korisnika - kolicina_raspodeljena_ostalima )
Kolicina ETH za korisnika se smanjuje na 0 ali se vreme ne vraca na 0 vec ostaje isto. Ukoliko bi se vratilo na nula prilikom sledeceg depositovanja korisnik bi se gledao kao nov sto nije potrebno. Kako mu je sada kolicina koju je depositovao 0 on nece dobijati nikakav procenat od ostalih korisnika jer ce on imati 0%. 

Zaradu moze da uzme samo firma odnosno vlasnik smart contract-a po istom principu kao sto korisnik dobija nazad svoj ETH




