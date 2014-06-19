type file;

(int result) randomInt ()
{
  //float range = 9999999.0;
  float range = 9999.0;
  float rand = java("java.lang.Math","random");
  string s[] = strsplit(toString(range*rand),"\\.");
  result = toInt(s[0]);
}


#app (file out) simulation (string npart, string steps, string mass, file md)
app (file out, file traj) simulation (string npart, string steps, string mass, file md)
{ 
  #sh "-c" strjoin(["chmod a+x ./md; ./md","3",npart,steps,">/dev/null; cat md.dat"]," ") stdout=filename(o);
  sh "-c" strjoin(["chmod a+x ./md; ./md","3",npart,steps, "10 .0001", mass, "0.1 1.0 0.2", toString(randomInt()), @out, @traj]," ");
  # sh "-c" strjoin(["chmod a+x ./md; ./md","3",npart,steps, "10 .0001", mass, "0.1 1.0 0.2", toString(randomInt()), ">/dev/null; cat md.dat"]," ") stdout=filename(out);
}

app (file o) analyze (file s[])
{
  mdstats filenames(s) stdout=filename(o);
}

app (file o) convert (file s[])
{
  convert filenames(s) filename(o);
}

app (file gif, file out) makegif (file trj, file cray, file mdvisual)
{
    sh "-c chmod a+x ./mdvisual; ./mdvisual" @trj @gif stdout=@out;
}

int    nsim   = toInt(arg("nsim","10"));
string npart  = arg("npart","50");
string steps  = arg("steps","1000");
string mass   = arg("mass",".005");

file md <"md">;
file cray <"c-ray">;
file mdvisual <"mdvisual">;

file sim[] <simple_mapper; prefix="sim_", suffix=".out">;
file trj[] <simple_mapper; prefix="sim_", suffix=".trj.tgz">;
file gif[] <simple_mapper; prefix="gifs/sim_", suffix="gif">;
file gout[] <simple_mapper; prefix="gifs/stdout_", suffix="gif">;

foreach i in [0:nsim-1] {
  (sim[i],  trj[i])  = simulation(npart,steps,mass,md);
  (gout[i], gif[i])  = makegif(trj[i], cray, mdvisual);
}

file stats_out<"output/average.out">;
stats_out = analyze(sim);

#file viz_all<"output/all.gif">;
#viz_all = convert(gifs);
