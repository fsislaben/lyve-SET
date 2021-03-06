# Author: Lee Katz <lkatz@cdc.gov>
# Lyve-SET
 
PROFILE := $(HOME)/.bashrc
PROJECT := "setTestProject"
NUMCPUS := 1
SHELL   := /bin/bash

# Style variables
T= "	"
T2=$(T)$(T)
PREFIXNOTE="Must be an absolute path directory. Default: $(PWD)"

###################################

.DEFAULT: install

.PHONY: core extras install install-perlModules install-config core extras

.DELETE_ON_ERROR:

install: core
	# Making sure prereqs are in place
	@blastp -version
	@perl -v | grep -i version
	@perl -Mthreads -e 1
	@java -version 2>&1 | grep version
	@python -V
	@echo "Don't forget to include scripts in your PATH"
	@echo "DONE: installation of Lyve-SET complete."

all: core extras

core: scripts/run_assembly_isFastqPE.pl scripts/run_assembly_trimClean.pl scripts/run_assembly_shuffleReads.pl scripts/run_assembly_removeDuplicateReads.pl scripts/run_assembly_readMetrics.pl scripts/run_assembly_metrics.pl scripts/wgsim scripts/vcf-sort lib/Vcf.pm lib/Schedule/SGELK.pm lib/varscan.v2.3.7.jar lib/snpEff.jar scripts/samtools scripts/bgzip scripts/tabix scripts/bcftools scripts/smalt scripts/raxmlHPC scripts/raxmlHPC-PTHREADS install-perlModules install-config lib/datasets/scripts/downloadDataset.pl
	@echo DONE installing core prerequisites

extras: scripts/vcfutils.pl scripts/basqcol scripts/fetchseq scripts/mixreads scripts/readstats scripts/simqual scripts/simread scripts/splitmates scripts/splitreads scripts/trunkreads scripts/snap scripts/snapxl scripts/stampy.py scripts/bowtie2 scripts/bwa
	@echo DONE installing extras

scripts/vcffilter:
	rm -rf {build,lib}/vcflib
	git clone --recursive https://github.com/ekg/vcflib.git build/vcflib
	make -C build/vcflib
	mv -v build/vcflib lib/vcflib
	ln -sf ../lib/vcflib/bin/vcffilter $@

scripts/vcffixup: scripts/vcffilter
	ln -sf ../lib/vcflib/bin/vcffixup $@

scripts/vcf-sort:
	rm -rf lib/vcftools*
	wget https://github.com/vcftools/vcftools/releases/download/v0.1.14/vcftools-0.1.14.tar.gz -O build/vcftools-0.1.14.tar.gz
	cd build && \
	  tar zxvf vcftools-0.1.14.tar.gz
	mv build/vcftools-0.1.14 lib/
	cd lib/vcftools-0.1.14 && \
	  ./configure --prefix=`pwd -P` && make MAKEFLAGS="" && make install
	ln -sf ../lib/vcftools-0.1.14/bin/vcftools scripts/vcftools
	ln -sf ../lib/vcftools-0.1.14/bin/vcf-sort $@

lib/Vcf.pm: scripts/vcf-sort
	cp lib/vcftools-0.1.14/src/perl/Vcf.pm $@

# CGP scripts that are needed and that don't depend on CGP libraries
scripts/run_assembly_isFastqPE.pl: 
	git clone https://github.com/lskatz/cg-pipeline lib/cg-pipeline
	ln -sf ../lib/cg-pipeline/scripts/run_assembly_isFastqPE.pl $@
scripts/run_assembly_trimClean.pl: scripts/run_assembly_isFastqPE.pl
	ln -sf ../lib/cg-pipeline/scripts/run_assembly_trimClean.pl $@
scripts/run_assembly_shuffleReads.pl: scripts/run_assembly_isFastqPE.pl
	ln -sf ../lib/cg-pipeline/scripts/run_assembly_shuffleReads.pl $@
scripts/run_assembly_removeDuplicateReads.pl: scripts/run_assembly_isFastqPE.pl
	ln -sf ../lib/cg-pipeline/scripts/run_assembly_removeDuplicateReads.pl $@
scripts/run_assembly_readMetrics.pl: scripts/run_assembly_isFastqPE.pl
	ln -sf ../lib/cg-pipeline/scripts/run_assembly_readMetrics.pl $@
scripts/run_assembly_metrics.pl: scripts/run_assembly_isFastqPE.pl
	ln -sf ../lib/cg-pipeline/scripts/run_assembly_metrics.pl $@

lib/Schedule/SGELK.pm:
	git clone https://github.com/lskatz/Schedule--SGELK.git build/Schedule
	mkdir -p lib/Schedule
	mv -v build/Schedule/SGELK.pm lib/Schedule/
	mv -v build/Schedule/README.md lib/Schedule/
	mv -v build/Schedule/.git lib/Schedule/

lib/varscan.v2.3.7.jar:
	wget 'http://downloads.sourceforge.net/project/varscan/VarScan.v2.3.7.jar' -O $@

scripts/samtools:
	rm -rf build/samtools-1.2* lib/samtools-1.2
	wget 'https://github.com/samtools/samtools/releases/download/1.2/samtools-1.2.tar.bz2' -O build/samtools-1.2.tar.bz2
	cd build && tar jxvf samtools-1.2.tar.bz2
	mv build/samtools-1.2 lib
	cd lib/samtools-1.2 && make DFLAGS="-D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE -D_CURSES_LIB=0" LIBCURSES="" 
	cd lib/samtools-1.2/htslib-1.2.1 && make
	ln -sf ../lib/samtools-1.2/samtools $@
scripts/wgsim: scripts/samtools
	ln -sf ../lib/samtools-1.2/misc/wgsim $@
scripts/bgzip: scripts/samtools
	ln -sf ../lib/samtools-1.2/htslib-1.2.1/bgzip $@
scripts/tabix: scripts/samtools
	ln -sf ../lib/samtools-1.2/htslib-1.2.1/tabix $@

scripts/bcftools:
	rm -rf build/bcftools* lib/bcftools*
	wget 'https://github.com/samtools/bcftools/releases/download/1.2/bcftools-1.2.tar.bz2' -O build/bcftools-1.2.tar.bz2
	cd build && tar jxvf bcftools-1.2.tar.bz2
	mv build/bcftools-1.2 lib/bcftools-1.2
	cd lib/bcftools-1.2 && make
	ln -sf ../lib/bcftools-1.2/bcftools $@
scripts/vcfutils.pl: scripts/bcftools
	cp lib/bcftools-1.2/vcfutils.pl $@

scripts/smalt:
	rm -rf build/smalt* lib/smalt*
	wget --continue 'http://downloads.sourceforge.net/project/smalt/smalt-0.7.6-static.tar.gz' -O build/smalt-0.7.6-static.tar.gz
	cd build && tar zxvf smalt-0.7.6-static.tar.gz
	mv build/smalt-0.7.6 lib/
	cd lib/smalt-0.7.6 && ./configure --prefix `pwd -P` && make && make install
	ln -sf ../lib/smalt-0.7.6/bin/smalt $@
scripts/basqcol: scripts/smalt
	ln -sf ../lib/smalt-0.7.6/bin/basqcol $@
scripts/fetchseq: scripts/smalt
	ln -sf ../lib/smalt-0.7.6/bin/fetchseq $@
scripts/mixreads: scripts/smalt
	ln -sf ../lib/smalt-0.7.6/bin/mixreads $@
scripts/readstats: scripts/smalt
	ln -sf ../lib/smalt-0.7.6/bin/readstats $@
scripts/simqual: scripts/smalt
	ln -sf ../lib/smalt-0.7.6/bin/simqual $@
scripts/simread: scripts/smalt
	ln -sf ../lib/smalt-0.7.6/bin/simread $@
scripts/splitmates: scripts/smalt
	ln -sf ../lib/smalt-0.7.6/bin/splitmates $@
scripts/splitreads: scripts/smalt
	ln -sf ../lib/smalt-0.7.6/bin/splitreads $@
scripts/trunkreads: scripts/smalt
	ln -sf ../lib/smalt-0.7.6/bin/trunkreads $@

scripts/snap:
	rm -rf build/snap* lib/snap*
	git clone https://github.com/amplab/snap.git lib/snap
	cd lib/snap && git checkout v1.0beta.18 && make
	cp -vn lib/snap/snap-aligner $@
scripts/snapxl: scripts/snap
	cd lib/snap && make clean && make CXXFLAGS="-DLONG_READS -O3 -Wno-format -MMD -ISNAPLib -msse"
	cp -vn lib/snap/snap-aligner $@

scripts/raxmlHPC:
	rm -rf build/raxml* lib/standard-RAxML*
	wget 'https://github.com/stamatak/standard-RAxML/archive/v8.1.16.tar.gz' -O build/raxml_v8.1.16.tar.gz
	cd build && tar zxvf raxml_v8.1.16.tar.gz
	mv build/standard-RAxML-8.1.16 lib
	cd lib/standard-RAxML-8.1.16 && make -f Makefile.gcc
	ln -sf ../lib/standard-RAxML-8.1.16/raxmlHPC $@
scripts/raxmlHPC-PTHREADS: scripts/raxmlHPC
	cd lib/standard-RAxML-8.1.16 && make -f Makefile.PTHREADS.gcc
	ln -sf ../lib/standard-RAxML-8.1.16/raxmlHPC-PTHREADS $@

# There isn't an easy way for Make to detect whether these files have
# been installed and so it shouldn't depend on a file existing and
# should run no matter what. CPAN will know if the module will be
# there.
install-perlModules: lib/lib/perl5/Config/Simple.pm lib/lib/perl5/File/Slurp.pm lib/lib/perl5/Math/Round.pm lib/lib/perl5/Number/Range.pm lib/lib/perl5/Array/IntSpan.pm lib/lib/perl5/Statistics/Distributions.pm lib/lib/perl5/Statistics/Basic.pm lib/lib/perl5/Graph/Centrality/Pagerank.pm lib/lib/perl5/String/Escape.pm lib/lib/perl5/Statistics/LineFit.pm lib/lib/perl5/Spreadsheet/ParseExcel.pm lib/lib/perl5/Spreadsheet/XLSX.pm
	@echo "Done with Perl modules"
lib/lib/perl5/Config/Simple.pm:
	perl scripts/cpanm --self-contained -L lib Config::Simple
lib/lib/perl5/File/Slurp.pm:
	perl scripts/cpanm --self-contained -L lib File::Slurp
lib/lib/perl5/Math/Round.pm:
	perl scripts/cpanm --self-contained -L lib Math::Round
lib/lib/perl5/Number/Range.pm:
	perl scripts/cpanm --self-contained -L lib Number::Range
lib/lib/perl5/Array/IntSpan.pm:
	perl scripts/cpanm --self-contained -L lib Array::IntSpan
lib/lib/perl5/Statistics/Distributions.pm:
	perl scripts/cpanm --self-contained -L lib Statistics::Distributions
lib/lib/perl5/Statistics/Basic.pm:
	perl scripts/cpanm --self-contained -L lib Statistics::Basic
lib/lib/perl5/Graph/Centrality/Pagerank.pm:
	perl scripts/cpanm --self-contained -L lib Graph::Centrality::Pagerank
lib/lib/perl5/String/Escape.pm:
	perl scripts/cpanm --self-contained -L lib String::Escape
lib/lib/perl5/Statistics/LineFit.pm:
	perl scripts/cpanm --self-contained -L lib Statistics::LineFit
lib/lib/perl5/Spreadsheet/ParseExcel.pm:
	perl scripts/cpanm --self-contained -L lib Spreadsheet::ParseExcel
lib/lib/perl5/Spreadsheet/XLSX.pm:
	perl scripts/cpanm --self-contained -L lib Spreadsheet::XLSX

install-config: config/LyveSET.conf config/presets.conf
config/LyveSET.conf:
	cp config/original/LyveSET.conf $@
config/presets.conf:
	cp config/original/presets.conf $@

lib/snpEff.jar:
	rm -rf lib/snpEff* 
	wget http://sourceforge.net/projects/snpeff/files/snpEff_latest_core.zip -O lib/snpEff_latest_core.zip
	cd lib && unzip -o snpEff_latest_core.zip
	cp lib/snpEff/snpEff.jar $@
	rm -f lib/snpEff_latest_core.zip
config/snpEff.conf: lib/snpEff.jar
	cp lib/snpEff/snpEff.config config/snpEff.conf

scripts/stampy.py:
	rm -rf build/Stampy* lib/stampy*
	wget www.well.ox.ac.uk/bioinformatics/Software/Stampy-latest.tgz -O build/Stampy-latest.tgz
	mkdir lib/stampy && tar zxvf build/Stampy-latest.tgz -C lib/stampy --strip-components 1
	cd lib/stampy && make CXXFLAGS='-Wno-deprecated -Wunused-but-set-variable'
	ln -sf ../lib/stampy/stampy.py $@

scripts/bowtie2:
	rm -rf {build,lib}/bowtie2*
	wget 'https://github.com/BenLangmead/bowtie2/archive/v2.2.6.tar.gz' -O build/bowtie2.2.6.tar.gz
	cd build && tar zxvf bowtie2.2.6.tar.gz
	mv build/bowtie2-2.2.6 lib
	cd lib/bowtie2-2.2.6 && make
	ln -sf ../lib/bowtie2-2.2.6/bowtie2 $@
	ln -sf ../lib/bowtie2-2.2.6/bowtie2-build $@-build
	ln -sf ../lib/bowtie2-2.2.6/bowtie2-build-s $@-build-s
	ln -sf ../lib/bowtie2-2.2.6/bowtie2-build-l $@-build-l
	ln -sf ../lib/bowtie2-2.2.6/bowtie2-align-s $@-align-s
	ln -sf ../lib/bowtie2-2.2.6/bowtie2-align-l $@-align-l

scripts/bwa:
	rm -rf {build,lib}/bwa*
	wget 'https://downloads.sourceforge.net/project/bio-bwa/bwa-0.7.12.tar.bz2' -O build/bwa-0.7.12.tar.bz2
	cd build && tar jxvf bwa-0.7.12.tar.bz2
	mv build/bwa-0.7.12 lib
	cd lib/bwa-0.7.12 && make
	ln -sf ../lib/bwa-0.7.12/bwa $@

lib/datasets/scripts/downloadDataset.pl:
	rm -rf lib/datasets
	git clone https://github.com/WGS-standards-and-analysis/datasets.git lib/datasets
	cd lib/datasets && git checkout be0797662ffa9134f27cacb3b2758d5dac72f0d9
	for i in lib/datasets/datasets/*.xlsx; do \
	  perl scripts/excel2tsv.pl $$i; \
	done;

