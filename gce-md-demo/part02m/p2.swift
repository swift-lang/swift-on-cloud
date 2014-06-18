type file;

app (file o) simulation ()
{
  sh "-c" "md 3 50 1000 >/dev/null; cat md.dat" stdout=filename(o);
}

foreach i in [0:9] {
  file f <single_file_mapper; file=strcat("output/sim_",i,".out")>;
  f = simulation();
}
