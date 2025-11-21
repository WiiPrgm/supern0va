numlist() {
    local hddimage="$1"
    dd if="$hddimage" bs=4096 count=8 status=none | strings -n 6 | sed 's/^SES://' | nl -w1 -s'. '
}

numlistall() {
    local hddimage="$1"
    dd if="$hddimage" bs=4096 count=8 status=none | strings -n 6 | nl -w1 -s'. '
}

bankextract() {
    local hddimage="$1"
    local banknum="$2"

    dd if="$hddimage" bs=4096 count=8 status=none | strings -n 6 | sed -n "${banknum}p"

    SKIP=$((1150264 + (1150000 * (banknum - 1))))

    dd if="$hddimage" bs=4096 skip=$SKIP count=1147488 conv=swab status=none \
    | openssl enc -d -des-ede3-ecb \
        -K 92072A6B1C6BE373A4023E7ABA86153E1007FEE35B689BCB \
        -nopad \
    | dd of="$hddimage.$banknum.out.img" bs=4096 conv=swab status=progress

    mv "$hddimage.$banknum.out.img" "$(dd if="$hddimage.$banknum.out.img" bs=1 count=64 skip=8 status=none | strings).iso"
}

case "$1" in
    list|-l)
        numlist "$2"
        ;;
    extract|-x)
        bankextract "$2" "$3"
        ;;
	listall|-la)
		numlistall "$2"
		;;

	help|--h|-h)
	echo This tool can extract individual images from a Starlight Wii HDD dump.
	echo There are 2 available options in this releaase.
	echo $0 -l [HDD image] will list all games from the HDD header.
	echo $0 -x [HDD image] [Bank Number] will extract that game from the HDD image.
	exit 1
	;;

	*)
        echo run $0 -h for usage instructions
        exit 1
        ;;
esac
