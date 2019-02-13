for demoscript in scripts/*-portplug.sh; do
    bbuild --out=bin "$demoscript"
done
