# 你的项目根目录  
# 项目目录: /Users/lxy/android/zsl/cm_android
# 测试demo 目录: /Users/yl/android/AutoCI
project_path="/Users/yl/android/AutoCI"
# 项目的gradle目录
gradlew_path="${project_path}/gradlew"
# apk 目录
# 测试用目录 /Users/yl/Desktop
apk_path="/Users/yl/Desktop"

# 切换到 项目目录中
cd ${project_path}
echo " "
echo "==>正在切换到 你的项目根目录"
pwd

# 进行代码分时选择
echo " "
echo "==>正在更新分支信息...."
git fetch -p


# checkout master
git checkout master

# 获取所有远程分支信息
echo " "
echo "==>确认当前分支...."
remote_branchs='git branch -a'


git pull

# gradlew文件增加可执行权限
chmod u+x ${gradlew_path}

echo "请选择版本的环境地址"
echo "1:正式环境"
echo "2:测试环境"

read environment


if [ ${environment} = 1 ]; then
	#生成环境
	echo " "
	echo "==>你选择的是生产环境的包..."
	${gradlew_path} assembleRelease -POUT_PUT_DIR_PARA=${apk_path} -info --stacktrace
else
	#测试环境
	echo " "
	echo "==>你选择的是测试环境的包..."
	${gradlew_path} assembleDebug -POUT_PUT_DIR_PARA=${apk_path} -info --stacktrace
fi

