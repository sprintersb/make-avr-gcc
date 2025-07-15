digraph
{
    label = "Dependency Tree for Native Cross Compiler\nand Canadian Cross Compiler Generation"
    labelloc = top;

    newrank = true;
    rankdir = TB;

    node [style="filled"; fillcolor="white"];

include(`cluster-host.h')
include(`cluster-canadian.h')

}
