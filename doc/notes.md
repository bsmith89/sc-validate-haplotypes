# TITLE OF PROJECT

## NOTES

### Metadata source

#### `meta/droplet.tsv`

```
cd /pollard/ucfmt/raw_data_archive/2021-06-29
find B-10??/scFASTQ/ -name '*_R1.fastq' \
    | tr '/-' '<TAB>' \
    | awk -v OFS='        ' '{print "SS"$2"_"$4,"SS"$2,"SS"$2"/"$4"-"$5,"SS"$2,"SS"$2"/"$4"-"$5}' \
    > ~/Projects/sc-validate-haplotypes/meta/droplet.tsv
# Then clean up this table e.g. by adding a header, replace R1 with R2 in
second column.
```
