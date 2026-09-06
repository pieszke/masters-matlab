addpath("helpers")

iwr = IWR1843("C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-along_side_run_0\measurement_001");

IWR1843.viewArr(iwr.vArray,"Wirtualny szyk antenowy");
hAxes = findobj(gcf,"Type","axes");
hAxes.Position = [-0.4553,-0.6976,1.8262,2.2198];
hAxes.Color = [1,1,1];