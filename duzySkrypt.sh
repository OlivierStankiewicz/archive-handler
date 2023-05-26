#!/bin/bash
# Author		: Olivier Stankiewicz ( olivierst03@gmail.com )
# Created On		: 15.05.2023
# Last Modified By	: Olivier Stankiewicz ( olivierst03@gmail.com )
# Last Modified On	: 16.05.2023
# Version		: 1.0
#
# Description		:
# Skrpt umozliwiajac uzytkownikowi pakowanie i rozpakowanie plikow
# Wykozystuje on srodowisko graficzne Zenity
# Dodatkowymi funkcjonalnosciami skryptu sa:
# Podanie sciezki docelowej spakowania lub rozpakowania
# Szyfrowanie i odszyfrowywanie
# Usuniecie plikow zrodlowych, pozoztalych po wykonaniu operacji
# Wyswietlenie informacji o wypakowanych plikach lub stworzonym archiwum
#
# Licensed under GPL (see /usr/share/common/-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

#Funkcja odpowiadajaca za obsluge opcji help
function wyswietl_pomoc {
zenity --info --title="POMOC" --text="Skrypt sluzy do wypakowywania i pakowania plikow
Obslugiwane typy archiwow to .zip, .tar, .tar.gz, .tbzip.2
W kwestii szyfrowania obslugiwane jest tylko gpg

W glownym menu uzytkownik moze wybrac jedna z nastepujacych opcji:
-Rozpakowanie archiwum
-Stworzenie nowego archiwum
-Wyswietlenie pomocy
-Wyswietlenie wersji programu
-Wyjscie z programu ( tak samo dziala cancel )

W przypadku wyboru wypakowywania plikow z archiwum uzytkownik:
-Musi wybrac plik archiwum ktory chce wypakowac
-Musi podac katalog docelowy rozpakowania
-Moze zaznaczyc chec usuniecia archiwum po wypakowaniu z niego plikow
-Moze zaznaczyc chec wyswietlenia informacji o wypakowanych plikach
-Jesli archiwum jest zaszyfrowane moze zostac zapytany o haslo potrzebne do odszyfrowania
Klikniecie cancel podczas wybierania archiwum lub katalogu przerywa funkcje i uzytkownik wraca do glownego menu

W przypadku wyboru tworzenia nowego archiwum uzytkownik:
-Musi wybrac pliki do spakowania
-Musi wybrac katalog w ktorym ma zostac umieszczone stworzone archiwum
-Musi nadac archiwum nazwe ( razem z odpowiednim rozszerzeniem )
-Moze zaznaczyc chec usuniecia plikow po stworzeniu z nich archiwum
-Moze zaznaczyc chec wyswietlenia informacji o utworzonym archiwum
-Moze zaznaczyc chec zaszyfrowania archiwum i podac haslo ktorym ma zostac ono zabezpieczone
Klikniecie cancel podczas wybierania plikow lub katalogu i nazwy przerywa funkcje i uzytkownik wraca do glownego menu" --height 500 --width 800
}

#Funkcja odpowiadajaca za obsluge opcji version
function wyswietl_wersje {
zenity --info --title="WERSJA" --text="Version: 1.0
Author: Olivier Stankiewicz ( olivierst03@gmail.com )
Created on: 15.05.2023
Last Modified By: Olivier Stankiewicz ( olivierst03@gmail.com )
Last Modified On : 23.05.2023"
}

#Funkcja odpowiadajaca za rozpakowywanie archiwow
function rozpakuj_archiwum {

	local NAZWA_ARCHIWUM=$(zenity --file-selection --title="Wybierz archiwum ktore chcesz rozpakowac" --height 500 --width 500)
	#Jesli klikniete cancel, funkcja zostaje przerwana i nastepuje powrot do glownego menu
	if [ -z "$NAZWA_ARCHIWUM" ]; then
		return
	fi

	#Opcja --directory uniemozliwia uzytkownikowi wybranie pliku jako lokalizacji zapisu archiwum
	local FOLDER_DOCELOWY=$(zenity --file-selection --directory --title="Wybierz katalog do ktorego maja zostawc wypakowane pliki z archiwum" --height 500 --width 500);
	if [ -z "$FOLDER_DOCELOWY" ]; then
		return
	fi

	#Jesli wybrane przez uzytkownika archiwum konczy sie rozszerzeniem .gpg to znaczy ze jest zaszyfrowane
	#Nazwa zaszyfrowanego archiwum zostaje w tym wypadku przypisana do zmiennej NAZWA_ZASZYFROWANEGO
	#Archiwum zostaje rozszyfrowane i do zmiennej NAZWA_ARCHIWUM zostaje przypisana nazwa odpowiednia dla stanu po rozszyfrowaniu
	local NAZWA_ZASZYFROWANEGO
	if [[ "$NAZWA_ARCHIWUM" == *.gpg ]]; then
		gpg "$NAZWA_ARCHIWUM"
		NAZWA_ZASZYFROWANEGO="$NAZWA_ARCHIWUM"
		NAZWA_ARCHIWUM="${NAZWA_ARCHIWUM%.gpg}"
	fi

	zenity --question --text="Czy chcesz usunac to archiwum po wypakowaniu z niego plikow?"
	local USUNAC=$?

	zenity --question --text="Czy chcesz wyswietlic informacje o plikach wypakowanych z archiwum?"
	local WYSWIETL_INFO=$?

	#Stworzenie wewnatrz folderu wybranego przez uzytkownika tymczasowego folderu do ktorego zostanie wypakowane archiwum
	local TEMP_DIR=$(mktemp -d "$FOLDER_DOCELOWY/temp_XXXXXX")

	#Rozpakowanie archiwum
	case "$NAZWA_ARCHIWUM" in
		*.zip)
		unzip "$NAZWA_ARCHIWUM" -d "$TEMP_DIR"
		;;
		*.tar)
		tar -xf "$NAZWA_ARCHIWUM" -C "$TEMP_DIR"
		;;
		*.tar.gz)
		tar -xf "$NAZWA_ARCHIWUM" -C "$TEMP_DIR"
		;;
		*.tbzip.2)
		tar -xf "$NAZWA_ARCHIWUM" -C "$TEMP_DIR"
		;;
		*)
                zenity --info --text="Plik nie spelnia wymagan, zobacz obslugiwane typy archiwum w Pomoc"
                return
                ;;
	esac

	#Jesli archiwum bylo zaszyfrowane to usunieta zostaje tymczasowo stworzona odszyfrowana wersja
	if [ ! -z "$NAZWA_ZASZYFROWANEGO" ]; then
		rm "$NAZWA_ARCHIWUM"
	fi

	if [ "$USUNAC" == 0 ]; then
		if [ ! -z "$NAZWA_ZASZYFROWANEGO" ]; then
			rm "$NAZWA_ZASZYFROWANEGO";
		else
			rm "$NAZWA_ARCHIWUM";
		fi
        fi

	#Do wyswietlenia informacji o wypakowanych plikach uzywany jest fakt ze zostaly one wypakowane do stworzonego specjalnie na to folderu
	if [ "$WYSWIETL_INFO" == 0 ]; then
		local output=$(ls -l "$TEMP_DIR")
		zenity --info --text="$output"
	fi

	mv "$TEMP_DIR"/* "$FOLDER_DOCELOWY"
	rm -r "$TEMP_DIR"
}

#Funkcja odpowiadajaca za pakowanie nowych archiwow
function zapakuj_archiwum {
	#Opcja --multiple pozwala na wybor wielu plikow
	local NAZWY_PLIKOW=$(zenity --file-selection --multiple --separator=' ' --title="Wybierz pliki do spakowania" --height  500 --width 500);
	if [ -z "$NAZWY_PLIKOW" ]; then
		return
	fi

	local NOWA_NAZWA=$(zenity --file-selection --save --title="Wybierz gdzie chcesz zapisac archiwum oraz nadaj mu nazwe" --height 500 --width 500);
        if [ -z "$NOWA_NAZWA" ]; then
                return
        fi

	zenity --question --text="Czy chcesz usunac pliki po zapakowaniu ich do archiwum?"
        local USUNAC=$?

	zenity --question --text="Czy chcesz wyswietlic informacje o utworzonym archiwum?"
        local WYSWIETL_INFO=$?

	#Dzieki tej tablicy mozliwe jest umieszczenie wszystkich nazw plikow w cudzyslowie w poleceniu zip, co pozwala na specjalne znaki w nazwach
	#Znakiem niedozwolonym w sciezkach do pliku jest w tym przypadku spacja
	local TABLICA_NAZW_PLIKOW=()
	IFS=' ' read -ra TABLICA_NAZW_PLIKOW <<< "$NAZWY_PLIKOW"

	case "$NOWA_NAZWA" in
		*.zip)
			#Opcja -j pozwala na niedolaczanie do archiwum folderow w ktorych znajduje sie plik docelowy, a tylko samego pliku
			#Jako plik ktory ma znalezc sie w archiwum podana zostaje tablica zawierajaca sciezki do wszystkich plikow
			zip -j "$NOWA_NAZWA" "${TABLICA_NAZW_PLIKOW[@]}"
		;;
		*.tar)
			#--transform 's|.*/||' powoduje zastapienie sciezki do plikow do pierwszego wystapienia / pustym tekstem, co pozostawia tylko sama nazwe pliku
			#Dzieki temu do archiwum dodane sa tylko pliki bez katalogow im nadrzednych
			tar --transform 's|.*/||' -cf "$NOWA_NAZWA" "${TABLICA_NAZW_PLIKOW[@]}"
		;;
		*.tar.gz)
			#Tak samo jak powyzej, dodatkowo opcja -z ktora okresla spozob kompresji na gzip
			tar --transform 's|.*/||' -zcf "$NOWA_NAZWA" "${TABLICA_NAZW_PLIKOW[@]}"
		;;
		*.tbzip.2)
			#Jak wyzej, -j okresla kompresje bzip2
			tar --transform 's|.*/||' -jcf "$NOWA_NAZWA" "${TABLICA_NAZW_PLIKOW[@]}"
		;;
		*)
			zenity --info --text="Podano zly typ archiwum"
			return
		;;
	esac

	zenity --question --text="Czy chcesz zaszyfrowac utworzone archiwum?"
	local CZY_SZYFROWAC=$?

	if [ "$CZY_SZYFROWAC" == 0 ]; then
                gpg -c "$NOWA_NAZWA"
        fi

	if [ "$USUNAC" == 0 ]; then
                rm -r "${TABLICA_NAZW_PLIKOW[@]}"
        fi

	if [ "$WYSWIETL_INFO" == 0 ]; then
                local output=$(ls -l "$NOWA_NAZWA")
                zenity --info --text="$output"
        fi

}

MAIN_MENU=""

while [[ "$MAIN_MENU" != "Wyjscie" ]];
do
	MAIN_MENU=$(zenity --list --title="Wybierz opcje" --text="Program do obslugi archiwow" --column "Opcje" "Rozpakuj archiwum" "Spakuj pliki w archiwum" "Pomoc" "Wersja programu" "Wyjscie" --height 250 --width 350)
	#Klikniecie cancel powoduje pozostawienie zmiennej MAIN_MENU pustej i nastepuje wyjscie z programu
	if [ -z "$MAIN_MENU" ]; then
		exit
	fi

	#Obsluga opcji glownego menu
	case "$MAIN_MENU" in
		"Rozpakuj archiwum")
			rozpakuj_archiwum;;
		"Spakuj pliki w archiwum")
			zapakuj_archiwum;;
		"Pomoc")
			wyswietl_pomoc;;
		"Wersja programu")
			wyswietl_wersje;;
	esac
done
