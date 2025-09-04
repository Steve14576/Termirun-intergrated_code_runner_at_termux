#!/data/data/com.termux/files/usr/bin/bash

# 基础配置与常量定义
VERSION="1.9.0"
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
INSTANCE_ID=$(basename "$SCRIPT_DIR")
INSTANCE_CONFIG_ROOT="$HOME/.termirun_instances"
INSTANCE_CONFIG_DIR="$INSTANCE_CONFIG_ROOT/$INSTANCE_ID"
COMPILE_CONFIG=".termirun_compile_config"
SOURCE_CONFIG=".termirun_source_config"
LAST_COMMAND_FILE="$INSTANCE_CONFIG_DIR/last_command"  # 新增：存储上一条命令
TAG_FILE="$INSTANCE_CONFIG_DIR/tag"  # 新增：标签文件

# 编译产物子目录结构定义
COMPILE_SUB_DIR="comps"
C_BIN_DIR="c_bin"
CPP_BIN_DIR="cpp_bin"
JAVA_BIN_DIR="java_bin"
PYTHON_BIN_DIR="python_bin"
FORTRAN_BIN_DIR="fortran_bin"
R_BIN_DIR="r_bin"

# 演示文件名称
DEMO_C="termirun_demo_c.c"
DEMO_CPP="termirun_demo_cpp.cpp"
DEMO_JAVA="termirun_demo_java.java"
DEMO_PYTHON="termirun_demo_python.py"
DEMO_FORTRAN="termirun_demo_fortran.f90"
DEMO_R="termirun_demo_r.r"

# 所有演示文件列表
ALL_DEMOS=("$DEMO_C" "$DEMO_CPP" "$DEMO_JAVA" "$DEMO_PYTHON" "$DEMO_FORTRAN" "$DEMO_R")

mkdir -p "$INSTANCE_CONFIG_DIR"

# 新增：标签初始化函数
initialize_tag() {
    if [ ! -f "$TAG_FILE" ]; then
        echo "=== 实例标签设置 ==="
        read -p "请为当前termirun实例设置一个标签（用于区分不同实例，直接回车留空）: " initial_tag
        if [ -n "$initial_tag" ]; then
            echo "$initial_tag" > "$TAG_FILE"
            echo "✅ 已设置初始标签: $initial_tag"
        else
            touch "$TAG_FILE"  # 创建空标签文件
            echo "ℹ️ 未设置标签，可通过 'termirun tag' 命令管理"
        fi
    fi
}

# 执行标签初始化
initialize_tag

# 确保$HOME/bin在环境变量PATH中
ensure_path() {
    if ! echo "$PATH" | grep -q "$HOME/bin/bin"; then
        export PATH="$PATH:$HOME/bin"
    fi
}

# 目录树展示函数
display_directory_tree() {
    local target_dir=$1
    local root_name=$2
    
    if [ ! -d "$target_dir" ]; then
        echo "❌ 目录不存在: $target_dir"
        return 1
    fi
    
    echo "📂 $root_name 目录: $target_dir"
    echo "----------------------------------------"
    # 使用tree命令展示目录结构，若没有tree则使用find命令
    if command -v tree &>/dev/null; then
        tree -f -n "$target_dir"
    else
        find "$target_dir" -print
    fi
    echo "----------------------------------------"
}

# ls命令处理函数
handle_ls_command() {
    echo "=== termirun 文件浏览 ==="
    echo "请选择要查看的目录类型:"
    echo "  carrot - 查看源代码目录及其文件"
    echo "  bins   - 查看编译产物目录及其文件"
    echo "  all    - 同时查看上述两个目录及其文件"
    echo "  q      - 退出浏览"
    read -p "请输入选项: " choice
    
    # 处理退出条件
    if [ -z "$choice" ] || [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
        echo "已退出文件浏览"
        return 0
    fi
    
    # 查看源代码目录
    if [ "$choice" = "carrot" ] || [ "$choice" = "all" ]; then
        local source_dir=$(head -n1 "$SOURCE_CONFIG" 2>/dev/null)
        if [ -z "$source_dir" ] || [ ! -d "$source_dir" ]; then
            source_dir=$(pwd)
            echo "⚠️ 未设置源代码目录，使用当前目录: $source_dir"
        fi
        display_directory_tree "$source_dir" "源代码"
    fi
    
    # 查看编译产物目录
    if [ "$choice" = "bins" ] || [ "$choice" = "all" ]; then
        local base_dir=$(cat "$COMPILE_CONFIG" 2>/dev/null)
        if [ -z "$base_dir" ] || [ ! -d "$base_dir" ]; then
            echo "❌ 未设置编译产物目录，请先运行 'termirun bins'"
            if [ "$choice" = "bins" ]; then
                return 1
            fi
        else
            local comps_dir="$base_dir/$COMPILE_SUB_DIR"
            display_directory_tree "$comps_dir" "编译产物"
        fi
    fi
    
    # 处理无效选项
    if [ "$choice" != "carrot" ] && [ "$choice" != "bins" ] && [ "$choice" != "all" ]; then
        echo "❌ 无效选项，已退出文件浏览"
    fi
}

# 1. 版本信息显示
show_version() {
    echo "termirun $VERSION"
    echo "实例ID: $INSTANCE_ID"
    # 新增：显示标签信息
    local current_tag=$(cat "$TAG_FILE" 2>/dev/null)
    if [ -n "$current_tag" ]; then
        echo "实例标签: $current_tag"
    else
        echo "实例标签: 未设置"
    fi
    echo "脚本路径: $SCRIPT_PATH"
}

# 2. 帮助信息显示
show_help() {
    # 版本信息
    echo "=== termirun 多语言编译运行运行工具 ==="
    echo "版本: $VERSION (实例ID: $INSTANCE_ID)"
    
    # 项目GitHub地址
    echo "GitHub: XXX"
    
    # 当前termirun脚本的文件路径
    echo "脚本路径: $SCRIPT_PATH"
    
    # carrot命令指定的源文件路径
    echo -n "carrot源文件路径: "
    if [ -f "$SOURCE_CONFIG" ]; then
        local source_dir=$(head -n1 "$SOURCE_CONFIG" 2>/dev/null)
        local recursive_flag=$(tail -n1 "$SOURCE_CONFIG" 2>/dev/null || echo 1)
        echo "$source_dir (递归搜索: $( [ "$recursive_flag" = "1" ] && echo "启用" || echo "禁用" ))"
    else
        echo "未设置（使用当前目录）"
    fi
    
    # bins命令编译产物路径
    echo -n "bins编译产物路径: "
    if [ -f "$COMPILE_CONFIG" ]; then
        local base_dir=$(cat "$COMPILE_CONFIG")
        local full_dir="$base_dir/$COMPILE_SUB_DIR"
        echo "$full_dir"
    else
        echo "未设置（请运行 'termirun bins' 配置）"
    fi
    
    # 是否有demo文件以及demo文件的路径
    echo "演示文件信息:"
    local source_dir=$(head -n1 "$SOURCE_CONFIG" 2>/dev/null)
    if [ -z "$source_dir" ] || [ ! -d "$source_dir" ]; then
        echo "  未设置有效的有效的源代码目录，无法检查演示文件"
    else
        local demo_count=0
        local demo_list=""
        for file in "${ALL_DEMOS[@]}"; do
            if [ -f "$source_dir/$file" ]; then
                ((demo_count++))
                demo_list="$demo_list $file"
            fi
        done
        if [ $demo_count -eq 6 ]; then
            echo "  所有6个演示文件均已存在于: $source_dir"
            echo "  文件列表:$demo_list"
        else
            echo "  存在 $demo_count/6 个演示文件于: $source_dir"
            if [ $demo_count -gt 0 ]; then
                echo "  已存在文件:$demo_list"
            fi
            echo "  提示: 运行 'termirun demo' 可管理演示文件"
        fi
    fi
    
    # 支持的文件类型
    echo "支持 .c (C), .cpp (C++), .java (Java), .py (Python), .f90 (Fortran), .r (R) 文件"
    echo


    echo "核心命令:"
    echo "  termirun tag        - 管理当前实例的标签（查看/修改/删除）"  # 新增tag命令说明
    echo "  termirun bins       - 设置编译产物产物存放目录"
    echo "  termirun carrot     - 设置源代码文件存放目录（支持递归搜索子目录）"
    echo "  termirun cucumber <文件名>   - 详细模式运行（使用carrot配置目录）"
    echo "  termirun cucumber t <文件路径> - 详细模式临时运行（指定任意路径文件）"
    echo "  termirun cub <文件名>        - 简洁模式运行（使用carrot配置目录）"
    echo "  termirun cub t <文件路径>     - 简洁模式临时运行（指定定任意路径文件）"
    echo "  termirun compilers  - 检查并安装所需编译器"
    echo "  termirun clean      - 手动清理所有失效编译产物"
    echo "  termirun uninstall  - 彻底卸载当前实例（含配置和编译产物）"
    echo "  termirun uninit     - 反初始化（清理当前实例内部配置，保留编译产物）"
    echo "  termirun help       - 显示本帮助信息"
    echo "  termirun --version  - 显示版本信息"
    echo "  termirun go50       - 进入快速模式（每次可以50次无前缀调用cub/cucumber/oo/kk）"
    echo "  termirun ls         - 浏览源代码或编译产物目录结构"
    echo "  termirun demo       - 管理各语言演示文件（清空/重置）"
    echo "  termirun oo         - 显示上一个cucumber或cub命令"
    echo "  termirun kk         - 执行上一个cucumber或cub命令"
    echo
    
  
    echo "使用提示:"

    echo "  0. 建议搭配Termux，MT管理器，Acode，Acodex-Terminal使用"
    echo "  1. 复制实例后运行 'uninit' 可恢复至初始状态"
    echo "  2. 不同实例需放在不同目录以避免冲突"
    echo "  3. 支持 .c (C), .cpp (C++), .java (Java), .py (Python), .f90 (Fortran), .r (R) 文件"
    echo "  4. 临时模式(t)可直接运行任意路径文件，不改变carrot配置"
    echo "  5. 设置carrot时可启用递归搜索，自动查找子目录中的源文件"
    echo "  6. 在go50模式中，可直接使用oo查看上一条命令，kk执行上一条命令"
    echo "  7. 传播或复用termirun, 直接复制粘贴即可"
}

# 3. 编译器环境检查与安装
check_compilers() {
    echo "=== 编译器环境检查 ==="
    local all_installed=1

    if command -v clang &>/dev/null; then
        echo "✅ C/C++ 编译器: clang 已安装"
        echo "   版本: $(clang --version | head -n1 | awk '{print $3}')"
    else
        echo "❌ C/C++ 编译器: clang 未安装"
        all_installed=0
    fi

    if command -v javac &>/dev/null; then
        echo "✅ Java 编译器: javac 已安装"
        echo "   版本: $(javac -version 2>&1 | head -n1 | awk '{print $2}')"
    else
        echo "❌ Java 编译器: javac 未安装"
        all_installed=0
    fi

    if command -v java &>/dev/null; then
        echo "✅ Java 运行环境: java 已安装"
        echo "   版本: $(java -version 2>&1 | head -n1 | awk -F'"' '{print $2}')"
    else
        echo "❌ Java 运行环境: java 未安装"
        all_installed=0
    fi

    # Python3 检查
    if command -v python3 &>/dev/null; then
        echo "✅ Python 解释器: python3 已安装"
        echo "   版本: $(python3 --version 2>&1 | awk '{print $2}')"
    else
        echo "❌ Python 解释器: python3 未安装"
        all_installed=0
    fi

    # Fortran 检查
    if command -v gfortran &>/dev/null; then
        echo "✅ Fortran 编译器: gfortran 已安装"
        echo "   版本: $(gfortran --version | head -n1 | awk '{print $4}')"
    else
        echo "❌ Fortran 编译器: gfortran 未安装"
        all_installed=0
    fi

    # R 语言检查
    if command -v R &>/dev/null; then
        echo "✅ R 语言环境: R 已安装"
        echo "   版本: $(R --version | head -n1 | awk '{print $3}')"
    else
        echo "❌ R 语言环境: R 未安装"
        all_installed=0
    fi

    if [ $all_installed -eq 1 ]; then
        echo "🎉 所有必要的编译器均已就绪"
    else
        echo
        read -p "是否立即立即立即安装所有缺失的编译器？(y/N/q退出) " install_confirm
        if [ "$install_confirm" = "q" ] || [ "$install_confirm" = "Q" ]; then
            echo "已退出编译器安装流程"
            return 0
        fi
        
        if [ "$install_confirm" = "y" ] || [ "$install_confirm" = "Y" ]; then
            echo "正在更新软件源..."
            apt update -y >/dev/null 2>&1
            
            if ! command -v clang &>/dev/null; then
                echo "正在安装clang..."
                apt install clang -y >/dev/null 2>&1
            fi
            
            if ! command -v javac &>/dev/null || ! command -v java &>/dev/null; then
                echo "正在安装openjdk-17..."
                apt install openjdk-17 -y >/dev/null 2>&1
            fi

            if ! command -v python3 &>/dev/null; then
                echo "正在安装python3..."
                apt install python3 -y >/dev/null 2>&1
            fi

            if ! command -v gfortran &>/dev/null; then
                echo "正在安装gfortran..."
                apt install gfortran -y >/dev/null 2>&1
            fi

            if ! command -v R &>/dev/null; then
                echo "正在安装R..."
                apt install r-base -y >/dev/null 2>&1
            fi
            
            echo "✅ 所有缺失组件安装完成"
        else
            echo "⚠️ 请手动安装缺失组件后再使用"
        fi
    fi
}

# 4. 获取不冲突的编译目录名
get_safe_compile_dir() {
    local base_name="termirun_comps"
    
    # 使用$RANDOM生成5位数字随机数（00000-32767）
    # 格式化为5位数字，不足补前导零
    RANDOM_NUM=$(printf "%05d" $RANDOM)
    
    echo "${base_name}_${RANDOM_NUM}"
}

# 5. 设置编译产物目录
set_compile_path() {
    local old_base_dir=""
    local old_full_dir=""
    
    if [ -f "$COMPILE_CONFIG" ]; then
        old_base_dir=$(cat "$COMPILE_CONFIG")
        old_full_dir="$old_base_dir/$COMPILE_SUB_DIR"
        echo "当前编译产物基础目录: $old_base_dir"
        echo "实际产物存放目录: $old_full_dir"
    else
        echo "尚未设置编译产物目录"
    fi

    read -p "是否要设置新的编译产物基础目录？(Y/n/q退出) " confirm
    if [ "$confirm" = "q" ] || [ "$confirm" = "Q" ]; then
        echo "已退出目录设置流程"
        return 0
    fi
    if [ "$confirm" != "Y" ] && [ "$confirm" != "y" ]; then
        echo "已取消设置"
        return 0
    fi

    read -p "请输入新的基础目录路径（直接回车跳过设置/q退出）: " user_path
    if [ "$user_path" = "q" ] || [ "$user_path" = "Q" ]; then
        echo "已退出目录设置流程"
        return 0
    fi
    
    if [ -n "$user_path" ]; then
        local new_base_dir="$user_path"
        local new_full_dir="$new_base_dir/$COMPILE_SUB_DIR"
        
        # 处理旧目录
        if [ -n "$old_base_dir" ] && [ -d "$old_full_dir" ]; then
            read -p "检测到旧编译目录 $old_full_dir，是否删除？(y/N/q退出) " delete_old
            if [ "$delete_old" = "q" ] || [ "$delete_old" = "Q" ]; then
                echo "已退出目录设置流程"
                return 0
            fi
            
            if [ "$delete_old" = "y" ] || [ "$delete_old" = "Y" ]; then
                rm -rf "$old_full_dir"
                echo "🗑️ 已删除旧编译目录: $old_full_dir"
            else
                echo "⚠️ 保留旧编译目录: $old_full_dir"
            fi
        fi

        # 创建新目录结构（包含新增语言）
        mkdir -p "$new_full_dir/$C_BIN_DIR" \
                 "$new_full_dir/$CPP_BIN_DIR" \
                 "$new_full_dir/$JAVA_BIN_DIR" \
                 "$new_full_dir/$PYTHON_BIN_DIR" \
                 "$new_full_dir/$FORTRAN_BIN_DIR" \
                 "$new_full_dir/$R_BIN_DIR"

        # 保存基础目录
        echo "$new_base_dir" > "$COMPILE_CONFIG"
        echo "✅ 编译产物基础目录已更新为: $new_base_dir"
        echo "✅ 实际产物存放目录: $new_full_dir"
        echo "  - C产物: $new_full_dir/$C_BIN_DIR"
        echo "  - C++产物: $new_full_dir/$CPP_BIN_DIR"
        echo "  - Java产物: $new_full_dir/$JAVA_BIN_DIR"
        echo "  - Python产物: $new_full_dir/$PYTHON_BIN_DIR"
        echo "  - Fortran产物: $new_full_dir/$FORTRAN_BIN_DIR"
        echo "  - R产物: $new_full_dir/$R_BIN_DIR"

        # 不再在设置编译目录时自动生成demo文件
    else
        # 使用自动生成的带5位数字随机数的目录名
        local auto_dir=$(get_safe_compile_dir)
        local new_base_dir="$auto_dir"
        local new_full_dir="$new_base_dir/$COMPILE_SUB_DIR"
        
        # 处理旧目录
        if [ -n "$old_base_dir" ] && [ -d "$old_full_dir" ]; then
            read -p "检测到旧编译目录 $old_full_dir，是否删除？(y/N/q退出) " delete_old
            if [ "$delete_old" = "q" ] || [ "$delete_old" = "Q" ]; then
                echo "已退出目录设置流程"
                return 0
            fi
            
            if [ "$delete_old" = "y" ] || [ "$delete_old" = "Y" ]; then
                rm -rf "$old_full_dir"
                echo "🗑️ 已删除旧编译目录: $old_full_dir"
            else
                echo "⚠️ 保留旧编译目录: $old_full_dir"
            fi
        fi

        # 创建新目录结构
        mkdir -p "$new_full_dir/$C_BIN_DIR" \
                 "$new_full_dir/$CPP_BIN_DIR" \
                 "$new_full_dir/$JAVA_BIN_DIR" \
                 "$new_full_dir/$PYTHON_BIN_DIR" \
                 "$new_full_dir/$FORTRAN_BIN_DIR" \
                 "$new_full_dir/$R_BIN_DIR"

        # 保存基础目录
        echo "$new_base_dir" > "$COMPILE_CONFIG"
        echo "✅ 已自动创建编译产物基础目录: $new_base_dir"
        echo "✅ 实际产物存放目录: $new_full_dir"
        echo "  - C产物: $new_full_dir/$C_BIN_DIR"
        echo "  - C++产物: $new_full_dir/$CPP_BIN_DIR"
        echo "  - Java产物: $new_full_dir/$JAVA_BIN_DIR"
        echo "  - Python产物: $new_full_dir/$PYTHON_BIN_DIR"
        echo "  - Fortran产物: $new_full_dir/$FORTRAN_BIN_DIR"
        echo "  - R产物: $new_full_dir/$R_BIN_DIR"

        # 不再在设置编译目录时自动生成demo文件
    fi
}

# 递归查找源文件（返回完整路径）
find_source_file() {
    local root_dir=$1
    local target_name=$2
    local recursive_flag=$3

    if [ "$recursive_flag" -eq 1 ]; then
        # 递归搜索根目录下所有子文件夹
        local found_paths=$(find "$root_dir" -type f -name "$target_name")
    else
        # 仅搜索根目录本级
        local found_paths=$(find "$root_dir" -maxdepth 1 -type f -name "$target_name")
    fi

    # 处理查找结果（去重）
    local unique_paths=$(echo "$found_paths" | sort -u)
    local path_count=$(echo "$unique_paths" | wc -l | tr -d ' ')

    if [ "$path_count" -eq 0 ]; then
        echo ""  # 未找到
    elif [ "$path_count" -eq 1 ]; then
        echo "$unique_paths"  # 唯一结果
    else
        # 存在多个同名文件，提示用户选择
        echo "⚠️ 找到多个同名文件："
        echo "$unique_paths" | nl  # 编号显示
        read -p "请输入要使用的文件编号 (1-$path_count): " selected_num
        echo "$unique_paths" | sed -n "${selected_num}p"  # 返回选中的路径
    fi
}

# 6. 设置源代码目录（carrot命令，支持递归搜索）
set_source_path() {
    local old_source_dir=""
    local old_recursive_flag=""
    
    # 读取旧配置
    if [ -f "$SOURCE_CONFIG" ]; then
        old_source_dir=$(head -n1 "$SOURCE_CONFIG" 2>/dev/null)
        old_recursive_flag=$(tail -n1 "$SOURCE_CONFIG" 2>/dev/null)
        echo "当前源代码根目录: $old_source_dir"
        echo "当前递归搜索模式: $( [ "$old_recursive_flag" = "1" ] && echo "启用" || echo "禁用" )"
    else
        echo "尚未设置源代码目录"
    fi

    read -p "是否要设置新的源代码根目录？(Y/n/q退出) " confirm
    if [ "$confirm" = "q" ] || [ "$confirm" = "Q" ]; then
        echo "已退出目录设置流程"
        return 0
    fi
    if [ "$confirm" != "Y" ] && [ "$confirm" != "y" ]; then
        echo "已取消设置"
        return 0
    fi

    # 询问用户是否已准备好目录或需要自动创建
    echo "请选择目录设置方式:"
    echo "  1 - 手动输入已准备好的目录路径"
    echo "  2 - 还没准备好，让系统自动创建一个（推荐安卓用户）"
    read -p "请输入选项 (1/2): " dir_choice

    local new_source_dir=""
    
    if [ "$dir_choice" = "1" ]; then
        # 用户手动输入目录
        read -p "请输入新的源代码根目录路径（直接回车使用当前目录/q退出）: " user_path
        if [ "$user_path" = "q" ] || [ "$user_path" = "Q" ]; then
            echo "已退出目录设置流程"
            return 0
        fi
        
        if [ -n "$user_path" ]; then
            new_source_dir="$user_path"
        else
            new_source_dir=$(pwd)
        fi
    elif [ "$dir_choice" = "2" ]; then
        # 系统自动创建目录，使用5位数字随机数后缀防重名
        local base_path="storage/emulated/0/TermirunDefaultCarrots"
        
        # 使用$RANDOM生成5位数字随机数
        RANDOM_NUM=$(printf "%05d" $RANDOM)
        new_source_dir="${base_path}_${RANDOM_NUM}"
        
        # 创建目录
        if mkdir -p "$new_source_dir"; then
            echo "✅ 已自动创建目录: $new_source_dir"
        else
            echo "❌ 创建目录失败，可能是权限不足"
            echo "请手动输入一个目录"
            # 手动输入处理（与选项1逻辑一致）
            read -p "请输入新的源代码根目录路径（直接回车使用当前目录/q退出）: " user_path
            if [ "$user_path" = "q" ] || [ "$user_path" = "Q" ]; then
                echo "已退出目录设置流程"
                return 0
            fi
            
            if [ -n "$user_path" ]; then
                new_source_dir="$user_path"
            else
                new_source_dir=$(pwd)
            fi
        fi
    else
        echo "❌ 无效选项，使用当前目录作为默认值"
        new_source_dir=$(pwd)
    fi

    # 验证并创建目录（如果不存在）
    if [ ! -d "$new_source_dir" ]; then
        if mkdir -p "$new_source_dir"; then
            echo "✅ 已创建目录: $new_source_dir"
        else
            echo "❌ 无法创建目录，请检查权限"
            return 1
        fi
    fi

    # 询问是否启用递归搜索子目录
    read -p "是否启用子目录递归搜索？(默认Y，输入n禁用): " recursive_confirm
    local recursive_flag=1  # 默认启用递归
    if [ "$recursive_confirm" = "n" ] || [ "$recursive_confirm" = "N" ]; then
        recursive_flag=0
    fi

    # 保存配置（第一行：根目录；第二行：递归标记）
    echo "$new_source_dir" > "$SOURCE_CONFIG"
    echo "$recursive_flag" >> "$SOURCE_CONFIG"
    echo "✅ 源代码根目录已设置为: $new_source_dir"
    echo "✅ 子目录递归搜索: $( [ "$recursive_flag" = "1" ] && echo "启用" || echo "禁用" )"
    echo "   （启用时会搜索所有子文件夹中的 .c/.cpp/.java/.py/.f90/.r 文件）"
}

# 7. 生成演示文件（包含新增语言）
generate_demo_files() {
    # 获取源代码目录（严格使用carrot配置）
    local source_dir=$(head -n1 "$SOURCE_CONFIG" 2>/dev/null)
    if [ -z "$source_dir" ] || [ ! -d "$source_dir" ]; then
        echo "❌ 未设置有效的源代码目录，请先运行 'termirun carrot' 配置"
        return 1
    fi

    # C演示文件
    cat > "$source_dir/$DEMO_C" << 'EOF'
#include <stdio.h>
int main() {
    printf("🎉 C程序运行成功！\n");
    printf("这是termirun的C演示文件\n");
    printf("尝试命令:\n");
    printf("  termirun cucumber termirun_demo_c.c (详细模式)\n");
    printf("  termirun cub termirun_demo_c.c (简洁模式)\n");
    return 0;
}
EOF
    echo "📝 已生成C演示文件: $source_dir/$DEMO_C"

    # C++演示文件
    cat > "$source_dir/$DEMO_CPP" << 'EOF'
#include <iostream>
using namespace std;

int main() {
    cout << "🎉 C++程序运行成功！" << endl;
    cout << "这是termirun的C++演示文件" << endl;
    cout << "尝试命令:" << endl;
    cout << "  termirun cucumber termirun_demo_cpp.cpp (详细模式)" << endl;
    cout << "  termirun cub termirun_demo_cpp.cpp (简洁模式)" << endl;
    return 0;
}
EOF
    echo "📝 已生成C++演示文件: $source_dir/$DEMO_CPP"

    # Java演示文件
    cat > "$source_dir/$DEMO_JAVA" << 'EOF'
public class termirun_demo_java {
    public static void main(String[] args) {
        System.out.println("🎉 Java程序运行成功！");
        System.out.println("这是termirun的Java演示文件");
        System.out.println("尝试命令:");
        System.out.println("  termirun cucumber termirun_demo_java.java (详细模式)");
        System.out.println("  termirun cub termirun_demo_java.java (简洁模式)");
    }
}
EOF
    echo "📝 已生成Java演示文件: $source_dir/$DEMO_JAVA"

    # Python演示文件
    cat > "$source_dir/$DEMO_PYTHON" << 'EOF'
print("🎉 Python程序运行成功！")
print("这是termirun的Python演示文件")
print("尝试命令:")
print("  termirun cucumber termirun_demo_python.py (详细模式)")
print("  termirun cub termirun_demo_python.py (简洁模式)")
EOF
    echo "📝 已生成Python演示文件: $source_dir/$DEMO_PYTHON"

    # Fortran演示文件
    cat > "$source_dir/$DEMO_FORTRAN" << 'EOF'
program termirun_demo_fortran
    print *, "🎉 Fortran程序运行成功！"
    print *, "这是termirun的Fortran演示文件"
    print *, "尝试命令:"
    print *, "  termirun cucumber termirun_demo_fortran.f90 (详细模式)"
    print *, "  termirun cub termirun_demo_fortran.f90 (简洁模式)"
end program termirun_demo_fortran
EOF
    echo "📝 已生成Fortran演示文件: $source_dir/$DEMO_FORTRAN"

    # R演示文件
    cat > "$source_dir/$DEMO_R" << 'EOF'
cat("🎉 R程序运行成功！\n")
cat("这是termirun的R演示文件\n")
cat("尝试命令:\n")
cat("  termirun cucumber termirun_demo_r.r (详细模式)\n")
cat("  termirun cub termirun_demo_r.r (简洁模式)\n")
EOF
    echo "📝 已生成R演示文件: $source_dir/$DEMO_R"
}

# 8. 自动清理无效编译产物（包含新增语言）
clean_invalid_products() {
    local base_dir=$(cat "$COMPILE_CONFIG" 2>/dev/null)
    
    if [ -z "$base_dir" ] || [ ! -d "$base_dir" ]; then
        return 0
    fi

    # 完整产物目录路径
    local full_dir="$base_dir/$COMPILE_SUB_DIR"
    local c_bin_dir="$full_dir/$C_BIN_DIR"
    local cpp_bin_dir="$full_dir/$CPP_BIN_DIR"
    local java_bin_dir="$full_dir/$JAVA_BIN_DIR"
    local python_bin_dir="$full_dir/$PYTHON_BIN_DIR"
    local fortran_bin_dir="$full_dir/$FORTRAN_BIN_DIR"
    local r_bin_dir="$full_dir/$R_BIN_DIR"

    # 获取源代码目录
    local source_dir=$(head -n1 "$SOURCE_CONFIG" 2>/dev/null)
    local recursive_flag=$(tail -n1 "$SOURCE_CONFIG" 2>/dev/null || echo 1)
    if [ -z "$source_dir" ] || [ ! -d "$source_dir" ]; then
        source_dir=$(pwd)
    fi

    # 清理C产物
    if [ -d "$c_bin_dir" ]; then
        for exe in "$c_bin_dir"/*_c; do
            [ -f "$exe" ] || continue
            local base=$(basename "$exe" "_c")
            local src=$(find_source_file "$source_dir" "$base.c" "$recursive_flag")
            if [ -z "$src" ] || [ ! -f "$src" ]; then
                rm -f "$exe"
                echo "🗑️ 清理无效C产物: $exe" >&2
            fi
        done
    fi

    # 清理C++产物
    if [ -d "$cpp_bin_dir" ]; then
        for exe in "$cpp_bin_dir"/*_cpp; do
            [ -f "$exe" ] || continue
            local base=$(basename "$exe" "_cpp")
            local src=$(find_source_file "$source_dir" "$base.cpp" "$recursive_flag")
            if [ -z "$src" ] || [ ! -f "$src" ]; then
                rm -f "$exe"
                echo "🗑️ 清理无效C++产物: $exe" >&2
            fi
        done
    fi

    # 清理Java产物
    if [ -d "$java_bin_dir" ]; then
        for class_file in "$java_bin_dir"/*.class; do
            [ -f "$class_file" ] || continue
            local base=$(basename "$class_file" ".class")
            local src=$(find_source_file "$source_dir" "$base.java" "$recursive_flag")
            if [ -z "$src" ] || [ ! -f "$src" ]; then
                rm -f "$class_file"
                echo "🗑️ 清理无效Java产物: $class_file" >&2
            fi
        done
    fi

    # 清理Python产物
    if [ -d "$python_bin_dir" ]; then
        for script in "$python_bin_dir"/*.py; do
            [ -f "$script" ] || continue
            local base=$(basename "$script")
            local src=$(find_source_file "$source_dir" "$base" "$recursive_flag")
            if [ -z "$src" ] || [ ! -f "$src" ]; then
                rm -f "$script"
                echo "🗑️ 清理无效Python产物: $script" >&2
            fi
        done
    fi

    # 清理Fortran产物
    if [ -d "$fortran_bin_dir" ]; then
        for exe in "$fortran_bin_dir"/*_fortran; do
            [ -f "$exe" ] || continue
            local base=$(basename "$exe" "_fortran")
            local src=$(find_source_file "$source_dir" "$base.f90" "$recursive_flag")
            if [ -z "$src" ] || [ ! -f "$src" ]; then
                rm -f "$exe"
                echo "🗑️ 清理无效Fortran产物: $exe" >&2
            fi
        done
    fi

    # 清理R产物
    if [ -d "$r_bin_dir" ]; then
        for script in "$r_bin_dir"/*.r; do
            [ -f "$script" ] || continue
            local base=$(basename "$script")
            local src=$(find_source_file "$source_dir" "$base" "$recursive_flag")
            if [ -z "$src" ] || [ ! -f "$src" ]; then
                rm -f "$script"
                echo "🗑️ 清理无效R产物: $script" >&2
            fi
        done
    fi
}

# 9. 编译文件（支持新增语言）
compile_file() {
    local full_filename=$1
    local lang=$2
    local is_temp=$3  # 1=临时文件，0=普通文件
    local base_dir=$(cat "$COMPILE_CONFIG" 2>/dev/null)

    if [ -z "$base_dir" ] || [ ! -d "$base_dir" ]; then
        echo "❌ 未设置或找不到编译目录，请先运行 'termirun bins'"
        return 1
    fi

    # 完整产物目录路径
    local full_dir="$base_dir/$COMPILE_SUB_DIR"
    clean_invalid_products

    # 解析源文件路径
    local src_file=""
    if [ "$is_temp" -eq 1 ]; then
        # 临时模式：直接使用用户提供的路径
        src_file="$full_filename"
    else
        # 普通模式：从配置的根目录递归查找
        if [[ "$full_filename" == /* ]]; then
            src_file="$full_filename"  # 绝对路径直接使用
        else
            # 读取配置：第一行是根目录，第二行是递归标记
            local source_dir=$(head -n1 "$SOURCE_CONFIG" 2>/dev/null)
            local recursive_flag=$(tail -n1 "$SOURCE_CONFIG" 2>/dev/null || echo 1)

            if [ -z "$source_dir" ] || [ ! -d "$source_dir" ]; then
                source_dir=$(pwd)
                recursive_flag=1  # 默认为递归
            fi

            # 递归查找目标文件
            src_file=$(find_source_file "$source_dir" "$full_filename" "$recursive_flag")
            if [ -z "$src_file" ] || [ ! -f "$src_file" ]; then
                echo "❌ 在源代码目录（含子文件夹）中未找到文件: $full_filename"
                return 1
            fi
        fi
    fi

    if [ ! -f "$src_file" ]; then
        echo "❌ 源文件不存在: $src_file"
        return 1
    fi

    # 生成唯一文件名（临时文件使用完整路径哈希值避免冲突）
    local filename=""
    if [ "$is_temp" -eq 1 ]; then
        # 临时文件：使用路径哈希值作为文件名前缀
        local hash=$(echo -n "$src_file" | md5sum | cut -c1-8)
        filename="${hash}_$(basename "$full_filename" ".$lang")"
    else
        filename=$(basename "$full_filename" ".$lang")
    fi
    
    # 根据语言确定具体产物目录和输出文件
    local out_dir="$full_dir/${lang}_bin"
    local out_file=""
    
    case "$lang" in
        c)
            out_file="$out_dir/${filename}_c"
            if [ ! -f "$out_file" ] || [ "$src_file" -nt "$out_file" ]; then
                echo "正在编译 $src_file..." >&2
                clang "$src_file" -o "$out_file" 2>&1 || return 1
            fi
            ;;
        cpp)
            out_file="$out_dir/${filename}_cpp"
            if [ ! -f "$out_file" ] || [ "$src_file" -nt "$out_file" ]; then
                echo "正在编译 $src_file..." >&2
                clang++ "$src_file" -o "$out_file" 2>&1 || return 1
            fi
            ;;
        java)
            out_file="$out_dir/${filename}.class"
            if [ ! -f "$out_file" ] || [ "$src_file" -nt "$out_file" ]; then
                echo "正在编译 $src_file..." >&2
                javac "$src_file" -d "$out_dir" 2>&1 || return 1
            fi
            ;;
        python)
            out_file="$out_dir/$(basename "$src_file")"
            # Python不需要编译，仅复制文件
            if [ ! -f "$out_file" ] || [ "$src_file" -nt "$out_file" ]; then
                echo "正在准备Python文件 $src_file..." >&2
                cp "$src_file" "$out_file"
                chmod +x "$out_file"
            fi
            ;;
        fortran)
            out_file="$out_dir/${filename}_fortran"
            if [ ! -f "$out_file" ] || [ "$src_file" -nt "$out_file" ]; then
                echo "正在编译 $src_file..." >&2
                gfortran "$src_file" -o "$out_file" 2>&1 || return 1
            fi
            ;;
        r)
            out_file="$out_dir/$(basename "$src_file")"
            # R不需要编译，仅复制文件
            if [ ! -f "$out_file" ] || [ "$src_file" -nt "$out_file" ]; then
                echo "正在准备R文件 $src_file..." >&2
                cp "$src_file" "$out_file"
                chmod +x "$out_file"
            fi
            ;;
        *)
            echo "❌ 不支持的语言类型: $lang"
            return 1
            ;;
    esac

    echo "$out_file"
    return 0
}

# 10. 详细运行模式（cucumber）
run_verbose() {
    local is_temp=0
    local full_filename=""
    
    # 解析参数，判断是否为临时模式
    if [ "$1" = "t" ]; then
        is_temp=1
        full_filename="$2"
        if [ -z "$full_filename" ]; then
            echo "❌ 请指定临时运行的文件路径"
            echo "用法: termirun cucumber t <文件路径>"
            return 1
        fi
    else
        full_filename="$1"
        if [ -z "$full_filename" ]; then
            echo "❌ 请指定完整文件名（包含后缀）"
            echo "用法: termirun cucumber <文件名.后缀>"
            echo "示例: termirun cucumber test.c 或 termirun cucumber program.java"
            return 1
        fi
    fi

    if [ ! -f "$COMPILE_CONFIG" ]; then
        echo "❌ 未设置编译目录，请先运行 'termirun bins'"
        return 1
    fi
    local base_dir=$(cat "$COMPILE_CONFIG")
    local full_dir="$base_dir/$COMPILE_SUB_DIR"

    # 识别文件类型（包含新增语言）
    local lang=""
    if [[ "$full_filename" == *.java ]]; then
        lang="java"
    elif [[ "$full_filename" == *.c ]]; then
        lang="c"
    elif [[ "$full_filename" == *.cpp ]]; then
        lang="cpp"
    elif [[ "$full_filename" == *.py ]]; then
        lang="python"
    elif [[ "$full_filename" == *.f90 ]]; then
        lang="fortran"
    elif [[ "$full_filename" == *.r ]]; then
        lang="r"
    else
        echo "❌ 不支持的文件类型: $full_filename"
        echo "❌ 不支持的文件类型: $full_filename"
        echo "支持的类型: .c (C), .cpp (C++), .java (Java), .py (Python), .f90 (Fortran), .r (R)"
        return 1
    fi

    local out_file=$(compile_file "$full_filename" "$lang" "$is_temp")
    if [ $? -ne 0 ]; then
        echo "❌ 编译失败"
        return 1
    fi

    # 解析实际源文件路径
    local src_file=""
    if [ "$is_temp" -eq 1 ]; then
        src_file="$full_filename"
    else
        if [[ "$full_filename" == /* ]]; then
            src_file="$full_filename"
        else
            local source_dir=$(head -n1 "$SOURCE_CONFIG" 2>/dev/null)
            if [ -n "$source_dir" ] && [ -d "$source_dir" ]; then
                src_file="$source_dir/$full_filename"
            else
                src_file="$full_filename"
            fi
        fi
    fi

    local src_size=$(du -h "$src_file" | cut -f1)
    local out_size=$(du -h "$out_file" | cut -f1)
    local display_name=$(basename "$full_filename" ".$lang")

    echo "=== 编译信息 ==="
    if [ "$is_temp" -eq 1 ]; then
        echo "模式: 临时运行（不改变carrot配置）"
    fi
    echo "源文件: $src_file ($src_size)"
    echo "产物目录: $full_dir/${lang}_bin"
    echo "产物文件: $(basename "$out_file") ($out_size)"

    echo -e "\n=== 运行结果 ==="
    # 运行不同类型的程序（包含新增语言）
    case "$lang" in
        java)
            local class_name=$(basename "$out_file" ".class")
            java -cp "$full_dir/java_bin" "$class_name"
            ;;
        c|cpp|fortran)
            "$out_file"
            ;;
        python)
            python3 "$out_file"
            ;;
        r)
            Rscript "$out_file"
            ;;
    esac

    # 临时文件运行完成后不立即删除，等待clean机制处理
    if [ "$is_temp" -eq 1 ]; then
        echo -e "\n⚠️ 临时文件产物将在下次清理时自动移除"
    fi
}

# 11. 简洁运行模式（cub）
run_simple() {
    local is_temp=0
    local full_filename=""
    
    # 解析参数，判断是否为临时模式
    if [ "$1" = "t" ]; then
        is_temp=1
        full_filename="$2"
        if [ -z "$full_filename" ]; then
            echo "❌ 请指定临时运行的文件路径"
            echo "用法: termirun cub t <文件路径>"
            return 1
        fi
    else
        full_filename="$1"
        if [ -z "$full_filename" ]; then
            echo "❌ 请指定完整文件名（包含后缀）"
            echo "用法: termirun cub <文件名.后缀>"
            echo "示例: termirun cub test.cpp 或 termirun cub app.java"
            return 1
        fi
    fi

    if [ ! -f "$COMPILE_CONFIG" ]; then
        echo "❌ 未设置编译目录，请先运行 'termirun bins'"
        return 1
    fi
    local base_dir=$(cat "$COMPILE_CONFIG")
    local full_dir="$base_dir/$COMPILE_SUB_DIR"

    # 识别文件类型（包含新增语言）
    local lang=""
    if [[ "$full_filename" == *.java ]]; then
        lang="java"
    elif [[ "$full_filename" == *.c ]]; then
        lang="c"
    elif [[ "$full_filename" == *.cpp ]]; then
        lang="cpp"
    elif [[ "$full_filename" == *.py ]]; then
        lang="python"
    elif [[ "$full_filename" == *.f90 ]]; then
        lang="fortran"
    elif [[ "$full_filename" == *.r ]]; then
        lang="r"
    else
        echo "❌ 不支持的文件类型: $full_filename"
        echo "支持的类型: .c (C), .cpp (C++), .java (Java), .py (Python), .f90 (Fortran), .r (R)"
        return 1
    fi

    local out_file=$(compile_file "$full_filename" "$lang" "$is_temp")
    if [ $? -ne 0 ]; then
        echo "❌ 编译失败"
        return 1
    fi

    # 运行不同类型的程序（包含新增语言）
    case "$lang" in
        java)
            local class_name=$(basename "$out_file" ".class")
            java -cp "$full_dir/java_bin" "$class_name"
            ;;
        c|cpp|fortran)
            "$out_file"
            ;;
        python)
            python3 "$out_file"
            ;;
        r)
            Rscript "$out_file"
            ;;
    esac

    # 临时文件运行完成后不立即删除，等待clean机制处理
    if [ "$is_temp" -eq 1 ]; then
        echo "⚠️ 临时产物将在下次清理时自动移除" >&2
    fi
}

# 12. 手动清理
manual_clean() {
    if [ ! -f "$COMPILE_CONFIG" ]; then
        echo "❌ 未设置编译目录，请先运行 'termirun bins'"
        return 1
    fi
    
    echo "=== 开始手动清理失效编译产物 ==="
    clean_invalid_products
    echo "✅ 清理完成（包括临时文件产物）"
}

# 13. 卸载
uninstall() {
    echo "⚠️ 即将卸载 termirun 实例（ID: $INSTANCE_ID）"
    # 新增：显示标签信息
    local current_tag=$(cat "$TAG_FILE" 2>/dev/null)
    if [ -n "$current_tag" ]; then
        echo "实例标签: $current_tag"
    fi
    echo "将删除以下默认内容:"
    echo "  1. 实例配置: $INSTANCE_CONFIG_DIR"
    echo "  2. 目录配置文件: $COMPILE_CONFIG 和 $SOURCE_CONFIG"
    echo "（以下内容将询问是否删除）"
    echo

    # 获取相关目录路径
    local source_dir=$(head -n1 "$SOURCE_CONFIG" 2>/dev/null)
    [ -z "$source_dir" ] && source_dir=$(pwd)  # 默认为当前目录
    local base_dir=$(cat "$COMPILE_CONFIG" 2>/dev/null)
    local comps_dir=""
    [ -n "$base_dir" ] && comps_dir="$base_dir/$COMPILE_SUB_DIR"

    # 询问是否删除comps文件夹
    if [ -n "$comps_dir" ]; then
        read -p "是否删除编译产物目录（$comps_dir）？(y/N) " del_comps
        if [ "$del_comps" = "y" ] || [ "$del_comps" = "Y" ]; then
            if [ -d "$comps_dir" ]; then
                rm -rf "$comps_dir"
                echo "🗑️ 已删除编译产物目录: $comps_dir"
            else
                echo "⚠️ 编译产物目录不存在，跳过删除"
            fi
        else
            echo "⚠️ 保留编译产物目录: $comps_dir"
        fi
    else
        echo "⚠️ 未设置编译产物目录，跳过相关删除"
    fi

    # 询问是否删除六个demo源文件（包含新增语言）
    read -p "是否删除演示生成的6个源文件（$source_dir下的各类演示文件）？(y/N) " del_demo
    if [ "$del_demo" = "y" ] || [ "$del_demo" = "Y" ]; then
        # 逐个删除，忽略不存在的文件
        [ -f "$source_dir/$DEMO_C" ] && rm -f "$source_dir/$DEMO_C" && echo "🗑️ 已删除C演示文件: $source_dir/$DEMO_C"
        [ -f "$source_dir/$DEMO_CPP" ] && rm -f "$source_dir/$DEMO_CPP" && echo "🗑️ 已删除C++演示文件: $source_dir/$DEMO_CPP"
        [ -f "$source_dir/$DEMO_JAVA" ] && rm -f "$source_dir/$DEMO_JAVA" && echo "🗑️ 已删除Java演示文件: $source_dir/$DEMO_JAVA"
        [ -f "$source_dir/$DEMO_PYTHON" ] && rm -f "$source_dir/$DEMO_PYTHON" && echo "🗑️ 已删除Python演示文件: $source_dir/$DEMO_PYTHON"
        [ -f "$source_dir/$DEMO_FORTRAN" ] && rm -f "$source_dir/$DEMO_FORTRAN" && echo "🗑️ 已删除Fortran演示文件: $source_dir/$DEMO_FORTRAN"
        [ -f "$source_dir/$DEMO_R" ] && rm -f "$source_dir/$DEMO_R" && echo "🗑️ 已删除R演示文件: $source_dir/$DEMO_R"
        # 检查是否有未删除的文件
        local remaining=0
        [ -f "$source_dir/$DEMO_C" ] && remaining=1
        [ -f "$source_dir/$DEMO_CPP" ] && remaining=1
        [ -f "$source_dir/$DEMO_JAVA" ] && remaining=1
        [ -f "$source_dir/$DEMO_PYTHON" ] && remaining=1
        [ -f "$source_dir/$DEMO_FORTRAN" ] && remaining=1
        [ -f "$source_dir/$DEMO_R" ] && remaining=1
        [ $remaining -eq 1 ] && echo "⚠️ 部分演示文件已不存在，未执行删除"
    else
        echo "⚠️ 保留所有演示源文件"
    fi

    # 删除实例配置和目录配置文件（必删项）
    rm -rf "$INSTANCE_CONFIG_DIR"
    echo "✅ 已删除实例配置目录: $INSTANCE_CONFIG_DIR"
    
    rm -f "$COMPILE_CONFIG" 2>/dev/null
    rm -f "$SOURCE_CONFIG" 2>/dev/null
    echo "✅ 已删除目录配置文件"

    echo -e "\n🎉 卸载完成"
}

# 14. 反初始化
uninit() {
    if [ ! -f "$INSTANCE_CONFIG_DIR/initialized" ]; then
        echo "❌ 当前实例未初始化，无需反初始化"
        return 1
    fi

    echo -e "\n⚠️ 即将执行反初始化（仅清理当前实例内部配置）"
    # 新增：显示标签信息
    local current_tag=$(cat "$TAG_FILE" 2>/dev/null)
    if [ -n "$current_tag" ]; then
        echo "实例标签: $current_tag"
    fi
    echo "将删除以下内容（不影响编译产物、源代码和其他实例）:"
    echo "  1. 实例配置: $INSTANCE_CONFIG_DIR（含初始化标记）"
    echo "  2. 目录配置文件: $COMPILE_CONFIG 和 $SOURCE_CONFIG"
    echo "  保留内容: 编译产物、源代码文件、编译器、脚本文件本身"

    read -p $'\n请输入 "uninit" 确认反初始化（输入q退出）: ' confirm
    if [ "$confirm" = "q" ] || [ "$confirm" = "Q" ]; then
        echo "已取消反初始化操作"
        return 0
    fi
    
    if [ "$confirm" != "uninit" ]; then
        echo -e "\n🚫 取消反初始化操作"
        return 0
    fi

    echo -e "\n开始反初始化..."
    rm -rf "$INSTANCE_CONFIG_DIR"
    rm -f "$COMPILE_CONFIG" "$SOURCE_CONFIG"
    echo "✅ 已清除当前实例的内部配置和目录配置"

    echo -e "\n🎉 反初始化完成"
    echo "当前实例已恢复至初始状态，运行 './termirun' 可重新初始化"
    echo "原编译产物和源代码目录已保留，重新初始化后可继续使用"
}

# 15. 快速模式（50次无前缀调用机会，支持临时模式）
run_go50() {
    echo "=== 快速模式 ==="
    echo "每次快速模式可以50次无前缀调用cub/cucumber，支持临时模式(t)"
    echo "还支持: oo(查看上一条命令)、kk(执行上一条命令)"
    echo "50次用完或者输入q即退出快速模式，再次输入'./termirun go50'可以唤起下一次"
    echo "使用方法:"
    echo "  - 输入 'cub <文件名>' 运行简洁模式（使用carrot目录）"
    echo "  - 输入 'cub t <文件路径>' 简洁临时模式（任意路径）"
    echo "  - 输入 'cucumber <文件名>' 运行详细模式（使用carrot目录）"
    echo "  - 输入 'cucumber t <文件路径>' 详细临时模式（任意路径）"
    echo "  - 输入 'oo' 显示上一条命令"
    echo "  - 输入 'kk' 执行上一条命令"
    echo "  - 输入 'q' 退出快速模式"
    echo "剩余次数: 50"
    
    local count=50
    while (( count > 0 )); do
        read -p "[$count] > " input
        if [ "$input" = "q" ] || [ "$input" = "Q" ]; then
            echo "已退出快速模式"
            return 0
        fi
        
        # 解析输入命令
        local cmd=$(echo "$input" | awk '{print $1}')
        local arg1=$(echo "$input" | awk '{print $2}')
        local arg2=$(echo "$input" | awk '{print $3}')
        
        # 新增：处理oo和kk命令
        if [ "$cmd" = "oo" ]; then
            show_last_command
        elif [ "$cmd" = "kk" ]; then
            run_last_command
            ((count--))
        elif [ "$cmd" = "cub" ]; then
            if [ "$arg1" = "t" ] && [ -n "$arg2" ]; then
                run_simple "t" "$arg2"
                # 保存命令
                save_last_command "cub t $arg2"
                ((count--))
            elif [ -n "$arg1" ]; then
                run_simple "$arg1"
                # 保存命令
                save_last_command "cub $arg1"
                ((count--))
            else
                echo "❌ 无效命令，使用 'cub <文件>' 或 'cub t <文件路径>'"
            fi
        elif [ "$cmd" = "cucumber" ]; then
            if [ "$arg1" = "t" ] && [ -n "$arg2" ]; then
                run_verbose "t" "$arg2"
                # 保存命令
                save_last_command "cucumber t $arg2"
                ((count--))
            elif [ -n "$arg1" ]; then
                run_verbose "$arg1"
                # 保存命令
                save_last_command "cucumber $arg1"
                ((count--))
            else
                echo "❌ 无效命令，使用 'cucumber <文件>' 或 'cucumber t <文件路径>'"
            fi
        else
            echo "❌ 无效命令，请使用 'cub' 或 'cucumber' 或 'oo' 或 'kk'，输入 'q' 退出"
        fi
        
        if (( count > 0 )); then
            echo "剩余次数: $count"
        fi
    done
    
    echo "⚠️ 已达到50次，自动退出快速模式，可再次输入'./termirun go50'唤起下一次"
}

# 16. 演示文件管理（简化版）
manage_demo_files() {
    echo "=== 演示文件管理 ==="
    
    # 获取源代码目录（严格使用carrot配置）
    local source_dir=$(head -n1 "$SOURCE_CONFIG" 2>/dev/null)
    if [ -z "$source_dir" ] || [ ! -d "$source_dir" ]; then
        echo "❌ 未设置有效的源代码目录，请先运行 'termirun carrot' 配置"
        return 1
    fi
    echo "当前源代码目录（carrot配置）: $source_dir"

    # 检查现有演示文件状态
    local missing=0
    local existing=0
    
    echo -e "\n演示文件状态:"
    for file in "${ALL_DEMOS[@]}"; do
        if [ -f "$source_dir/$file" ]; then
            echo "✅ $file 已存在"
            ((existing++))
        else
            echo "❌ $file 缺失"
            ((missing++))
        fi
    done
    
    # 判断是否完整
    local is_complete=0
    if [ $missing -eq 0 ]; then
        echo -e "\n✅ 所有演示文件均已完整存在"
        is_complete=1
    else
        echo -e "\n⚠️ 存在 $missing 个缺失的演示文件"
    fi

    # 显示操作选项
    echo -e "\n请选择操作:"
    echo "  1 - 清空所有演示文件（删除全部6个文件）"
    echo "  2 - 重置所有演示文件（生成/覆盖全部6个文件）"
    echo "  3 - 退出管理"
    read -p "请输入选项 (1-3): " choice

    case "$choice" in
        1)
            echo -e "\n正在清空所有演示文件..."
            local deleted=0
            for file in "${ALL_DEMOS[@]}"; do
                if [ -f "$source_dir/$file" ]; then
                    rm -f "$source_dir/$file"
                    echo "🗑️ 已删除: $file"
                    ((deleted++))
                fi
            done
            if [ $deleted -eq 0 ]; then
                echo "⚠️ 没有可删除的演示文件"
            else
                echo "✅ 已完成清空操作，共删除 $deleted 个文件"
            fi
            ;;
        2)
            echo -e "\n正在重置所有演示文件（将覆盖现有文件）..."
            generate_demo_files
            echo "✅ 已完成重置操作，所有6个演示文件已生成"
            ;;
        3)
            echo "已退出演示文件管理"
            ;;
        *)
            echo "❌ 无效选项，已退出"
            ;;
    esac
}

# 17. 首次运行初始化
first_run_initialization() {
    if [ -f "$INSTANCE_CONFIG_DIR/initialized" ]; then
        return 0
    fi

    echo "======================================"
    echo "欢迎使用 termirun $VERSION"
    echo "实例路径: $SCRIPT_DIR"
    echo "开始首次运行初始化...（输入q仅退出当前步骤）"
    echo "======================================"
    echo

    echo "[1/5] 环境变量检查..."
    ensure_path
    echo
    read -p "按回车键继续到下一步: " -r
    echo

    echo "[2/5] 查看使用帮助..."
    show_help
    echo
    read -p "按回车键继续到下一步（输入q跳过此步骤）: " -r
    if [ "$REPLY" = "q" ] || [ "$REPLY" = "Q" ]; then
        echo "已跳过帮助信息步骤"
    fi
    echo

    echo "[3/5] 检查编译器环境..."
    check_compilers
    echo
    read -p "按回车键继续到下一步（输入q跳过此步骤）: " -r
    if [ "$REPLY" = "q" ] || [ "$REPLY" = "Q" ]; then
        echo "已跳过编译器检查步骤"
    fi
    echo

    echo "[4/5] 配置编译产物目录..."
    set_compile_path
    echo
    read -p "按回车键继续到下一步（输入q跳过此步骤）: " -r
    if [ "$REPLY" = "q" ] || [ "$REPLY" = "Q" ]; then
        echo "已跳过编译产物目录配置步骤"
    fi
    echo

    echo "[5/5] 配置源代码存放目录..."
    set_source_path
    echo

    mkdir -p "$INSTANCE_CONFIG_DIR"
    touch "$INSTANCE_CONFIG_DIR/initialized"
    echo "======================================"
    echo "✅ 初始化完成！"
    echo "现在可以直接使用以下命令:"
    echo "  - termirun: 主命令"
    echo "  - termirun cub: 简洁运行程序"
    echo "  - termirun cucumber: 详细运行程序"
    echo "  - termirun go50: 进入快速模式"
    echo "  - termirun carrot: 更改源代码存放目录"
    echo "  - termirun ls: 浏览目录结构"
    echo "  - termirun demo: 管理演示文件（生成/清空）"
    echo "  - termirun tag: 管理实例标签"  # 新增tag命令提示
    echo "  - termirun oo: 显示上一条命令"
    echo "  - termirun kk: 执行上一条命令"
    echo "要生成演示文件，请运行: termirun demo 并选择选项2"
    echo "======================================"
}

# 新增：保存上一条命令
save_last_command() {
    local cmd=$1
    echo "$cmd" > "$LAST_COMMAND_FILE"
}

# 新增：显示上一条命令
show_last_command() {
    if [ -f "$LAST_COMMAND_FILE" ]; then
        local last_cmd=$(cat "$LAST_COMMAND_FILE")
        echo "上一条命令: termirun $last_cmd"
    else
        echo "❌ 没有记录的cucumber或cub命令"
    fi
}

# 新增：执行上一条命令
run_last_command() {
    if [ -f "$LAST_COMMAND_FILE" ]; then
        local last_cmd=$(cat "$LAST_COMMAND_FILE")
        echo "执行命令: termirun $last_cmd"
        # 解析命令并执行
        local cmd=$(echo "$last_cmd" | awk '{print $1}')
        local arg1=$(echo "$last_cmd" | awk '{print $2}')
        local arg2=$(echo "$last_cmd" | awk '{print $3}')
        
        if [ "$cmd" = "cucumber" ]; then
            run_verbose "$arg1" "$arg2"
        elif [ "$cmd" = "cub" ]; then
            run_simple "$arg1" "$arg2"
        else
            echo "❌ 无效的历史命令: $last_cmd"
            return 1
        fi
    else
        echo "❌ 没有记录的cucumber或cub命令"
        return 1
    fi
}

# 新增：标签管理命令处理
handle_tag_command() {
    local current_tag=$(cat "$TAG_FILE" 2>/dev/null)
    
    echo "=== 实例标签管理 ==="
    if [ -n "$current_tag" ]; then
        echo "当前标签: $current_tag"
    else
        echo "当前无标签"
    fi
    
    echo "请选择操作:"
    echo "  1 - 修改标签"
    echo "  2 - 删除标签"
    echo "  q - 退出"
    read -p "请输入选项: " choice
    
    case "$choice" in
        1)
            read -p "请输入新标签: " new_tag
            echo "$new_tag" > "$TAG_FILE"
            echo "✅ 标签已更新为: $new_tag"
            ;;
        2)
            > "$TAG_FILE"  # 清空标签文件
            echo "✅ 已删除标签"
            ;;
        q|Q)
            echo "已退出标签管理"
            ;;
        *)
            echo "❌ 无效选项"
            ;;
    esac
}

# 主程序逻辑
current_cmd=$(basename "$0")

# 处理主命令（termirun）
if [ "$current_cmd" = "termirun" ] || [ "$current_cmd" = "$(basename "$SCRIPT_PATH")" ]; then
    # 确保环境变量已配置
    ensure_path
    
    if [ ! -f "$INSTANCE_CONFIG_DIR/initialized" ] && [ -z "$1" ]; then
        first_run_initialization
    else
        case "$1" in
            "")
                # 核心修改：初始化后无参数时仅显示帮助信息
                show_help
                ;;
            "bins")
                set_compile_path
                ;;
            "carrot")
                set_source_path
                ;;
            "compilers")
                check_compilers
                ;;
            "clean")
                manual_clean
                ;;
            "uninstall")
                uninstall
                ;;
            "uninit")
                uninit
                ;;
            "help")
                show_help
                ;;
            "--version")
                show_version
                ;;
            "cucumber")
                # 保存命令
                save_last_command "cucumber $2 $3"
                run_verbose "$2" "$3"  # 支持临时模式参数传递
                ;;
            "cub")
                # 保存命令
                save_last_command "cub $2 $3"
                run_simple "$2" "$3"   # 支持临时模式参数传递
                ;;
            "go50")
                run_go50
                ;;
            "ls")
                handle_ls_command
                ;;
            "demo")
                manage_demo_files  # 简化的演示文件管理命令
                ;;
            # 新增：oo和kk命令
            "oo")
                show_last_command
                ;;
            "kk")
                run_last_command
                ;;
            # 新增：tag命令
            "tag")
                handle_tag_command
                ;;
            *)
                echo "❌ 未知命令: $1"
                echo "使用 'termirun help' 查看可用命令"
                exit 1
                ;;
        esac
    fi
    exit $?
fi
