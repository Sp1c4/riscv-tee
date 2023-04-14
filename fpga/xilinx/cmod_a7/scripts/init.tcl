set prj_name {tinyriscv}
set part_fpga {xc7a15tcpg236-1}
set top_module {tinyriscv_soc_top}

set scriptsdir ./scripts
set constrsdir ./constrs
set outdir ./out
set srcdir ../../../rtl

# 在某目录下递归查找所有指定文件
proc rec_glob { basedir pattern } {
    set dirlist [glob -nocomplain -directory $basedir -type d *]
    set findlist [glob -nocomplain -directory $basedir $pattern]
    foreach dir $dirlist {
        set reclist [rec_glob $dir $pattern]
        set findlist [concat $findlist $reclist]
    }
    return $findlist
}

# 创建工程(内存模式)
create_project -part $part_fpga -in_memory

# 创建sources_1
if {[get_filesets -quiet sources_1] eq ""} {
    create_fileset -srcset sources_1
}
set src_pkg_files [rec_glob $srcdir "*pkg.sv"]
set src_verilog_files [rec_glob $srcdir "*.sv"]
set src_all_files [concat $src_pkg_files $src_verilog_files]
# 添加verilog文件
add_files -norecurse -fileset sources_1 $src_all_files
add_files -norecurse -fileset sources_1 ./tinyriscv_soc_top.sv

# 创建constrs_1
if {[get_filesets -quiet constrs_1] eq ""} {
    create_fileset -constrset constrs_1
}
# 添加约束文件
add_files -norecurse -fileset constrs_1 [glob -directory $constrsdir {*.xdc}]

# 创建输出目录
file mkdir $outdir
