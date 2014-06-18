type file;

app (file o) simulation ()
{
  md 3 50 1000 stdout=filename(o);
}

file f <"sim.out">;
f = simulation();
