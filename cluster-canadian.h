    subgraph cluster_canadian
    {
        label = "Canadian Cross";
        bgcolor = "#fff8f8";

        subgraph cluster_binW
        {
            label = "Binutils Win";
            bgcolor = "white";
            binW_i [label="install"; fillcolor="#ffddcc"];
            binW_m[label="make"; fillcolor="#ffddcc"];
            binW_c[label="conf"; fillcolor="#ffddcc"];
            binW_s[label="src"];
            binW_i -> binW_m -> binW_c -> binW_s;
        }

        subgraph cluster_gccW
        {
            label = "GCC Win";
            bgcolor = "white";
            gccW_ih [label="install\n-host"; fillcolor="#ffddcc"];
            gccW_it [label="install\n-target"; fillcolor="#ffddcc"];
            gcc_m_x [label="GCC\nmake", fillcolor="#ddddff"];
            libc_i_x [label="LibC\ninstall", fillcolor="#ddddff"];
            gccW_m[label="make\nall-host"; fillcolor="#ffddcc"];
            gccW_c[label="conf"; fillcolor="#ffddcc"];
            gccW_s[label="src"];
            gccW_ih -> gccW_m -> gccW_c -> gccW_s;
        }

        { rank=same; binW_i; gccW_ih; gccW_it; libcW_i; }

        gccW_c -> binW_i;
        gccW_c -> libc_i_x;
        gccW_it -> gcc_m_x;

        subgraph cluster_libcW
        {
            label = "LibC Win";
            bgcolor = "white";
            libcW_i [label="install"; fillcolor="#ffddcc"];
            libc_m_x [label="LibC\nmake", fillcolor="#ddddff"];
        }
    }
    libcW_i -> libc_m_x;
