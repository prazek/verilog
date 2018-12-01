stopwatch : abc.v abc.xst abc.ucf abc.prj
	xst -ifn abc.xst
	echo "Linkowanie (.ngc -> .ngd)"
	ngdbuild abc -uc abc.ucf
	echo "Tłumaczenie na prymitywy dostępne w układzie Spartan 3E (.ngd -> .ncd)"
	map abc
	echo "Place and route (.ncd -> lepszy .ncd)"
	par -w abc.ncd abc_par.ncd
	echo "Generowanie finalnego bitstreamu (.ncd -> .bit)"
	bitgen -w abc_par.ncd -g StartupClk:JTAGClk
	echo "done"

	

flush : stopwatch
	./flush.sh

clean :
	rm -rf *.bld *.map *.mrp *.ncd *.ngc *.ngd *.ngm *.pcf *.srp *_ngdbuild.xrpt *_par.bgn *_par.bit *_par.drc 
	rm -rf *_par.ncd *_par.pad *_par.par *_par.ptwx *_par.unroutes *_par.xpi *_par_bitgen.xwbt *_par_pad.csv *_par_pad.txt  
	rm -rf *_summary.xml *_usage.xml *_xst.xrpt *.lst *.html *.log xlnx_auto_0_xdb/ xst/ *.lso *.xrpt *.xrpt _xmsg

 

