function MAP=maplib_bcaug89()
% MAP=maplib_bcaug89() -  MAP(16) process obtained by KPC fitting of
% Bellcore Aug89 Trace, see [1]
%
%  Output:
%  MAP: pre-fitted MAP process
%
% References:
% [1] G.Casale, E.Zhang, and E.Smirni. Interarrival times characterization  and fitting for markovian traffic analysis, 2008.
%     Department of Computer Science, College of William and Mary, Tech. Rep. WM-CS-2008-02. Available at:
%     http://www.wm.edu/computerscience/techreport/2008/WM-CS-2008-02.pdf
%

D0=diag([ -1.081448703958653
  -0.226850164937913
  -0.022507608953628
  -0.004721310206206
  -0.690100658578776
  -0.144759014134750
  -0.014362693029337
  -0.003012791333265
  -0.279735483503277
  -0.058678733757243
  -0.005821983835293
  -0.001221248856712
  -0.178506516940488
  -0.037444432326945
  -0.003715159918601
  -0.000779310786744]);
D1=zeros(16);
D1(:,1:9)=1000*[
   1.054383960274358   0.008706068961608   0.000065882543492   0.000000543993449   0.000026360258013   0.000000217657165   0.000000001647105   0.000000000013600   0.018114498976751
   0.079963171346053   0.143035984872132   0.000004996450356   0.000008937516929   0.000001999129262   0.000003575989022   0.000000000124914   0.000000000223444   0.001373781127275
   0.016448903243899   0.000135818915480   0.005496792965716   0.000045387126920   0.000000411232862   0.000000003395558   0.000000137423260   0.000000001134707   0.000282595005431
   0.001247464413442   0.002231431019631   0.000416869958508   0.000745685846060   0.000000031187390   0.000000055787170   0.000000010422010   0.000000018642612   0.000021431654589
   0.000016821169001   0.000000138892721   0.000000001051061   0.000000000008679   0.672829938874338   0.005555569951719   0.000042041371437   0.000000347136425   0.000000288990596
   0.000001275696587   0.000002281931977   0.000000000079711   0.000000000142585   0.051026587766911   0.091274997139851   0.000003188365448   0.000005703262943   0.000000021916688
   0.000000262418428   0.000000002166794   0.000000087693371   0.000000000724086   0.010496474700983   0.000086669596697   0.003507647132801   0.000028962710912   0.000000004508394
   0.000000019901488   0.000000035599250   0.000000006650556   0.000000011896338   0.000796039618078   0.001423934404455   0.000266015606524   0.000475841610957   0.000000000341911
   0.004685629666144   0.000038689335706   0.000000292778733   0.000000002417480   0.000000117143670   0.000000000967258   0.000000000007320   0.000000000000060   0.272734717648452
   0.000355352340300   0.000635644773910   0.000000022203976   0.000000039717879   0.000000008884031   0.000000015891517   0.000000000000555   0.000000000000993   0.020683862597517
   0.000073098104599   0.000000603572478   0.000024427473443   0.000000201698126   0.000000001827498   0.000000000015090   0.000000000610702   0.000000000005043   0.004254794411596
   0.000005543669558   0.000009916368019   0.000001852549278   0.000003313790662   0.000000000138595   0.000000000247915   0.000000000046315   0.000000000082847   0.000322678329143
   0.000000074752435   0.000000000617232   0.000000000004671   0.000000000000039   0.002990022648902   0.000024688675434   0.000000186829755   0.000000001542657   0.000004351087413
   0.000000005669132   0.000000010140792   0.000000000000354   0.000000000000634   0.000226759607895   0.000405621529243   0.000000014168937   0.000000025345016   0.000000329981071
   0.000000001166174   0.000000000009629   0.000000000389705   0.000000000003218   0.000046645809403   0.000000385155360   0.000015587808695   0.000000128708841   0.000000067879083
   0.000000000088441   0.000000000158201   0.000000000029555   0.000000000052867   0.000003537560310   0.000006327893386   0.000001182160071   0.000002114616357   0.000000005147865];
D1(:,10:16)=100*[
       0.001495717719905   0.000011318735031   0.000000093459016   0.000004528737963   0.000000037393878   0.000000000282975   0.000000000002337
   0.024573829830744   0.000000858398821   0.000001535480881   0.000000343453868   0.000000614361105   0.000000000021461   0.000000000038388
   0.000023333924815   0.000944358547782   0.000007797586981   0.000000070650518   0.000000000583363   0.000000023609554   0.000000000194945
   0.000383363712317   0.000071618980574   0.000128110119315   0.000000005358048   0.000000009584332   0.000000001790519   0.000000003202833
   0.000000023862010   0.000000000180574   0.000000000001491   0.115593348329155   0.000954456535734   0.000007222780397   0.000000059638639
   0.000000392039864   0.000000000013695   0.000000000024496   0.008766456117659   0.015681202527612   0.000000547766704   0.000000979830447
   0.000000000372259   0.000000015065873   0.000000000124399   0.001803312525553   0.000014889986758   0.000602619849997   0.000004975843876
   0.000000006116013   0.000000001142577   0.000000002043811   0.000136760984522   0.000244634395859   0.000045701941738   0.000081750412559
   0.022519758925906   0.000170416637339   0.000001407133504   0.000068185384047   0.000000563008048   0.000000004260522   0.000000000035179
   0.369987408927563   0.000012924186335   0.000023118439277   0.000005171094927   0.000009249916471   0.000000000323113   0.000000000577975
   0.000351319205910   0.014218409364712   0.000117401683938   0.000001063725196   0.000000008783200   0.000000355469121   0.000000002935115
   0.005771983755639   0.001078306525075   0.001928845907583   0.000000080671599   0.000000144303201   0.000000026958337   0.000000048222353
   0.000000359270138   0.000000002718751   0.000000000022449   1.740391454329113   0.014370446243928   0.000108747306488   0.000000897928634
   0.000005902613249   0.000000000206187   0.000000000368821   0.131989128548117   0.236098627361736   0.000008247260798   0.000014752479810
   0.000000005604789   0.000000226834129   0.000000001872974   0.027150954222899   0.000224185959521   0.009073138310317   0.000074917080308
   0.000000092083641   0.000000017202819   0.000000030771943   0.002059094681381   0.003683253562089   0.000688095552180   0.001230846942853];
MAP={D0,D1};
MAP=map_normalize(MAP);
end