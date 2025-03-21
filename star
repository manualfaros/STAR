#Antes de nada suele hacerse un FastQC, para comprobar la calidad de las muestras.
module load fastqc
fastqc loquesea.fastq

#Aluego se usa trimmomatic, para quitar las reads que son malas
#Algunos no hacen trimmomatic, parace que Raul sí hizo.

##Para generar el genome index, le digo donde lo crea (carpeta genome es este caso), le doy el assembly scaffolds en fasta, el gff con la anotacion, y al no ser GTF sino gff, hay que decirle el nomnre del transcrito en el gff(--sjdbGTFtagExonParentTranscript). En este caso, el nombre es transcriptId(así nombran en este gff al tránscrito al que pertenece cada exon). --sjdbOverhang 100 : en la teoría dicen que lo normal es poner 100. --runThreadN 4. para los núcleos que usa, aqui pone cuatro porque lo hago en el ordenadol pelsonal.

STAR --runMode genomeGenerate --genomeDir /media/m/Datos/STAR/genome --genomeFastaFiles /media/m/Datos/STAR/database/PleosPC15_2_Assembly_scaffolds.fasta --sjdbGTFfile /media/m/Datos/STAR/database/PleosPC15_2_GeneModels_FilteredModels1.gff --sjdbGTFtagExonParentTranscript transcriptId --sjdbOverhang 100 --runThreadN 4

##A veces no te deja usar gff, para pasrlo a gtf usa el programa  gffread, ejemplo:    gffread Sa_NCTC8325_NC_007795.1.gff3 -T -o SA.gtf

##Para lanzar el STAR:

##DUDO sobre si es paired end o no. si es paired end, necesito incluir el otro archivo, R2. noseque es --outFilterMismatchNoverLmax 0.04 --outFilterMultimapNmax 1

#Raul
STAR --genomeDir /media/m/Datos/STAR/genome --runThreadN 4 --outReadsUnmapped Fastx --outFilterMismatchNoverLmax 0.04 --outFilterMultimapNmax 1 --outSAMtype BAM SortedByCoordinate --readFilesIn $1 $2

#tutorial https://bioinformatics.uconn.edu/resources-and-events/tutorials/rna-seq-tutorial-with-reference-genome/
STAR --genomeDir /media/m/Datos/STAR/genome --readFilesIn /media/m/Datos/STAR/RUN/M2-x-PC23_S1_R1_001.fastq  --runThreadN 4 --outSAMtype BAM SortedByCoordinate --outFileNamePrefix pruebamanu


#Funciona
#El el output te saca un .bam. Para abrirlo con el igv, hay que hacerle un index con este comando: samtools index elquesea.bam
#Ahora lo que tengo que hacer es incluir en el fasta del genoma el mitocondrila, y el gff también. 

#Es fasta es fácil, pero y el gff? uso el mitos web server, opcion mold, y el output es un gff.
En lugar del mitos, uso mf annot. El archivo que saca, se transforma en gfffusando el archivo perl mfannot2gff.pl.  Uso: perl mfannot2gff.pl -m mfannot -g PC15gff

#Creo que tengo que cambiar el nombre del sacffold, en lugar de mitochondrion le pongo scaffold 13

#DUDA: estoy usando todos los scaffolds posibles? en el STAR dicen que uses todos, aunque sean pequeños. YO estoy usando los 12 sacffolds de siempre más el mitocondrial.
#Creo genoma con la mitocondria
STAR --runMode genomeGenerate --genomeDir /media/m/Datos/STAR/genomemit --genomeFastaFiles /media/m/Datos/STAR/database/PleosPC15_2_Assembly_scaffolds_Mit.fasta --sjdbGTFfile /media/m/Datos/STAR/database/PleosPC15_2_GeneModels_FilteredModels1_Mit.gff --sjdbGTFtagExonParentTranscript transcriptId --sjdbOverhang 100 --runThreadN 4

#Runeo con genoma de mit
STAR --genomeDir /media/m/Datos/STAR/genomemit --readFilesIn /media/m/Datos/STAR/RUN/M2-x-PC23_S1_R1_001.fastq  --runThreadN 4 --outSAMtype BAM SortedByCoordinate --outFileNamePrefix mit

#sale bien, al abrir con el IGV se ven cuentas en la mitocondria.

#Problema: es paired end, no single end. Lo se por que en cada lectura pone un dos(@NS500599:137:H7JYTBGX3:1:11101:7236:1033 2:N:0:ACAGTG) on un 1(@NS500599:137:H7JYTBGX3:1:11101:7236:1033 1:N:0:ACAGTG)
#para hacerlo paired end le digo que coja los dos archivos a la vez

STAR --genomeDir /media/m/Datos/STAR/genomemit --readFilesIn /media/m/Datos/STAR/RUN/M2-x-PC23_S1_R1_001.fastq /media/m/Datos/STAR/RUN/M2-x-PC23_S1_R2_001.fastq --runThreadN 4 --outSAMtype BAM SortedByCoordinate --outFileNamePrefix mitPaired


#Para hacerlo en el biocluster:


#creo un script con los comandos del Star y alguna cosa mas (numero de núcleos, Ram. etc, ver ejemplo STARManu.sh). Y lo copio en la carpeta que quiero que esten los resultados.
#Para ver el script desde el termianl, uso:
less STARManu.sh
#Compruabo que está bien, y 

q #para salir del less


#desde esa carpeta ejecuto el script STARManu.sh

sbatch STARManu.sh

#Para ver como va:

squeue -u gpisabarro

#Una vez que ha sacado el .bam, creo el inex .bai, para que lo pueda leer el igv:
module load samtools
samtools index Aligned.sortedByCoord.out.bam

##OPCIONES
EStas tres las usaba Raul, mira aver que son

--outReadsUnmapped Fastx 
--outReadsUnmapped
default: None
string: output of unmapped reads (besides SAM)
None
no output
Fastx
output in separate fasta/fastq files, Unmapped.out.mate1/2

--outFilterMismatchNoverLmax 0.04 

--outFilterMismatchNoverLmax
default: 0.3
int: alignment will be output only if its ratio of mismatches to *mapped*
length is less than this value

--outFilterMultimapNmax 1

--outFilterMultimapNmax
default: 10
int: read alignments will be output only if the read maps fewer than this value,
otherwise no alignments will be output
