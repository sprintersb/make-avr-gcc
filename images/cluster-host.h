    subgraph cluster_host
    {
        label = "Native Cross";
        bgcolor = "#f4f4ff";

        subgraph cluster_bin
        {
            label = "Binutils";
            bgcolor = "white";
            bin_i [label="install", fillcolor="#ddddff"];
            bin_m[label="make", fillcolor="#ddddff"];
            bin_c[label="conf", fillcolor="#ddddff"];
            bin_s[label="src"];
            bin_i -> bin_m -> bin_c -> bin_s;
        }

        subgraph cluster_gcc
        {
            label = "GCC";
            bgcolor = "white";
            gcc_i [label="install", fillcolor="#ddddff"];
            gcc_m[label="make", fillcolor="#ddddff"];
            gcc_c[label="conf", fillcolor="#ddddff"];
            gcc_s[label="src"];
            gcc_i -> gcc_m -> gcc_c -> gcc_s;
        }

        subgraph cluster_libc
        {
            label = "LibC";
            bgcolor = "white";
            libc_i [label="install", fillcolor="#ddddff"];
            libc_m[label="make", fillcolor="#ddddff"];
            libc_c[label="conf", fillcolor="#ddddff"];
            libc_s[label="src"];
            libc_i -> libc_m -> libc_c -> libc_s;
        }

        { rank=same; bin_i; gcc_i; libc_i; }
    }
    gcc_c -> bin_i;
    libc_c -> gcc_i;
