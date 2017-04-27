echo "============================================="
echo ""
echo "             欢迎使用'好人好股'打包脚本"
echo ""
echo "============================================="
echo ""

echo "==> 正在读取路径配置..."
basepath="$(cd `dirname $0`; pwd)/"
path_config="${basepath}path_config.properties"

echo "==> 当前shell目录: ${basepath}"
cd ${basepath}
if [[ ! -f ${path_config} ]]; then
	#statements
	touch path_config.properties

	# 写入git 路径
	echo "==> 输入 git项目代码 路径"
	read read_project_base_path
	echo "git.dir="${read_project_base_path} >> ${path_config}

	# 写入apk 路径
	echo "==> 输入 apk 路径"
	read read_apk_path
	echo "apk.dir="${read_apk_path} >> ${path_config}

fi

echo "==>正在读取路径配置"
config_index=0;
while read path
do
	config_arr[config_index]=`echo $path | cut -d \= -f 2`
	((++config_index))
done < ${path_config}

project_base_path=${config_arr[0]}
apk_path=${config_arr[1]}

echo "==>项目目录: ${project_base_path}"
echo "==>apk目录: ${apk_path}"
# 判断是否存在根目录
if [ ! -d "${project_base_path}/" ];then
	# 根目录不存在 则创建一个根目录
	mkdir "$project_base_path"
fi
# apk目录是否存在
if [[ ! -d "${apk_path}/" ]]; then
	mkdir "$apk_path"
fi

# 项目相关的地址
project_path="${project_base_path}/cm_android"
local_properties_path="${project_path}/local.properties"
gradlew_path="${project_path}/gradlew"

cd ${project_base_path}
echo "==> 已切换到 项目的根目录 "${project_base_path}

# 判断是否存在项目
if [[ ! -d "$project_path" ]]; then
	echo "==> 项目不存在 正在从 git clone"
	git clone https://github.com/SHcmwl/cm_android.git
	cd ${project_path}
	git checkout -t origin/dev
	git checkout master
else
	cd ${project_path}
fi

echo "==> 正在更新分支信息..."
git fetch origin --prune

echo "==> 请选择打包方式:"
echo "==> 1:从分支打包"
echo "==> 2:从Tag打包"
echo "==> q:退出"

read checkout_type
if [[ ${checkout_type} = "q" ]]; then
	#statements
	exit 1
elif [[ ${checkout_type} = 2 ]]; then
	# tag 打包
	git checkout dev
	echo "==> 当前Tag列表"
	git tag
	echo "==> 请输入要打包的Tag"
	read tag_name

	git checkout ${tag_name}

	result_checkout_tag=$?

	if [[ ${result_checkout_tag} != 0 ]]; then
		git checkout -b ${tag_name} ${tag_name}
		result_checkout_tag=$?
		if [[ ${result_checkout_tag} != 0 ]]; then
			#从tag获取代码失败
			echo "==> 从Tag获取代码失败！！"
		fi
	fi
else
	echo "==> 当前分支状态: "
	git branch -r
	# 分支打包
	remote_branchs=`git branch -r`
	# 分割成数组后让使用者选择打包分支
	echo "==> 请选择待打包分支: "
	arr=(${remote_branchs// /})
	index=1
	for i in ${arr[@]}; do
	    #statements
	    if [[ ! ${i:7} =~ "HEAD" ]]; then
	    	echo ${index}". "${i:7}
	    	((index++))
	    fi
	done

	# 读取使用者数据
	read branch_index
	echo "==> 你选择要打包的分支是： ${arr[${branch_index}]}"

	if [[ -z ${branch_index} ]]; then
	    echo "==> Error: 选择的分支序号不合法"
	fi
	# 切换branch并拉取最新代码
	echo "==> 切换到该分支并拉取最新代码..."
	if [[ ${arr[${branch_index}]} =~ "HEAD" ]]; then
	    echo "==> Error: 不能切换到该分支(${arr[${branch_index}]})"
	    exit 1
	fi

	git checkout ${arr[${branch_index}]:7} 
	result_code=$?
	git pull 
	result_code=$?

	if [[ ${result_code} != 0 ]]; then
	    echo "==> Error: 拉取代码失败"
	    exit 1
	fi
fi
# 判断 SDK配置文件是否存在
if [[ ! -f "${local_properties_path}" ]]; then
	# 创建 sdk 配置文件
	touch local.properties

	# 写入sdk 路径
	echo "==>输入 sdk 路径"
	read sdk_path
	echo "sdk.dir="${sdk_path} >> ${local_properties_path}

fi

# gradlew文件增加可执行权限
chmod u+x ${gradlew_path}

echo "==> 请选择版本的环境地址"
echo "==> 1:正式环境"
echo "==> 2:测试环境"
echo "==> q:退出"

read environment

if [[ ${environment} = "q" ]]; then
	#statements
	exit 1
elif [[ ${environment} = 1 ]]; then
	#正式环境
	echo "==> 是否跳过 版本检查 (Y:跳过,N:不跳过)"
	read to_judge_version
	if [[ ${to_judge_version} = "Y" || ${to_judge_version} = "y" ]]; then
		#statements
		echo "==> 正在打包 正式环境 并跳过版本检查..."
		${gradlew_path} clean
		${gradlew_path} assembleRelease -POUT_PUT_DIR_PARA=${apk_path} --info --stacktrace
	else
		echo "==> 正在打包 正式环境..."
		${gradlew_path} clean
		${gradlew_path} assembleFlavor -POUT_PUT_DIR_PARA=${apk_path} --info --stacktrace
	fi
else
	#测试环境
	echo "==> 正在打包 测试环境..."
	${gradlew_path} clean
	${gradlew_path} assembleDebug -POUT_PUT_DIR_PARA=${apk_path} --info --stacktrace
fi

