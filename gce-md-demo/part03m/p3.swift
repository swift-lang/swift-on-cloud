type file;

/*
    md nd np step_num print_step_num dt mass printinfo scale_factor scale_offset
    where
    * nd is the spatial dimension (2 or 3);
    * np is the number of particles (500, for instance);
    * step_num is the number of time steps (500, for instance);
    * print_step_num is the number of snapshot prints (10 for instance);
    * dt is size of timestep;
    * mass is particle mass;
    * printinfo is a string to append to each particle coord
    * scale_offset and scale_factor are used to scale particle positions for logging/rendering (FIXME)

    e.g.:

    md 3 50 30000 50  .0001  .005  "0.03 1.0 0.2 0.05 50.0 0.1" 2.5 2.0
*/

app (file o) simulation (string npart, string steps, string mass)
{
  sh "-c" strjoin(["md","3",npart,steps,">/dev/null; cat md.dat"]," ") stdout=filename(o);
}

app (file o) analyze (file s[])
{
  mdstats filenames(s) stdout=filename(o);
}

int    nsim   = toInt(arg("nsim","10"));
string npart  = arg("npart","50");
string steps  = arg("steps","1000");
string mass   = arg("mass",".0001");

file sims[];

foreach i in [0:nsim-1] {
  file simout <single_file_mapper; file=strcat("output/sim_",i,".out")>;
  simout = simulation(npart,steps,mass);
  sims[i] = simout;
}

file stats<"output/average.out">;
stats = analyze(sims);
