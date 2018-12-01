set -e
echo "Synteza (.v -> .ngc)"
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

