filename="$@"

# Extract the base name
basename="${filename%.*}"
# Extract the extension
extension="${filename##*.}"

echo "Base name: $basename"
echo "Extension: $extension"

ffmpeg -i "$filename" -f ffmetadata -

ffmpeg -i "$filename" -map_metadata -1 -c copy "$basename".no-meta.$extension
