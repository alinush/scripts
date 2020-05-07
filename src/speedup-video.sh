if [ $# -lt 3 ]; then
    echo "Usage: $0 <input-video> <speedup> <output-video>"
    exit 1
fi

# 1.0795
speedup=$2
# 1/1.0795 = 0.926355
invspeedup=`awk "BEGIN {print 1/$speedup}"`

outfile=$3

echo "Speedup:   $speedup"
echo "1/Speedup: $invspeedup"

ffmpeg -i $1 -filter_complex "[0:v]setpts=$invspeedup*PTS[v];[0:a]atempo=$speedup[a]" -map "[v]" -map "[a]" $outfile
