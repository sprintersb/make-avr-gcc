#!/bin/bash

dir=avr-gcc

file=$1
user=$2
home=/home/pfs/project/winavr

cmd=scp
cmp="rsync -e ssh"

case $name in
    *tar*)
	m5=/tmp/${file}.md5
	md5sum ${file} > ${m5}
	${cmd} ${m5} ${user}@frs.sourceforge.net:${home}/${dir}
	;;
esac

${cmd} ${file} ${user}@frs.sourceforge.net:${home}/${dir}
