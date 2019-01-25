all: graphics

graphics: graphics_par.bit

graphics_par.bit : vga.v top.v graphics.xst graphics.ucf graphics.prj EPP.v GraphicsCard.v
	xst -ifn graphics.xst
	echo "Linkowanie (.ngc -> .ngd)"
	ngdbuild graphics -uc graphics.ucf
	echo "Tłumaczenie na prymitywy dostępne w układzie Spartan 3E (.ngd -> .ncd)"
	map graphics
	echo "Place and route (.ncd -> lepszy .ncd)"
	par -w graphics.ncd graphics_par.ncd
	echo "Generowanie finalnego bitstreamu (.ncd -> .bit)"
	bitgen -w graphics_par.ncd -g StartupClk:JTAGClk
	echo "done"

	

flush : graphics_par.bit
	./flush.sh

.PHONY: clean

clean :
	rm -rf *.bld *.map *.mrp *.ncd *.ngc *.ngd *.ngm *.pcf *.srp *_ngdbuild.xrpt *_par.bgn *_par.bit *_par.drc 
	rm -rf *_par.ncd *_par.pad *_par.par *_par.ptwx *_par.unroutes *_par.xpi *_par_bitgen.xwbt *_par_pad.csv *_par_pad.txt  
	rm -rf *_summary.xml *_usage.xml *_xst.xrpt *.lst *.html *.log xlnx_auto_0_xdb/ xst/ *.lso *.xrpt *.xrpt _xmsgs

 

