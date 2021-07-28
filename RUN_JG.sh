#!/bin/bash
# ./RUN_JG.sh -g 1 -n 0
# set -x
echo "[RUN_JG] run formal" 
gui=0
SVA=
na=1
FILE=./src/main/verilog/vscale_sim_top_unmod.v
#FILE=./src/main/verilog/vscale_sim_top_dup.v
ACT_FILE=./src/main/verilog/vscale_sim_top_mod.v
TCL=./jg_test.tcl
DIR=./jgp
DUMPNAME=jg_summary
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -n|--noupdate)
    na="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--sva)
    SVA="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--dir)
    DIR="$2_dir"
    shift # past argument
    shift # past value
    ;;
    -g|--gui)
    gui="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--tcl)
    TCL="$2"
    shift
    shift
    ;;
    -r|--res)
    DUMPNAME="$2"
    shift
    shift
    ;;
    --help)
    echo "-g/--gui <0(default)/1> with gui, -s/--sva <sva relative file path>, -t/--tcl <a.tcl> -n/--noupdate <0/1(default)> update sv to top module"
    exit 0
    shift # past argument
    ;;
    --default)
    DEFAULT=YES
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

mkdir -p $DIR
HDLF="${DIR}/${DUMPNAME}_hdls.f"
TCLF="${DIR}/${DUMPNAME}_.tcl"
TOPV="${DIR}/${DUMPNAME}_top.v"
if [ -f "$SVA" ]; then
    if [ "$na" -eq "1" ]; then 
        echo "[RUN_JG] concat $FILE - $SVA => ${DIR}/${DUMPNAME}_top.v"
	    echo "${DUMPNAME}_top.v"
        { head -n -1 "$FILE"; cat "$SVA" ; echo "" ; tail -n 1 "$FILE"; } > "${TOPV}" #"${DIR}/${DUMPNAME}_top.v"
        { head -n 1 jg_hdls_base.f; echo "${TOPV}" ; tail -n +2 jg_hdls_base.f; } > $HDLF
    fi 
else 
    echo "[RUN_JG] no sva found"
    echo "[RUN_JG] file: $FILE"
    cp $FILE $ACT_FILE
    exit 1
fi

sed "s~CSVNAME~${DIR}/${DUMPNAME}~" $TCL > $TCLF
sed -i "s~jg_hdls.f~${HDLF}~" $TCLF
if [ "$gui" -eq "0" ]; then
    echo "[RUN_JG] no gui"
    if [ -z "$DISPLAY" ]; then
        jc -fpv $TCLF -proj $DIR/jgsession
    else 
        jg -no_gui -fpv $TCLF -proj $DIR/jgsession
    fi
else
    echo "[RUN_JG] gui"
    echo "jg -fpv $TCL -proj $DIR/jgsession " 
    sed -i "s~exit~#exit~" $TCLF
    if [ -z "$DISPLAY" ]; then
        echo "no x server"
        exit 1
    else 
        jg -fpv $TCLF  -proj $DIR/jgsession & 
    fi 
fi 
cp $DIR/jgsession/sessionLogs/session_0/jg_session_0.log "${DIR}/${DUMPNAME}_jg.log"
# next: python3 parse_summary.py 

