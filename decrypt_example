dd if=$1 bs=4096 count=8 status=none | strings -n 6 | sed -n "${2}p"
SKIP=$((1150264+(1150000*($2-1))))
dd if="$1" bs=4096 skip=$SKIP count=1147488 conv=swab status=none \
| openssl enc -d -des-ede3-ecb -K 92072A6B1C6BE373A4023E7ABA86153E1007FEE35B689BCB -nopad \
| dd of="$1.$2.out.img" bs=4096 conv=swab status=progress
mv "$1.$2.out.img" "$(dd if="$1.$2.out.img" bs=1 count=64 skip=8 status=none | strings).iso"

#Usage supern0va.sh $1 $2
#$1=name of HDD image 
#$2=bank number you want to extract
