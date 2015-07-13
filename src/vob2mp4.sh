# vob2mp4.sh
#  - avconv -i 'file.vob' -vf yadif -strict experimental 'out.mp4'
#  - avconv -i 'concat:file1.vob|file2.vob' -vf yadif -strict experimental 'out.mp4'

vInput=     # the input file(s)
vOutput=    # the output file

if [ $# -lt 2 ]; then
    echo "Usage: $(basename $0) input-1.vob [input-2.vob] [...] output.mp4"
    exit 1
elif [ $# -eq 2 ]; then
    vInput="$1"
    vOutput="$2"
elif [ $# -gt 2 ]; then
    vInput="concat:$1"
    shift
    vInput="$vInput|$1"
    shift
    while [ $# -gt 1 ]; do
        vInput="$vInput|$1"
        shift
    done
    vOutput="$1"
else
    echo "INTERNAL ERROR: You messed up your if logic bro"
    exit 2
fi

avconv -i "$vInput" -vf yadif -strict experimental "$vOutput"
