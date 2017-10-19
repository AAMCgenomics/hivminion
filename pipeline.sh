# !/bin/bash

cdir=$(pwd)

echo "enter sequence name:"
read name
echo $name


#nanopolish extract fasta
nanopolish extract --type any $cdir > reads.fa
#nanopolish extract fastq
nanopolish extract -q --type any $cdir > reads.fq

#### canu draft

canu \
-p assembled -d reads_assembled \
contigFilter="1 700 1.0 1.0 2" \
errorRate=0.009 \
genomeSize=0.01m \
-nanopore-raw reads.fq

cp $cdir/reads_assembled/assembled.contigs.fasta .

######LASTAL 

lastdb lastalbd assembled.contigs.fasta

lastal -s 2 -q 1 -b 1 -a 1 -e 45 -T 0 -Q 0 -a 1 lastalbd reads.fa | maf-convert sam > reads.sam


samtools faidx assembled.contigs.fasta

samtools view -bt assembled.contigs.fasta.fai reads.sam > reads.bam

samtools sort reads.bam -o reads.sorted.bam

samtools index reads.sorted.bam

###### nanopolish

cp ~/nanopolish/etc/r9-models/* .

nanopolish eventalign -t 4 --sam -r reads.fa -b reads.sorted.bam -g assembled.contigs.fasta | samtools view -Sb - | samtools sort -o reads.eventalign.sorted.01.bam

samtools index reads.eventalign.sorted.01.bam

nanopolish variants --progress -t 4 --fix-homopolymers --consensus $name.fa --min-candidate-frequency 0.1 --reads reads.fa --outfile $name.vcf --bam reads.sorted.bam --event-bam reads.eventalign.sorted.01.bam --genome assembled.contigs.fasta -vv -w "tig00000000:0-1200" --snps 


sed -i 's/tig00000000/'$name'/g' $name.fa
sed -i 's/tig00000000/'$name'/g' $name.vcf

