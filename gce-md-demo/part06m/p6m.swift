type file;

(int result) randomInt ()
{
  float range = 9999999.0;
  float rand = java("java.lang.Math","random");
  string s[] = strsplit(toString(range*rand),"\\.");
  result = toInt(s[0]);
}

app (file out, file traj) simulation (string npart, string steps, string mass, int randval)
{
# mdviz  @out @traj 3 npart steps 50 ".0001" mass "0.1 1.0 0.2 0.05 50.0 0.1" 2.5 2.0 randomInt();
  md     3 npart steps 10 ".0001" mass "0.1 1.0 0.2 0.05 50.0 0.1" 2.5 2.0 randval @out @traj;
}

app (file out) genconfig ()
{
  simulate "-n" 1 "-r" 1000000 stdout=filename(out);
}

app (file o) analyze (file s[])
{
  mdstats filenames(s) stdout=filename(o);
}

app (file o) maxkinetic (file s[])
{
  mdmaxk "3" filenames(s) stdout=filename(o);
}

app (file o) convert (file s[])
{
  convert filenames(s) filename(o);
}

int    nsim  = toInt(arg("nsim","10"));
string npart = arg("npart","50");
string steps = arg("steps","1000");
string mass  = arg("mass",".005");

file sim[] <simple_mapper; prefix="output/sim_", suffix=".out">;
file trj[] <simple_mapper; prefix="output/sim_", suffix=".trj.tgz">;

foreach i in [0:nsim-1] {
  int startstate = readData(genconfig());
  (sim[i],trj[i]) = simulation(npart,steps,mass,startstate);
}

file stats_out<"output/average.out">;
stats_out = analyze(sim);

#file viz_all<"output/all.gif">;
#viz_all = convert(gifs);
