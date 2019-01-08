all: calculator

calculator: calculator_par.bit

calculator_par.bit : calculator.xst calculator.ucf calculator.prj \
                     calculator.v top.v display.v
	rm -f synthesis.log
	xst -ifn calculator.xst >> synthesis.log
	echo "Linkowanie (.ngc -> .ngd)" >> synthesis.log
	ngdbuild calculator -uc calculator.ucf >> synthesis.log
	echo "Tłumaczenie na prymitywy dostępne w układzie Spartan 3E (.ngd -> .ncd)" >> synthesis.log
	map calculator >> synthesis.log
	echo "Place and route (.ncd -> lepszy .ncd)" >> synthesis.log
	par -w calculator.ncd calculator_par.ncd >> synthesis.log
	echo "Generowanie finalnego bitstreamu (.ncd -> .bit)" >> synthesis.log
	bitgen -w calculator_par.ncd -g StartupClk:JTAGClk >> synthesis.log
	echo "done" >> synthesis.log


flush : calculator_par.bit
	./flush.sh

.PHONY: clean

clean :
	rm -rf *.bld *.map *.mrp *.ncd *.ngc *.ngd *.ngm *.pcf *.srp *_ngdbuild.xrpt *_par.bgn *_par.bit *_par.drc 
	rm -rf *_par.ncd *_par.pad *_par.par *_par.ptwx *_par.unroutes *_par.xpi *_par_bitgen.xwbt *_par_pad.csv *_par_pad.txt  
	rm -rf *_summary.xml *_usage.xml *_xst.xrpt *.lst *.html *.log xlnx_auto_0_xdb/ xst/ *.lso *.xrpt *.xrpt _xmsgs

 

