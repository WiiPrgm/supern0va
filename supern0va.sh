numlist() {
    #This truncates the output to remove the leading 'SES:' from the header titles.
    local hddimage="$1"
    dd if="$hddimage" bs=4096 count=8 status=none | strings -n 6 | sed 's/^SES://' | nl -w1 -s'. '
}


numlistall() {
    #This lists the raw output from the HDD header
    local hddimage="$1"
    dd if="$hddimage" bs=4096 count=8 status=none | strings -n 6 | nl -w1 -s'. '
}

bankextract() {
    local hddimage="$1"
    local banknum="$2"

    #Outputs the name of the bank being extracted to stdout
    dd if="$hddimage" bs=4096 count=8 status=none | strings -n 6 | sed -n "${banknum}p"

    #math to calculate the starting offset of the bank being extracted
    SKIP=$((1150264 + (1150000 * (banknum - 1))))

#this may be wrong. Might need to remove 128 from the count?
    dd if="$hddimage" bs=4096 skip=$SKIP count=1147488 conv=swab status=none \
    | openssl enc -d -des-ede3-ecb \
        -K 92072A6B1C6BE373A4023E7ABA86153E1007FEE35B689BCB \
        -nopad \
    | dd of="$hddimage.$banknum.out.img" bs=4096 conv=swab status=progress


#This code checks to see if bank number=1 / if user is extracting the SES menu. If so, it renames it based on the HDD header as the name on the disc image is a placeholder.
    if [ "$banknum" -eq 1 ]; then
        mv "$hddimage.$banknum.out.img" "$(dd if="$hddimage" bs=4096 count=8 status=none | strings -n 6 | sed -n "${banknum}p").iso"
    else
	mv "$hddimage.$banknum.out.img" "$(dd if="$hddimage.$banknum.out.img" bs=1 count=64 skip=8 status=none | strings).iso"
    fi


}

tplextract(){
	local hddimage="$1"
	local banknum="$2"

	#Outputs the name of the bank being extracted to stdout
    dd if="$hddimage" bs=4096 count=8 status=none | strings -n 6 | sed -n "${banknum}p"

	#math to calculate the offset of the tpl being extracted
    SKIP=$((2297744 + (1150000 * (banknum - 1))))

	 dd if="$hddimage" bs=4096 skip=$SKIP count=128 conv=swab status=none \
    | openssl enc -d -des-ede3-ecb \
        -K 92072A6B1C6BE373A4023E7ABA86153E1007FEE35B689BCB \
        -nopad \
    | dd of="$hddimage.$banknum.1.tpl" bs=4096 conv=swab status=none


#checks to make sure generated file is a tpl. It renames it based on the HDD header it it's a tpl. Otherwise, it deletes the file.
	if [ "$(xxd -p -l 4 "$hddimage.$banknum.1.tpl")" = "0020af30" ]; then
    		mv "$hddimage.$banknum.1.tpl" "$(dd if="$hddimage" bs=4096 count=8 status=none | strings -n 6 | sed -n "${banknum}p").1.tpl"
		echo "TPL1 Extracted."
	else
    		echo "No TPL Detected."
		rm "$hddimage.$banknum.1.tpl"
	fi



#extract tpl2

 	dd if="$hddimage" bs=4096 skip=$((SKIP+128)) count=416 conv=swab status=none \
    | openssl enc -d -des-ede3-ecb \
        -K 92072A6B1C6BE373A4023E7ABA86153E1007FEE35B689BCB \
        -nopad \
    | dd of="$hddimage.$banknum.2.tpl" bs=4096 conv=swab status=none


	if [ "$(xxd -p -l 4 "$hddimage.$banknum.2.tpl")" = "0020af30" ]; then
    		mv "$hddimage.$banknum.2.tpl" "$(dd if="$hddimage" bs=4096 count=8 status=none | strings -n 6 | sed -n "${banknum}p").2.tpl"
		echo "TPL2 Extracted."
	else
    		echo "No TPL Detected."
		rm "$hddimage.$banknum.2.tpl"
	fi

}

#loop to extract all images sequentially
bankextractall() {
    local hddimage="$1"
    local totalbanks

    totalbanks=$(numlist "$hddimage" | wc -l)

    for bank in $(seq 1 "$totalbanks"); do
        echo "$bank" / "$totalbanks"
        bankextract "$hddimage" "$bank"
	done
}

case "$1" in
    list|-l)
        numlist "$2"
        ;;
    extract|-x)
        bankextract "$2" "$3"
        ;;
	tplextract|-tpl)
        tplextract "$2" "$3"
        ;;
    listall|-la)
		numlistall "$2"
	;;
    extractall|-xa)
		bankextractall "$2"
	;;

	help|--h|-h)
	echo This tool can extract individual images from a Starlight Wii HDD dump.
	echo There are 3 available options in this releaase.
	echo $0 -l [HDD image] will list all games from the HDD header.
	echo $0 -tpl [HDD image] [Bank Number] will extract the box art TPL if present.
	echo $0 -x [HDD image] [Bank Number] will extract that game from the HDD image.
	echo $0 -xa [HDD image] will extract all games from the HDD image.
	exit 1
	;;

	*)
        echo run $0 -h for usage instructions
        exit 1
        ;;
esac
