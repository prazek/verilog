set -e
echo "Synteza (.v -> .ngc)"
xst -ifn stopwatch.xst
echo "Linkowanie (.ngc -> .ngd)"
ngdbuild stopwatch -uc stopwatch.ucf
echo "Tłumaczenie na prymitywy dostępne w układzie Spartan 3E (.ngd -> .ncd)"
map stopwatch
echo "Place and route (.ncd -> lepszy .ncd)"
par -w stopwatch.ncd stopwatch_par.ncd
echo "Generowanie finalnego bitstreamu (.ncd -> .bit)"
bitgen -w stopwatch_par.ncd -g StartupClk:JTAGClk
echo "done"

